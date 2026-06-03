class HeartLocation {
  final String? id;
  final String? relationshipId;
  final String? userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime recordedAt;
  final DateTime? updatedAt;

  const HeartLocation({
    this.id,
    this.relationshipId,
    this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.recordedAt,
    this.updatedAt,
  });

  factory HeartLocation.fromJson(Map<String, dynamic> json) {
    return HeartLocation(
      id: json['id']?.toString(),
      relationshipId: json['relationshipId']?.toString(),
      userId: json['userId']?.toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String).toLocal(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }
}
