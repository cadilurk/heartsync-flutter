import 'dart:async';
import 'package:flutter/material.dart';

import 'package:heartsync/ui_heartsync/UIColor/appcolors.dart';
import 'package:heartsync/ui_heartsync/UIColor/ministat.dart';
import 'package:heartsync/ui_heartsync/UIColor/screenscaffold.dart';
import 'package:heartsync/ui_heartsync/UIColor/uicard.dart';


class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Heart Challenges',
      subtitle: 'Raise your love pet together 🐾',
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFFC174EE), Color(0xFFEF5BA2)]),
          ),
          child: Column(children: [
            Stack(
              clipBehavior: Clip.none,
              children: const [
                CircleAvatar(radius: 42, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1681062791533-81a44832eb72?q=80&w=1080')),
                Positioned(right: -2, top: -6, child: _LevelBadge()),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Love Cat', style: TextStyle(color: Colors.white, fontSize: 31 / 1.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const _Progress(title: 'Happiness', value: 0.85, trail: '85%', color: Color(0xFFFACC15)),
            const SizedBox(height: 8),
            const _Progress(title: 'Experience', value: 0.64, trail: '320/500', color: Color(0xFFF9A8D4)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFEF9C3), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFFDE047))),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline, color: Color(0xFFD97706), size: 17),
                SizedBox(width: 6),
                Expanded(child: Text('4 days left to complete challenges\nIf no challenges completed in 7 days, pet will be frozen', style: TextStyle(color: Color(0xFF92400E), fontSize: 12.5))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: MiniStat(icon: Icons.emoji_events_outlined, label: 'Today', value: '2', iconColor: Color(0xFFEAB308))),
          SizedBox(width: 8),
          Expanded(child: MiniStat(icon: Icons.check_circle_outline, label: 'This Week', value: '24', iconColor: Color(0xFF22C55E))),
          SizedBox(width: 8),
          Expanded(child: MiniStat(icon: Icons.access_time, label: 'Day Streak', value: '3', iconColor: Color(0xFFA855F7))),
        ]),
        const SizedBox(height: 12),
        const Row(children: [Icon(Icons.emoji_events_outlined, color: AppColors.active, size: 18), SizedBox(width: 6), Text("Today's Challenges", style: TextStyle(fontSize: 31 / 1.5, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 10),
        const _Challenge(icon: Icons.videocam_outlined, title: '15-minute video call', desc: 'Chat via video call for at least 15 minutes', points: '+10 points'),
        const SizedBox(height: 8),
        const _Challenge(icon: Icons.place_outlined, title: 'Check-in together', desc: 'Check-in at the same location', points: '+15 points', completed: true),
        const SizedBox(height: 8),
        const _Challenge(icon: Icons.free_breakfast_outlined, title: 'Order food for partner', desc: 'Send a surprise food order to your partner', points: '+20 points'),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFFACC15), borderRadius: BorderRadius.circular(999)),
      child: const Text('Lv.5', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _Progress extends StatelessWidget {
  final String title;
  final double value;
  final String trail;
  final Color color;
  const _Progress({required this.title, required this.value, required this.trail, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.white)), Text(trail, style: const TextStyle(color: Colors.white))]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 9,
          backgroundColor: const Color(0x66FFFFFF),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}

class _Challenge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String points;
  final bool completed;
  const _Challenge({required this.icon, required this.title, required this.desc, required this.points, this.completed = false});
  @override
  Widget build(BuildContext context) {
    return UiCard(
      border: Border.all(color: completed ? const Color(0xFF86EFAC) : AppColors.border),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(colors: completed ? [const Color(0xFF22C55E), const Color(0xFF10B981)] : [const Color(0xFF38BDF8), const Color(0xFF06B6D4)]),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: const TextStyle(fontSize: 31 / 1.5, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
              if (completed) const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 18),
            ]),
            Text(desc, style: const TextStyle(color: AppColors.subtitle)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(points, style: const TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.w600, fontSize: 13)),
              if (completed)
                const Text('Completed', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600))
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEF5BA2), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}