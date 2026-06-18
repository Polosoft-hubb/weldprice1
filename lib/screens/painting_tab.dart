import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/project_provider.dart';
import '../models/project_item.dart';

class PaintingTab extends StatefulWidget {
  const PaintingTab({super.key});

  @override
  State<PaintingTab> createState() => _PaintingTabState();
}

class _PaintingTabState extends State<PaintingTab> {
  late TextEditingController _paintPriceController;
  late TextEditingController _paintConsumptionController;
  
  final Map<int, TextEditingController> _itemControllers = {};
  int? _lastProjectId;

  @override
  void initState() {
    super.initState();
    _paintPriceController = TextEditingController();
    _paintConsumptionController = TextEditingController();
  }

  @override
  void dispose() {
    _paintPriceController.dispose();
    _paintConsumptionController.dispose();
    for (final c in _itemControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatCurrency(double val) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(val);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final project = provider.selectedProject;
        if (project == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Sync controllers when changing project
        final int currentProjId = (project.id as num).toInt();
        if (_lastProjectId != currentProjId) {
          _lastProjectId = currentProjId;
          _paintPriceController.text = project.paintPrice == 0 ? '' : project.paintPrice.toString();
          _paintConsumptionController.text = project.paintConsumption.toString();
          
          for (final c in _itemControllers.values) {
            c.dispose();
          }
          _itemControllers.clear();
        }

        // Populate item controllers dynamically
        for (final item in project.items) {
          if (item.id != null && !_itemControllers.containsKey(item.id)) {
            _itemControllers[item.id!] = TextEditingController(
              text: item.paintingArea == 0 ? '' : item.paintingArea.toString(),
            );
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MAIN SWITCH CARD
                Card(
                  color: const Color(0xFF161616),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Включить покраску в стоимость',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Добавить стоимость материалов покраски к смете проекта',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          activeColor: const Color(0xFFFF4081),
                          value: project.isPaintingEnabled,
                          onChanged: (val) {
                            provider.updatePaintingSettings(enabled: val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // SETTINGS DETAILS
                if (project.isPaintingEnabled) ...[
                  Card(
                    color: const Color(0xFF1E1E1E),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Параметры расхода и цены краски',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _paintPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Цена краски (₽/кг)',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  onChanged: (val) {
                                    final price = double.tryParse(val.trim()) ?? 0.0;
                                    provider.updatePaintingSettings(price: price);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _paintConsumptionController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Расход (кг/м²)',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  onChanged: (val) {
                                    final cons = double.tryParse(val.trim()) ?? 0.2;
                                    provider.updatePaintingSettings(consumption: cons);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // MATERIALS LIST FOR PAINTING
                  const Text(
                    'Детали и площадь покраски',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  
                  if (project.items.isEmpty)
                    Card(
                      color: const Color(0xFF1E1E1E),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              const Text(
                                'Спецификация проекта пуста',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Добавьте материалы во вкладке "Материалы"',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: project.items.length,
                      itemBuilder: (context, index) {
                        final item = project.items[index];
                        final double estimatedArea = ProjectItemModel.estimateAreaFromName(item.name, item.unit);
                        final double activeArea = item.paintingArea > 0 ? item.paintingArea : estimatedArea;
                        final double totalArea = item.quantity * activeArea;
                        final double paintNeeded = totalArea * project.paintConsumption;
                        final double paintCost = paintNeeded * project.paintPrice;
                        final double totalPaintingCost = paintCost;

                        return Card(
                          color: const Color(0xFF262626),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Количество: ${item.quantity.toStringAsFixed(1)} ${item.unit} × ${_formatCurrency(item.price)}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 130,
                                      child: TextField(
                                        controller: _itemControllers[item.id],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          labelText: 'Площадь 1 ед.',
                                          hintText: estimatedArea > 0 ? estimatedArea.toStringAsFixed(2) : '0.00',
                                          suffixText: ' м²',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                                          floatingLabelBehavior: FloatingLabelBehavior.always,
                                        ),
                                        onChanged: (val) {
                                          final area = double.tryParse(val.trim()) ?? 0.0;
                                          provider.updateItemPaintingArea(item.id!, area);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (activeArea > 0) ...[
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Общая площадь: ${totalArea.toStringAsFixed(2)} м²${item.paintingArea == 0 ? " (авто)" : ""}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                          Text(
                                            'Расход краски: ${paintNeeded.toStringAsFixed(2)} кг',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Краска: ${_formatCurrency(totalPaintingCost)}',
                                        style: const TextStyle(
                                          color: Color(0xFFFF4081),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ] else ...[
                  Card(
                    color: const Color(0xFF1E1E1E),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.format_paint_outlined, size: 64, color: Colors.grey.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            const Text(
                              'Покраска не включена в смету',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Включите переключатель выше, чтобы активировать расчет стоимости покраски деталей по площади поверхности.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
