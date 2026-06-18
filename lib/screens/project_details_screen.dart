import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import 'estimate_tab.dart';
import 'materials_tab.dart';
import 'painting_tab.dart';
import 'settings_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    EstimateTab(),
    MaterialsTab(),
    PaintingTab(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final project = provider.selectedProject;
        if (project == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'К проектам',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calculate_outlined),
                activeIcon: Icon(Icons.calculate),
                label: 'Смета',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                activeIcon: Icon(Icons.inventory_2),
                label: 'Материалы',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.format_paint_outlined),
                activeIcon: Icon(Icons.format_paint),
                label: 'Покраска',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.price_change_outlined),
                activeIcon: Icon(Icons.price_change),
                label: 'База цен',
              ),
            ],
          ),
        );
      },
    );
  }
}
