import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartsync/ui_heartsync/UIColor/appcolors.dart';
import 'package:heartsync/ui_heartsync/uiscreen/accountscreen.dart';
import 'package:heartsync/ui_heartsync/uiscreen/alarmscreen.dart';
import 'package:heartsync/ui_heartsync/uiscreen/challengescreen.dart';
import 'package:heartsync/ui_heartsync/uiscreen/homescreen.dart';
import 'package:heartsync/ui_heartsync/uiscreen/mapscreen.dart';
import 'package:heartsync/ui_heartsync/uiscreen/spacescreen.dart';
import 'package:heartsync/ui_heartsync/uiscreen/storescreen.dart';
import 'ui_heartsync/UIColor/screenscaffold.dart';


void main() => runApp(const HeartSyncApp());

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











