import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../account/providers/account_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _avatarController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _startDateController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().session.profile;
    _displayNameController = TextEditingController(text: profile?.displayName);
    _avatarController = TextEditingController(text: profile?.avatarUrl);
    _birthdayController = TextEditingController(
      text: profile?.dateOfBirth?.toIso8601String().split('T').first,
    );
    _startDateController = TextEditingController(
      text: profile?.relationshipStartDate?.toIso8601String().split('T').first,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarController.dispose();
    _birthdayController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _error = null);
      await context.read<AccountProvider>().saveProfile(
            displayName: _displayNameController.text,
            avatarUrl: _emptyToNull(_avatarController.text),
            dateOfBirth: _emptyToNull(_birthdayController.text),
            relationshipStartDate: _emptyToNull(_startDateController.text),
          );
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.go(auth.isPaired ? '/home' : '/pairing');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AccountProvider, bool>((value) => value.isLoading);
    // Reached two ways: a forced first-time onboarding step (profile not yet
    // completed — no way back, must finish it) and an explicit "Sửa hồ sơ"
    // edit action from AccountScreen (profile already completed — user should
    // be able to cancel back out). Only show the back button for the latter.
    final isEditing = context.select<AuthProvider, bool>((value) => value.isProfileCompleted);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        leading: isEditing ? BackButton(onPressed: () => context.go('/home')) : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Hoàn thiện hồ sơ để bắt đầu ghép đôi.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Vui lòng nhập tên hiển thị.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _avatarController,
                    decoration: const InputDecoration(labelText: 'Avatar URL (tuỳ chọn)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthdayController,
                    decoration: const InputDecoration(labelText: 'Ngày sinh yyyy-mm-dd (tuỳ chọn)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(labelText: 'Ngày yêu yyyy-mm-dd (tuỳ chọn)'),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _save,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu hồ sơ'),
            ),
          ],
        ),
      ),
    );
  }
}
