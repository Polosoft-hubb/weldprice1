import 'dart:convert';
import 'project_item.dart';

class ProjectContact {
  final String name;
  final String phone;

  ProjectContact({
    this.name = '',
    required this.phone,
  });

  factory ProjectContact.fromJson(Map<String, dynamic> json) {
    return ProjectContact(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }

  ProjectContact copyWith({
    String? name,
    String? phone,
  }) {
    return ProjectContact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}

class ProjectModel {
  final int? id;
  final String name;
  final List<ProjectContact> contacts;
  final String address;
  final double complexity;
  final DateTime createdAt;
  final List<ProjectItemModel> items;

  // Painting settings
  final bool isPaintingEnabled;
  final double paintPrice;         // Now represents the price of 1 can
  final double paintConsumption;   // in kg/m2 or l/m2
  final double paintingWorkPrice;
  final double paintCanWeight;     // in kg

  ProjectModel({
    this.id,
    required this.name,
    List<ProjectContact> contacts = const [],
    String? phone,
    this.address = '',
    this.complexity = 2.5,
    required this.createdAt,
    this.items = const [],
    this.isPaintingEnabled = false,
    this.paintPrice = 0.0,
    this.paintConsumption = 0.2,
    this.paintingWorkPrice = 200.0,
    this.paintCanWeight = 1.0,
  }) : contacts = contacts.isNotEmpty
            ? contacts
            : ((phone != null && phone.trim().isNotEmpty)
                ? [ProjectContact(phone: phone.trim())]
                : const []);

  String get phone => contacts.isNotEmpty ? contacts.first.phone : '';

  double get materialsCost {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get totalWeight {
    return items.fold(0.0, (sum, item) => sum + item.totalWeight);
  }

  double get workCost {
    return materialsCost * complexity;
  }

  double get consumablesCost {
    return workCost * 0.05;
  }

  double get totalPaintingArea {
    return items.fold(0.0, (sum, item) {
      final area = item.paintingArea > 0
          ? item.paintingArea
          : ProjectItemModel.estimateAreaFromName(item.name, item.unit);
      return sum + (item.quantity * area);
    });
  }

  double get totalPaintWeight {
    return items.fold(0.0, (sum, item) {
      final area = item.paintingArea > 0
          ? item.paintingArea
          : ProjectItemModel.estimateAreaFromName(item.name, item.unit);
      return sum + (item.quantity * area * paintConsumption);
    });
  }

  int get cansNeeded {
    if (paintCanWeight <= 0) return 0;
    return (totalPaintWeight / paintCanWeight).ceil();
  }

  double get totalPaintingCost {
    if (!isPaintingEnabled) return 0.0;
    return cansNeeded * paintPrice;
  }

  double get totalPrice {
    final base = materialsCost + workCost + consumablesCost;
    return isPaintingEnabled ? base + totalPaintingCost : base;
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json, {List<ProjectItemModel> items = const []}) {
    List<ProjectContact> parsedContacts = [];
    if (json['contacts'] != null) {
      final raw = json['contacts'];
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw) as List;
          parsedContacts = decoded.map((e) => ProjectContact.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      } else if (raw is List) {
        parsedContacts = raw.map((e) => ProjectContact.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    }
    final legacyPhone = json['phone'] as String? ?? '';
    if (parsedContacts.isEmpty && legacyPhone.trim().isNotEmpty) {
      parsedContacts.add(ProjectContact(phone: legacyPhone.trim()));
    }

    return ProjectModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] ?? '',
      contacts: parsedContacts,
      address: json['address'] as String? ?? '',
      complexity: (json['complexity'] as num?)?.toDouble() ?? 2.5,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      items: items,
      isPaintingEnabled: (json['is_painting_enabled'] as num?)?.toInt() == 1,
      paintPrice: (json['paint_price'] as num?)?.toDouble() ?? 0.0,
      paintConsumption: (json['paint_consumption'] as num?)?.toDouble() ?? 0.2,
      paintingWorkPrice: (json['painting_work_price'] as num?)?.toDouble() ?? 200.0,
      paintCanWeight: (json['paint_can_weight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'contacts': jsonEncode(contacts.map((c) => c.toJson()).toList()),
      'address': address,
      'complexity': complexity,
      'created_at': createdAt.toIso8601String(),
      'is_painting_enabled': isPaintingEnabled ? 1 : 0,
      'paint_price': paintPrice,
      'paint_consumption': paintConsumption,
      'painting_work_price': paintingWorkPrice,
      'paint_can_weight': paintCanWeight,
    };
  }

  ProjectModel copyWith({
    int? id,
    String? name,
    List<ProjectContact>? contacts,
    String? phone,
    String? address,
    double? complexity,
    DateTime? createdAt,
    List<ProjectItemModel>? items,
    bool? isPaintingEnabled,
    double? paintPrice,
    double? paintConsumption,
    double? paintingWorkPrice,
    double? paintCanWeight,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contacts: contacts ?? (phone != null ? [ProjectContact(phone: phone)] : this.contacts),
      address: address ?? this.address,
      complexity: complexity ?? this.complexity,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      isPaintingEnabled: isPaintingEnabled ?? this.isPaintingEnabled,
      paintPrice: paintPrice ?? this.paintPrice,
      paintConsumption: paintConsumption ?? this.paintConsumption,
      paintingWorkPrice: paintingWorkPrice ?? this.paintingWorkPrice,
      paintCanWeight: paintCanWeight ?? this.paintCanWeight,
    );
  }
}
