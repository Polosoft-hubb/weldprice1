class NoteModel {
  final String id;
  final String title;
  final String content;
  final int? projectId;
  final String? projectName;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    this.title = '',
    required this.content,
    this.projectId,
    this.projectName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      projectId: (json['project_id'] as num?)?.toInt(),
      projectName: json['project_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'project_id': projectId,
      'project_name': projectName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    int? projectId,
    bool clearProject = false,
    String? projectName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      projectName: clearProject ? null : (projectName ?? this.projectName),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
