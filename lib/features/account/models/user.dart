class User {
  final String id;
  final String email;
  final String? phone;
  final String authProvider;
  final String status;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    this.phone,
    this.authProvider = 'email',
    this.status = 'active',
    this.emailVerified = true,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      authProvider: json['authProvider']?.toString() ?? 'email',
      status: json['status']?.toString() ?? 'active',
      // Fail-open: any payload lacking this field (e.g. a partner object
      // elsewhere) should never wrongly gate someone behind email verification.
      emailVerified: json['emailVerified'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'authProvider': authProvider,
        'status': status,
        'emailVerified': emailVerified,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
