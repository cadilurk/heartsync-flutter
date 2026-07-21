enum FirebaseAuthProviderKind {
  google,
  phone;

  String get wireValue => switch (this) {
        FirebaseAuthProviderKind.google => 'google',
        FirebaseAuthProviderKind.phone => 'phone',
      };
}

class FirebaseLoginRequest {
  final String idToken;
  final FirebaseAuthProviderKind provider;

  const FirebaseLoginRequest({
    required this.idToken,
    required this.provider,
  });

  Map<String, dynamic> toJson() => {
        'idToken': idToken,
        'provider': provider.wireValue,
      };
}
