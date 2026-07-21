import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/milestone.dart';
import '../models/song_result.dart';

class MilestoneService {
  final ApiClient _apiClient;
  final ImagePicker _picker;

  MilestoneService(this._apiClient, {ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<List<Milestone>> getMilestones() {
    return _apiClient.get<List<Milestone>>('/milestones', (json) {
      if (json is List) {
        return json
            .map((item) => Milestone.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    });
  }

  Future<Milestone> createMilestone({
    required String title,
    required String date,
    required String icon,
    String type = 'memory',
    String? mood,
    String? songTitle,
    String? songArtist,
    String? songPreviewUrl,
    String? songArtworkUrl,
    List<MilestoneTask> checklist = const [],
  }) {
    return _apiClient.post<Milestone>('/milestones', {
      'title': title,
      'date': date,
      'icon': icon,
      'type': type,
      if (mood != null) 'mood': mood,
      if (songTitle != null) 'songTitle': songTitle,
      if (songArtist != null) 'songArtist': songArtist,
      if (songPreviewUrl != null) 'songPreviewUrl': songPreviewUrl,
      if (songArtworkUrl != null) 'songArtworkUrl': songArtworkUrl,
      'checklist': checklist.map((task) => task.toJson()).toList(),
    }, (json) => Milestone.fromJson(json as Map<String, dynamic>));
  }

  Future<Milestone> updateMilestone({
    required String id,
    required String title,
    required String date,
    required String icon,
    String type = 'memory',
    String? mood,
    String? songTitle,
    String? songArtist,
    String? songPreviewUrl,
    String? songArtworkUrl,
    List<MilestoneTask> checklist = const [],
  }) {
    return _apiClient.put<Milestone>('/milestones/$id', {
      'title': title,
      'date': date,
      'icon': icon,
      'type': type,
      if (mood != null) 'mood': mood,
      if (songTitle != null) 'songTitle': songTitle,
      if (songArtist != null) 'songArtist': songArtist,
      if (songPreviewUrl != null) 'songPreviewUrl': songPreviewUrl,
      if (songArtworkUrl != null) 'songArtworkUrl': songArtworkUrl,
      'checklist': checklist.map((task) => task.toJson()).toList(),
    }, (json) => Milestone.fromJson(json as Map<String, dynamic>));
  }

  Future<Milestone> updateChecklistTask({
    required String milestoneId,
    required String taskId,
    required bool isDone,
  }) {
    return _apiClient.patch<Milestone>(
      '/milestones/$milestoneId/tasks/$taskId',
      {'isDone': isDone},
      (json) => Milestone.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Partner responds to a milestone created by the creator.
  /// [action]: 'accept' | 'decline' | 'propose_date'
  Future<Milestone> respondToMilestone({
    required String id,
    required String action,
    String? proposedDate,
  }) {
    return _apiClient.post<Milestone>(
      '/milestones/$id/respond',
      {
        'action': action,
        if (proposedDate != null) 'proposedDate': proposedDate,
      },
      (json) => Milestone.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Creator confirms or declines the date proposed by the partner.
  /// [action]: 'accept' | 'decline'
  Future<Milestone> confirmMilestone({
    required String id,
    required String action,
  }) {
    return _apiClient.post<Milestone>(
      '/milestones/$id/confirm',
      {'action': action},
      (json) => Milestone.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<bool> deleteMilestone(String id) {
    return _apiClient.delete<bool>('/milestones/$id', null, (json) {
      if (json is Map<String, dynamic>) {
        return json['success'] as bool? ?? true;
      }
      return json as bool? ?? true;
    });
  }

  // ── Cover Image Upload ────────────────────────────────────────────────────

  /// Pick multiple images from gallery
  Future<List<XFile>> pickCoverImages() {
    return _picker.pickMultiImage(imageQuality: 85, limit: 5);
  }

  /// Upload cover image to backend → Cloudinary
  Future<Milestone> uploadCoverImage({
    required String milestoneId,
    required List<XFile> files,
  }) async {
    final token = await _apiClient.tokenStorage.readAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${_apiClient.baseUrl}/milestones/$milestoneId/cover'),
    );
    request.headers.addAll({
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    for (final file in files) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('covers', bytes, filename: file.name),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (streamed.statusCode >= 200 &&
        streamed.statusCode < 300 &&
        decoded['success'] == true) {
      return Milestone.fromJson(decoded['data'] as Map<String, dynamic>);
    }

    final error = decoded['error'] as Map<String, dynamic>?;
    throw ApiException(
      code: error?['code'] as String? ?? 'SERVER_ERROR',
      message: error?['message'] as String? ?? 'Upload failed',
      statusCode: streamed.statusCode,
    );
  }

  // ── Music Search (iTunes API) ─────────────────────────────────────────────

  /// Search songs using the iTunes Search API (free, no auth needed)
  Future<List<SongResult>> searchSongs(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': query.trim(),
      'media': 'music',
      'entity': 'song',
      'limit': '10',
      'country': 'VN', // Vietnamese store first
    });

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>? ?? [];

    return results
        .whereType<Map<String, dynamic>>()
        .where((r) => r['previewUrl'] != null) // only tracks with preview
        .map(SongResult.fromJson)
        .toList();
  }
}
