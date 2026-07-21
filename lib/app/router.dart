import 'package:go_router/go_router.dart';

import '../features/account/screens/account_screen.dart';
import '../features/account/screens/profile_setup_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_verify_screen.dart';
import '../features/auth/screens/phone_login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/home/screens/home_shell_screen.dart';
import '../features/pairing/screens/enter_pairing_code_screen.dart';
import '../features/pairing/screens/pairing_code_screen.dart';
import '../features/pairing/screens/pairing_hub_screen.dart';
import '../features/pairing/screens/pairing_success_screen.dart';
import '../features/store/models/cart_item.dart';
import '../features/store/models/product.dart';
import '../features/store/screens/cart_screen.dart';
import '../features/store/screens/checkout/checkout_screen.dart';

import '../features/store/screens/order_history_screen.dart';
import '../features/store/screens/product_detail_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final location = state.uri.path;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/login-phone' ||
          location == '/otp-verify' ||
          location == '/forgot-password' ||
          location == '/reset-password';
      final isSplash = location == '/splash';
      final isProfileSetup = location == '/profile-setup';
      final isPairingRoute = location.startsWith('/pairing');
      final isVerifyEmail = location == '/verify-email';

      if (authProvider.status == AuthStatus.unknown ||
          authProvider.status == AuthStatus.loading) {
        return isSplash ? null : '/splash';
      }

      // An auth action (phone OTP send, email verify, forgot/reset password...)
      // is in flight on whatever screen is currently showing. These can take
      // many seconds (Play Integrity retries etc.) — don't let a mid-flight
      // notifyListeners() yank the user away from that screen; let it finish
      // and decide its own navigation from the result.
      if (authProvider.isBusy) {
        return null;
      }

      if (!authProvider.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (!authProvider.isEmailVerified) {
        return isVerifyEmail ? null : '/verify-email';
      }

      if (!authProvider.isProfileCompleted) {
        return isProfileSetup ? null : '/profile-setup';
      }

      if (!authProvider.isPaired) {
        return isPairingRoute || isProfileSetup ? null : '/pairing';
      }

      if (isAuthRoute || isSplash || isVerifyEmail || location == '/pairing') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/login-phone', builder: (_, _) => const PhoneLoginScreen()),
      GoRoute(path: '/otp-verify', builder: (_, _) => const OtpVerifyScreen()),
      GoRoute(path: '/verify-email', builder: (_, _) => const VerifyEmailScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (_, _) => const ResetPasswordScreen()),
      GoRoute(path: '/profile-setup', builder: (_, _) => const ProfileSetupScreen()),
      GoRoute(path: '/pairing', builder: (_, _) => const PairingHubScreen()),
      GoRoute(path: '/pairing/code', builder: (_, _) => const PairingCodeScreen()),
      GoRoute(path: '/pairing/enter', builder: (_, _) => const EnterPairingCodeScreen()),
      GoRoute(path: '/pairing/success', builder: (_, _) => const PairingSuccessScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeShellScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      GoRoute(path: '/order-history', builder: (_, _) => const OrderHistoryScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final items = state.extra as List<CartItem>;
          return CheckoutScreen(items: items);
        },
      ),
      GoRoute(
        path: '/product-detail',
        builder: (context, state) {
          final product = state.extra as Product;
          return ProductDetailScreen(product: product);
        },
      ),
    ],
  );
}
