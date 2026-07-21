import '../../../core/network/api_client.dart';
import '../models/love_pet.dart';
import '../models/challenge.dart';

class PetService {
  final ApiClient _apiClient;

  PetService(this._apiClient);

  /// Lấy thông tin Pet của cặp đôi. Trả về map gồm { 'hasPet': bool, 'pet': LovePet? }
  Future<Map<String, dynamic>> getPetStatus() async {
    return _apiClient.get<Map<String, dynamic>>(
      '/pet',
      (json) {
        if (json is Map<String, dynamic>) {
          final hasPet = json['hasPet'] as bool? ?? false;
          if (hasPet) {
            return {
              'hasPet': true,
              'pet': LovePet.fromJson(json),
            };
          }
        }
        return {
          'hasPet': false,
          'pet': null,
        };
      },
    );
  }

  /// Nhận nuôi pet hoặc đổi loài pet
  Future<LovePet> adoptPet({required String petType, required String name}) async {
    return _apiClient.post<LovePet>(
      '/pet/adopt',
      {
        'petType': petType,
        'name': name,
      },
      (json) {
        if (json is Map<String, dynamic>) {
          return LovePet.fromJson(json);
        }
        throw Exception('Failed to adopt pet');
      },
    );
  }

  /// Đổi tên pet
  Future<bool> renamePet(String name) async {
    return _apiClient.post<bool>(
      '/pet/rename',
      {
        'name': name,
      },
      (json) {
        if (json is Map<String, dynamic>) {
          return json['success'] as bool? ?? true;
        }
        return json as bool? ?? true;
      },
    );
  }

  /// Lấy danh sách nhiệm vụ hôm nay và stats
  Future<Map<String, dynamic>> getTodayChallenges() async {
    return _apiClient.get<Map<String, dynamic>>(
      '/challenges/today',
      (json) {
        if (json is Map<String, dynamic>) {
          final challengesList = json['challenges'] as List? ?? [];
          final stats = json['stats'] as Map<String, dynamic>? ?? {};
          
          final challenges = challengesList
              .map((item) => Challenge.fromJson(item as Map<String, dynamic>))
              .toList();

          return {
            'challenges': challenges,
            'stats': stats,
          };
        }
        return {
          'challenges': <Challenge>[],
          'stats': <String, dynamic>{},
        };
      },
    );
  }

  /// Báo hoàn thành thử thách
  Future<Map<String, dynamic>> completeChallenge(String challengeKey) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/challenges/$challengeKey/complete',
      {},
      (json) {
        if (json is Map<String, dynamic>) {
          return {
            'completed': json['completed'] as bool? ?? false,
            'xpEarned': json['xpEarned'] as int? ?? 0,
            'happinessEarned': json['happinessEarned'] as int? ?? 0,
            'petData': json['pet'] as Map<String, dynamic>? ?? {},
          };
        }
        throw Exception('Failed to complete challenge');
      },
    );
  }

  /// Giải băng pet
  Future<bool> unfreezePet({required String method}) async {
    return _apiClient.post<bool>(
      '/pet/unfreeze',
      {
        'method': method,
      },
      (json) {
        if (json is Map<String, dynamic>) {
          return json['unfrozen'] as bool? ?? false;
        }
        throw Exception('Failed to unfreeze pet');
      },
    );
  }
}
