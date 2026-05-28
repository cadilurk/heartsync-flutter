import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartsync/ui_heartsync/UIColor/appcolors.dart';
import 'package:heartsync/ui_heartsync/UIColor/uicard.dart';

class MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  const MiniStat({required this.icon, required this.label, required this.value, this.iconColor = AppColors.active});
  @override
  Widget build(BuildContext context) {
    return UiCard(
      child: Column(children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 23)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.subtitle)),
      ]),
    );
  }
}