class RegisterRequest {
  final String email;
  final String password;
  final String? displayName;

  const RegisterRequest({
    required this.email,
    required this.password,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'password': password,
        if (displayName != null && displayName!.trim().isNotEmpty)
          'displayName': displayName!.trim(),
      };
}
