import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part_item.dart';
import '../providers/project_provider.dart';

class PartsTab extends StatefulWidget {
  const PartsTab({super.key});

  @override
  State<PartsTab> createState() => _PartsTabState();
}

class _PartsTabState extends State<PartsTab> {
  String? _selectedProfile;
  final TextEditingController _stockLengthController = TextEditingController(text: '6000');
  final TextEditingController _bladeThicknessController = TextEditingController(text: '3');
  final TextEditingController _profileHeightController = TextEditingController(text: '40');

  // Controllers for adding/editing part dialog
  final TextEditingController _partLengthController = TextEditingController();
  final TextEditingController _partQtyController = TextEditingController(text: '1');
  String _leftCut = '90';
  String _rightCut = '90';

  @override
  void dispose() {
    _stockLengthController.dispose();
    _bladeThicknessController.dispose();
    _profileHeightController.dispose();
    _partLengthController.dispose();
    _partQtyController.dispose();
    super.dispose();
  }

  bool _cutsMatch(String cutA, String cutB) {
    final normA = cutA == '45' ? '45_up' : cutA;
    final normB = cutB == '45' ? '45_up' : cutB;
    return normA == normB;
  }

  String _flippedCut(String cut) {
    if (cut == '45_up' || cut == '45') return '45_down';
    if (cut == '45_down') return '45_up';
    return '90';
  }

  List<PlacedPartState>? _findOptimalOrientations(
    List<PartItem> sequence,
    double profileHeight,
  ) {
    List<PlacedPartState>? bestConfig;
    double bestWaste = double.infinity;
    int bestWasteSegments = 999999;

    void search(int index, String currentAngle, double currentWaste, int currentSegments, List<PlacedPartState> currentPath) {
      if (currentWaste > bestWaste) return; // Prune if intermediate waste exceeds best total waste

      if (index == sequence.length) {
        // Calculate end waste if the final cut is not 90°
        double endWaste = 0.0;
        if (currentPath.isNotEmpty && currentPath.last.part.rightCut != '90') {
          endWaste = profileHeight;
        }
        final totalWaste = currentWaste + endWaste;
        if (totalWaste < bestWaste ||
            (totalWaste == bestWaste && currentSegments < bestWasteSegments)) {
          bestWaste = totalWaste;
          bestWasteSegments = currentSegments;
          bestConfig = List.from(currentPath);
        }
        return;
      }

      final item = sequence[index];
      final String l1 = item.leftCut;
      final String r1 = item.rightCut;

      final String l2 = _flippedCut(r1);
      final String r2 = _flippedCut(l1);

      final String l3 = _flippedCut(l1);
      final String r3 = _flippedCut(r1);

      final String l4 = r1;
      final String r4 = l1;

      final List<List<String>> orientations = [
        [l1, r1],
        [l2, r2],
        [l3, r3],
        [l4, r4],
      ];

      for (final orient in orientations) {
        // Start waste for the first piece if it starts with a slant
        double stepWaste = 0.0;
        int stepSegment = 0;
        if (index == 0) {
          if (orient[0] != '90') {
            stepWaste = profileHeight;
          }
        } else {
          if (!_cutsMatch(currentAngle, orient[0])) {
            stepWaste = profileHeight;
            stepSegment = 1;
          }
        }

        final nextPart = item.copyWith(leftCut: orient[0], rightCut: orient[1]);
        currentPath.add(PlacedPartState(nextPart, stepWaste));
        
        search(index + 1, orient[1], currentWaste + stepWaste, currentSegments + stepSegment, currentPath);
        
        currentPath.removeLast();
      }
    }

    search(0, '90', 0.0, 0, []);
    return bestConfig;
  }

  List<PlacedPart> _buildPlacementsForSequence(
    List<PartItem> sequence,
    double stockLength,
    double bladeThickness,
    double profileHeight,
  ) {
    final optimalStates = _findOptimalOrientations(sequence, profileHeight);
    if (optimalStates == null) return [];

    final List<PlacedPart> placements = [];
    double currentUsed = 0.0;

    for (int i = 0; i < optimalStates.length; i++) {
      final state = optimalStates[i];
      final double waste = state.waste;
      final PartItem part = state.part;
      final bool isLast = (i == optimalStates.length - 1);
      final double neededCut = isLast ? 0.0 : bladeThickness;

      final double endX = currentUsed + waste + part.length + neededCut;
      if (endX > stockLength) {
        return []; // Doesn't fit in the pipe
      }

      if (waste > 0) {
        final String prevRightCut = placements.isEmpty ? '90' : placements.last.part.rightCut;
        placements.add(PlacedPart(
          part: PartItem(
            id: 'waste_${DateTime.now().microsecondsSinceEpoch}_${part.id}',
            projectId: part.projectId,
            profileName: part.profileName,
            length: waste,
            quantity: 1,
            leftCut: prevRightCut,
            rightCut: part.leftCut,
          ),
          startX: currentUsed,
          endX: currentUsed + waste,
          isWaste: true,
        ));
        currentUsed += waste;
      }

      placements.add(PlacedPart(
        part: part,
        startX: currentUsed,
        endX: currentUsed + part.length,
      ));
      currentUsed += part.length + neededCut;
    }

    return placements;
  }

  List<PlacedPart> _optimizePipeSequence(
    List<PartItem> pipeParts,
    double stockLength,
    double bladeThickness,
    double profileHeight,
  ) {
    if (pipeParts.isEmpty) return [];

    // If there are too many parts, permutation search is too slow.
    // In that case, just return the original list.
    if (pipeParts.length > 8) {
      return _buildPlacementsForSequence(pipeParts, stockLength, bladeThickness, profileHeight);
    }

    double bestTotalWaste = double.infinity;
    int bestWasteSegments = 999999;
    List<PlacedPart>? bestPlacements;

    // Helper to generate permutations and find the best one using standard Heap's algorithm
    void permute(List<PartItem> list, int k) {
      if (k == 1) {
        final placements = _buildPlacementsForSequence(list, stockLength, bladeThickness, profileHeight);
        if (placements.isNotEmpty) {
          // Calculate total waste including start and end waste
          double totalWaste = 0.0;
          
          // Start waste
          if (placements.first.part.leftCut != '90') {
            totalWaste += profileHeight;
          }
          
          // Intermediate waste
          for (final p in placements) {
            if (p.isWaste) {
              totalWaste += p.part.length;
            }
          }
          
          // End waste
          if (placements.last.part.rightCut != '90') {
            totalWaste += profileHeight;
          }

          final int currentWasteSegments = placements.where((p) => p.isWaste).length;

          if (totalWaste < bestTotalWaste || 
              (totalWaste == bestTotalWaste && currentWasteSegments < bestWasteSegments)) {
            bestTotalWaste = totalWaste;
            bestWasteSegments = currentWasteSegments;
            bestPlacements = placements;
          }
        }
        return;
      }

      // Generate permutations with k-th unaltered
      permute(list, k - 1);

      // Generate permutations for list[0..k-2] with k-th swapped with each list[i]
      for (int i = 0; i < k - 1; i++) {
        if (k % 2 == 0) {
          final temp = list[i];
          list[i] = list[k - 1];
          list[k - 1] = temp;
        } else {
          final temp = list[0];
          list[0] = list[k - 1];
          list[k - 1] = temp;
        }
        permute(list, k - 1);
      }
    }

    permute(List.from(pipeParts), pipeParts.length);

    return bestPlacements ?? _buildPlacementsForSequence(pipeParts, stockLength, bladeThickness, profileHeight);
  }

  // Linear layout solver algorithm (1D Bin Packing with 45° cuts optimization)
  List<StockPipe> _calculateLayout({
    required List<PartItem> parts,
    required double stockLength,
    required double bladeThickness,
    required double profileHeight,
  }) {
    // 1. Flatten the parts list (expand quantity)
    final List<PartItem> remainingItems = [];
    for (final p in parts) {
      for (int i = 0; i < p.quantity; i++) {
        remainingItems.add(p);
      }
    }

    // 2. Sort by length descending, then by number of 45-degree cuts descending
    remainingItems.sort((a, b) {
      final lenComp = b.length.compareTo(a.length);
      if (lenComp != 0) return lenComp;

      int aCuts = (a.leftCut.startsWith('45') ? 1 : 0) + (a.rightCut.startsWith('45') ? 1 : 0);
      int bCuts = (b.leftCut.startsWith('45') ? 1 : 0) + (b.rightCut.startsWith('45') ? 1 : 0);
      return bCuts.compareTo(aCuts);
    });

    final List<StockPipe> pipes = [];

    // 3. Pack bin-by-bin
    while (remainingItems.isNotEmpty) {
      final pipe = StockPipe(length: stockLength);
      pipes.add(pipe);

      while (true) {
        final double currentUsed = pipe.placements.isEmpty
            ? 0.0
            : pipe.placements.last.endX + bladeThickness;
        final String currentAngle = pipe.placements.isEmpty
            ? '90'
            : pipe.placements.last.part.rightCut;

        // Find all remaining items that can physically fit in any of their 4 valid orientations
        final List<PartPlacementCandidate> candidates = [];
        for (final item in remainingItems) {
          final String l1 = item.leftCut;
          final String r1 = item.rightCut;

          final String l2 = _flippedCut(r1);
          final String r2 = _flippedCut(l1);

          final String l3 = _flippedCut(l1);
          final String r3 = _flippedCut(r1);

          final String l4 = r1;
          final String r4 = l1;

          final List<List<String>> orientations = [
            [l1, r1], // 1. Original
            [l2, r2], // 2. Flipped Horizontal
            [l3, r3], // 3. Flipped Vertical
            [l4, r4], // 4. Rotated 180
          ];

          double bestWaste = double.infinity;
          List<String>? bestOrientation;

          for (final orient in orientations) {
            final double waste = (pipe.placements.isEmpty || _cutsMatch(currentAngle, orient[0]))
                ? 0.0
                : profileHeight;
            if (waste < bestWaste) {
              bestWaste = waste;
              bestOrientation = orient;
            }
          }

          if (bestOrientation != null) {
            final double endX = currentUsed + bestWaste + item.length;
            if (endX <= stockLength) {
              candidates.add(PartPlacementCandidate(
                part: item,
                leftCut: bestOrientation[0],
                rightCut: bestOrientation[1],
                waste: bestWaste,
                endX: endX,
              ));
            }
          }
        }

        if (candidates.isEmpty) {
          break; // No more items fit in this pipe
        }

        // Select the best candidate:
        // We prioritize matching angles for items within a certain length window of the largest item that fits.
        final double maxLength = candidates.first.part.length;
        const double windowSize = 500.0; // Search within 500mm of max length

        final List<PartPlacementCandidate> windowCandidates = candidates
            .where((c) => c.part.length >= maxLength - windowSize)
            .toList();

        final List<PartPlacementCandidate> matchingCandidates = windowCandidates
            .where((c) => c.waste == 0.0)
            .toList();

        PartPlacementCandidate selected;
        if (matchingCandidates.isNotEmpty) {
          selected = matchingCandidates.first;
        } else {
          selected = candidates.first;
        }

        // Calculate final placement coordinates
        final double wasteLength = selected.waste;
        final PartItem selectedPart = selected.part.copyWith(
          leftCut: selected.leftCut,
          rightCut: selected.rightCut,
        );

        double startX = pipe.placements.isEmpty
            ? 0.0
            : pipe.placements.last.endX + bladeThickness;
        if (wasteLength > 0) {
          pipe.placements.add(PlacedPart(
            part: PartItem(
              id: 'waste_${DateTime.now().microsecondsSinceEpoch}_${selectedPart.id}',
              projectId: selectedPart.projectId,
              profileName: selectedPart.profileName,
              length: wasteLength,
              quantity: 1,
              leftCut: pipe.placements.last.part.rightCut,
              rightCut: selectedPart.leftCut,
            ),
            startX: startX,
            endX: startX + wasteLength,
            isWaste: true,
          ));
          startX += wasteLength;
        }

        pipe.placements.add(PlacedPart(
          part: selectedPart,
          startX: startX,
          endX: startX + selectedPart.length,
        ));

        remainingItems.remove(selected.part);
      }

      // Optimize placements inside this pipe to minimize total waste (including start and end trim cuts)
      final List<PartItem> pipeParts = [];
      for (final p in pipe.placements) {
        if (!p.isWaste) {
          final originalPart = parts.firstWhere((item) => item.id == p.part.id, orElse: () => p.part);
          pipeParts.add(originalPart);
        }
      }

      final optimizedPlacements = _optimizePipeSequence(
        pipeParts,
        stockLength,
        bladeThickness,
        profileHeight,
      );

      if (optimizedPlacements.isNotEmpty) {
        pipe.placements.clear();
        pipe.placements.addAll(optimizedPlacements);
      }
    }

    return pipes;
  }

  void _showAddPartDialog(BuildContext context, ProjectProvider provider, {PartItem? editingPart}) {
    if (editingPart != null) {
      _partLengthController.text = editingPart.length.toInt().toString();
      _partQtyController.text = editingPart.quantity.toString();
      _leftCut = editingPart.leftCut == '45' ? '45_up' : editingPart.leftCut;
      _rightCut = editingPart.rightCut == '45' ? '45_up' : editingPart.rightCut;
    } else {
      _partLengthController.clear();
      _partQtyController.text = '1';
      _leftCut = '90';
      _rightCut = '90';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(editingPart == null ? 'Добавить деталь' : 'Редактировать деталь'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _partLengthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Длина детали (мм)',
                        hintText: 'например, 1500',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _partQtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Количество (шт)',
                        hintText: 'например, 4',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Углы реза:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Левый конец', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              DropdownButtonFormField<String>(
                                value: _leftCut,
                                items: const [
                                  DropdownMenuItem(value: '90', child: Text('Ровный (90°)')),
                                  DropdownMenuItem(value: '45_up', child: Text('Снизу вверх (45° /)')),
                                  DropdownMenuItem(value: '45_down', child: Text('Сверху вниз (45° \\)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      _leftCut = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Правый конец', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              DropdownButtonFormField<String>(
                                value: _rightCut,
                                items: const [
                                  DropdownMenuItem(value: '90', child: Text('Ровный (90°)')),
                                  DropdownMenuItem(value: '45_up', child: Text('Снизу вверх (45° /)')),
                                  DropdownMenuItem(value: '45_down', child: Text('Сверху вниз (45° \\)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      _rightCut = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final double len = double.tryParse(_partLengthController.text) ?? 0.0;
                    final int qty = int.tryParse(_partQtyController.text) ?? 0;
                    if (len <= 0 || qty <= 0) return;

                    final part = PartItem(
                      id: editingPart?.id ?? 'part_${DateTime.now().millisecondsSinceEpoch}',
                      projectId: (provider.selectedProject!.id as num).toInt(),
                      profileName: _selectedProfile ?? 'Без имени',
                      length: len,
                      quantity: qty,
                      leftCut: _leftCut,
                      rightCut: _rightCut,
                    );

                    if (editingPart == null) {
                      provider.addProjectPart(part);
                    } else {
                      provider.updateProjectPart(part);
                    }

                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4081),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(editingPart == null ? 'Добавить' : 'Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddProfileDialog(BuildContext context, ProjectProvider provider) {
    final controller = TextEditingController();
    
    // Build list of suggested profile names from project materials
    final List<String> suggestions = provider.selectedProject?.items
        .where((i) => i.name.toLowerCase().contains('труб') || i.name.toLowerCase().contains('профил'))
        .map((i) => i.name)
        .toList() ?? [];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Новый профиль'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Название профиля / трубы',
                  hintText: 'например, Труба 40х20х2',
                ),
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Быстрый выбор из сметы:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: suggestions.map((name) {
                    // Extract simpler name if too long
                    final cleanName = name.replaceAll(RegExp(r'(Арматура|Труба профильная|Труба стальная электросварная)\s*'), '');
                    return ActionChip(
                      label: Text(cleanName, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        controller.text = name;
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _selectedProfile = name;
                  });
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4081),
                foregroundColor: Colors.black,
              ),
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final allParts = provider.projectParts;

        // Get list of all profiles currently defined in parts + our state variable
        final Set<String> profiles = allParts.map((p) => p.profileName).toSet();
        if (_selectedProfile != null) {
          profiles.add(_selectedProfile!);
        }

        // If still empty and project has some materials, prefill selectedProfile with first pipe in project
        if (profiles.isEmpty) {
          final matchingItems = provider.selectedProject?.items.where(
            (i) => i.name.toLowerCase().contains('труб') || i.name.toLowerCase().contains('профил'),
          ).toList();

          final firstPipeItem = (matchingItems != null && matchingItems.isNotEmpty)
              ? matchingItems.first
              : (provider.selectedProject?.items.isNotEmpty == true
                  ? provider.selectedProject!.items.first
                  : null);

          if (firstPipeItem != null) {
            profiles.add(firstPipeItem.name);
            _selectedProfile = firstPipeItem.name;
          }
        }

        // Setup active profile
        if (_selectedProfile == null && profiles.isNotEmpty) {
          _selectedProfile = profiles.first;
        }

        final activeProfileParts = allParts.where((p) => p.profileName == _selectedProfile).toList();

        // Parse config values
        final double stockLength = double.tryParse(_stockLengthController.text) ?? 6000.0;
        final double bladeThickness = double.tryParse(_bladeThicknessController.text) ?? 3.0;
        final double profileHeight = double.tryParse(_profileHeightController.text) ?? 40.0;

        // Run linear layout solver
        final List<StockPipe> pipes = _calculateLayout(
          parts: activeProfileParts,
          stockLength: stockLength,
          bladeThickness: bladeThickness,
          profileHeight: profileHeight,
        );

        // Stats
        final int totalPipesCount = pipes.length;
        final double totalPartsLength = activeProfileParts.fold(0.0, (sum, p) => sum + (p.length * p.quantity));
        
        double totalWaste = 0.0;
        for (final pipe in pipes) {
          double pipePartsLength = 0.0;
          for (final placement in pipe.placements) {
            if (!placement.isWaste) {
              pipePartsLength += placement.part.length;
            }
          }
          totalWaste += (stockLength - pipePartsLength);
        }
        
        final double efficiency = (totalPipesCount > 0) 
            ? (totalPartsLength / (totalPipesCount * stockLength)) * 100.0 
            : 0.0;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Selector of Profiles / Pipes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'МАРКА ПРОФИЛЯ / ТРУБЫ',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: profiles.isEmpty
                                  ? const Text('Нет добавленных профилей', style: TextStyle(color: Colors.grey))
                                  : DropdownButtonFormField<String>(
                                      value: _selectedProfile,
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: profiles.map((p) {
                                        return DropdownMenuItem(
                                          value: p,
                                          child: Text(
                                            p,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedProfile = val;
                                        });
                                      },
                                    ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: () => _showAddProfileDialog(context, provider),
                              tooltip: 'Добавить профиль',
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_selectedProfile == null) ...[
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'Пожалуйста, создайте или выберите профиль,\nчтобы начать добавлять детали.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  
                  // 2. Parts Management Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'СПИСОК ДЕТАЛЕЙ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddPartDialog(context, provider),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Добавить'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4081).withOpacity(0.15),
                          foregroundColor: const Color(0xFFFF4081),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  activeProfileParts.isEmpty
                      ? Card(
                          color: const Color(0xFF1E1E1E),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            child: const Column(
                              children: [
                                Icon(Icons.playlist_add, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Деталей пока нет.\nНажмите «Добавить», чтобы занести размеры.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeProfileParts.length,
                          itemBuilder: (context, index) {
                            final part = activeProfileParts[index];
                            final String cutLabel = _getCutLabel(part.leftCut, part.rightCut);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF4081).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${part.length.toInt()} мм',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF4081)),
                                  ),
                                ),
                                title: Text('Количество: ${part.quantity} шт.'),
                                subtitle: Text('Срезы: $cutLabel', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                                      onPressed: () => _showAddPartDialog(context, provider, editingPart: part),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                      onPressed: () {
                                        provider.deleteProjectPart(part.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  const SizedBox(height: 16),

                  // 3. Layout Options
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text('Параметры раскроя', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(
                        'Профиль: ${stockLength.toInt()} мм, рез: ${bladeThickness.toInt()} мм, высота: ${profileHeight.toInt()} мм',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _stockLengthController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Профиль (мм)',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _bladeThicknessController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Пропил (мм)',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _profileHeightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Профиль H (мм)',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // 4. Graphical and Text Results
                  if (activeProfileParts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 8),
                    
                    const Text(
                      'РЕЗУЛЬТАТЫ РАСКРОЯ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // Stats card
                    Card(
                      color: const Color(0xFF161616),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Купить целых профилей:', style: TextStyle(color: Colors.grey)),
                                Text(
                                  '$totalPipesCount шт. (по ${(stockLength / 1000).toStringAsFixed(1)} м)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF4081)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Общая длина деталей:', style: TextStyle(color: Colors.grey)),
                                Text('${(totalPartsLength / 1000).toStringAsFixed(2)} м', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Общая длина отходов:', style: TextStyle(color: Colors.grey)),
                                Text('${(totalWaste / 1000).toStringAsFixed(2)} м', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Эффективность раскроя:', style: TextStyle(color: Colors.grey)),
                                Text('${efficiency.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    const Text(
                      'КАРТА РАСПИЛА',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),

                    // Draw layout for each pipe
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pipes.length,
                      itemBuilder: (context, pipeIndex) {
                        final pipe = pipes[pipeIndex];
                        final double usedInPipe = pipe.placements.fold(0.0, (sum, p) => sum + p.part.length);
                        final double pipeWaste = stockLength - usedInPipe;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Профиль №${pipeIndex + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'Испол. ${usedInPipe.toInt()} мм / Ост. ${pipeWaste.toInt()} мм',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              
                              // Visual pipe bar representation
                              Container(
                                height: 55,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2C),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: PipeLayoutPainter(
                                    placements: pipe.placements,
                                    stockLength: stockLength,
                                    profileHeight: profileHeight,
                                    getPartColor: _getPartColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCut(String cut) {
    if (cut == '90') return 'Ровный (90°)';
    if (cut == '45_up' || cut == '45') return 'Снизу вверх (45° /)';
    if (cut == '45_down') return r'Сверху вниз (45° \)';
    return cut;
  }

  String _getCutLabel(String left, String right) {
    return '${_formatCut(left)} / ${_formatCut(right)}';
  }

  // Consistent color palette for pipe parts of different sizes
  Color _getPartColor(double length) {
    final int hash = length.toInt().hashCode;
    final List<Color> colors = [
      const Color(0xFF00BFA5), // Teal Accent
      const Color(0xFF0288D1), // Sky Blue
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFF388E3C), // Dark Green
      const Color(0xFFFBC02D), // Golden Yellow
      const Color(0xFFD32F2F), // Muted Red
      const Color(0xFF1976D2), // Dark Blue
      const Color(0xFFE64A19), // Orange-Red
      const Color(0xFF0097A7), // Cyan
    ];
    return colors[hash % colors.length].withOpacity(0.65);
  }
}

// Layout Structs
class StockPipe {
  final double length;
  final List<PlacedPart> placements = [];

  StockPipe({required this.length});

  double get usedLength {
    if (placements.isEmpty) return 0.0;
    return placements.last.endX;
  }
}

class PlacedPart {
  final PartItem part;
  final double startX;
  final double endX;
  final bool isWaste;

  PlacedPart({
    required this.part,
    required this.startX,
    required this.endX,
    this.isWaste = false,
  });
}

class PartPlacementCandidate {
  final PartItem part;
  final String leftCut;
  final String rightCut;
  final double waste;
  final double endX;

  PartPlacementCandidate({
    required this.part,
    required this.leftCut,
    required this.rightCut,
    required this.waste,
    required this.endX,
  });
}

class PlacedPartState {
  final PartItem part;
  final double waste;
  PlacedPartState(this.part, this.waste);
}

class PipeLayoutPainter extends CustomPainter {
  final List<PlacedPart> placements;
  final double stockLength;
  final double profileHeight;
  final Color Function(double) getPartColor;

  PipeLayoutPainter({
    required this.placements,
    required this.stockLength,
    required this.profileHeight,
    required this.getPartColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double dx = 10.0; // 3D projection X-offset
    const double dy = 10.0; // 3D projection Y-offset
    
    final double scale = size.width > dx ? (size.width - dx) / stockLength : 1.0;
    final double hDraw = size.height;
    double hDrawScale = 35.0; // Dynamic visual offset in pixels
    
    // Scale down visual slant for short real parts to prevent them from looking like triangles
    for (final p in placements) {
      if (!p.isWaste) {
        final double len = (p.endX - p.startX) * scale;
        final String lCut = p.part.leftCut;
        final String rCut = p.part.rightCut;
        final double lUnit = (lCut == '45_up' || lCut == '45') ? 1.0 : (lCut == '45_down' ? -1.0 : 0.0);
        final double rUnit = (rCut == '45_up' || rCut == '45') ? 1.0 : (rCut == '45_down' ? -1.0 : 0.0);
        
        final double diffUnits = (lUnit - rUnit).abs();
        if (diffUnits > 0) {
          final double maxH = (len * 0.5) / diffUnits;
          if (maxH < hDrawScale) {
            hDrawScale = maxH;
          }
        }
      }
    }
    if (hDrawScale < 10.0) {
      hDrawScale = 10.0; // Ensure slant remains visible
    }

    double getSlantVal(String cut) {
      if (cut == '45_up' || cut == '45') {
        return hDrawScale;
      } else if (cut == '45_down') {
        return -hDrawScale;
      }
      return 0.0;
    }

    // Build initial slant offsets for each boundary.
    // There are placements.length + 1 boundaries.
    final List<double> slants = List.filled(placements.length + 1, 0.0);
    if (placements.isNotEmpty) {
      for (int i = 0; i <= placements.length; i++) {
        if (i == 0) {
          slants[i] = getSlantVal(placements[0].part.leftCut);
        } else if (i == placements.length) {
          slants[i] = getSlantVal(placements[i - 1].part.rightCut);
        } else {
          // Boundary between placement i-1 and placement i
          slants[i] = getSlantVal(placements[i].part.leftCut);
        }
      }
    }

    // Calculate unscaled sequential boundaries at the bottom to guarantee no crossing slants
    final List<double> bottomX = List.filled(placements.length + 1, 0.0);
    bottomX[0] = 0.0;
    for (int i = 0; i < placements.length; i++) {
      final double len = (placements[i].endX - placements[i].startX) * scale;
      final double diff = slants[i] - slants[i + 1];
      final double step = len > diff ? len : diff;
      bottomX[i + 1] = bottomX[i] + step;
    }

    final double remainderLen = placements.isNotEmpty && placements.last.endX < stockLength
        ? (stockLength - placements.last.endX) * scale
        : 0.0;

    final double totalDrawnWidth = bottomX[placements.length] +
        (placements.isNotEmpty && placements.last.endX < stockLength
            ? (remainderLen > slants[placements.length]
                ? remainderLen
                : slants[placements.length])
            : 0.0);

    double adjustScale = 1.0;
    if (totalDrawnWidth > size.width - dx) {
      adjustScale = (size.width - dx) / totalDrawnWidth;
    }

    // Scale boundaries and slants to fit container perfectly
    for (int i = 0; i < bottomX.length; i++) {
      bottomX[i] *= adjustScale;
    }
    for (int i = 0; i < slants.length; i++) {
      slants[i] *= adjustScale;
    }

    // Draw background slot
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF151515)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    final Paint outlinePaint = Paint()
      ..color = const Color(0xFF121212)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw segments
    for (int i = 0; i < placements.length; i++) {
      final placement = placements[i];
      final part = placement.part;

      // Front face coordinates using calculated and scaled boundaries
      final double xStartBottom = bottomX[i];
      final double xStartTop = xStartBottom + slants[i];
      final double xEndBottom = bottomX[i + 1];
      final double xEndTop = xEndBottom + slants[i + 1];

      // Define face colors
      final Color baseColor = placement.isWaste
          ? Colors.orange.withOpacity(0.35)
          : getPartColor(part.length);

      final Color topColor = Color.lerp(baseColor, Colors.white, 0.20)!;
      final Color sideColor = Color.lerp(baseColor, Colors.black, 0.25)!;

      final Paint frontPaint = Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill;

      final Paint topPaint = Paint()
        ..color = topColor
        ..style = PaintingStyle.fill;

      final Paint sidePaint = Paint()
        ..color = sideColor
        ..style = PaintingStyle.fill;

      // 1. Draw Front Face
      final Path frontPath = Path()
        ..moveTo(xStartTop, dy)
        ..lineTo(xEndTop, dy)
        ..lineTo(xEndBottom, hDraw)
        ..lineTo(xStartBottom, hDraw)
        ..close();
      canvas.drawPath(frontPath, frontPaint);
      canvas.drawPath(frontPath, outlinePaint);

      // 2. Draw Top Face
      final Path topPath = Path()
        ..moveTo(xStartTop + dx, 0.0)
        ..lineTo(xEndTop + dx, 0.0)
        ..lineTo(xEndTop, dy)
        ..lineTo(xStartTop, dy)
        ..close();
      canvas.drawPath(topPath, topPaint);
      canvas.drawPath(topPath, outlinePaint);

      // 3. Draw Right End Face (only if this is the last placement and there is no remainder)
      final bool isLastSegment = (i == placements.length - 1);
      final bool hasNoRemainder = !(placements.last.endX < stockLength);
      if (isLastSegment && hasNoRemainder) {
        final Path sidePath = Path()
          ..moveTo(xEndTop, dy)
          ..lineTo(xEndTop + dx, 0.0)
          ..lineTo(xEndBottom + dx, hDraw - dy)
          ..lineTo(xEndBottom, hDraw)
          ..close();
        canvas.drawPath(sidePath, sidePaint);
        canvas.drawPath(sidePath, outlinePaint);
      }

      // Draw text labels
      if (!placement.isWaste) {
        final double xCenterTop = (xStartTop + xEndTop) / 2.0;
        final double xCenterBottom = (xStartBottom + xEndBottom) / 2.0;
        final double xCenter = (xCenterTop + xCenterBottom) / 2.0;

        final String text = '${part.length.toInt()} мм';
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              shadows: [
                Shadow(
                  color: Color(0xD9000000),
                  offset: Offset(0.0, 1.0),
                  blurRadius: 2.0,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        String formatCutForText(String cut) {
          if (cut == '45_up' || cut == '45') return '45/';
          if (cut == '45_down') return r'45\';
          return cut;
        }
        final String slantText = '${formatCutForText(part.leftCut)}/${formatCutForText(part.rightCut)}°';
        final slantPainter = TextPainter(
          text: TextSpan(
            text: slantText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
              fontSize: 8,
              shadows: const [
                Shadow(
                  color: Color(0xD9000000),
                  offset: Offset(0.0, 1.0),
                  blurRadius: 2.0,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final double textY = dy + (hDraw - dy - (textPainter.height + slantPainter.height)) / 2.0;
        textPainter.paint(canvas, Offset(xCenter - textPainter.width / 2.0, textY));
        slantPainter.paint(canvas, Offset(xCenter - slantPainter.width / 2.0, textY + textPainter.height));
      } else {
        final double xCenter = ((xStartBottom + xEndBottom) / 2.0 + (xStartTop + xEndTop) / 2.0) / 2.0;
        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'Опилок',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8,
              fontStyle: FontStyle.italic,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0.0, 1.0),
                  blurRadius: 1.0,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(xCenter - textPainter.width / 2.0, dy + (hDraw - dy - textPainter.height) / 2.0));
      }
    }

    // Draw remaining empty space at the end
    if (placements.isNotEmpty && placements.last.endX < stockLength) {
      final double xStart = placements.last.endX;
      final double xStartBottom = bottomX[placements.length];
      final double xStartTop = xStartBottom + slants[placements.length];
      final double xEnd = size.width - dx;

      // Remainder coordinates
      final Path frontPath = Path()
        ..moveTo(xStartTop, dy)
        ..lineTo(xEnd, dy)
        ..lineTo(xEnd, hDraw)
        ..lineTo(xStartBottom, hDraw)
        ..close();

      final Path topPath = Path()
        ..moveTo(xStartTop + dx, 0.0)
        ..lineTo(xEnd + dx, 0.0)
        ..lineTo(xEnd, dy)
        ..lineTo(xStartTop, dy)
        ..close();

      final Path sidePath = Path()
        ..moveTo(xEnd, dy)
        ..lineTo(xEnd + dx, 0.0)
        ..lineTo(xEnd + dx, hDraw - dy)
        ..lineTo(xEnd, hDraw)
        ..close();

      final Color remainderBase = Colors.grey.withOpacity(0.15);
      final Color topColor = Color.lerp(remainderBase, Colors.white, 0.20)!;
      final Color sideColor = Color.lerp(remainderBase, Colors.black, 0.25)!;

      final Paint frontPaint = Paint()
        ..color = remainderBase
        ..style = PaintingStyle.fill;

      final Paint topPaint = Paint()
        ..color = topColor
        ..style = PaintingStyle.fill;

      final Paint sidePaint = Paint()
        ..color = sideColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(frontPath, frontPaint);
      canvas.drawPath(frontPath, outlinePaint);

      canvas.drawPath(topPath, topPaint);
      canvas.drawPath(topPath, outlinePaint);

      canvas.drawPath(sidePath, sidePaint);
      canvas.drawPath(sidePath, outlinePaint);

      final double xCenter = (xStartBottom + xEnd) / 2.0;
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Остаток ${(stockLength - xStart).toInt()} мм',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(
                color: Color(0xD9000000),
                offset: Offset(0.0, 1.0),
                blurRadius: 2.0,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(xCenter - textPainter.width / 2.0, dy + (hDraw - dy - textPainter.height) / 2.0));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
