// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';
import '../models/milestone.dart';
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

  Future<void> addMilestone({
    required String title,
    required DateTime date,
    required String icon,
    String type = 'memory',
    bool isCompleted = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final formattedDate =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final newMilestone = await _milestoneService.createMilestone(
        title: title,
        date: formattedDate,
        icon: icon,
        type: type,
        isCompleted: isCompleted,
      );
      _milestones.add(newMilestone);
      _sortMilestones();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editMilestone({
    required String id,
    required String title,
    required DateTime date,
    required String icon,
    String type = 'memory',
    bool isCompleted = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final formattedDate =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final updatedMilestone = await _milestoneService.updateMilestone(
        id: id,
        title: title,
        date: formattedDate,
        icon: icon,
        type: type,
        isCompleted: isCompleted,
      );
      final index = _milestones.indexWhere((item) => item.id == id);
      if (index != -1) {
        _milestones[index] = updatedMilestone;
        _sortMilestones();
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

  void _sortMilestones() {
    _milestones.sort((a, b) => a.date.compareTo(b.date));
  }
}
