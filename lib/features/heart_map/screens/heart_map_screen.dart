import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/heart_map_snapshot.dart';
import '../models/heart_route_point.dart';
import '../providers/heart_map_provider.dart';

class HeartMapScreen extends StatefulWidget {
  const HeartMapScreen({super.key});

  @override
  State<HeartMapScreen> createState() => _HeartMapScreenState();
}

class _HeartMapScreenState extends State<HeartMapScreen>
    with WidgetsBindingObserver {
  HeartMapProvider? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<HeartMapProvider>();
      unawaited(_provider!.startAutomaticUpdates());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_provider?.startAutomaticUpdates());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_provider?.stopAutomaticUpdates());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_provider?.stopAutomaticUpdates());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HeartMapProvider>();
    final snapshot = provider.snapshot;
    final session = context.watch<AuthProvider>().session;

    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          color: AppColors.active,
          onRefresh: provider.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Bản đồ trái tim',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.title,
                            ),
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Làm mới',
                          onPressed: provider.isLoading ? null : provider.load,
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DistancePanel(snapshot: snapshot),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _MapPanel(
                        snapshot: snapshot,
                        routePoints: provider.routePoints,
                        selfAvatarUrl: session.profile?.avatarUrl,
                        partnerAvatarUrl: session.partnerProfile?.avatarUrl,
                        isTracking: provider.isTracking,
                      ),
                    ),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        provider.errorMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DistancePanel extends StatelessWidget {
  final HeartMapSnapshot? snapshot;

  const _DistancePanel({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final distance = snapshot?.distanceMeters;
    final status = snapshot?.status ?? 'unknown';
    final color = switch (status) {
      'near' => Colors.green,
      'far' => Colors.orange,
      _ => Colors.grey,
    };
    final label = switch (status) {
      'near' => 'Gần nhau',
      'far' => 'Đang xa nhau',
      _ => 'Chờ dữ liệu',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDistance(distance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  final HeartMapSnapshot? snapshot;
  final List<HeartRoutePoint> routePoints;
  final String? selfAvatarUrl;
  final String? partnerAvatarUrl;
  final bool isTracking;

  const _MapPanel({
    required this.snapshot,
    required this.routePoints,
    required this.selfAvatarUrl,
    required this.partnerAvatarUrl,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    final self = snapshot?.self;
    final partner = snapshot?.partner;
    final selfPoint = self == null
        ? null
        : LatLng(self.latitude, self.longitude);
    final partnerPoint = partner == null
        ? null
        : LatLng(partner.latitude, partner.longitude);
    final roadRoute = routePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final displayedRoute = roadRoute.length >= 2
        ? roadRoute
        : [?selfPoint, ?partnerPoint];
    final fitCoordinates = roadRoute.length >= 2
        ? roadRoute
        : [?selfPoint, ?partnerPoint];
    final camera = _cameraFor(
      selfPoint,
      partnerPoint,
      snapshot?.distanceMeters,
    );
    final mapKey = ValueKey(
      '${self?.latitude}:${self?.longitude}:${partner?.latitude}:${partner?.longitude}:${roadRoute.length}',
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              key: mapKey,
              options: MapOptions(
                initialCenter: camera.center,
                initialZoom: camera.zoom,
                initialCameraFit: fitCoordinates.length >= 2
                    ? CameraFit.coordinates(
                        coordinates: fitCoordinates,
                        padding: const EdgeInsets.fromLTRB(64, 80, 64, 62),
                        maxZoom: 16.5,
                      )
                    : null,
                minZoom: 3,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.heartsync_flutter',
                ),
                if (displayedRoute.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: displayedRoute,
                        color: const Color(0x55D4145A),
                        strokeWidth: 12,
                      ),
                      Polyline(
                        points: displayedRoute,
                        strokeWidth: 7,
                        borderStrokeWidth: 1.5,
                        borderColor: Colors.white.withValues(alpha: 0.88),
                        gradientColors: const [
                          Color(0xFFC2185B),
                          Color(0xFFF43F7E),
                          Color(0xFFFF91B8),
                          Color(0xFF9B6DFF),
                        ],
                        colorsStop: const [0, 0.38, 0.72, 1],
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (selfPoint != null)
                      Marker(
                        point: selfPoint,
                        width: 72,
                        height: 72,
                        child: _PersonMarker(
                          avatarUrl: selfAvatarUrl,
                          color: AppColors.active,
                          fallbackIcon: Icons.person,
                        ),
                      ),
                    if (partnerPoint != null)
                      Marker(
                        point: partnerPoint,
                        width: 72,
                        height: 72,
                        child: _PersonMarker(
                          avatarUrl: partnerAvatarUrl,
                          color: const Color(0xFF8267E8),
                          fallbackIcon: Icons.favorite,
                        ),
                      ),
                  ],
                ),
                const RichAttributionWidget(
                  showFlutterMapAttribution: false,
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                    TextSourceAttribution(
                      'Định tuyến bởi OSRM',
                      prependCopyright: false,
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _TrackingBadge(isTracking: isTracking),
            ),
            if (self == null && partner == null)
              const Center(
                child: _MapMessage(
                  message: 'Đang chờ dữ liệu vị trí của hai bạn.',
                ),
              )
            else if (partner == null)
              const Positioned(
                left: 18,
                right: 18,
                bottom: 34,
                child: _MapMessage(
                  message: 'Bạn đời chưa chia sẻ vị trí gần đây.',
                ),
              ),
          ],
        ),
      ),
    );
  }

  ({LatLng center, double zoom}) _cameraFor(
    LatLng? self,
    LatLng? partner,
    int? distanceMeters,
  ) {
    if (self == null && partner == null) {
      return (center: const LatLng(16.0471, 108.2062), zoom: 5.5);
    }
    if (self == null || partner == null) {
      return (center: self ?? partner!, zoom: 15);
    }

    final center = LatLng(
      (self.latitude + partner.latitude) / 2,
      (self.longitude + partner.longitude) / 2,
    );
    final distance = distanceMeters ?? 0;
    final zoom = switch (distance) {
      < 200 => 16.5,
      < 1000 => 15.0,
      < 5000 => 13.0,
      < 20000 => 11.0,
      < 100000 => 9.0,
      _ => 6.0,
    };
    return (center: center, zoom: zoom);
  }
}

class _PersonMarker extends StatefulWidget {
  final String? avatarUrl;
  final Color color;
  final IconData fallbackIcon;

  const _PersonMarker({
    required this.avatarUrl,
    required this.color,
    required this.fallbackIcon,
  });

  @override
  State<_PersonMarker> createState() => _PersonMarkerState();
}

class _PersonMarkerState extends State<_PersonMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = 0.92 + (_pulseController.value * 0.12);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: pulse,
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.32),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(child: _avatar()),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 9),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _avatar() {
    final url = widget.avatarUrl?.trim();
    if (url == null || url.isEmpty) return _fallback();
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => ColoredBox(
    color: widget.color.withValues(alpha: 0.12),
    child: Icon(widget.fallbackIcon, color: widget.color, size: 24),
  );
}

class _TrackingBadge extends StatelessWidget {
  final bool isTracking;

  const _TrackingBadge({required this.isTracking});

  @override
  Widget build(BuildContext context) {
    final color = isTracking ? const Color(0xFF16865C) : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            isTracking ? 'Đang chia sẻ vị trí' : 'Vị trí chưa bật',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  final String message;

  const _MapMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

String _formatDistance(int? meters) {
  if (meters == null) return '-- km';
  if (meters < 1000) return '$meters m';
  return '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';
}
