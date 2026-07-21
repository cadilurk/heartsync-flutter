import 'dart:async';
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: NetworkImage(widget.imageUrls[_currentIndex]),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
