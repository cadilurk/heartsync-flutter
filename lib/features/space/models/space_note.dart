class SpaceNote {
  final String id;
  final String? albumId;
  final String title;
  final String content;
  final List<String> mediaIds;
  final DateTime memoryDate;
  final DateTime createdAt;

  const SpaceNote({
    required this.id,
    this.albumId,
    required this.title,
    required this.content,
    required this.mediaIds,
    required this.memoryDate,
    required this.createdAt,
  });

  factory SpaceNote.fromJson(Map<String, dynamic> json) {
    return SpaceNote(
      id: json['id'] as String,
      albumId: json['albumId'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      mediaIds: (json['mediaIds'] as List? ?? const []).map((id) => id.toString()).toList(),
      memoryDate: DateTime.tryParse(json['memoryDate'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumId': albumId,
      'title': title,
      'content': content,
      'mediaIds': mediaIds,
      'memoryDate': memoryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
