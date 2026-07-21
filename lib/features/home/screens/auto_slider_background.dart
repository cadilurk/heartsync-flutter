import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class AutoSliderBackground extends StatefulWidget {
  final List<String> imageUrls;
  final Duration duration;

  const AutoSliderBackground({
    super.key,
    required this.imageUrls,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AutoSliderBackground> createState() => _AutoSliderBackgroundState();
}

class _AutoSliderBackgroundState extends State<AutoSliderBackground> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrls.length > 1) {
      _timer = Timer.periodic(widget.duration, (timer) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.imageUrls.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<int>(_currentIndex),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Image.network(
                widget.imageUrls[_currentIndex],
                fit: BoxFit.cover,
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.18)),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Image.network(
                widget.imageUrls[_currentIndex],
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FramedContainImage extends StatelessWidget {
  final String imageUrl;
  final double borderRadius;
  final EdgeInsets padding;

  const FramedContainImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color(0xFFF8EEF5),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.12),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
