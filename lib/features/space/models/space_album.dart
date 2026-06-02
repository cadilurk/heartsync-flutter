class SpaceAlbum {
  final String id;
  final String title;
  final String description;
  final String? coverMediaId;
  final String? cloudinaryFolder;
  final DateTime createdAt;

  const SpaceAlbum({
    required this.id,
    required this.title,
    this.description = '',
    this.coverMediaId,
    this.cloudinaryFolder,
    required this.createdAt,
  });

  factory SpaceAlbum.fromJson(Map<String, dynamic> json) {
    return SpaceAlbum(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverMediaId: json['coverMediaId'] as String?,
      cloudinaryFolder: json['cloudinaryFolder'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverMediaId': coverMediaId,
      'cloudinaryFolder': cloudinaryFolder,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
