class ProjectItemModel {
  final int? id;
  final int projectId;
  final String materialId;
  final String name;
  final double quantity;
  final String unit;
  final double price;
  final double paintingArea;

  ProjectItemModel({
    this.id,
    required this.projectId,
    required this.materialId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    this.paintingArea = 0.0,
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
      paintingArea: (json['painting_area'] as num?)?.toDouble() ?? 0.0,
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
      'painting_area': paintingArea,
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
    double? paintingArea,
  }) {
    return ProjectItemModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      materialId: materialId ?? this.materialId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      paintingArea: paintingArea ?? this.paintingArea,
    );
  }

  static double estimateAreaFromName(String name, String unit) {
    final nameLower = name.toLowerCase();
    
    // Check for two dimensions: e.g. 40х40х2, 60x40, 50*50
    final regTwoDims = RegExp(r'(\d+)\s*[xхXХ*]\s*(\d+)');
    final matchTwo = regTwoDims.firstMatch(name);
    
    if (matchTwo != null) {
      final double dim1 = double.tryParse(matchTwo.group(1) ?? '') ?? 0.0;
      final double dim2 = double.tryParse(matchTwo.group(2) ?? '') ?? 0.0;
      
      if (dim1 > 0 && dim2 > 0) {
        if (nameLower.contains('полоса')) {
          return (2 * dim1) / 1000.0;
        } else if (nameLower.contains('труба') && !nameLower.contains('профил')) {
          return (3.14159 * dim1) / 1000.0;
        } else {
          // Profile pipe (square/rectangular) or Angle (уголок)
          return (2 * (dim1 + dim2)) / 1000.0;
        }
      }
    }
    
    // Check for one dimension: e.g. Арматура 12 мм, Катанка d8, Швеллер 10
    final regOneDim = RegExp(r'(?:d|диаметр|Ду)?\s*(\d+)\s*(?:мм|м)?', caseSensitive: false);
    final matchOne = regOneDim.firstMatch(name);
    if (matchOne != null) {
      final double dim = double.tryParse(matchOne.group(1) ?? '') ?? 0.0;
      if (dim > 0) {
        if (nameLower.contains('швеллер')) {
          return (4 * dim * 10) / 1000.0;
        } else if (nameLower.contains('двутавр') || nameLower.contains('балка')) {
          return (6 * dim * 10) / 1000.0;
        } else {
          return (3.14159 * dim) / 1000.0;
        }
      }
    }

    return 0.0;
  }
}
