import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartsync/ui_heartsync/UIColor/appcolors.dart';
import 'package:heartsync/ui_heartsync/UIColor/screenscaffold.dart';
import 'package:heartsync/ui_heartsync/UIColor/uicard.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Heart Map',
      subtitle: 'Distance between two hearts 🗺️',
      children: [
        Container(
          height: 285,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFFCBDCF0), Color(0xFFEAD6EA)]),
            boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: CustomPaint(painter: _GridPainter()),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF3EDB6), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE8D94C))),
          child: const Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [Text('💛', style: TextStyle(fontSize: 34 / 1.5)), SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Close by', style: TextStyle(fontSize: 34 / 1.5, fontWeight: FontWeight.w700)), Text('Current Status', style: TextStyle(color: AppColors.subtitle))])]),
              Icon(Icons.circle, color: Color(0xFFDABC3C), size: 14),
            ]),
            SizedBox(height: 10),
            Divider(height: 1),
            SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Distance', style: TextStyle(color: Color(0xFF374151), fontSize: 31 / 1.5)), Text('2.5 km', style: TextStyle(color: Color(0xFFD88700), fontWeight: FontWeight.w800, fontSize: 44 / 1.5))]),
          ]),
        ),
        const SizedBox(height: 14),
        const UiCard(
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: Color(0xFFFCE7F3), child: Icon(Icons.location_on_outlined, color: AppColors.active)),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your Location', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))), Text('District 1, HCMC', style: TextStyle(color: AppColors.subtitle))])),
            Icon(Icons.navigation_outlined, color: Color(0xFF9CA3AF)),
          ]),
        ),
        const SizedBox(height: 10),
        const UiCard(
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: Color(0xFFEDE9FE), child: Icon(Icons.location_on_outlined, color: Color(0xFFA855F7))),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Partner's Location", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151))), Text('District 3, HCMC', style: TextStyle(color: AppColors.subtitle))])),
            Icon(Icons.navigation_outlined, color: Color(0xFF9CA3AF)),
          ]),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = const Color(0x22A8A8B3)..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final p1 = Offset(size.width * .25, size.height * .35);
    final p2 = Offset(size.width * .75, size.height * .56);
    final dash = Paint()..color = const Color(0x99F6C343)..strokeWidth = 2;
    canvas.drawLine(p1, p2, dash);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}