// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';
import '../models/love_pet.dart';
import '../models/challenge.dart';
import '../services/pet_service.dart';

class PetProvider with ChangeNotifier {
  final PetService _petService;

  LovePet? _activePet;
  List<Challenge> _challenges = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _errorMessage;

  PetProvider({required PetService petService}) : _petService = petService;

  LovePet? get activePet => _activePet;
  List<Challenge> get challenges => _challenges;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasPet => _activePet != null;

  /// Tải thông tin thú cưng và các thử thách hôm nay
  Future<void> loadPetAndChallenges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final petResult = await _petService.getPetStatus();
      if (petResult['hasPet'] == true) {
        _activePet = petResult['pet'] as LovePet;

        // Tải các thử thách đi kèm
        final challengesResult = await _petService.getTodayChallenges();
        _challenges = challengesResult['challenges'] as List<Challenge>;
        _stats = challengesResult['stats'] as Map<String, dynamic>;
      } else {
        _activePet = null;
        _challenges = [];
        _stats = {};
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nhận nuôi pet mới hoặc chuyển loại thú cưng
  Future<void> adoptNewPet(String petType, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pet = await _petService.adoptPet(petType: petType, name: name);
      _activePet = pet;
      
      // Tải lại nhiệm vụ để đồng bộ
      final challengesResult = await _petService.getTodayChallenges();
      _challenges = challengesResult['challenges'] as List<Challenge>;
      _stats = challengesResult['stats'] as Map<String, dynamic>;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đổi tên thú cưng
  Future<void> renameActivePet(String name) async {
    if (_activePet == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _petService.renamePet(name);
      if (success) {
        _activePet = _activePet!.copyWith(name: name);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Báo hoàn thành nhiệm vụ
  Future<Map<String, dynamic>> completeTask(String challengeKey) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _petService.completeChallenge(challengeKey);
      
      // Cập nhật lại pet cục bộ nếu có dữ liệu trả về
      if (result['petData'] != null && _activePet != null) {
        final pData = result['petData'] as Map<String, dynamic>;
        _activePet = _activePet!.copyWith(
          level: pData['level'] as int? ?? _activePet!.level,
          xp: pData['xp'] as int? ?? _activePet!.xp,
          xpNeeded: pData['xpNeeded'] as int? ?? _activePet!.xpNeeded,
          happiness: pData['happiness'] as int? ?? _activePet!.happiness,
          streak: pData['streak'] as int? ?? _activePet!.streak,
        );
      }

      // Tải lại danh sách nhiệm vụ để đồng bộ hóa trạng thái hoàn thành
      final challengesResult = await _petService.getTodayChallenges();
      _challenges = challengesResult['challenges'] as List<Challenge>;
      _stats = challengesResult['stats'] as Map<String, dynamic>;

      return result;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Giải đóng băng cho thú cưng
  Future<void> unfreeze(String method) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _petService.unfreezePet(method: method);
      if (success) {
        // Tải lại toàn bộ thông tin
        await loadPetAndChallenges();
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
