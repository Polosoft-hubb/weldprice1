import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';
import 'project_details_screen.dart';

class MonthStat {
  final int year;
  final int month;
  final List<ProjectModel> projects;

  MonthStat({
    required this.year,
    required this.month,
    required this.projects,
  });

  String get title {
    const monthsRu = [
      '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return '${monthsRu[month]} $year';
  }

  List<ProjectModel> get completedProjects =>
      projects.where((p) => p.status == ProjectStatus.completed).toList();

  List<ProjectModel> get inProgressProjects =>
      projects.where((p) => p.status == ProjectStatus.inProgress).toList();

  List<ProjectModel> get rejectedProjects =>
      projects.where((p) => p.status == ProjectStatus.rejected).toList();

  double get completedRevenue =>
      completedProjects.fold(0.0, (sum, p) => sum + p.totalPrice);

  double get completedProfit =>
      completedProjects.fold(0.0, (sum, p) => sum + p.workCost);

  double get inProgressRevenue =>
      inProgressProjects.fold(0.0, (sum, p) => sum + p.totalPrice);

  double get averageCheck => completedProjects.isEmpty
      ? 0.0
      : completedRevenue / completedProjects.length;
}

class DetailedStatsScreen extends StatefulWidget {
  const DetailedStatsScreen({super.key});

  @override
  State<DetailedStatsScreen> createState() => _DetailedStatsScreenState();
}

class _DetailedStatsScreenState extends State<DetailedStatsScreen> {
  int _viewMode = 0; // 0: Детально по заказам, 1: Сводная таблица
  String _statusFilter = 'all'; // 'all', 'completed', 'in_progress', 'rejected'

  String _formatCurrency(double val) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    );
    return formatter.format(val);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case ProjectStatus.completed:
        return const Color(0xFF22C55E); // Bold vivid green
      case ProjectStatus.rejected:
        return const Color(0xFFEF4444); // Bold vivid red
      case ProjectStatus.inProgress:
      default:
        return const Color(0xFFFFB300); // Bold vivid warm yellow/amber
    }
  }

  String _getStatusLabel(String status) {
    return ProjectStatus.getLabel(status);
  }

  List<MonthStat> _groupProjects(List<ProjectModel> projects) {
    final Map<String, List<ProjectModel>> map = {};
    for (final p in projects) {
      final key = '${p.createdAt.year}-${p.createdAt.month.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(p);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((key) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final list = map[key]!..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return MonthStat(year: year, month: month, projects: list);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final allProjects = provider.projects;
        final completedProjects = allProjects
            .where((p) => p.status == ProjectStatus.completed)
            .toList();

        final totalCompletedSum = completedProjects.fold(0.0, (sum, p) => sum + p.totalPrice);
        final totalCompletedProfit = completedProjects.fold(0.0, (sum, p) => sum + p.workCost);

        final monthStats = _groupProjects(allProjects);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Подробная статистика'),
          ),
          body: allProjects.isEmpty
              ? const Center(
                  child: Text(
                    'Нет данных для статистики',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP OVERVIEW CARDS
                      _buildTopOverview(
                        totalCompletedSum: totalCompletedSum,
                        totalCompletedProfit: totalCompletedProfit,
                      ),
                      const SizedBox(height: 16),

                      // VIEW MODE SELECTOR (Заказы по месяцам / Сводная таблица)
                      Center(
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(
                              value: 0,
                              icon: Icon(Icons.calendar_month_outlined, size: 18),
                              label: Text('По месяцам и заказам'),
                            ),
                            ButtonSegment(
                              value: 1,
                              icon: Icon(Icons.table_chart_outlined, size: 18),
                              label: Text('Сводная таблица'),
                            ),
                          ],
                          selected: {_viewMode},
                          onSelectionChanged: (val) {
                            setState(() {
                              _viewMode = val.first;
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.selected)) {
                                return const Color(0xFFFF4081).withOpacity(0.18);
                              }
                              return const Color(0xFF1E1E1E);
                            }),
                            foregroundColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.selected)) {
                                return const Color(0xFFFF4081);
                              }
                              return Colors.white70;
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // FILTER CHIPS (FOR ORDERS VIEW)
                      if (_viewMode == 0) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusFilterChip('all', 'Все заказы', null),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('completed', 'Завершенные', const Color(0xFF22C55E)),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('in_progress', 'В работе', const Color(0xFFFFB300)),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('rejected', 'Не согласились', const Color(0xFFEF4444)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // CONTENT BASED ON VIEW MODE
                      if (_viewMode == 0)
                        _buildMonthlyOrdersView(context, provider, monthStats)
                      else
                        _buildSummaryTableView(monthStats, totalCompletedSum, totalCompletedProfit),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTopOverview({
    required double totalCompletedSum,
    required double totalCompletedProfit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF4081).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'СВОДКА ЗА ВСЕ ВРЕМЯ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Общая выручка',
                  _formatCurrency(totalCompletedSum),
                  Colors.white,
                  Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Моя прибыль',
                  _formatCurrency(totalCompletedProfit),
                  const Color(0xFFFF4081),
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusFilterChip(String value, String label, Color? color) {
    final isSelected = _statusFilter == value;
    final activeColor = color ?? const Color(0xFFFF4081);
    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? (color ?? Colors.white) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- VIEW 0: ПО МЕСЯЦАМ И ЗАКАЗАМ ---
  Widget _buildMonthlyOrdersView(
    BuildContext context,
    ProjectProvider provider,
    List<MonthStat> monthStats,
  ) {
    return Column(
      children: monthStats.map((stat) {
        final filteredProjects = _statusFilter == 'all'
            ? stat.projects
            : stat.projects.where((p) => p.status == _statusFilter).toList();
        if (filteredProjects.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MONTH HEADER
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: const Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stat.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Заказов: ${stat.projects.length}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Выручка: ',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatCurrency(stat.completedRevenue),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Прибыль: ',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatCurrency(stat.completedProfit),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF4081),
                              ),
                            ),
                          ],
                        ),
                        if (stat.inProgressRevenue > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'В работе: ',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _formatCurrency(stat.inProgressRevenue),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ORDERS TABLE
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  horizontalMargin: 14,
                  headingRowHeight: 38,
                  dataRowMinHeight: 46,
                  dataRowMaxHeight: 52,
                  headingTextStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  columns: const [
                    DataColumn(label: Text('ДАТА')),
                    DataColumn(label: Text('ПРОЕКТ / ЗАКАЗ')),
                    DataColumn(label: Text('СТАТУС')),
                    DataColumn(label: Text('СУММА (КЛИЕНТ)')),
                    DataColumn(label: Text('ПРИБЫЛЬ')),
                  ],
                  rows: filteredProjects.map((p) {
                    final statusColor = _getStatusColor(p.status);
                    final isRejected = p.status == ProjectStatus.rejected;
                    final isCompleted = p.status == ProjectStatus.completed;

                    return DataRow(
                      onSelectChanged: (_) async {
                        if (p.id != null) {
                          await provider.selectProject(p.id!);
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProjectDetailsScreen(),
                              ),
                            ).then((_) {
                              provider.deselectProject();
                            });
                          }
                        }
                      },
                      cells: [
                        DataCell(
                          Text(
                            _formatDate(p.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (p.contacts.isNotEmpty && p.contacts.first.name.isNotEmpty)
                                  Text(
                                    p.contacts.first.name,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _getStatusLabel(p.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(p.totalPrice),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                              color: isRejected
                                  ? Colors.grey
                                  : (isCompleted ? const Color(0xFF22C55E) : Colors.white),
                              decoration: isRejected ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            isRejected ? '—' : _formatCurrency(p.workCost),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isRejected ? Colors.grey : const Color(0xFFFF4081),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- VIEW 1: СВОДНАЯ ТАБЛИЦА ПО МЕСЯЦАМ ---
  Widget _buildSummaryTableView(
    List<MonthStat> monthStats,
    double totalRevenue,
    double totalProfit,
  ) {
    final totalCompletedCount = monthStats.fold(0, (sum, m) => sum + m.completedProjects.length);
    final totalOrdersCount = monthStats.fold(0, (sum, m) => sum + m.projects.length);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
          horizontalMargin: 16,
          headingRowHeight: 44,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 54,
          headingTextStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          columns: const [
            DataColumn(label: Text('МЕСЯЦ')),
            DataColumn(label: Text('ЗАКАЗОВ')),
            DataColumn(label: Text('ВЫРУЧКА')),
            DataColumn(label: Text('ПРИБЫЛЬ')),
          ],
          rows: [
            ...monthStats.map((m) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      m.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${m.completedProjects.length} / ${m.projects.length}',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatCurrency(m.completedRevenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatCurrency(m.completedProfit),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF4081),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // TOTAL ROW
            DataRow(
              color: MaterialStateProperty.all(const Color(0xFFFF4081).withOpacity(0.08)),
              cells: [
                const DataCell(
                  Text(
                    'ИТОГО',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF4081),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '$totalCompletedCount / $totalOrdersCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatCurrency(totalRevenue),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _formatCurrency(totalProfit),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF4081),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
