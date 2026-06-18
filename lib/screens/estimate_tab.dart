import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/project_provider.dart';

class EstimateTab extends StatefulWidget {
  const EstimateTab({super.key});

  @override
  State<EstimateTab> createState() => _EstimateTabState();
}

class _EstimateTabState extends State<EstimateTab> {
  final TextEditingController _customCoeffController = TextEditingController();
  bool _isCustomCoeff = false;

  String _formatCurrency(double val) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(val);
  }

  @override
  void dispose() {
    _customCoeffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final project = provider.selectedProject;
        if (project == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<double> standardCoeffs = [2.0, 2.3, 2.5, 3.0, 3.5, 4.0];
        final bool isStandard = standardCoeffs.contains(project.complexity);

        // Sync local controller if custom
        if (!isStandard && !_isCustomCoeff) {
          _isCustomCoeff = true;
          _customCoeffController.text = project.complexity.toString();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CLIENT TOTAL BOX (Highlight)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC2185B), Color(0xFFFF4081)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4081).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ИТОГОВАЯ ЦЕНА ДЛЯ КЛИЕНТА',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatCurrency(project.totalPrice),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      color: Colors.black12,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        Text(
                          'Материалы: ${_formatCurrency(project.materialsCost)}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                        if (project.isPaintingEnabled)
                          Text(
                            'Покраска: ${_formatCurrency(project.totalPaintingCost)}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                        Text(
                          'Работа: ${_formatCurrency(project.workCost)}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // DETAILS LIST
              const Text(
                'Детализация расчета',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Materials Cost Row
                      _buildDetailRow(
                        title: 'Стоимость материалов',
                        value: _formatCurrency(project.materialsCost),
                        subtitle: 'Сумма добавленных позиций',
                        icon: Icons.inventory_2_outlined,
                      ),
                      const Divider(height: 24, color: Colors.grey),
                      
                      // Complexity Coefficient Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.speed, color: Colors.pinkAccent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Коэффициент сложности',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Зависит от сложности работы',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 10),
                                
                                // Selection Controls
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _isCustomCoeff ? 'custom' : project.complexity.toString(),
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: [
                                          ...standardCoeffs.map((c) => DropdownMenuItem(
                                            value: c.toString(),
                                            child: Text('x${c.toStringAsFixed(1)}'),
                                          )),
                                          const DropdownMenuItem(
                                            value: 'custom',
                                            child: Text('Свой коэффициент'),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val == 'custom') {
                                            setState(() {
                                              _isCustomCoeff = true;
                                            });
                                          } else if (val != null) {
                                            setState(() {
                                              _isCustomCoeff = false;
                                            });
                                            final double valD = double.parse(val);
                                            provider.updateComplexity(valD);
                                          }
                                        },
                                      ),
                                    ),
                                    if (_isCustomCoeff) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _customCoeffController,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                            labelText: 'Коэфф.',
                                            hintText: 'например, 2.7',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onChanged: (val) {
                                            final double? parsedVal = double.tryParse(val);
                                            if (parsedVal != null && parsedVal > 0) {
                                              provider.updateComplexity(parsedVal);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.grey),
                      
                      // Work Cost Row
                      _buildDetailRow(
                        title: 'Стоимость работы',
                        value: _formatCurrency(project.workCost),
                        subtitle: 'Материалы × Коэффициент',
                        icon: Icons.handyman_outlined,
                      ),
                      const Divider(height: 24, color: Colors.grey),
                      
                      // Consumables Row
                      _buildDetailRow(
                        title: 'Расходные материалы',
                        value: _formatCurrency(project.consumablesCost),
                        subtitle: '5% от работы (диски, электроды, проволока)',
                        icon: Icons.electric_bolt_outlined,
                      ),
                      if (project.isPaintingEnabled) ...[
                        const Divider(height: 24, color: Colors.grey),
                        _buildDetailRow(
                          title: 'Стоимость покраски',
                          value: _formatCurrency(project.totalPaintingCost),
                          subtitle: 'Расход краски: ${project.totalPaintWeight.toStringAsFixed(2)} кг\nНеобходимо: ${project.cansNeeded} бан. по ${project.paintCanWeight.toString().replaceAll(RegExp(r"\.0$"), "")} кг',
                          icon: Icons.format_paint_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
