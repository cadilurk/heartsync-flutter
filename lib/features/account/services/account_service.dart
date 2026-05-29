import '../../../core/network/api_client.dart';
import '../../auth/models/current_user_session.dart';
import '../../pairing/models/couple_relationship.dart';
import '../models/profile.dart';
import '../models/user.dart';

class AccountService {
  final ApiClient _apiClient;

  AccountService(this._apiClient);

  Future<CurrentUserSession> me() {
    return _apiClient.get<CurrentUserSession>(
      '/account/me',
      (json) => _sessionFromJson(json as Map<String, dynamic>),
    );
  }

  Future<Profile> updateProfile({
    required String displayName,
    String? avatarUrl,
    String? dateOfBirth,
    String? relationshipStartDate,
    String? gender,
    String? bio,
  }) {
    return _apiClient.put<Profile>(
      '/account/profile',
      {
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'dateOfBirth': dateOfBirth,
        'relationshipStartDate': relationshipStartDate,
        'gender': gender,
        'bio': bio,
      },
      (json) => Profile.fromJson(json as Map<String, dynamic>),
    );
  }

  CurrentUserSession _sessionFromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final profileJson = json['profile'];
    final relationshipJson = json['relationship'];
    final partnerJson = json['partner'];

    return CurrentUserSession(
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
      profile: profileJson is Map<String, dynamic> ? Profile.fromJson(profileJson) : null,
      relationship: relationshipJson is Map<String, dynamic>
          ? CoupleRelationship.fromJson(relationshipJson)
          : null,
      partner: partnerJson is Map<String, dynamic> ? User.fromJson(partnerJson) : null,
      isAuthenticated: userJson is Map<String, dynamic>,
    );
  }
}
