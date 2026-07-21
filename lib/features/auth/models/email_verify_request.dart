class EmailVerifyRequest {
  final String email;
  final String code;

  const EmailVerifyRequest({
    required this.email,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'code': code,
      };
}
