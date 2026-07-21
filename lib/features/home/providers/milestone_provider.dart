import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/milestone.dart';
import '../models/song_result.dart';
import '../services/milestone_service.dart';

class MilestoneProvider with ChangeNotifier {
  final MilestoneService _milestoneService;
  List<Milestone> _milestones = [];
  bool _isLoading = false;
  String? _errorMessage;

  MilestoneProvider({required MilestoneService milestoneService})
    : _milestoneService = milestoneService;

  List<Milestone> get milestones => _milestones;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadMilestones() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _milestoneService.getMilestones();
      _milestones = list;
      _sortMilestones();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<Milestone> addMilestone({
    required String title,
    required DateTime date,
    required String icon,
    String type = 'memory',
    String? mood,
    String? songTitle,
    String? songArtist,
    String? songPreviewUrl,
    String? songArtworkUrl,
    List<MilestoneTask> checklist = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final formattedDate = _fmt(date);
      final newMilestone = await _milestoneService.createMilestone(
        title: title,
        date: formattedDate,
        icon: icon,
        type: type,
        mood: mood,
        songTitle: songTitle,
        songArtist: songArtist,
        songPreviewUrl: songPreviewUrl,
        songArtworkUrl: songArtworkUrl,
        checklist: checklist,
      );
      _milestones.add(newMilestone);
      _sortMilestones();
      _errorMessage = null;
      return newMilestone;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Edit ──────────────────────────────────────────────────────────────────

  Future<void> editMilestone({
    required String id,
    required String title,
    required DateTime date,
    required String icon,
    String type = 'memory',
    String? mood,
    String? songTitle,
    String? songArtist,
    String? songPreviewUrl,
    String? songArtworkUrl,
    List<MilestoneTask> checklist = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedMilestone = await _milestoneService.updateMilestone(
        id: id,
        title: title,
        date: _fmt(date),
        icon: icon,
        type: type,
        mood: mood,
        songTitle: songTitle,
        songArtist: songArtist,
        songPreviewUrl: songPreviewUrl,
        songArtworkUrl: songArtworkUrl,
        checklist: checklist,
      );
      _updateLocal(updatedMilestone);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateChecklistTask({
    required String milestoneId,
    required String taskId,
    required bool isDone,
  }) async {
    try {
      final index = _milestones.indexWhere((item) => item.id == milestoneId);
      Milestone? previous;
      if (index != -1) {
        previous = _milestones[index];
        final updatedTasks = previous.checklist
            .map(
              (task) =>
                  task.id == taskId ? task.copyWith(isDone: isDone) : task,
            )
            .toList();
        _milestones[index] = previous.copyWith(checklist: updatedTasks);
        notifyListeners();
      }

      final updated = await _milestoneService.updateChecklistTask(
        milestoneId: milestoneId,
        taskId: taskId,
        isDone: isDone,
      );
      _updateLocal(updated);
      _errorMessage = null;
    } catch (e) {
      await loadMilestones();
      _errorMessage = e.toString();
      rethrow;
    }
  }

  // ── Cover Image ───────────────────────────────────────────────────────────

  Future<List<XFile>> pickCoverImages() {
    return _milestoneService.pickCoverImages();
  }

  Future<void> uploadCoverImage({
    required String milestoneId,
    required List<XFile> files,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _milestoneService.uploadCoverImage(
        milestoneId: milestoneId,
        files: files,
      );
      _updateLocal(updated);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Song Search ───────────────────────────────────────────────────────────

  Future<List<SongResult>> searchSongs(String query) {
    return _milestoneService.searchSongs(query);
  }

  // ── Dual Confirmation ─────────────────────────────────────────────────────

  /// Partner responds: 'accept' | 'decline' | 'propose_date'
  Future<void> respondToMilestone({
    required String id,
    required String action,
    String? proposedDate,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _milestoneService.respondToMilestone(
        id: id,
        action: action,
        proposedDate: proposedDate,
      );
      _updateLocal(updated);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creator confirms or declines partner's proposed date: 'accept' | 'decline'
  Future<void> confirmMilestone({
    required String id,
    required String action,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updated = await _milestoneService.confirmMilestone(
        id: id,
        action: action,
      );
      _updateLocal(updated);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> removeMilestone(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _milestoneService.deleteMilestone(id);
      if (success) {
        _milestones.removeWhere((item) => item.id == id);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updateLocal(Milestone updated) {
    final index = _milestones.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _milestones[index] = updated;
      _sortMilestones();
    }
  }

  void _sortMilestones() {
    _milestones.sort((a, b) => a.date.compareTo(b.date));
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
