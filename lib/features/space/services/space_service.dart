import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/space_album.dart';
import '../models/space_media.dart';
import '../models/space_note.dart';

class SpaceService {
  final ApiClient _apiClient;
  final ImagePicker _picker;

  SpaceService(this._apiClient, {ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<List<SpaceMedia>> fetchMedia() async {
    try {
      return await _apiClient.get<List<SpaceMedia>>(
        '/space/media',
        (json) {
          if (json is List) {
            return json.map((item) => SpaceMedia.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
    } catch (_) {
      return _seedMedia;
    }
  }

  Future<List<SpaceNote>> fetchNotes() async {
    try {
      return await _apiClient.get<List<SpaceNote>>(
        '/space/notes',
        (json) {
          if (json is List) {
            return json.map((item) => SpaceNote.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
    } catch (_) {
      return _seedNotes;
    }
  }

  Future<List<SpaceAlbum>> fetchAlbums() async {
    try {
      return await _apiClient.get<List<SpaceAlbum>>(
        '/space/albums',
        (json) {
          if (json is List) {
            return json.map((item) => SpaceAlbum.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
    } catch (_) {
      return [];
    }
  }

  Future<XFile?> pickPhotoFromGallery() => _picker.pickImage(source: ImageSource.gallery);

  Future<XFile?> capturePhoto() => _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

  Future<XFile?> pickVideoFromGallery() => _picker.pickVideo(source: ImageSource.gallery);

  Future<XFile?> recordVideo() => _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 3),
      );

  Future<SpaceMedia> createLocalMedia({
    required XFile file,
    required SpaceMediaType type,
    required String note,
    required DateTime memoryDate,
    String? albumId,
  }) async {
    final now = DateTime.now();
    return SpaceMedia(
      id: 'local_${now.microsecondsSinceEpoch}',
      albumId: albumId,
      type: type,
      localPath: file.path,
      note: note,
      memoryDate: memoryDate,
      createdAt: now,
    );
  }

  Future<SpaceMedia> uploadMedia({
    required XFile file,
    required SpaceMediaType type,
    required String note,
    required DateTime memoryDate,
    String? albumId,
  }) async {
    final token = await _apiClient.tokenStorage.readAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${_apiClient.baseUrl}/space/media'),
    );
    request.headers.addAll({
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields['type'] = type.name;
    request.fields['note'] = note;
    request.fields['memoryDate'] = memoryDate.toIso8601String();
    if (albumId != null) request.fields['albumId'] = albumId;
    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'media',
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (streamed.statusCode >= 200 && streamed.statusCode < 300 && decoded['success'] == true) {
      return SpaceMedia.fromJson(decoded['data'] as Map<String, dynamic>);
    }

    final error = decoded['error'] as Map<String, dynamic>?;
    throw ApiException(
      code: error?['code'] as String? ?? 'SERVER_ERROR',
      message: error?['message'] as String? ?? 'Không thể upload lên Heart Space.',
      statusCode: streamed.statusCode,
    );
  }

  Future<SpaceNote> createLocalNote({
    required String title,
    required String content,
    required List<String> mediaIds,
    required DateTime memoryDate,
    String? albumId,
  }) async {
    final now = DateTime.now();
    return SpaceNote(
      id: 'note_${now.microsecondsSinceEpoch}',
      albumId: albumId,
      title: title,
      content: content,
      mediaIds: mediaIds,
      memoryDate: memoryDate,
      createdAt: now,
    );
  }

  Future<SpaceNote> createNote({
    required String title,
    required String content,
    required List<String> mediaIds,
    required DateTime memoryDate,
    String? albumId,
  }) async {
    try {
      return await _apiClient.post<SpaceNote>(
        '/space/notes',
        {
          'title': title,
          'content': content,
          'mediaIds': mediaIds,
          'memoryDate': memoryDate.toIso8601String(),
          'albumId': albumId,
        },
        (json) => SpaceNote.fromJson(json as Map<String, dynamic>),
      );
    } catch (_) {
      return createLocalNote(
        title: title,
        content: content,
        mediaIds: mediaIds,
        memoryDate: memoryDate,
        albumId: albumId,
      );
    }
  }

  Future<SpaceAlbum> createAlbum({
    required String title,
    String description = '',
  }) {
    return _apiClient.post<SpaceAlbum>(
      '/space/albums',
      {'title': title, 'description': description},
      (json) => SpaceAlbum.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<SpaceAlbum> renameAlbum({
    required String id,
    required String title,
  }) {
    return _apiClient.put<SpaceAlbum>(
      '/space/albums/$id',
      {'title': title},
      (json) => SpaceAlbum.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteAlbum(String id) async {
    await _apiClient.delete<bool>(
      '/space/albums/$id',
      null,
      (json) => json == true,
    );
  }

  Future<void> deleteMedia(String id) async {
    await _apiClient.delete<bool>(
      '/space/media/$id',
      null,
      (json) => json == true,
    );
  }

  Future<SpaceMedia> updateMediaNote({
    required String id,
    required String note,
  }) {
    return _apiClient.put<SpaceMedia>(
      '/space/media/$id/note',
      {'note': note},
      (json) => SpaceMedia.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> deleteNote(String id) async {
    await _apiClient.delete<bool>(
      '/space/notes/$id',
      null,
      (json) => json == true,
    );
  }

  List<SpaceMedia> get _seedMedia => [
        SpaceMedia(
          id: 'seed_photo_1',
          type: SpaceMediaType.photo,
          url: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=900',
          note: 'The sunset felt like it was waiting for us.',
          memoryDate: DateTime(2024, 1, 14),
          createdAt: DateTime(2024, 1, 14),
        ),
        SpaceMedia(
          id: 'seed_photo_2',
          type: SpaceMediaType.photo,
          url: 'https://images.unsplash.com/photo-1522673607200-164d1b6ce486?q=80&w=900',
          note: 'Walking by the sea and laughing at tiny waves.',
          memoryDate: DateTime(2024, 2, 28),
          createdAt: DateTime(2024, 2, 28),
        ),
        SpaceMedia(
          id: 'seed_photo_3',
          type: SpaceMediaType.photo,
          url: 'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?q=80&w=900',
          note: 'A small table, warm candles, and a very full heart.',
          memoryDate: DateTime(2024, 3, 15),
          createdAt: DateTime(2024, 3, 15),
        ),
      ];

  List<SpaceNote> get _seedNotes => [
        SpaceNote(
          id: 'seed_note_1',
          title: 'First Meeting',
          content: 'You wore a white shirt that day, with the brightest smile. I knew right then you were the one...',
          mediaIds: const ['seed_photo_1'],
          memoryDate: DateTime(2024, 1, 14),
          createdAt: DateTime(2024, 1, 14),
        ),
        SpaceNote(
          id: 'seed_note_2',
          title: 'Da Lat Trip',
          content: 'Those days in Da Lat were unforgettable. We watched sunsets together, walked in the morning...',
          mediaIds: const ['seed_photo_2'],
          memoryDate: DateTime(2024, 2, 28),
          createdAt: DateTime(2024, 2, 28),
        ),
      ];
}
