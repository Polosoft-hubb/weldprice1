import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';
import '../utils/url_launcher_helper.dart';
import 'project_details_screen.dart';
import 'calculator_screen.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

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

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Номер телефона не указан')),
      );
      return;
    }
    try {
      await launchCall(clean);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть вызов: $e')),
        );
      }
    }
  }

  Future<void> _openYandexMaps(BuildContext context, String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Адрес не указан')),
      );
      return;
    }
    try {
      await launchYandexMaps(trimmed);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть Яндекс Карты: $e')),
        );
      }
    }
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Новый проект'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Название проекта *',
                    hintText: 'Например, Навес у дома',
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Номер телефона',
                    hintText: '+7 (999) 000-00-00',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.streetAddress,
                  decoration: const InputDecoration(
                    labelText: 'Адрес объекта',
                    hintText: 'г. Москва, ул. Ленина, д. 10',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
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
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();
                if (name.isNotEmpty) {
                  final provider = Provider.of<ProjectProvider>(context, listen: false);
                  Navigator.of(ctx).pop();
                  provider.createProject(name, phone: phone, address: address);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Проект создан. Обновление цен в фоне...'),
                      duration: Duration(seconds: 3),
                    ),
                  );
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

  void _showEditProjectDialog(BuildContext context, ProjectModel project) {
    final nameController = TextEditingController(text: project.name);
    final phoneController = TextEditingController(text: project.phone);
    final addressController = TextEditingController(text: project.address);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Редактировать проект'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Название проекта *',
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Номер телефона',
                    hintText: '+7 (999) 000-00-00',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.streetAddress,
                  decoration: const InputDecoration(
                    labelText: 'Адрес объекта',
                    hintText: 'г. Москва, ул. Ленина, д. 10',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
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
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final address = addressController.text.trim();
                if (name.isNotEmpty && project.id != null) {
                  final provider = Provider.of<ProjectProvider>(context, listen: false);
                  Navigator.of(ctx).pop();
                  provider.updateProjectInfo(
                    project.id!,
                    name: name,
                    phone: phone,
                    address: address,
                  );
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

  void _showDeleteProjectDialog(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Удалить проект?'),
          content: Text('Вы действительно хотите удалить проект "${project.name}" и все его сметы? Это действие необратимо.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (project.id != null) {
                  Provider.of<ProjectProvider>(context, listen: false)
                      .deleteProject(project.id!);
                }
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WELDPRICE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, size: 32),
            iconSize: 32,
            tooltip: 'Калькулятор',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalculatorScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          if (provider.projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.architecture_outlined,
                      size: 80,
                      color: Colors.pinkAccent.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Нет созданных проектов',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Нажмите кнопку "+", чтобы создать свой первый проект.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalProjects = provider.projects.length;
          final totalClientSum = provider.projects.fold(0.0, (sum, p) => sum + p.totalPrice);
          final totalMyEarnings = provider.projects.fold(0.0, (sum, p) => sum + p.workCost);

          final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
          final lastMonthSum = provider.projects
              .where((p) => p.createdAt.isAfter(oneMonthAgo))
              .fold(0.0, (sum, p) => sum + p.totalPrice);

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF4081).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'СТАТИСТИКА ПРОЕКТОВ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4081).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Проектов: $totalProjects',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF4081),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Всего',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(totalClientSum),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: Colors.grey.shade800,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'За 30 дней',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(lastMonthSum),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: Colors.grey.shade800,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Мой доход',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(totalMyEarnings),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF4081),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: provider.projects.length,
                  itemBuilder: (context, index) {
                    final project = provider.projects[index];
                    final hasPhone = project.phone.trim().isNotEmpty;
                    final hasAddress = project.address.trim().isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () async {
                          if (project.id != null) {
                            await provider.selectProject(project.id!);
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
                        borderRadius: BorderRadius.circular(16),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Title and Edit/Delete Actions
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Создан: ${_formatDate(project.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                                      tooltip: 'Редактировать',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showEditProjectDialog(context, project),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                      tooltip: 'Удалить проект',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showDeleteProjectDialog(context, project),
                                    ),
                                  ],
                                ),

                                // Address & Phone display
                                if (hasAddress) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFFFB300)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          project.address,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (hasPhone) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 16, color: Colors.greenAccent),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          project.phone,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 10),
                                // Total Client Price
                                Row(
                                  children: [
                                    const Text(
                                      'Итого для клиента: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(project.totalPrice),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF4081),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),
                                const Divider(height: 1, color: Colors.white10),
                                const SizedBox(height: 10),

                                // Action Buttons: Call & Yandex Maps
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          if (hasPhone) {
                                            _makePhoneCall(context, project.phone);
                                          } else {
                                            _showEditProjectDialog(context, project);
                                          }
                                        },
                                        icon: Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: hasPhone ? Colors.greenAccent : Colors.grey,
                                        ),
                                        label: Text(
                                          hasPhone ? 'Позвонить' : 'Указать телефон',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hasPhone ? Colors.greenAccent : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: hasPhone
                                              ? Colors.greenAccent.withOpacity(0.08)
                                              : Colors.white.withOpacity(0.03),
                                          side: BorderSide(
                                            color: hasPhone
                                                ? Colors.greenAccent.withOpacity(0.4)
                                                : Colors.grey.shade800,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          if (hasAddress) {
                                            _openYandexMaps(context, project.address);
                                          } else {
                                            _showEditProjectDialog(context, project);
                                          }
                                        },
                                        icon: Icon(
                                          Icons.map_outlined,
                                          size: 16,
                                          color: hasAddress ? const Color(0xFFFFB300) : Colors.grey,
                                        ),
                                        label: Text(
                                          hasAddress ? 'Яндекс Карты' : 'Указать адрес',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hasAddress ? const Color(0xFFFFB300) : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: hasAddress
                                              ? const Color(0xFFFFB300).withOpacity(0.08)
                                              : Colors.white.withOpacity(0.03),
                                          side: BorderSide(
                                            color: hasAddress
                                                ? const Color(0xFFFFB300).withOpacity(0.4)
                                                : Colors.grey.shade800,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
        onPressed: () => _showCreateProjectDialog(context),
        backgroundColor: const Color(0xFFFF4081),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
