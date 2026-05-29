import '../../features/auth/providers/auth_provider.dart';

bool requiresAuth(String location) {
  return !location.startsWith('/login') && !location.startsWith('/register');
}

bool canAccessAuthenticatedRoute(AuthProvider authProvider) {
  return authProvider.status == AuthStatus.authenticated;
}
