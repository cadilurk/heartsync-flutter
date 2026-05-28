
import 'package:flutter/material.dart';

import 'appcolors.dart';

class ScreenScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const ScreenScaffold({super.key, required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      children: [
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 37 / 1.5, color: AppColors.title, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.subtitle)),
        const SizedBox(height: 18),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }
}

