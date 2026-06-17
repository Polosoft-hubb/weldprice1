class ProjectItemModel {
  final int? id;
  final int projectId;
  final String materialId;
  final String name;
  final double quantity;
  final String unit;
  final double price;

  ProjectItemModel({
    this.id,
    required this.projectId,
    required this.materialId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  double get totalPrice => quantity * price;

  factory ProjectItemModel.fromJson(Map<String, dynamic> json) {
    return ProjectItemModel(
      id: (json['id'] as num?)?.toInt(),
      projectId: (json['project_id'] as num).toInt(),
      materialId: json['material_id']?.toString() ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'пог. м',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'material_id': materialId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
    };
  }

  ProjectItemModel copyWith({
    int? id,
    int? projectId,
    String? materialId,
    String? name,
    double? quantity,
    String? unit,
    double? price,
  }) {
    return ProjectItemModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      materialId: materialId ?? this.materialId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
    );
  }
}
