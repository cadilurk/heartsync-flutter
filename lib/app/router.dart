import 'package:go_router/go_router.dart';

import '../features/account/screens/account_screen.dart';
import '../features/account/screens/profile_setup_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/screens/home_shell_screen.dart';
import '../features/pairing/screens/enter_pairing_code_screen.dart';
import '../features/pairing/screens/pairing_code_screen.dart';
import '../features/pairing/screens/pairing_hub_screen.dart';
import '../features/pairing/screens/pairing_success_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' || location == '/register';
      final isSplash = location == '/splash';
      final isProfileSetup = location == '/profile-setup';
      final isPairingRoute = location.startsWith('/pairing');

      if (authProvider.status == AuthStatus.unknown ||
          authProvider.status == AuthStatus.loading) {
        return isSplash ? null : '/splash';
      }

      if (!authProvider.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (!authProvider.isProfileCompleted) {
        return isProfileSetup ? null : '/profile-setup';
      }

      if (!authProvider.isPaired) {
        return isPairingRoute || isProfileSetup ? null : '/pairing';
      }

      if (isAuthRoute || isSplash || location == '/pairing') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/profile-setup', builder: (_, _) => const ProfileSetupScreen()),
      GoRoute(path: '/pairing', builder: (_, _) => const PairingHubScreen()),
      GoRoute(path: '/pairing/code', builder: (_, _) => const PairingCodeScreen()),
      GoRoute(path: '/pairing/enter', builder: (_, _) => const EnterPairingCodeScreen()),
      GoRoute(path: '/pairing/success', builder: (_, _) => const PairingSuccessScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeShellScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
    ],
  );
}
