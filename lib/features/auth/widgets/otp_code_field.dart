import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Presentation-only 6-digit OTP input, reused across the phone login,
/// email verification and password reset flows.
class OtpCodeField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? labelText;

  const OtpCodeField({
    super.key,
    required this.controller,
    this.validator,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w700),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: labelText ?? 'Mã xác thực',
        counterText: '',
      ),
      validator: validator ??
          (value) => (value == null || value.length != 6) ? 'Vui lòng nhập mã 6 số.' : null,
    );
  }
}
