import '../../../core/network/api_client.dart';
import '../models/heart_map_snapshot.dart';

class HeartMapService {
  final ApiClient _apiClient;

  HeartMapService(this._apiClient);

  Future<HeartMapSnapshot> getSnapshot() {
    return _apiClient.get<HeartMapSnapshot>(
      '/heart-map',
      (json) => HeartMapSnapshot.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<HeartMapSnapshot> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) {
    return _apiClient.post<HeartMapSnapshot>(
      '/heart-map/location',
      {'latitude': latitude, 'longitude': longitude, 'accuracy': accuracy},
      (json) => HeartMapSnapshot.fromJson(json as Map<String, dynamic>),
    );
  }
}
