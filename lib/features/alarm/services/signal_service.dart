import '../../../core/network/api_client.dart';
import '../models/signal.dart';
import '../providers/alarm_provider.dart';

class SignalService {
  final ApiClient _apiClient;

  SignalService(this._apiClient);

  Future<Signal> sendSignal(SignalType type) {
    return _apiClient.post<Signal>(
      '/signals',
      {'signalType': type.name},
      (json) => Signal.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<Signal>> getUnread() {
    return _apiClient.get<List<Signal>>(
      '/signals/unread',
      (json) {
        if (json is List) {
          return json.map((item) => Signal.fromJson(item as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  Future<List<Signal>> getHistory({int limit = 20, String? before}) {
    final queryParams = <String>[
      'limit=$limit',
      if (before != null) 'before=${Uri.encodeComponent(before)}',
    ].join('&');

    return _apiClient.get<List<Signal>>(
      '/signals/history?$queryParams',
      (json) {
        if (json is List) {
          return json.map((item) => Signal.fromJson(item as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  Future<bool> markRead(String signalId) {
    return _apiClient.patch<bool>(
      '/signals/$signalId/read',
      null,
      (json) => json == true,
    );
  }

  Future<bool> markAllRead() {
    return _apiClient.patch<bool>(
      '/signals/read-all',
      null,
      (json) => json == true,
    );
  }
}
