import 'project_item.dart';

class ProjectModel {
  final int? id;
  final String name;
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
    this.complexity = 2.5,
    required this.createdAt,
    this.items = const [],
    this.isPaintingEnabled = false,
    this.paintPrice = 0.0,
    this.paintConsumption = 0.2,
    this.paintingWorkPrice = 200.0,
    this.paintCanWeight = 1.0,
  });

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
    return ProjectModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] ?? '',
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
