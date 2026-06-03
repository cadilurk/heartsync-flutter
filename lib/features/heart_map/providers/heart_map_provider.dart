// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/heart_map_snapshot.dart';
import '../services/heart_map_service.dart';

class HeartMapProvider with ChangeNotifier {
  final HeartMapService _service;

  HeartMapSnapshot? _snapshot;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  HeartMapProvider({required HeartMapService service}) : _service = service;

  HeartMapSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _snapshot = await _service.getSnapshot();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCurrentLocation() async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await _currentPosition();
      _snapshot = await _service.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e) {
      _errorMessage = _friendlyLocationError(e);
      rethrow;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<Position> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Vui long bat dich vu vi tri tren thiet bi.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Ban chua cap quyen vi tri cho HeartSync.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyen vi tri dang bi khoa. Hay mo trong Settings.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  String _friendlyLocationError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('TimeoutException')) {
      return 'Khong lay duoc vi tri kip thoi. Hay thu lai.';
    }
    return message;
  }
}
