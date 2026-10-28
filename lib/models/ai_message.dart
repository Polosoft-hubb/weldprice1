class SuggestedMaterialItem {
  final String name;
  final double quantity;
  final String unit;
  final double? price;

  SuggestedMaterialItem({
    required this.name,
    required this.quantity,
    this.unit = 'пог. м',
    this.price,
  });

  factory SuggestedMaterialItem.fromJson(Map<String, dynamic> json) {
    return SuggestedMaterialItem(
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'пог. м',
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      if (price != null) 'price': price,
    };
  }
}

class AIMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<SuggestedMaterialItem> suggestedMaterials;

  AIMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.suggestedMaterials = const [],
  }) : timestamp = timestamp ?? DateTime.now();
}
