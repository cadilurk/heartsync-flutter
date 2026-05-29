import 'dart:async';
import 'package:flutter/material.dart';
import 'services/mongo_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MongoService.connect();
  await MongoService.testInsert();

  runApp(const HeartSyncApp());
}

class HeartSyncApp extends StatelessWidget {
  const HeartSyncApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HeartSyncShell(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F0F4),
      ),
    );
  }
}

class AppColors {
  static const bg = Color(0xFFF7F0F4);
  static const card = Color(0xFFF8F7FA);
  static const border = Color(0xFFEEDBE7);
  static const title = Color(0xFFD946B7);
  static const subtitle = Color(0xFF6B7280);
  static const active = Color(0xFFF43F7B);
}

class HeartSyncShell extends StatefulWidget {
  const HeartSyncShell({super.key});
  @override
  State<HeartSyncShell> createState() => _HeartSyncShellState();
}

class _HeartSyncShellState extends State<HeartSyncShell> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    AlarmScreen(),
    MapScreen(),
    SpaceScreen(),
    ChallengesScreen(),
    StoreScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 11,
              color: s.contains(WidgetState.selected) ? AppColors.active : const Color(0xFF94A3B8),
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(
              size: 22,
              color: s.contains(WidgetState.selected) ? AppColors.active : const Color(0xFF94A3B8),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          backgroundColor: const Color(0xFFFBFCFD),
          indicatorColor: Colors.transparent,
          height: 62,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Alarm'),
            NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
            NavigationDestination(icon: Icon(Icons.image_outlined), label: 'Space'),
            NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Challenges'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Store'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      ),
    );
  }
}

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

class UiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Border? border;
  const UiCard({super.key, required this.child, this.padding, this.color, this.border});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: border ?? Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

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
          Expanded(child: _StatCard(icon: Icons.auto_awesome, iconColor: Color(0xFFF59E0B), label: 'Challenges', value: '24', sub: 'Completed')),
          SizedBox(width: 12),
          Expanded(child: _StatCard(icon: Icons.calendar_month_outlined, iconColor: Color(0xFFF43F7B), label: 'Memories', value: '156', sub: 'Saved')),
        ]),
        const SizedBox(height: 18),
        const Row(children: [
          Icon(Icons.calendar_month_outlined, size: 19, color: AppColors.active),
          SizedBox(width: 6),
          Text('Important Milestones', style: TextStyle(fontSize: 30 / 1.5, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
        ]),
        const SizedBox(height: 10),
        const _Milestone(title: 'First Meeting', date: 'Jan 14, 2024', emoji: '👋'),
        const _Milestone(title: '100 Days Anniversary', date: 'Apr 23, 2024', emoji: '💯'),
        const _Milestone(title: "Valentine's Day 2025", date: 'Feb 14, 2025', emoji: '💝'),
        const _Milestone(title: 'Your Birthday', date: 'Jun 15, 2025', emoji: '🎂'),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  const _StatCard({required this.icon, required this.iconColor, required this.label, required this.value, required this.sub});
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

class _Milestone extends StatelessWidget {
  final String title;
  final String date;
  final String emoji;
  const _Milestone({required this.title, required this.date, required this.emoji});
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
          Expanded(child: _MiniStat(icon: Icons.image_outlined, label: 'Photos', value: '156')),
          SizedBox(width: 10),
          Expanded(child: _MiniStat(icon: Icons.chat_bubble_outline, label: 'Notes', value: '42', iconColor: Color(0xFFA855F7))),
          SizedBox(width: 10),
          Expanded(child: _MiniStat(icon: Icons.favorite_border, label: 'Moments', value: '24', iconColor: AppColors.active)),
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

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  const _MiniStat({required this.icon, required this.label, required this.value, this.iconColor = AppColors.active});
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

class _Photo extends StatelessWidget {
  final String url;
  const _Photo(this.url);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url, fit: BoxFit.cover));
  }
}

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
          Expanded(child: _MiniStat(icon: Icons.emoji_events_outlined, label: 'Today', value: '2', iconColor: Color(0xFFEAB308))),
          SizedBox(width: 8),
          Expanded(child: _MiniStat(icon: Icons.check_circle_outline, label: 'This Week', value: '24', iconColor: Color(0xFF22C55E))),
          SizedBox(width: 8),
          Expanded(child: _MiniStat(icon: Icons.access_time, label: 'Day Streak', value: '3', iconColor: Color(0xFFA855F7))),
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

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Heart Store',
      subtitle: 'Gift suggestions for your love 🎁',
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search for gifts...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF5BA2))),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [Color(0xFFEF5A79), Color(0xFFA35BEA)]),
            boxShadow: const [BoxShadow(color: Color(0x261F2937), blurRadius: 12, offset: Offset(0, 6))],
          ),
          child: const Text("📈  Valentine's Day is coming!\nPrepare gifts for your loved one 💝", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _CatChip('All', selected: true),
              _CatChip('Valentine'),
              _CatChip('Anniversary'),
              _CatChip('Birthday'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: .68,
          children: const [
            _Product(name: 'Rose Gift Box', price: '\$35', sold: '234 sold', img: 'https://images.unsplash.com/photo-1723274154450-654d2250ccbb?q=80&w=1080', rating: '4.8'),
            _Product(name: 'Premium Silver Necklace', price: '\$52', sold: '156 sold', img: 'https://images.unsplash.com/photo-1643300866907-032b3baeeb1f?q=80&w=1080', rating: '4.9'),
            _Product(name: 'Luxury Perfume', price: '\$88', sold: '98 sold', img: 'https://images.unsplash.com/photo-1747052881000-a640a4981dd0?q=80&w=1080', rating: '4.7'),
            _Product(name: 'Valentine Chocolate Box', price: '\$19', sold: '412 sold', img: 'https://images.unsplash.com/photo-1620527792840-30bee250b846?q=80&w=1080', rating: '4.6'),
          ],
        ),
      ],
    );
  }
}

class _CatChip extends StatelessWidget {
  final String text;
  final bool selected;
  const _CatChip(this.text, {this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected ? const Color(0xFFEF5BA2) : AppColors.card,
        border: Border.all(color: selected ? const Color(0xFFEF5BA2) : AppColors.border),
      ),
      child: Text(text, style: TextStyle(color: selected ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.w600)),
    );
  }
}

class _Product extends StatelessWidget {
  final String name;
  final String price;
  final String sold;
  final String img;
  final String rating;
  const _Product({required this.name, required this.price, required this.sold, required this.img, required this.rating});
  @override
  Widget build(BuildContext context) {
    return UiCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), child: Image.network(img, fit: BoxFit.cover))),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(999)),
                  child: Text('⭐ $rating', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 9, 3),
          child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Color(0xFF374151))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Text(price, style: const TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w800, fontSize: 31 / 1.5)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 4, 9, 9),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(sold, style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Color(0xFFFFE4EE), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border, color: AppColors.active, size: 15),
            ),
          ]),
        )
      ]),
    );
  }
}

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
