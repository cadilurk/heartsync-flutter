import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartsync/ui_heartsync/UIColor/appcolors.dart';
import 'package:heartsync/ui_heartsync/UIColor/statcard.dart';
import 'package:heartsync/ui_heartsync/UIColor/milestone.dart';
import 'package:heartsync/ui_heartsync/UIColor/screenscaffold.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DateTime startDate = DateTime(2024, 1, 14);
  int days = 0;
  @override
  void initState() {
    super.initState();
    _update();
    Timer.periodic(const Duration(hours: 1), (_) => _update());
  }

  void _update() => setState(() => days = DateTime.now().difference(startDate).inDays.abs());

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Our Love Story',
      subtitle: 'Every day is worth cherishing 💕',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEE5AA6), Color(0xFFF85787), Color(0xFFA63EE8)],
            ),
            boxShadow: const [BoxShadow(color: Color(0x2E9A3AA0), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Column(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 62),
              const SizedBox(height: 16),
              const Text("We've been together for", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('$days', style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w800, height: 1)),
              const SizedBox(height: 4),
              const Text('days', style: TextStyle(color: Colors.white, fontSize: 33 / 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(children: const [
          Expanded(child: StatCard(icon: Icons.auto_awesome, iconColor: Color(0xFFF59E0B), label: 'Challenges', value: '24', sub: 'Completed')),
          SizedBox(width: 12),
          Expanded(child: StatCard(icon: Icons.calendar_month_outlined, iconColor: Color(0xFFF43F7B), label: 'Memories', value: '156', sub: 'Saved')),
        ]),
        const SizedBox(height: 18),
        const Row(children: [
          Icon(Icons.calendar_month_outlined, size: 19, color: AppColors.active),
          SizedBox(width: 6),
          Text('Important Milestones', style: TextStyle(fontSize: 30 / 1.5, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
        ]),
        const SizedBox(height: 10),
        const Milestone(title: 'First Meeting', date: 'Jan 14, 2024', emoji: '👋'),
        const Milestone(title: '100 Days Anniversary', date: 'Apr 23, 2024', emoji: '💯'),
        const Milestone(title: "Valentine's Day 2025", date: 'Feb 14, 2025', emoji: '💝'),
        const Milestone(title: 'Your Birthday', date: 'Jun 15, 2025', emoji: '🎂'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF5BA2),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: const Text('+ Add New Milestone', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}