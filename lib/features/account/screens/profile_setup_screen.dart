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
  late final TextEditingController _birthdayController;
  late final TextEditingController _startDateController;
  String? _avatarUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().session.profile;
    _displayNameController = TextEditingController(text: profile?.displayName);
    _avatarUrl = profile?.avatarUrl;
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
    _birthdayController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final url = await context.read<AccountProvider>().pickAndUploadAvatar();
      if (url == null || !mounted) return;
      setState(() => _avatarUrl = url);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải ảnh lên: ${error.message}')),
      );
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initial = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initial = DateTime.parse(controller.text);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF4B72),
              onPrimary: Colors.white,
              onSurface: Color(0xFF231B1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        controller.text = formatted;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _error = null);
      await context.read<AccountProvider>().saveProfile(
            displayName: _displayNameController.text,
            avatarUrl: _avatarUrl,
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
    final isEditing = context.select<AuthProvider, bool>((value) => value.isProfileCompleted);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            color: Color(0xFF231B1E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF231B1E), size: 20),
                onPressed: () => context.go('/home'),
              )
            : null,
      ),
      body: Stack(
        children: [
          // Background ambient circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE3EC).withValues(alpha: 0.7),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE3EC).withValues(alpha: 0.5),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Avatar picker — tap to choose a photo, uploads to Cloudinary
                  Consumer<AccountProvider>(
                    builder: (context, accountProvider, _) {
                      final uploading = accountProvider.isUploadingAvatar;
                      return GestureDetector(
                        onTap: uploading ? null : _pickAvatar,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFF537B), Color(0xFFFF8DA1)],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: const Color(0xFFE4E6EB),
                                backgroundImage: _avatarUrl != null
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                // Default placeholder (à la Facebook) when no
                                // photo has been chosen yet.
                                child: _avatarUrl == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 52,
                                        color: Color(0xFFBEC3C9),
                                      )
                                    : null,
                              ),
                            ),
                            if (uploading)
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0x66000000),
                                  ),
                                  child: const Center(
                                    child: SizedBox.square(
                                      dimension: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4B72),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Hoàn thiện thông tin cá nhân',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF231B1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Giúp hai bạn kết nối và theo dõi kỷ niệm chính xác hơn 💕',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF706066),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Container Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFDE8EE), width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Display Name
                          _buildTextField(
                            controller: _displayNameController,
                            hintText: 'Tên hiển thị',
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Vui lòng nhập tên hiển thị.' : null,
                          ),
                          const SizedBox(height: 14),

                          // Birthday
                          _buildTextField(
                            controller: _birthdayController,
                            hintText: 'Ngày sinh (YYYY-MM-DD)',
                            icon: Icons.cake_outlined,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF4B72), size: 20),
                              onPressed: () => _selectDate(_birthdayController),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Relationship Start Date
                          _buildTextField(
                            controller: _startDateController,
                            hintText: 'Ngày chính thức yêu (YYYY-MM-DD)',
                            icon: Icons.favorite_outline_rounded,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF4B72), size: 20),
                              onPressed: () => _selectDate(_startDateController),
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: Colors.red, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF537B), Color(0xFFFF3B65)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x55FF4B72),
                                    blurRadius: 12,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: isLoading ? null : _save,
                                child: isLoading
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Lưu hồ sơ 💕',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 15, color: Color(0xFF231B1E)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFA59B9E), fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFF4B72), size: 20),
          ),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF0E2E7), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF4B72), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

