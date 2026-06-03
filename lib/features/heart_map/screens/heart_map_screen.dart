import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/heart_location.dart';
import '../models/heart_map_snapshot.dart';
import '../providers/heart_map_provider.dart';

class HeartMapScreen extends StatefulWidget {
  const HeartMapScreen({super.key});

  @override
  State<HeartMapScreen> createState() => _HeartMapScreenState();
}

class _HeartMapScreenState extends State<HeartMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HeartMapProvider>().load();
    });
  }

  Future<void> _updateLocation() async {
    final provider = context.read<HeartMapProvider>();
    try {
      await provider.updateCurrentLocation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da cap nhat vi tri.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final message = provider.errorMessage ?? 'Khong the cap nhat vi tri.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HeartMapProvider>();
    final snapshot = provider.snapshot;
    final selfUserId = context.watch<AuthProvider>().session.user?.id;

    return RefreshIndicator(
      color: AppColors.active,
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Heart Map',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Refresh',
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
          const SizedBox(height: 14),
          _DistancePanel(snapshot: snapshot),
          const SizedBox(height: 16),
          SizedBox(height: 260, child: _MapPanel(snapshot: snapshot)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: provider.isUpdating ? null : _updateLocation,
            icon: provider.isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              provider.isUpdating ? 'Dang cap nhat...' : 'Cap nhat vi tri',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.active,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: const [
              Icon(Icons.history, color: AppColors.active),
              SizedBox(width: 8),
              Text(
                'Lich su distance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (snapshot == null && provider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.active),
              ),
            )
          else if (snapshot == null || snapshot.history.isEmpty)
            const _EmptyHistory()
          else
            ...snapshot.history.map(
              (item) =>
                  _HistoryTile(item: item, isSelf: item.userId == selfUserId),
            ),
        ],
      ),
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
      'near' => 'Gan nhau',
      'far' => 'Dang xa nhau',
      _ => 'Cho du lieu',
    };

    return Container(
      padding: const EdgeInsets.all(18),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDistance(distance),
                  style: const TextStyle(
                    fontSize: 26,
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

  const _MapPanel({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final self = snapshot?.self;
    final partner = snapshot?.partner;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _HeartMapPainter(self: self, partner: partner),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _MapLegend(color: AppColors.active, label: 'Ban'),
            ),
            Positioned(
              left: 14,
              top: 44,
              child: _MapLegend(color: Colors.indigo, label: 'Partner'),
            ),
            if (self == null || partner == null)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Can ca hai nguoi cap nhat vi tri de hien distance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _MapLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _HeartMapPainter extends CustomPainter {
  final HeartLocation? self;
  final HeartLocation? partner;

  _HeartMapPainter({required this.self, required this.partner});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [?self, ?partner];
    if (points.isEmpty) return;

    final minLat = points
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLat = points
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    final minLng = points
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    final maxLng = points
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);

    Offset project(HeartLocation item) {
      final latRange = (maxLat - minLat).abs() < 0.000001
          ? 0.01
          : maxLat - minLat;
      final lngRange = (maxLng - minLng).abs() < 0.000001
          ? 0.01
          : maxLng - minLng;
      final x = 28 + ((item.longitude - minLng) / lngRange) * (size.width - 56);
      final y =
          28 + (1 - ((item.latitude - minLat) / latRange)) * (size.height - 56);
      return Offset(x, y);
    }

    final selfOffset = self == null ? null : project(self!);
    final partnerOffset = partner == null ? null : project(partner!);

    if (selfOffset != null && partnerOffset != null) {
      final linePaint = Paint()
        ..color = AppColors.active.withValues(alpha: 0.55)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(selfOffset, partnerOffset, linePaint);
    }

    void drawPoint(Offset offset, Color color) {
      canvas.drawCircle(
        offset,
        13,
        Paint()..color = color.withValues(alpha: 0.18),
      );
      canvas.drawCircle(offset, 7, Paint()..color = color);
    }

    if (selfOffset != null) drawPoint(selfOffset, AppColors.active);
    if (partnerOffset != null) drawPoint(partnerOffset, Colors.indigo);
  }

  @override
  bool shouldRepaint(covariant _HeartMapPainter oldDelegate) {
    return oldDelegate.self != self || oldDelegate.partner != partner;
  }
}

class _HistoryTile extends StatelessWidget {
  final HeartLocation item;
  final bool isSelf;

  const _HistoryTile({required this.item, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final color = isSelf ? AppColors.active : Colors.indigo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelf ? 'Ban da cap nhat' : 'Partner da cap nhat',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(item.recordedAt),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.map_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Chua co lich su vi tri.',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDistance(int? meters) {
  if (meters == null) return '-- km';
  if (meters < 1000) return '$meters m';
  return '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return 'Vua xong';
  if (diff.inHours < 1) return '${diff.inMinutes}p';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
}
