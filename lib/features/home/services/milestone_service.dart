import '../../../core/network/api_client.dart';
import '../models/milestone.dart';

class MilestoneService {
  final ApiClient _apiClient;

  MilestoneService(this._apiClient);

  Future<List<Milestone>> getMilestones() {
    return _apiClient.get<List<Milestone>>(
      '/milestones',
      (json) {
        if (json is List) {
          return json
              .map((item) => Milestone.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<Milestone> createMilestone({
    required String title,
    required String date,
    required String icon,
    String type = 'memory',
    bool isCompleted = false,
  }) {
    return _apiClient.post<Milestone>(
      '/milestones',
      {
        'title': title,
        'date': date,
        'icon': icon,
        'type': type,
        'isCompleted': isCompleted,
      },
      (json) => Milestone.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Milestone> updateMilestone({
    required String id,
    required String title,
    required String date,
    required String icon,
    String type = 'memory',
    bool isCompleted = false,
  }) {
    return _apiClient.put<Milestone>(
      '/milestones/$id',
      {
        'title': title,
        'date': date,
        'icon': icon,
        'type': type,
        'isCompleted': isCompleted,
      },
      (json) => Milestone.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<bool> deleteMilestone(String id) {
    return _apiClient.delete<bool>(
      '/milestones/$id',
      null,
      (json) {
        if (json is Map<String, dynamic>) {
          return json['success'] as bool? ?? true;
        }
        return json as bool? ?? true;
      },
    );
  }
}
