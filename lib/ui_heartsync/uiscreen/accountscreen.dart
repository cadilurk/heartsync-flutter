import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartsync/ui_heartsync/UIColor/appcolors.dart';
import 'package:heartsync/ui_heartsync/UIColor/screenscaffold.dart';
import 'package:heartsync/ui_heartsync/UIColor/uicard.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'My Account',
      subtitle: 'Manage your love journey 💖',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFFEF5BA2), Color(0xFFF45D8B), Color(0xFFA855F7)]),
            boxShadow: const [BoxShadow(color: Color(0x2E9A3AA0), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Column(children: [
            Stack(children: [
              const CircleAvatar(radius: 40, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop')),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: const Icon(Icons.photo_camera_outlined, size: 14, color: AppColors.active),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            const Text('Emma Wilson', style: TextStyle(color: Colors.white, fontSize: 34 / 1.5, fontWeight: FontWeight.w700)),
            const Text('emma.wilson@email.com', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(999)),
              child: const Text('♥ Together since Jan 14, 2024', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        const Row(children: [Icon(Icons.link, color: AppColors.active, size: 18), SizedBox(width: 6), Text('Partner Connection', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 34 / 1.5))]),
        const SizedBox(height: 8),
        const UiCard(
          child: Column(children: [
            Row(children: [
              CircleAvatar(radius: 18, backgroundColor: Color(0xFFE9D5FF), child: Icon(Icons.favorite, size: 18, color: Colors.white)),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Alex Johnson', style: TextStyle(fontWeight: FontWeight.w600)), Text('● Connected', style: TextStyle(color: Color(0xFF22C55E)))])),
              Text('Disconnect', style: TextStyle(color: AppColors.active)),
            ]),
            SizedBox(height: 10),
            Divider(height: 1),
            SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LOVE2024', style: TextStyle(color: AppColors.active, fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 24 / 1.5)), Text('📋 Copy', style: TextStyle(color: AppColors.active))]),
          ]),
        ),
        const SizedBox(height: 14),
        const Row(children: [Icon(Icons.settings_outlined, color: AppColors.active, size: 18), SizedBox(width: 6), Text('Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 34 / 1.5))]),
        const SizedBox(height: 8),
        const UiCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('👤  Edit Profile'), Icon(Icons.chevron_right, color: Color(0xFF9CA3AF))])),
        const SizedBox(height: 8),
        const UiCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('♡  Anniversary Date'), Text('Jan 14, 2024', style: TextStyle(color: AppColors.subtitle))])),
        const SizedBox(height: 8),
        UiCard(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('⚙️  Notifications'),
            Switch(value: true, onChanged: (_) {}, activeColor: Colors.white, activeTrackColor: const Color(0xFFFB7185)),
          ]),
        ),
        const SizedBox(height: 10),
        UiCard(
          color: const Color(0xFFE8EBEF),
          child: const Center(child: Text('↪ Log Out', style: TextStyle(fontSize: 31 / 1.5, color: Color(0xFF374151), fontWeight: FontWeight.w600))),
        ),
      ],
    );
  }
}