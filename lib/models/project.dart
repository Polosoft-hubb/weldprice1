import 'project_item.dart';

class ProjectModel {
  final int? id;
  final String name;
  final double complexity;
  final DateTime createdAt;
  final List<ProjectItemModel> items;

  ProjectModel({
    this.id,
    required this.name,
    this.complexity = 2.0,
    required this.createdAt,
    this.items = const [],
  });

  double get materialsCost {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get workCost {
    return materialsCost * complexity;
  }

  double get consumablesCost {
    return workCost * 0.05;
  }

  double get totalPrice {
    return materialsCost + workCost + consumablesCost;
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json, {List<ProjectItemModel> items = const []}) {
    return ProjectModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] ?? '',
      complexity: (json['complexity'] as num?)?.toDouble() ?? 2.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'complexity': complexity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProjectModel copyWith({
    int? id,
    String? name,
    double? complexity,
    DateTime? createdAt,
    List<ProjectItemModel>? items,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      complexity: complexity ?? this.complexity,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
