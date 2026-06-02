// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/space_album.dart';
import '../models/space_media.dart';
import '../models/space_note.dart';
import '../services/space_service.dart';

class SpaceProvider extends ChangeNotifier {
  final SpaceService _spaceService;

  List<SpaceMedia> media = [];
  List<SpaceNote> notes = [];
  List<SpaceAlbum> albums = [];
  String? selectedAlbumId;
  bool showAllMedia = false;
  bool showAllNotes = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  SpaceProvider({required SpaceService spaceService}) : _spaceService = spaceService;

  int get photoCount => media.where((item) => item.type == SpaceMediaType.photo).length;
  int get videoCount => media.where((item) => item.type == SpaceMediaType.video).length;
  int get noteCount => notes.length;
  int get momentCount => media.length + notes.length;
  List<SpaceMedia> get visibleMedia {
    if (showAllMedia) return media;
    if (selectedAlbumId != null) {
      return media.where((item) => item.albumId == selectedAlbumId).toList();
    }
    return media.where((item) => item.albumId == null).toList();
  }

  List<SpaceNote> get visibleNotes {
    if (showAllNotes) return notes;
    if (selectedAlbumId != null) {
      return notes.where((note) => note.albumId == selectedAlbumId).toList();
    }
    return notes.where((note) => note.albumId == null).toList();
  }
  SpaceAlbum? get selectedAlbum {
    for (final album in albums) {
      if (album.id == selectedAlbumId) return album;
    }
    return null;
  }
  int mediaCountForAlbum(String albumId) {
    return media.where((item) => item.albumId == albumId).length;
  }

  int noteCountForAlbum(String albumId) {
    return notes.where((note) => note.albumId == albumId).length;
  }

  int get outsideMediaCount => media.where((item) => item.albumId == null).length;
  int get outsideNoteCount => notes.where((note) => note.albumId == null).length;

  Future<void> loadSpace() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await Future.wait([
        _spaceService.fetchMedia(),
        _spaceService.fetchNotes(),
        _spaceService.fetchAlbums(),
      ]);
      media = result[0] as List<SpaceMedia>;
      notes = result[1] as List<SpaceNote>;
      albums = result[2] as List<SpaceAlbum>;
      _sort();
    } catch (_) {
      errorMessage = 'Không thể tải Heart Space.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<XFile?> pickPhotoFromGallery() => _spaceService.pickPhotoFromGallery();
  Future<XFile?> capturePhoto() => _spaceService.capturePhoto();
  Future<XFile?> pickVideoFromGallery() => _spaceService.pickVideoFromGallery();
  Future<XFile?> recordVideo() => _spaceService.recordVideo();

  Future<void> addMedia({
    required XFile file,
    required SpaceMediaType type,
    required String note,
    required DateTime memoryDate,
    String? albumId,
  }) async {
    try {
      isSaving = true;
      errorMessage = null;
      notifyListeners();

      final item = await _spaceService.uploadMedia(
        file: file,
        type: type,
        note: note,
        memoryDate: memoryDate,
        albumId: albumId,
      );
      media.insert(0, item);
      if (note.trim().isNotEmpty) {
        notes.insert(
          0,
          await _spaceService.createLocalNote(
            title: _titleFromNote(note),
            content: note,
            mediaIds: [item.id],
            memoryDate: memoryDate,
            albumId: albumId,
          ),
        );
      }
      _sort();
    } catch (_) {
      errorMessage = 'Không thể upload lên Cloudinary. Kiểm tra backend/ngrok và thử lại.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> addNote({
    required String title,
    required String content,
    required DateTime memoryDate,
    String? albumId,
  }) async {
    try {
      isSaving = true;
      errorMessage = null;
      notifyListeners();

      final note = await _spaceService.createNote(
        title: title,
        content: content,
        mediaIds: const [],
        memoryDate: memoryDate,
        albumId: albumId,
      );
      notes.insert(0, note);
      _sort();
    } catch (_) {
      errorMessage = 'Không thể thêm note.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> addAlbum({
    required String title,
    String description = '',
  }) async {
    try {
      errorMessage = null;

      final album = await _spaceService.createAlbum(
        title: title,
        description: description,
      );
      albums.insert(0, album);
      selectedAlbumId = album.id;
    } catch (_) {
      errorMessage = 'Không thể tạo album.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> renameAlbum({
    required String id,
    required String title,
  }) async {
    try {
      errorMessage = null;
      final updated = await _spaceService.renameAlbum(id: id, title: title);
      final index = albums.indexWhere((album) => album.id == id);
      if (index >= 0) albums[index] = updated;
    } catch (_) {
      errorMessage = 'Không thể đổi tên album.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeAlbum(String id) async {
    try {
      errorMessage = null;
      await _spaceService.deleteAlbum(id);
      albums.removeWhere((album) => album.id == id);
      for (var index = 0; index < media.length; index++) {
        final item = media[index];
        if (item.albumId == id) media[index] = item.copyWith(clearAlbumId: true);
      }
      for (var index = 0; index < notes.length; index++) {
        final note = notes[index];
        if (note.albumId == id) {
          notes[index] = SpaceNote(
            id: note.id,
            albumId: null,
            title: note.title,
            content: note.content,
            mediaIds: note.mediaIds,
            memoryDate: note.memoryDate,
            createdAt: note.createdAt,
          );
        }
      }
      if (selectedAlbumId == id) {
        selectedAlbumId = null;
        showAllMedia = false;
        showAllNotes = false;
      }
    } catch (_) {
      errorMessage = 'Không thể xóa album.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeMedia(String id) async {
    try {
      isSaving = true;
      errorMessage = null;
      notifyListeners();

      await _spaceService.deleteMedia(id);
      media.removeWhere((item) => item.id == id);
      for (var index = 0; index < notes.length; index++) {
        final note = notes[index];
        if (note.mediaIds.contains(id)) {
          notes[index] = SpaceNote(
            id: note.id,
            albumId: note.albumId,
            title: note.title,
            content: note.content,
            mediaIds: note.mediaIds.where((mediaId) => mediaId != id).toList(),
            memoryDate: note.memoryDate,
            createdAt: note.createdAt,
          );
        }
      }
    } catch (_) {
      errorMessage = 'Không thể xóa media.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<SpaceMedia?> updateMediaNote({
    required String id,
    required String note,
  }) async {
    try {
      isSaving = true;
      errorMessage = null;
      notifyListeners();

      final updated = await _spaceService.updateMediaNote(id: id, note: note);
      final index = media.indexWhere((item) => item.id == id);
      if (index >= 0) {
        media[index] = updated;
      }
      for (var noteIndex = 0; noteIndex < notes.length; noteIndex++) {
        final currentNote = notes[noteIndex];
        if (currentNote.mediaIds.contains(id)) {
          notes[noteIndex] = SpaceNote(
            id: currentNote.id,
            albumId: currentNote.albumId,
            title: _titleFromNote(note),
            content: note,
            mediaIds: currentNote.mediaIds,
            memoryDate: currentNote.memoryDate,
            createdAt: currentNote.createdAt,
          );
        }
      }
      notifyListeners();
      return updated;
    } catch (_) {
      errorMessage = 'Không thể cập nhật note.';
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> removeNote(String id) async {
    try {
      errorMessage = null;
      await _spaceService.deleteNote(id);
      notes.removeWhere((note) => note.id == id);
    } catch (_) {
      errorMessage = 'Không thể xóa note.';
    } finally {
      notifyListeners();
    }
  }

  void selectAlbum(String? albumId) {
    selectedAlbumId = albumId;
    showAllMedia = false;
    showAllNotes = false;
    notifyListeners();
  }

  void showAllPhotos() {
    if (showAllMedia) {
      showOutsidePhotos();
      return;
    }
    selectedAlbumId = null;
    showAllMedia = true;
    showAllNotes = false;
    notifyListeners();
  }

  void showOutsidePhotos() {
    selectedAlbumId = null;
    showAllMedia = false;
    notifyListeners();
  }

  void showAllNoteItems() {
    if (showAllNotes) {
      showOutsideNotes();
      return;
    }
    selectedAlbumId = null;
    showAllNotes = true;
    showAllMedia = false;
    notifyListeners();
  }

  void showOutsideNotes() {
    selectedAlbumId = null;
    showAllNotes = false;
    notifyListeners();
  }

  SpaceMedia? mediaById(String id) {
    for (final item in media) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<SpaceMedia> mediaForNote(SpaceNote note) {
    return note.mediaIds.map(mediaById).whereType<SpaceMedia>().toList();
  }

  String _titleFromNote(String note) {
    final trimmed = note.trim();
    if (trimmed.length <= 28) return trimmed;
    return '${trimmed.substring(0, 28)}...';
  }

  void _sort() {
    media.sort((a, b) => b.memoryDate.compareTo(a.memoryDate));
    notes.sort((a, b) => b.memoryDate.compareTo(a.memoryDate));
  }
}
