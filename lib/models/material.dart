class MaterialModel {
  final String id;
  final String name;
  final String url;
  final String unit;
  final double price;
  final String category;

  MaterialModel({
    required this.id,
    required this.name,
    required this.url,
    required this.unit,
    required this.price,
    required this.category,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: (json['id'] ?? json['material_id'])?.toString() ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      unit: json['unit'] ?? 'пог. м',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'unit': unit,
      'price': price,
      'category': category,
    };
  }

  MaterialModel copyWith({
    String? id,
    String? name,
    String? url,
    String? unit,
    double? price,
    String? category,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }
}
