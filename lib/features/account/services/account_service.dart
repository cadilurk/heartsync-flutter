import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/models/current_user_session.dart';
import '../../pairing/models/couple_relationship.dart';
import '../models/profile.dart';
import '../models/user.dart';

class AccountService {
  final ApiClient _apiClient;
  final ImagePicker _picker;

  AccountService(this._apiClient, {ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Opens the gallery picker and returns the chosen image, or `null` if the
  /// user backed out.
  Future<XFile?> pickAvatarImage() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  }

  /// Uploads [file] to the backend, which forwards it to Cloudinary and
  /// stores the resulting URL on the user's profile. Returns that URL.
  Future<String> uploadAvatar(XFile file) async {
    final token = await _apiClient.tokenStorage.readAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${_apiClient.baseUrl}/account/avatar'),
    );
    request.headers.addAll({
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('avatar', bytes, filename: file.name),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (streamed.statusCode >= 200 &&
        streamed.statusCode < 300 &&
        decoded['success'] == true) {
      final data = decoded['data'] as Map<String, dynamic>;
      return data['avatarUrl'] as String;
    }

    final error = decoded['error'] as Map<String, dynamic>?;
    throw ApiException(
      code: error?['code'] as String? ?? 'SERVER_ERROR',
      message: error?['message'] as String? ?? 'Upload failed',
      statusCode: streamed.statusCode,
    );
  }

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
    final partnerProfileJson = json['partnerProfile'];

    return CurrentUserSession(
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
      profile: profileJson is Map<String, dynamic> ? Profile.fromJson(profileJson) : null,
      relationship: relationshipJson is Map<String, dynamic>
          ? CoupleRelationship.fromJson(relationshipJson)
          : null,
      partner: partnerJson is Map<String, dynamic> ? User.fromJson(partnerJson) : null,
      partnerProfile: partnerProfileJson is Map<String, dynamic>
          ? Profile.fromJson(partnerProfileJson)
          : null,
      isAuthenticated: userJson is Map<String, dynamic>,
    );
  }
}
