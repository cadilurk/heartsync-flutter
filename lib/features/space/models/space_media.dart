enum SpaceMediaType { photo, video }

class SpaceMedia {
  final String id;
  final String? albumId;
  final SpaceMediaType type;
  final String? url;
  final String? localPath;
  final String? thumbnailUrl;
  final String note;
  final DateTime memoryDate;
  final DateTime createdAt;

  const SpaceMedia({
    required this.id,
    this.albumId,
    required this.type,
    this.url,
    this.localPath,
    this.thumbnailUrl,
    required this.note,
    required this.memoryDate,
    required this.createdAt,
  });

  bool get isVideo => type == SpaceMediaType.video;
  String get displayUrl => thumbnailUrl ?? url ?? '';

  SpaceMedia copyWith({
    String? id,
    String? albumId,
    SpaceMediaType? type,
    String? url,
    String? localPath,
    String? thumbnailUrl,
    String? note,
    DateTime? memoryDate,
    DateTime? createdAt,
    bool clearAlbumId = false,
  }) {
    return SpaceMedia(
      id: id ?? this.id,
      albumId: clearAlbumId ? null : albumId ?? this.albumId,
      type: type ?? this.type,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      note: note ?? this.note,
      memoryDate: memoryDate ?? this.memoryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SpaceMedia.fromJson(Map<String, dynamic> json) {
    return SpaceMedia(
      id: json['id'] as String,
      albumId: json['albumId'] as String?,
      type: (json['type'] as String?) == 'video' ? SpaceMediaType.video : SpaceMediaType.photo,
      url: json['url'] as String?,
      localPath: json['localPath'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      note: json['note'] as String? ?? '',
      memoryDate: DateTime.tryParse(json['memoryDate'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumId': albumId,
      'type': type.name,
      'url': url,
      'localPath': localPath,
      'thumbnailUrl': thumbnailUrl,
      'note': note,
      'memoryDate': memoryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
