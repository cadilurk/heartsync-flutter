import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _error = null);
      await context.read<AuthProvider>().login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    await auth.loginWithGoogle();
    if (!mounted) return;
    if (auth.errorMessage != null) {
      setState(() => _error = auth.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>(
      (value) => value.isBusy,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F5),
      body: Stack(
        children: [
          // Background soft circular decorations
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE3EC).withValues(alpha: 0.8),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE3EC).withValues(alpha: 0.6),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),

                    // Header Heart Icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFD6E3),
                      ),
                      child: Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF4B72),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x40FF4B72),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Title
                    const Text(
                      'Heart Sync',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF231B1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD4E0), width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFFF4B72),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Lưu giữ từng nhịp đập yêu thương',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF70525A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Main Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFDE8EE), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF231B1E)),
                              decoration: InputDecoration(
                                hintText: 'Email',
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
                                    child: const Icon(
                                      Icons.mail_outline_rounded,
                                      color: Color(0xFFFF4B72),
                                      size: 20,
                                    ),
                                  ),
                                ),
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
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Vui lòng nhập email.' : null,
                            ),
                            const SizedBox(height: 14),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF231B1E)),
                              decoration: InputDecoration(
                                hintText: 'Mật khẩu',
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
                                    child: const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Color(0xFFFF4B72),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF706568),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
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
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu.' : null,
                            ),
                            const SizedBox(height: 10),

                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: isLoading ? null : () => context.go('/forgot-password'),
                                child: const Text(
                                  'Quên mật khẩu?',
                                  style: TextStyle(
                                    color: Color(0xFFFF4B72),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8),
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

                            const SizedBox(height: 20),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
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
                                  onPressed: isLoading ? null : _submit,
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
                                              'Đăng nhập',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
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

                    // Divider with Hearts
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFFE8D5DD), thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded, color: Color(0xFFFF4B72), size: 10),
                              SizedBox(width: 6),
                              Text(
                                'hoặc',
                                style: TextStyle(
                                  color: Color(0xFF7A6B70),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.favorite_rounded, color: Color(0xFFFF4B72), size: 10),
                            ],
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE8D5DD), thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Google Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE8DFE3), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                          shadowColor: const Color(0x10000000),
                        ),
                        onPressed: isLoading ? null : _submitGoogle,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GoogleLogoIcon(size: 22),
                            SizedBox(width: 12),
                            Text(
                              'Tiếp tục với Google',
                              style: TextStyle(
                                color: Color(0xFF231B1E),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Phone Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE8DFE3), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                          shadowColor: const Color(0x10000000),
                        ),
                        onPressed: isLoading ? null : () => context.go('/login-phone'),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              color: Color(0xFFFF4B72),
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Tiếp tục bằng số điện thoại',
                              style: TextStyle(
                                color: Color(0xFF231B1E),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bottom Register Button
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF0E0E6), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Chưa có tài khoản? ',
                                  style: TextStyle(color: Color(0xFF6B6065), fontWeight: FontWeight.w400),
                                ),
                                TextSpan(
                                  text: 'Đăng ký ngay 💕',
                                  style: TextStyle(color: Color(0xFFFF4B72), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double cx = s / 2;
    final double cy = s / 2;
    final double strokeWidth = s * 0.20;
    final double radius = (s - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final Paint pRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint pYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint pGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint pBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double degToRad(double deg) => deg * 3.141592653589793 / 180.0;

    canvas.drawArc(rect, degToRad(205), degToRad(125), false, pRed);
    canvas.drawArc(rect, degToRad(125), degToRad(80), false, pYellow);
    canvas.drawArc(rect, degToRad(45), degToRad(80), false, pGreen);
    canvas.drawArc(rect, degToRad(-30), degToRad(75), false, pBlue);

    final Paint pBlueFill = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(cx, cy - strokeWidth / 2, cx + radius + strokeWidth / 2, cy + strokeWidth / 2),
      pBlueFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

