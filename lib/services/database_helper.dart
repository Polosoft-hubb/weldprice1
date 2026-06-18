import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/material.dart';
import '../models/project.dart';
import '../models/project_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web Simulation Caches
  List<MaterialModel>? _webMaterials;
  List<ProjectModel>? _webProjects;
  List<ProjectItemModel>? _webProjectItems;
  List<Map<String, dynamic>>? _webProjectMaterials; // Stores maps with project_id and Material fields

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('sqflite is not supported on Web');
    if (_database != null) return _database!;
    _database = await _initDB('estimates.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add painting columns to projects table
      await db.execute('ALTER TABLE projects ADD COLUMN is_painting_enabled INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE projects ADD COLUMN paint_price REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE projects ADD COLUMN paint_consumption REAL DEFAULT 0.2');
      await db.execute('ALTER TABLE projects ADD COLUMN painting_work_price REAL DEFAULT 200.0');

      // Add painting columns to project_items table
      await db.execute('ALTER TABLE project_items ADD COLUMN painting_area REAL DEFAULT 0.0');
    }
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const integerPrimaryKey = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const doubleType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    // Global Materials Table (Template)
    await db.execute('''
      CREATE TABLE materials (
        id TEXT PRIMARY KEY,
        name $textType,
        url $textType,
        unit $textType,
        price $doubleType,
        category $textType
      )
    ''');

    // Projects Table
    await db.execute('''
      CREATE TABLE projects (
        id $integerPrimaryKey,
        name $textType,
        complexity $doubleType,
        created_at $textType,
        is_painting_enabled INTEGER DEFAULT 0,
        paint_price REAL DEFAULT 0.0,
        paint_consumption REAL DEFAULT 0.2,
        painting_work_price REAL DEFAULT 200.0
      )
    ''');

    // Project-Specific Materials Table
    await db.execute('''
      CREATE TABLE project_materials (
        project_id $integerType,
        material_id TEXT NOT NULL,
        name $textType,
        url $textType,
        unit $textType,
        price $doubleType,
        category $textType,
        PRIMARY KEY (project_id, material_id),
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // Project Items Table (Estimates)
    await db.execute('''
      CREATE TABLE project_items (
        id $integerPrimaryKey,
        project_id $integerType,
        material_id $textType,
        name $textType,
        quantity $doubleType,
        unit $textType,
        price $doubleType,
        painting_area REAL DEFAULT 0.0,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await _seedInitialMaterials(db);
  }

  Future<void> _seedInitialMaterials(Database db) async {
    try {
      final jsonString = await rootBundle.loadString('assets/materials_db.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      final batch = db.batch();
      for (final item in jsonList) {
        batch.insert('materials', {
          'id': item['id']?.toString() ?? '',
          'name': item['name'] ?? '',
          'url': item['url'] ?? '',
          'unit': item['unit'] ?? 'пог. м',
          'price': (item['price'] as num?)?.toDouble() ?? 0.0,
          'category': item['category'] ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      print("Seeded ${jsonList.length} materials into local SQLite.");
    } catch (e) {
      print("Error seeding initial materials: $e");
    }
  }

  // --- Web Helper Init ---
  Future<void> _initWebData() async {
    if (!kIsWeb) return;
    if (_webMaterials != null && _webProjects != null && _webProjectItems != null && _webProjectMaterials != null) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Global Materials
    final matsJson = prefs.getString('web_materials');
    if (matsJson != null) {
      final List<dynamic> decoded = json.decode(matsJson);
      _webMaterials = decoded.map((e) => MaterialModel.fromJson(e)).toList();
    } else {
      try {
        final jsonString = await rootBundle.loadString('assets/materials_db.json');
        final List<dynamic> jsonList = json.decode(jsonString);
        _webMaterials = jsonList.map((e) => MaterialModel.fromJson(e)).toList();
        await _saveWebMaterials();
      } catch (e) {
        _webMaterials = [];
      }
    }

    // 2. Projects
    final projsJson = prefs.getString('web_projects');
    if (projsJson != null) {
      final List<dynamic> decoded = json.decode(projsJson);
      _webProjects = decoded.map((e) => ProjectModel.fromJson(e)).toList();
    } else {
      _webProjects = [];
    }

    // 3. Project Items
    final itemsJson = prefs.getString('web_project_items');
    if (itemsJson != null) {
      final List<dynamic> decoded = json.decode(itemsJson);
      _webProjectItems = decoded.map((e) => ProjectItemModel.fromJson(e)).toList();
    } else {
      _webProjectItems = [];
    }

    // 4. Project Materials
    final pmJson = prefs.getString('web_project_materials');
    if (pmJson != null) {
      final List<dynamic> decoded = json.decode(pmJson);
      _webProjectMaterials = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _webProjectMaterials = [];
    }
  }

  Future<void> _saveWebMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_webMaterials?.map((e) => e.toJson()).toList());
    await prefs.setString('web_materials', jsonStr);
  }

  Future<void> _saveWebProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_webProjects?.map((e) => e.toJson()).toList());
    await prefs.setString('web_projects', jsonStr);
  }

  Future<void> _saveWebProjectItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_webProjectItems?.map((e) => e.toJson()).toList());
    await prefs.setString('web_project_items', jsonStr);
  }

  Future<void> _saveWebProjectMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('web_project_materials', json.encode(_webProjectMaterials));
  }

  // --- Global Material Operations (Templates) ---

  Future<void> addGlobalMaterial(MaterialModel material) async {
    if (kIsWeb) {
      await _initWebData();
      _webMaterials!.add(material);
      await _saveWebMaterials();
      return;
    }
    final db = await instance.database;
    await db.insert('materials', material.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MaterialModel>> getAllMaterials() async {
    if (kIsWeb) {
      await _initWebData();
      final sorted = List<MaterialModel>.from(_webMaterials!);
      sorted.sort((a, b) => a.category.compareTo(b.category) != 0 ? a.category.compareTo(b.category) : a.name.compareTo(b.name));
      return sorted;
    }
    final db = await instance.database;
    final result = await db.query('materials', orderBy: 'category ASC, name ASC');
    return result.map((json) => MaterialModel.fromJson(json)).toList();
  }

  Future<void> updateMaterialsBatch(List<MaterialModel> materials) async {
    if (kIsWeb) {
      await _initWebData();
      for (final newMat in materials) {
        final index = _webMaterials!.indexWhere((element) => element.id == newMat.id);
        if (index != -1) {
          _webMaterials![index] = newMat;
        } else {
          _webMaterials!.add(newMat);
        }
      }
      await _saveWebMaterials();
      return;
    }

    final db = await instance.database;
    final batch = db.batch();
    for (final mat in materials) {
      batch.insert('materials', mat.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // --- Project Specific Material Operations ---

  Future<List<MaterialModel>> getProjectMaterials(int projectId) async {
    if (kIsWeb) {
      await _initWebData();
      final list = _webProjectMaterials!
          .where((e) => (e['project_id'] as num).toInt() == projectId)
          .map((e) => MaterialModel.fromJson(e))
          .toList();
      list.sort((a, b) => a.category.compareTo(b.category) != 0 ? a.category.compareTo(b.category) : a.name.compareTo(b.name));
      return list;
    }
    final db = await instance.database;
    final result = await db.query(
      'project_materials',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'category ASC, name ASC',
    );
    return result.map((json) => MaterialModel.fromJson(json)).toList();
  }

  Future<List<MaterialModel>> searchProjectMaterials(int projectId, String query) async {
    if (kIsWeb) {
      final all = await getProjectMaterials(projectId);
      if (query.isEmpty) return all;
      final lower = query.toLowerCase();
      return all.where((m) =>
          m.name.toLowerCase().contains(lower) ||
          m.category.toLowerCase().contains(lower)).toList();
    }
    final db = await instance.database;
    final result = await db.query(
      'project_materials',
      where: 'project_id = ? AND (name LIKE ? OR category LIKE ?)',
      whereArgs: [projectId, '%$query%', '%$query%'],
      orderBy: 'category ASC, name ASC',
    );
    return result.map((json) => MaterialModel.fromJson(json)).toList();
  }

  Future<int> updateProjectMaterialPrice(int projectId, String materialId, double newPrice) async {
    if (kIsWeb) {
      await _initWebData();
      final index = _webProjectMaterials!.indexWhere(
        (e) => (e['project_id'] as num).toInt() == projectId && e['id'] == materialId
      );
      if (index != -1) {
        _webProjectMaterials![index]['price'] = newPrice;
        await _saveWebProjectMaterials();
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'project_materials',
      {'price': newPrice},
      where: 'project_id = ? AND material_id = ?',
      whereArgs: [projectId, materialId],
    );
  }

  Future<void> addProjectMaterial(int projectId, MaterialModel material) async {
    if (kIsWeb) {
      await _initWebData();
      final map = material.toJson();
      map['project_id'] = projectId;

      // Check if it already exists
      final existingIndex = _webProjectMaterials!.indexWhere(
        (e) => (e['project_id'] as num).toInt() == projectId && e['id'] == material.id
      );
      if (existingIndex != -1) {
        _webProjectMaterials![existingIndex] = map;
      } else {
        _webProjectMaterials!.add(map);
      }
      await _saveWebProjectMaterials();
      return;
    }

    final db = await instance.database;
    await db.insert('project_materials', {
      'project_id': projectId,
      'material_id': material.id,
      'name': material.name,
      'url': material.url,
      'unit': material.unit,
      'price': material.price,
      'category': material.category,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProjectMaterialsBatch(int projectId, List<MaterialModel> materials) async {
    if (kIsWeb) {
      await _initWebData();
      // Remove old project materials
      _webProjectMaterials!.removeWhere((e) => (e['project_id'] as num).toInt() == projectId);
      // Insert new batch
      for (final m in materials) {
        final map = m.toJson();
        map['project_id'] = projectId;
        _webProjectMaterials!.add(map);
      }
      await _saveWebProjectMaterials();
      return;
    }
    final db = await instance.database;
    final batch = db.batch();
    for (final mat in materials) {
      batch.insert('project_materials', {
        'project_id': projectId,
        'material_id': mat.id,
        'name': mat.name,
        'url': mat.url,
        'unit': mat.unit,
        'price': mat.price,
        'category': mat.category,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // --- Project Operations ---

  Future<ProjectModel> createProject(ProjectModel project) async {
    if (kIsWeb) {
      await _initWebData();
      final newId = (_webProjects!.isEmpty) 
          ? 1 
          : _webProjects!.map((e) => (e.id as num).toInt()).reduce((a, b) => a > b ? a : b) + 1;
      final created = project.copyWith(id: newId);
      _webProjects!.add(created);
      await _saveWebProjects();

      // Copy global templates into project specific database
      for (final template in _webMaterials!) {
        final map = template.toJson();
        map['project_id'] = newId;
        _webProjectMaterials!.add(map);
      }
      await _saveWebProjectMaterials();
      return created;
    }

    final db = await instance.database;
    final id = await db.insert('projects', project.toJson());
    
    // Copy templates in SQLite
    await db.execute('''
      INSERT INTO project_materials (project_id, material_id, name, url, unit, price, category)
      SELECT ?, id, name, url, unit, price, category FROM materials
    ''', [id]);

    return project.copyWith(id: id);
  }

  Future<List<ProjectModel>> getAllProjects() async {
    if (kIsWeb) {
      await _initWebData();
      final projects = <ProjectModel>[];
      for (final proj in _webProjects!) {
        final items = await getProjectItems((proj.id as num).toInt());
        projects.add(proj.copyWith(items: items));
      }
      projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return projects;
    }

    final db = await instance.database;
    final result = await db.query('projects', orderBy: 'created_at DESC');
    
    List<ProjectModel> projects = [];
    for (final row in result) {
      final projectId = (row['id'] as num).toInt();
      final items = await getProjectItems(projectId);
      projects.add(ProjectModel.fromJson(row, items: items));
    }
    return projects;
  }

  Future<ProjectModel?> getProjectById(int id) async {
    if (kIsWeb) {
      await _initWebData();
      final index = _webProjects!.indexWhere((element) => (element.id as num).toInt() == id);
      if (index == -1) return null;
      final items = await getProjectItems(id);
      return _webProjects![index].copyWith(items: items);
    }

    final db = await instance.database;
    final result = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    
    final items = await getProjectItems(id);
    return ProjectModel.fromJson(result.first, items: items);
  }

  Future<int> updateProjectComplexity(int projectId, double complexity) async {
    if (kIsWeb) {
      await _initWebData();
      final index = _webProjects!.indexWhere((element) => (element.id as num).toInt() == projectId);
      if (index != -1) {
        _webProjects![index] = _webProjects![index].copyWith(complexity: complexity);
        await _saveWebProjects();
        return 1;
      }
      return 0;
    }

    final db = await instance.database;
    return await db.update(
      'projects',
      {'complexity': complexity},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> deleteProject(int id) async {
    if (kIsWeb) {
      await _initWebData();
      _webProjects!.removeWhere((element) => (element.id as num).toInt() == id);
      _webProjectItems!.removeWhere((element) => (element.projectId as num).toInt() == id);
      _webProjectMaterials!.removeWhere((element) => (element['project_id'] as num).toInt() == id);
      await _saveWebProjects();
      await _saveWebProjectItems();
      await _saveWebProjectMaterials();
      return 1;
    }

    final db = await instance.database;
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // --- Project Item Operations ---

  Future<List<ProjectItemModel>> getProjectItems(int projectId) async {
    if (kIsWeb) {
      await _initWebData();
      final items = _webProjectItems!.where((element) => (element.projectId as num).toInt() == projectId).toList();
      
      // Merge current price from project specific materials
      final mergedItems = <ProjectItemModel>[];
      for (final item in items) {
        final pm = _webProjectMaterials!.firstWhere(
          (e) => (e['project_id'] as num).toInt() == projectId && e['id'] == item.materialId,
          orElse: () => {'price': item.price},
        );
        final currentPrice = (pm['price'] as num).toDouble();
        mergedItems.add(item.copyWith(price: currentPrice));
      }
      return mergedItems;
    }

    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT pi.*, pm.price as current_price
      FROM project_items pi
      LEFT JOIN project_materials pm ON pi.project_id = pm.project_id AND pi.material_id = pm.material_id
      WHERE pi.project_id = ?
    ''', [projectId]);
    
    return result.map((row) {
      final map = Map<String, dynamic>.from(row);
      if (row['current_price'] != null) {
        map['price'] = row['current_price'];
      }
      return ProjectItemModel.fromJson(map);
    }).toList();
  }

  Future<ProjectItemModel> addProjectItem(ProjectItemModel item) async {
    if (kIsWeb) {
      await _initWebData();
      
      final existingIndex = _webProjectItems!.indexWhere(
        (element) => (element.projectId as num).toInt() == item.projectId && element.materialId == item.materialId
      );

      if (existingIndex != -1) {
        final existingItem = _webProjectItems![existingIndex];
        final newQty = existingItem.quantity + item.quantity;
        final updatedItem = existingItem.copyWith(quantity: newQty);
        _webProjectItems![existingIndex] = updatedItem;
        await _saveWebProjectItems();
        return updatedItem;
      } else {
        final newId = (_webProjectItems!.isEmpty)
            ? 1
            : _webProjectItems!.map((e) => (e.id as num).toInt()).reduce((a, b) => a > b ? a : b) + 1;
        final created = item.copyWith(id: newId);
        _webProjectItems!.add(created);
        await _saveWebProjectItems();
        return created;
      }
    }

    final db = await instance.database;
    
    final existing = await db.query(
      'project_items',
      where: 'project_id = ? AND material_id = ?',
      whereArgs: [item.projectId, item.materialId],
    );

    if (existing.isNotEmpty) {
      final existingItem = ProjectItemModel.fromJson(existing.first);
      final newQty = existingItem.quantity + item.quantity;
      await db.update(
        'project_items',
        {'quantity': newQty},
        where: 'id = ?',
        whereArgs: [existingItem.id],
      );
      return existingItem.copyWith(quantity: newQty);
    } else {
      final id = await db.insert('project_items', item.toJson());
      return item.copyWith(id: id);
    }
  }

  Future<int> updateProjectItemQuantity(int itemId, double quantity) async {
    if (kIsWeb) {
      await _initWebData();
      final index = _webProjectItems!.indexWhere((element) => (element.id as num).toInt() == itemId);
      if (index != -1) {
        _webProjectItems![index] = _webProjectItems![index].copyWith(quantity: quantity);
        await _saveWebProjectItems();
        return 1;
      }
      return 0;
    }

    final db = await instance.database;
    return await db.update(
      'project_items',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> deleteProjectItem(int id) async {
    if (kIsWeb) {
      await _initWebData();
      _webProjectItems!.removeWhere((element) => (element.id as num).toInt() == id);
      await _saveWebProjectItems();
      return 1;
    }

    final db = await instance.database;
    return await db.delete('project_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateProjectItemPaintingArea(int itemId, double area) async {
    if (kIsWeb) {
      await _initWebData();
      final index = _webProjectItems!.indexWhere((element) => (element.id as num).toInt() == itemId);
      if (index != -1) {
        _webProjectItems![index] = _webProjectItems![index].copyWith(paintingArea: area);
        await _saveWebProjectItems();
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'project_items',
      {'painting_area': area},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> updateProjectPaintingSettings(int projectId, {required bool enabled, required double price, required double consumption, required double workPrice}) async {
    if (kIsWeb) {
      await _initWebData();
      final index = _webProjects!.indexWhere((element) => (element.id as num).toInt() == projectId);
      if (index != -1) {
        _webProjects![index] = _webProjects![index].copyWith(
          isPaintingEnabled: enabled,
          paintPrice: price,
          paintConsumption: consumption,
          paintingWorkPrice: workPrice,
        );
        await _saveWebProjects();
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'projects',
      {
        'is_painting_enabled': enabled ? 1 : 0,
        'paint_price': price,
        'paint_consumption': consumption,
        'painting_work_price': workPrice,
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }
}
