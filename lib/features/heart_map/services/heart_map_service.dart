import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../models/heart_map_snapshot.dart';
import '../models/heart_route_point.dart';

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

  Future<List<HeartRoutePoint>> getDrivingRoute({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) async {
    final coordinates = '$fromLongitude,$fromLatitude;$toLongitude,$toLatitude';
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coordinates',
      const {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Không thể tải tuyến đường lúc này.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = payload['routes'] as List<dynamic>?;
    if (payload['code'] != 'Ok' || routes == null || routes.isEmpty) {
      throw Exception('Không tìm thấy tuyến đường giữa hai vị trí.');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinatesList = geometry['coordinates'] as List<dynamic>;
    return coordinatesList
        .map((coordinate) {
          final values = coordinate as List<dynamic>;
          return HeartRoutePoint(
            latitude: (values[1] as num).toDouble(),
            longitude: (values[0] as num).toDouble(),
          );
        })
        .toList(growable: false);
  }
}
