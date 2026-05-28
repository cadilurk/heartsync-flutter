import 'package:flutter/material.dart';
import 'uicard.dart';


import 'appcolors.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  const StatCard({required this.icon, required this.iconColor, required this.label, required this.value, required this.sub});
  @override
  Widget build(BuildContext context) {
    return UiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: iconColor), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 15))]),
        const SizedBox(height: 7),
        Text(value, style: const TextStyle(fontSize: 35 / 1.5, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
        Text(sub, style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
      ]),
    );
  }
}