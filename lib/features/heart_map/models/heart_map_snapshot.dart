import 'heart_location.dart';

class HeartMapSnapshot {
  final String relationshipId;
  final HeartLocation? self;
  final HeartLocation? partner;
  final int? distanceMeters;
  final String status;
  final List<HeartLocation> history;

  const HeartMapSnapshot({
    required this.relationshipId,
    required this.self,
    required this.partner,
    required this.distanceMeters,
    required this.status,
    required this.history,
  });

  bool get hasBothLocations => self != null && partner != null;

  factory HeartMapSnapshot.fromJson(Map<String, dynamic> json) {
    final historyJson = json['history'];
    return HeartMapSnapshot(
      relationshipId: json['relationshipId']?.toString() ?? '',
      self: json['self'] == null
          ? null
          : HeartLocation.fromJson(json['self'] as Map<String, dynamic>),
      partner: json['partner'] == null
          ? null
          : HeartLocation.fromJson(json['partner'] as Map<String, dynamic>),
      distanceMeters: (json['distanceMeters'] as num?)?.round(),
      status: json['status']?.toString() ?? 'unknown',
      history: historyJson is List
          ? historyJson
                .map(
                  (item) =>
                      HeartLocation.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : const [],
    );
  }
}
