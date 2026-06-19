class PartItem {
  final String id;
  final int projectId;
  final String profileName;
  final double length; // in mm
  final int quantity;
  final String leftCut; // '90' or '45'
  final String rightCut; // '90' or '45'

  PartItem({
    required this.id,
    required this.projectId,
    required this.profileName,
    required this.length,
    required this.quantity,
    required this.leftCut,
    required this.rightCut,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'profileName': profileName,
      'length': length,
      'quantity': quantity,
      'leftCut': leftCut,
      'rightCut': rightCut,
    };
  }

  factory PartItem.fromJson(Map<String, dynamic> json) {
    return PartItem(
      id: json['id'] as String,
      projectId: json['projectId'] as int,
      profileName: json['profileName'] as String,
      length: (json['length'] as num).toDouble(),
      quantity: json['quantity'] as int,
      leftCut: json['leftCut'] as String? ?? '90',
      rightCut: json['rightCut'] as String? ?? '90',
    );
  }

  PartItem copyWith({
    String? id,
    int? projectId,
    String? profileName,
    double? length,
    int? quantity,
    String? leftCut,
    String? rightCut,
  }) {
    return PartItem(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      profileName: profileName ?? this.profileName,
      length: length ?? this.length,
      quantity: quantity ?? this.quantity,
      leftCut: leftCut ?? this.leftCut,
      rightCut: rightCut ?? this.rightCut,
    );
  }
}
