import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/project_provider.dart';
import '../models/material.dart' as model;
import '../models/project_item.dart';

class MaterialsTab extends StatelessWidget {
  const MaterialsTab({super.key});

  String _formatCurrency(double val) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(val);
  }

  void _showEditQuantityDialog(BuildContext context, ProjectItemModel item) {
    final textController = TextEditingController(text: item.quantity.toString());
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(item.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Единица измерения: ${item.unit}'),
              Text('Цена за единицу: ${_formatCurrency(item.price)}'),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Количество',
                  hintText: 'Введите новое количество',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? qty = double.tryParse(textController.text.replaceAll(',', '.').trim());
                final provider = Provider.of<ProjectProvider>(context, listen: false);
                Navigator.of(ctx).pop();
                if (qty != null && qty > 0 && item.id != null) {
                  provider.updateItemQuantity(item.id!, qty);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4081),
                foregroundColor: Colors.black,
              ),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMaterialBottomSheet(BuildContext parentContext) {
    final searchController = TextEditingController();
    String selectedCategory = 'Все';
    
    // Reset search filter first
    final provider = Provider.of<ProjectProvider>(parentContext, listen: false);
    provider.filterMaterials('');

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Get sorted list of categories
            final categories = ['Все', ...provider.projectMaterials
                .map((m) => m.category)
                .where((cat) => cat.isNotEmpty)
                .toSet()
                .toList()
                ..sort()];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(parentContext).size.height * 0.75,
                child: Column(
                  children: [
                    // Handle/Bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Добавить материал',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Search Field
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Поиск (например: труба, арматура)',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              selectedCategory = 'Все';
                            });
                            provider.filterMaterials('', category: 'Все');
                          },
                        ),
                      ),
                      onChanged: (val) {
                        provider.filterMaterials(val, category: selectedCategory);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Categories List
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (chipCtx, chipIdx) {
                          final cat = categories[chipIdx];
                          final isSelected = cat == selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = cat;
                                });
                                provider.filterMaterials(searchController.text, category: selectedCategory);
                              },
                              selectedColor: const Color(0xFFFF4081),
                              backgroundColor: const Color(0xFF262626),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide.none,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Results List
                    Expanded(
                      child: Consumer<ProjectProvider>(
                        builder: (consumerCtx, currentProvider, child) {
                          if (currentProvider.searchResults.isEmpty) {
                            return const Center(
                              child: Text(
                                'Материалы не найдены',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: currentProvider.searchResults.length,
                            itemBuilder: (itemCtx, index) {
                              final mat = currentProvider.searchResults[index];
                              return Card(
                                color: const Color(0xFF262626),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    mat.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${mat.category} • ${mat.unit}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    _formatCurrency(mat.price),
                                    style: const TextStyle(
                                      color: Color(0xFFFF4081),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(bottomSheetCtx).pop(); // Close bottom sheet
                                    _showQuantityInputDialog(parentContext, currentProvider, mat);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuantityInputDialog(BuildContext context, ProjectProvider provider, model.MaterialModel mat) {
    final textController = TextEditingController(text: '1.0');
    
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Количество'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mat.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text('Ед. изм.: ${mat.unit}'),
              Text('Цена: ${_formatCurrency(mat.price)}'),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Укажите метраж / количество',
                  hintText: 'Количество в ${mat.unit}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? qty = double.tryParse(textController.text.replaceAll(',', '.').trim());
                Navigator.of(dialogCtx).pop();
                if (qty != null && qty > 0) {
                  provider.addMaterialToProject(mat, qty);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4081),
                foregroundColor: Colors.black,
              ),
              child: const Text('Добавить'),
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
        final project = provider.selectedProject;
        if (project == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = project.items;

        if (items.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    size: 64,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Спецификация пуста',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Нажмите "+", чтобы добавить материалы в проект',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddMaterialBottomSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить материал'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4081),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${item.quantity.toStringAsFixed(1)} ${item.unit} × ${_formatCurrency(item.price)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatCurrency(item.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Удалить из сметы',
                        onPressed: () {
                          if (item.id != null) {
                            provider.removeItemFromProject(item.id!);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () => _showEditQuantityDialog(context, item),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddMaterialBottomSheet(context),
            backgroundColor: const Color(0xFFFF4081),
            foregroundColor: Colors.black,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
