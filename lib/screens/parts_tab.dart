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

  // Linear layout solver algorithm (1D Bin Packing with 45° cuts consideration)
  List<StockPipe> _calculateLayout({
    required List<PartItem> parts,
    required double stockLength,
    required double bladeThickness,
    required double profileHeight,
  }) {
    // 1. Flatten the parts list (expand quantity)
    final List<PartItem> flatItems = [];
    for (final p in parts) {
      for (int i = 0; i < p.quantity; i++) {
        flatItems.add(p);
      }
    }

    // 2. Sort by length descending (First Fit Decreasing heuristic)
    flatItems.sort((a, b) => b.length.compareTo(a.length));

    final List<StockPipe> pipes = [];

    // 3. Pack items
    for (final item in flatItems) {
      bool placed = false;

      // Try to fit in existing pipes
      for (final pipe in pipes) {
        if (_tryPlaceItem(pipe, item, stockLength, bladeThickness, profileHeight)) {
          placed = true;
          break;
        }
      }

      // If didn't fit, create a new pipe
      if (!placed) {
        final newPipe = StockPipe(length: stockLength);
        _placeItemInPipe(newPipe, item, 0.0, bladeThickness);
        pipes.add(newPipe);
      }
    }

    return pipes;
  }

  bool _tryPlaceItem(
    StockPipe pipe,
    PartItem item,
    double stockLength,
    double bladeThickness,
    double profileHeight,
  ) {
    if (pipe.placements.isEmpty) {
      _placeItemInPipe(pipe, item, 0.0, bladeThickness);
      return true;
    }

    final last = pipe.placements.last;
    double startX = last.endX;
    
    // Check if cuts match (both 45 or both 90)
    final bool cutsMatch = (last.part.rightCut == item.leftCut);

    double wasteLength = 0.0;
    if (!cutsMatch) {
      // Non-matching cuts require a diagonal scrap piece of length 'profileHeight'
      wasteLength = profileHeight;
    }

    double endX = startX + wasteLength + item.length + bladeThickness;

    if (endX <= stockLength) {
      if (wasteLength > 0) {
        // Place a waste segment
        pipe.placements.add(PlacedPart(
          part: PartItem(
            id: 'waste_${DateTime.now().microsecondsSinceEpoch}',
            projectId: item.projectId,
            profileName: item.profileName,
            length: wasteLength,
            quantity: 1,
            leftCut: last.part.rightCut,
            rightCut: item.leftCut,
          ),
          startX: startX,
          endX: startX + wasteLength,
          isWaste: true,
        ));
        startX += wasteLength;
      }
      _placeItemInPipe(pipe, item, startX, bladeThickness);
      return true;
    }

    return false;
  }

  void _placeItemInPipe(StockPipe pipe, PartItem item, double startX, double bladeThickness) {
    pipe.placements.add(PlacedPart(
      part: item,
      startX: startX,
      endX: startX + item.length + bladeThickness,
    ));
  }

  void _showAddPartDialog(BuildContext context, ProjectProvider provider, {PartItem? editingPart}) {
    if (editingPart != null) {
      _partLengthController.text = editingPart.length.toInt().toString();
      _partQtyController.text = editingPart.quantity.toString();
      _leftCut = editingPart.leftCut;
      _rightCut = editingPart.rightCut;
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
                                  DropdownMenuItem(value: '45', child: Text('Угол (45°)')),
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
                                  DropdownMenuItem(value: '45', child: Text('Угол (45°)')),
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
          final firstPipeItem = provider.selectedProject?.items.firstWhere(
            (i) => i.name.toLowerCase().contains('труб') || i.name.toLowerCase().contains('профил'),
            orElse: () => provider.selectedProject!.items.isNotEmpty 
                ? provider.selectedProject!.items.first 
                : null as dynamic,
          );
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
                        'Хлыст: ${stockLength.toInt()} мм, рез: ${bladeThickness.toInt()} мм, высота: ${profileHeight.toInt()} мм',
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
                                  labelText: 'Хлыст (мм)',
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
                                const Text('Купить целых хлыстов:', style: TextStyle(color: Colors.grey)),
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
                      'КАРТА РАСПИЛА ХЛЫСТОВ',
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
                                    'Хлыст №${pipeIndex + 1}',
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
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double totalWidth = constraints.maxWidth;
                                      
                                      // Render segments
                                      return Stack(
                                        children: [
                                          // Draw all placed parts
                                          ...pipe.placements.map((placement) {
                                            final double pWidth = (placement.endX - placement.startX) / stockLength * totalWidth;
                                            final double pLeft = placement.startX / stockLength * totalWidth;
                                            
                                            // Dynamic color matching item size to group identical parts
                                            final Color segmentColor = placement.isWaste 
                                                ? Colors.orange.withOpacity(0.3)
                                                : _getPartColor(placement.part.length);

                                            return Positioned(
                                              left: pLeft,
                                              width: pWidth,
                                              top: 0,
                                              bottom: 0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: segmentColor,
                                                  border: Border(
                                                    right: BorderSide(
                                                      color: Colors.white.withOpacity(0.3),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            placement.isWaste 
                                                                ? 'Опилок'
                                                                : '${placement.part.length.toInt()} мм',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: placement.isWaste ? 9 : 11,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                          if (!placement.isWaste)
                                                            Text(
                                                              '${placement.part.leftCut}/${placement.part.rightCut}°',
                                                              style: TextStyle(
                                                                fontSize: 9,
                                                                color: Colors.white.withOpacity(0.7),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),

                                          // Draw remaining empty space at the end
                                          if (pipe.usedLength < stockLength)
                                            Positioned(
                                              left: pipe.usedLength / stockLength * totalWidth,
                                              right: 0,
                                              top: 0,
                                              bottom: 0,
                                              child: Container(
                                                color: Colors.redAccent.withOpacity(0.08),
                                                child: Center(
                                                  child: Text(
                                                    'Остаток ${(stockLength - pipe.usedLength).toInt()} мм',
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
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

  String _getCutLabel(String left, String right) {
    if (left == '90' && right == '90') {
      return 'Ровный / Ровный (90°/90°)';
    } else if (left == '90' && right == '45') {
      return 'Ровный / Под 45°';
    } else if (left == '45' && right == '90') {
      return 'Под 45° / Ровный';
    } else {
      return 'Под 45° с двух сторон';
    }
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
