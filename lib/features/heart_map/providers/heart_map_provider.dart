// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/heart_map_snapshot.dart';
import '../models/heart_route_point.dart';
import '../services/heart_map_service.dart';

class HeartMapProvider with ChangeNotifier {
  static const _partnerRefreshInterval = Duration(seconds: 10);
  static const _locationDistanceFilterMeters = 25;

  final HeartMapService _service;

  HeartMapSnapshot? _snapshot;
  List<HeartRoutePoint> _routePoints = const [];
  StreamSubscription<Position>? _positionSubscription;
  Timer? _partnerRefreshTimer;
  Position? _lastSentPosition;
  DateTime? _lastSyncedAt;
  bool _isLoading = false;
  bool _isTracking = false;
  bool _requestInFlight = false;
  bool _routeRequestInFlight = false;
  String? _routeKey;
  String? _errorMessage;

  HeartMapProvider({required HeartMapService service}) : _service = service;

  HeartMapSnapshot? get snapshot => _snapshot;
  List<HeartRoutePoint> get routePoints => _routePoints;
  bool get isLoading => _isLoading;
  bool get isTracking => _isTracking;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get errorMessage => _errorMessage;

  Future<void> load({bool showLoading = true}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _snapshot = await _service.getSnapshot();
      _lastSyncedAt = DateTime.now();
      if (showLoading) _errorMessage = null;
      await _refreshRoute();
    } catch (error) {
      if (_snapshot == null || showLoading) {
        _errorMessage = _friendlyLocationError(error);
      }
    } finally {
      _requestInFlight = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startAutomaticUpdates() async {
    if (_partnerRefreshTimer == null) {
      await load(showLoading: _snapshot == null);
      _partnerRefreshTimer = Timer.periodic(
        _partnerRefreshInterval,
        (_) => unawaited(load(showLoading: false)),
      );
    }
    if (_positionSubscription != null) return;

    try {
      final initialPosition = await _currentPosition();
      await _sendPosition(initialPosition, force: true);
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: _locationDistanceFilterMeters,
            ),
          ).listen(
            (position) => unawaited(_handleAutomaticPosition(position)),
            onError: (Object error) {
              unawaited(_positionSubscription?.cancel());
              _positionSubscription = null;
              _isTracking = false;
              _errorMessage = _friendlyLocationError(error);
              notifyListeners();
            },
          );
      _isTracking = true;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _isTracking = false;
      _errorMessage = _friendlyLocationError(error);
      notifyListeners();
    }
  }

  Future<void> stopAutomaticUpdates() async {
    _partnerRefreshTimer?.cancel();
    _partnerRefreshTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  Future<void> _sendPosition(Position position, {bool force = false}) async {
    final previous = _lastSentPosition;
    if (!force && previous != null) {
      final movedMeters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      if (movedMeters < _locationDistanceFilterMeters) return;
    }
    if (_requestInFlight) return;

    _requestInFlight = true;
    try {
      _snapshot = await _service.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      _lastSentPosition = position;
      _lastSyncedAt = DateTime.now();
      _errorMessage = null;
      await _refreshRoute();
    } finally {
      _requestInFlight = false;
      notifyListeners();
    }
  }

  Future<void> _handleAutomaticPosition(Position position) async {
    try {
      await _sendPosition(position);
    } catch (error) {
      _errorMessage = _friendlyLocationError(error);
      notifyListeners();
    }
  }

  Future<void> _refreshRoute() async {
    final self = _snapshot?.self;
    final partner = _snapshot?.partner;
    if (self == null || partner == null) {
      _routePoints = const [];
      _routeKey = null;
      return;
    }

    final nextRouteKey = [
      self.latitude.toStringAsFixed(5),
      self.longitude.toStringAsFixed(5),
      partner.latitude.toStringAsFixed(5),
      partner.longitude.toStringAsFixed(5),
    ].join(':');
    if (_routeRequestInFlight || nextRouteKey == _routeKey) return;

    _routeRequestInFlight = true;
    try {
      final points = await _service.getDrivingRoute(
        fromLatitude: self.latitude,
        fromLongitude: self.longitude,
        toLatitude: partner.latitude,
        toLongitude: partner.longitude,
      );
      if (points.length >= 2) {
        _routePoints = points;
        _routeKey = nextRouteKey;
      }
    } catch (_) {
      // Keep the map usable with its direct-line fallback when routing is down.
      _routePoints = const [];
    } finally {
      _routeRequestInFlight = false;
    }
  }

  Future<Position> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Vui lòng bật dịch vụ vị trí trên thiết bị.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Bạn chưa cấp quyền vị trí cho HeartSync.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền vị trí đang bị khóa. Hãy cho phép trong phần Cài đặt.',
      );
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
      return 'Không lấy được vị trí kịp thời. Hãy thử lại.';
    }
    return message;
  }

  @override
  void dispose() {
    _partnerRefreshTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
