import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = context.select<AuthProvider, String?>((value) => value.errorMessage);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 72, color: Color(0xFFF43F7B)),
              const SizedBox(height: 16),
              const Text('Heart Sync', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
