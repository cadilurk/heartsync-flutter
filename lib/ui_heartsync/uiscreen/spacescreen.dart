import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartsync/ui_heartsync/UIColor/appcolors.dart';
import 'package:heartsync/ui_heartsync/UIColor/ministat.dart';
import 'package:heartsync/ui_heartsync/UIColor/screenscaffold.dart';
import 'package:heartsync/ui_heartsync/UIColor/uicard.dart';

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});
  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  bool photos = true;
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Heart Space',
      subtitle: '🔒  Your private space together',
      children: [
        Row(children: const [
          Expanded(child: MiniStat(icon: Icons.image_outlined, label: 'Photos', value: '156')),
          SizedBox(width: 10),
          Expanded(child: MiniStat(icon: Icons.chat_bubble_outline, label: 'Notes', value: '42', iconColor: Color(0xFFA855F7))),
          SizedBox(width: 10),
          Expanded(child: MiniStat(icon: Icons.favorite_border, label: 'Moments', value: '24', iconColor: AppColors.active)),
        ]),
        const SizedBox(height: 12),
        UiCard(
          padding: const EdgeInsets.all(4),
          child: Row(children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => photos = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: photos ? const Color(0xFFEF5BA2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('📷 Photos', textAlign: TextAlign.center, style: TextStyle(color: photos ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => photos = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: photos ? Colors.transparent : const Color(0xFFEF5BA2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('💬 Notes', textAlign: TextAlign.center, style: TextStyle(color: photos ? const Color(0xFF374151) : Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (photos)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            childAspectRatio: 1,
            children: [
              const _Photo('https://images.unsplash.com/photo-1658851866325-49fb8b7fbcb2?q=80&w=1080'),
              const _Photo('https://images.unsplash.com/photo-1688421937759-7c2b066d8371?q=80&w=1080'),
              const _Photo('https://images.unsplash.com/photo-1693462467631-e013fa26062d?q=80&w=1080'),
              const _Photo('https://images.unsplash.com/photo-1614680889829-9b2d25a71be0?q=80&w=1080'),
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFF9BCE), style: BorderStyle.solid)),
                child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, color: AppColors.active), SizedBox(height: 6), Text('Add Photo', style: TextStyle(color: AppColors.active))])),
              )
            ],
          )
        else
          Column(children: const [
            UiCard(child: Text('💕 First Meeting\nYou wore a white shirt that day...')),
            SizedBox(height: 8),
            UiCard(child: Text('🌄 Da Lat Trip\nThose days were unforgettable...')),
          ]),
      ],
    );
  }
}



class _Photo extends StatelessWidget {
  final String url;
  const _Photo(this.url);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url, fit: BoxFit.cover));
  }
}