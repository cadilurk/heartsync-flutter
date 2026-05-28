
import 'dart:async';
import 'package:flutter/material.dart';

import '../UIColor/appcolors.dart';
import '../UIColor/screenscaffold.dart';
import '../UIColor/uicard.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  String signal = 'love';
  List<Color> get _heartColors {
    if (signal == 'miss') return const [Color(0xFF5FA7F5), Color(0xFF6C82F1)];
    if (signal == 'care') return const [Color(0xFFFBB000), Color(0xFFF59E0B)];
    return const [Color(0xFFEF4E97), Color(0xFFF43F7B)];
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Heart Alarm',
      subtitle: 'Send love signals to your partner 💌',
      children: [
        Stack(
          children: [
            Align(
              child: Container(
                width: 175,
                height: 175,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: _heartColors), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 28, offset: Offset(0, 14))]),
                child: const Icon(Icons.favorite, color: Colors.white, size: 76),
              ),
            ),
            const Positioned(top: 12, right: 34, child: Text('✨', style: TextStyle(fontSize: 27))),
            const Positioned(bottom: 30, left: 26, child: Text('✨', style: TextStyle(fontSize: 20, color: Color(0xFFF472B6)))),
          ],
        ),
        const SizedBox(height: 14),
        const Center(child: Text('Tap or shake your phone', style: TextStyle(fontSize: 32 / 1.5, color: Color(0xFF374151)))),
        const SizedBox(height: 16),
        const Center(child: Text('Choose Signal Type', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF374151)))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _signalCard('miss', '🥺', 'Miss You')),
          const SizedBox(width: 10),
          Expanded(child: _signalCard('care', '🤗', 'Care')),
          const SizedBox(width: 10),
          Expanded(child: _signalCard('love', '💗', 'Love You')),
        ]),
        const SizedBox(height: 14),
        UiCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Row(children: [Icon(Icons.phone_iphone, color: AppColors.active, size: 18), SizedBox(width: 8), Text('Connection Status', style: TextStyle(fontSize: 33 / 1.5, fontWeight: FontWeight.w600, color: Color(0xFF374151)))]),
            SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Your Partner', style: TextStyle(color: AppColors.subtitle)), Row(children: [Icon(Icons.circle, size: 7, color: Color(0xFF22C55E)), SizedBox(width: 6), Text('Online', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600))])]),
            SizedBox(height: 7),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Distance', style: TextStyle(color: AppColors.subtitle)), Text('Close by', style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500))]),
          ]),
        ),
        const SizedBox(height: 14),
        UiCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Recent Signals', style: TextStyle(fontSize: 33 / 1.5, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
            SizedBox(height: 12),
            _Recent(iconBg: Color(0xFFFCE7F3), icon: '💗', title: 'You sent "Love You"', sub: '5 minutes ago'),
            SizedBox(height: 9),
            _Recent(iconBg: Color(0xFFFEF3C7), icon: '🤗', title: 'Partner sent "Care"', sub: '2 hours ago'),
            SizedBox(height: 9),
            _Recent(iconBg: Color(0xFFDBEAFE), icon: '🥺', title: 'You sent "Miss You"', sub: 'Yesterday'),
          ]),
        ),
      ],
    );
  }

  Widget _signalCard(String key, String emoji, String text) {
    final selected = signal == key;
    return InkWell(
      onTap: () => setState(() => signal = key),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.active : AppColors.border, width: selected ? 1.2 : 1),
          boxShadow: selected ? const [BoxShadow(color: Color(0x1AF43F7B), blurRadius: 10, offset: Offset(0, 4))] : null,
        ),
        child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 31 / 1.5)), const SizedBox(height: 6), Text(text, style: const TextStyle(fontSize: 12.5))]),
      ),
    );
  }
}

class _Recent extends StatelessWidget {
  final Color iconBg;
  final String icon;
  final String title;
  final String sub;
  const _Recent({required this.iconBg, required this.icon, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      CircleAvatar(radius: 18, backgroundColor: iconBg, child: Text(icon)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Color(0xFF374151))), Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.subtitle))]),
    ]);
  }
}