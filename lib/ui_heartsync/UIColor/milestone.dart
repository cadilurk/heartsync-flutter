import 'package:flutter/material.dart';

import 'appcolors.dart';
import 'uicard.dart';
class Milestone extends StatelessWidget {
  final String title;
  final String date;
  final String emoji;
  const Milestone({required this.title, required this.date, required this.emoji});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UiCard(
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 31 / 1.5)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 29 / 1.5, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
            Text(date, style: const TextStyle(fontSize: 13.5, color: AppColors.subtitle)),
          ]),
        ]),
      ),
    );
  }
}