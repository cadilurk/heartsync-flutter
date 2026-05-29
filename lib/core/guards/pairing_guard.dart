import '../../features/auth/providers/auth_provider.dart';

bool canAccessCoupleFeatures(AuthProvider authProvider) {
  return authProvider.isAuthenticated &&
      authProvider.isProfileCompleted &&
      authProvider.isPaired;
}
