import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/project_provider.dart';
import '../models/material.dart' as model;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Все';

  String _formatCurrency(double val) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(val);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  void _showEditPriceDialog(BuildContext context, model.MaterialModel mat) {
    final textController = TextEditingController(text: mat.price.toString());
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Редактировать цену'),
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
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Цена за единицу (₽)',
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
                final double? price = double.tryParse(textController.text.replaceAll(',', '.').trim());
                if (price != null && price >= 0) {
                  Provider.of<ProjectProvider>(context, listen: false)
                      .updateMaterialPrice(mat.id, price);
                }
                Navigator.of(ctx).pop();
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

  void _showAddCustomMaterialDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController(text: 'Свои материалы');
    final priceController = TextEditingController();
    
    String selectedUnit = 'пог. м';
    final customUnitController = TextEditingController();
    bool isCustomUnit = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Добавить свой материал'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Название материала',
                        hintText: 'например, Уголок 50х50х5',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Категория',
                        hintText: 'например, Свои материалы',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: isCustomUnit ? 'custom' : selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Единица измерения',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'пог. м', child: Text('пог. м')),
                        DropdownMenuItem(value: 'шт', child: Text('шт')),
                        DropdownMenuItem(value: 'т', child: Text('т')),
                        DropdownMenuItem(value: 'кг', child: Text('кг')),
                        DropdownMenuItem(value: 'кв. м', child: Text('кв. м')),
                        DropdownMenuItem(value: 'куб. м', child: Text('куб. м')),
                        DropdownMenuItem(value: 'custom', child: Text('Свой вариант...')),
                      ],
                      onChanged: (val) {
                        if (val == 'custom') {
                          setDialogState(() {
                            isCustomUnit = true;
                          });
                        } else if (val != null) {
                          setDialogState(() {
                            isCustomUnit = false;
                            selectedUnit = val;
                          });
                        }
                      },
                    ),
                    if (isCustomUnit) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Введите единицу измерения',
                          hintText: 'например, комплект',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Цена за единицу (₽)',
                        hintText: '0.0',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final category = categoryController.text.trim();
                    final unit = isCustomUnit 
                        ? customUnitController.text.trim() 
                        : selectedUnit;
                    final double? price = double.tryParse(priceController.text.replaceAll(',', '.').trim());

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Укажите название материала')),
                      );
                      return;
                    }
                    if (category.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Укажите категорию')),
                      );
                      return;
                    }
                    if (unit.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Укажите единицу измерения')),
                      );
                      return;
                    }
                    if (price == null || price < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Укажите корректную цену')),
                      );
                      return;
                    }

                    Provider.of<ProjectProvider>(context, listen: false)
                        .addCustomMaterial(name, category, unit, price);

                    Navigator.of(dialogCtx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Материал "$name" добавлен в базу цен')),
                    );
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
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).filterMaterials('', category: _selectedCategory);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          final lastUpdateText = provider.lastUpdateDate != null
              ? 'Цены актуальны на: ${_formatDate(provider.lastUpdateDate!)}'
              : 'Цены не обновлялись';

          return Column(
            children: [
              // SCRAPER CONTAINER
              Container(
                color: const Color(0xFF161616),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Синхронизация цен',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastUpdateText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        provider.isScraping
                            ? const CircularProgressIndicator(color: Color(0xFFFF4081))
                            : ElevatedButton(
                                onPressed: () async {
                                  await provider.syncPrices();
                                  if (context.mounted && provider.scrapingError == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Цены успешно обновлены!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4081),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: 18),
                                    SizedBox(width: 6),
                                    Text('Обновить цены'),
                                  ],
                                ),
                              ),
                      ],
                    ),
                    if (provider.scrapingError != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.scrapingError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // SEARCH FIELD
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск материалов в базе...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty || _selectedCategory != 'Все'
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _selectedCategory = 'Все';
                              });
                              provider.filterMaterials('', category: 'Все');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    provider.filterMaterials(val, category: _selectedCategory);
                    setState(() {});
                  },
                ),
              ),

              // CATEGORIES CHIPS
              (() {
                final categories = ['Все', ...provider.projectMaterials
                    .map((m) => m.category)
                    .where((cat) => cat.isNotEmpty)
                    .toSet()
                    .toList()
                    ..sort()];

                return Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: categories.length,
                    itemBuilder: (chipCtx, chipIdx) {
                      final cat = categories[chipIdx];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                            provider.filterMaterials(_searchController.text, category: _selectedCategory);
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
                );
              })(),

              // MATERIALS LIST
              Expanded(
                child: provider.searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'Ничего не найдено',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: provider.searchResults.length,
                        itemBuilder: (context, index) {
                          final mat = provider.searchResults[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                mat.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                '${mat.category} • ед. изм.: ${mat.unit}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatCurrency(mat.price),
                                    style: const TextStyle(
                                      color: Color(0xFFFF4081),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.pinkAccent, size: 20),
                                    tooltip: 'Редактировать цену',
                                    onPressed: () => _showEditPriceDialog(context, mat),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomMaterialDialog(context),
        backgroundColor: const Color(0xFFFF4081),
        foregroundColor: Colors.black,
        tooltip: 'Добавить свой материал',
        child: const Icon(Icons.add),
      ),
    );
  }
}
