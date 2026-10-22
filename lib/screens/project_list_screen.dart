import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/project_provider.dart';
import '../models/project.dart';
import '../utils/url_launcher_helper.dart';
import 'project_details_screen.dart';
import 'calculator_screen.dart';
import 'notes_screen.dart';

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

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
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

  void _handleCallAction(BuildContext context, ProjectModel project) {
    final contactsWithPhone = project.contacts
        .where((c) => c.phone.trim().isNotEmpty)
        .toList();

    if (contactsWithPhone.isEmpty) {
      _showEditProjectDialog(context, project);
      return;
    }

    if (contactsWithPhone.length == 1) {
      _makePhoneCall(context, contactsWithPhone.first.phone);
      return;
    }

    // More than 1 contact -> ask user who to call
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.call, color: Colors.greenAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Вызов',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20, color: Colors.white12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: contactsWithPhone.length,
                    itemBuilder: (context, index) {
                      final contact = contactsWithPhone[index];
                      final name = contact.name.trim().isNotEmpty
                          ? contact.name.trim()
                          : 'Контакт ${index + 1}';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.greenAccent.withOpacity(0.15),
                          child: const Icon(Icons.person, color: Colors.greenAccent),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          contact.phone.trim(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone, size: 14, color: Colors.greenAccent),
                              SizedBox(width: 4),
                              Text(
                                'Вызов',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _makePhoneCall(context, contact.phone);
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
  }

  void _showCreateProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _ProjectDialog(
        onSave: (name, address, contacts) {
          final provider = Provider.of<ProjectProvider>(context, listen: false);
          provider.createProject(name, contacts: contacts, address: address);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Проект создан. Обновление цен в фоне...'),
              duration: Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (_) => _ProjectDialog(
        project: project,
        onSave: (name, address, contacts) {
          if (project.id != null) {
            final provider = Provider.of<ProjectProvider>(context, listen: false);
            provider.updateProjectInfo(
              project.id!,
              name: name,
              contacts: contacts,
              address: address,
            );
          }
        },
      ),
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
            icon: const Icon(Icons.note_alt_outlined, size: 28),
            iconSize: 28,
            tooltip: 'Заметки',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotesScreen()),
              );
            },
          ),
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
          final lastMonthProjects = provider.projects
              .where((p) => p.createdAt.isAfter(oneMonthAgo))
              .toList();
          final lastMonthSum = lastMonthProjects.fold(0.0, (sum, p) => sum + p.totalPrice);
          final lastMonthEarnings = lastMonthProjects.fold(0.0, (sum, p) => sum + p.workCost);

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
                    // Row 1: Заказы (Всего & За 30 дней)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem('Всего', _formatCurrency(totalClientSum), Colors.white),
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: Colors.grey.shade800,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem('За 30 дней', _formatCurrency(lastMonthSum), Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Colors.white10),
                    const SizedBox(height: 12),
                    // Row 2: Прибыль (Моя прибыль & Прибыль за 30 дней)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem('Моя прибыль', _formatCurrency(totalMyEarnings), const Color(0xFFFF4081)),
                        ),
                        Container(
                          width: 1,
                          height: 35,
                          color: Colors.grey.shade800,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatItem('Прибыль за 30 дней', _formatCurrency(lastMonthEarnings), const Color(0xFFFF4081)),
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
                    final validContacts = project.contacts
                        .where((c) => c.phone.trim().isNotEmpty)
                        .toList();
                    final hasPhone = validContacts.isNotEmpty;
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

                                // Address display
                                if (hasAddress) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
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

                                // Contacts display (Name + Phone)
                                if (hasPhone) ...[
                                  const SizedBox(height: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: validContacts.map((contact) {
                                      final hasName = contact.name.trim().isNotEmpty;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: InkWell(
                                          onTap: () => _makePhoneCall(context, contact.phone),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.phone_outlined, size: 15, color: Colors.greenAccent),
                                              const SizedBox(width: 6),
                                              if (hasName) ...[
                                                Text(
                                                  '${contact.name.trim()}: ',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  contact.phone.trim(),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: hasName ? Colors.greenAccent.shade100 : Colors.white70,
                                                    decoration: TextDecoration.underline,
                                                    decorationColor: Colors.greenAccent.withOpacity(0.3),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
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

                                // Action Buttons: Call & Route
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _handleCallAction(context, project),
                                        icon: Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: hasPhone ? Colors.greenAccent : Colors.grey,
                                        ),
                                        label: Text(
                                          !hasPhone
                                              ? 'Указать телефон'
                                              : (validContacts.length == 1
                                                  ? (validContacts.first.name.trim().isNotEmpty
                                                      ? 'Позвонить (${validContacts.first.name.trim()})'
                                                      : 'Позвонить')
                                                  : 'Позвонить (${validContacts.length})'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hasPhone ? Colors.greenAccent : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                          Icons.location_on,
                                          size: 16,
                                          color: hasAddress ? Colors.redAccent : Colors.grey,
                                        ),
                                        label: Text(
                                          hasAddress ? 'Маршрут' : 'Указать адрес',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hasAddress ? Colors.redAccent : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: hasAddress
                                              ? Colors.redAccent.withOpacity(0.08)
                                              : Colors.white.withOpacity(0.03),
                                          side: BorderSide(
                                            color: hasAddress
                                                ? Colors.redAccent.withOpacity(0.4)
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

class _ContactRow {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  _ContactRow({String name = '', String phone = ''})
      : nameController = TextEditingController(text: name),
        phoneController = TextEditingController(text: phone);

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
  }
}

class _ProjectDialog extends StatefulWidget {
  final ProjectModel? project;
  final Function(String name, String address, List<ProjectContact> contacts) onSave;

  const _ProjectDialog({
    this.project,
    required this.onSave,
  });

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  final List<_ContactRow> _contacts = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _addressController = TextEditingController(text: widget.project?.address ?? '');

    if (widget.project != null && widget.project!.contacts.isNotEmpty) {
      for (final c in widget.project!.contacts) {
        _contacts.add(_ContactRow(name: c.name, phone: c.phone));
      }
    } else if (widget.project != null && widget.project!.phone.isNotEmpty) {
      _contacts.add(_ContactRow(name: '', phone: widget.project!.phone));
    } else {
      // Default: one empty contact entry ready to fill
      _contacts.add(_ContactRow());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    for (final c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  void _addContact() {
    setState(() {
      _contacts.add(_ContactRow());
    });
  }

  void _removeContact(int index) {
    setState(() {
      final removed = _contacts.removeAt(index);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;
    return AlertDialog(
      title: Text(isEditing ? 'Редактировать проект' : 'Новый проект'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Название проекта *',
                  hintText: 'Например, Навес у дома',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.streetAddress,
                decoration: const InputDecoration(
                  labelText: 'Адрес объекта',
                  hintText: 'г. Москва, ул. Ленина, д. 10',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Контакты:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addContact,
                    icon: const Icon(Icons.add, size: 16, color: Colors.greenAccent),
                    label: const Text(
                      'Добавить номер',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_contacts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: OutlinedButton.icon(
                      onPressed: _addContact,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Добавить контакт'),
                    ),
                  ),
                )
              else
                ..._contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Контакт ${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const Spacer(),
                            if (_contacts.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                tooltip: 'Удалить контакт',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeContact(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: contact.nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Имя / Должность',
                            hintText: 'Иван (заказчик) или Прораб',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: contact.phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Номер телефона',
                            hintText: '+7 (999) 000-00-00',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final address = _addressController.text.trim();
            if (name.isEmpty) return;

            final List<ProjectContact> validContacts = [];
            for (final c in _contacts) {
              final phone = c.phoneController.text.trim();
              final cName = c.nameController.text.trim();
              if (phone.isNotEmpty || cName.isNotEmpty) {
                validContacts.add(ProjectContact(name: cName, phone: phone));
              }
            }

            Navigator.of(context).pop();
            widget.onSave(name, address, validContacts);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4081),
            foregroundColor: Colors.black,
          ),
          child: Text(isEditing ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
