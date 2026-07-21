class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'code': code,
        'newPassword': newPassword,
      };
}
