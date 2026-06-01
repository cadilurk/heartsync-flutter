import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/socket_service.dart';
import '../core/storage/token_storage.dart';
import '../features/account/providers/account_provider.dart';
import '../features/account/services/account_service.dart';
import '../features/alarm/providers/alarm_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/providers/current_user_provider.dart';
import '../features/auth/services/auth_service.dart';
import '../features/pairing/providers/pairing_provider.dart';
import '../features/pairing/services/pairing_service.dart';
import '../features/alarm/services/signal_service.dart';
import 'router.dart';
import 'theme.dart';

class HeartSyncApp extends StatelessWidget {
  const HeartSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => TokenStorage()),
        ProxyProvider<TokenStorage, ApiClient>(
          update: (_, storage, previous) => previous ?? ApiClient(
            tokenStorage: storage,
            baseUrl: ApiConstants.resolveBaseUrl(),
          ),
        ),
        ProxyProvider<ApiClient, AuthService>(
          update: (_, apiClient, previous) => previous ?? AuthService(apiClient),
        ),
        ProxyProvider<ApiClient, AccountService>(
          update: (_, apiClient, previous) => previous ?? AccountService(apiClient),
        ),
        ProxyProvider<ApiClient, PairingService>(
          update: (_, apiClient, previous) => previous ?? PairingService(apiClient),
        ),
        ProxyProvider<ApiClient, SignalService>(
          update: (_, apiClient, previous) => previous ?? SignalService(apiClient),
        ),
        ChangeNotifierProxyProvider3<AuthService, AccountService, TokenStorage, AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
            accountService: context.read<AccountService>(),
            tokenStorage: context.read<TokenStorage>(),
            apiClient: context.read<ApiClient>(),
          ),
          update: (context, authService, accountService, tokenStorage, previous) =>
              previous ??
              AuthProvider(
                authService: authService,
                accountService: accountService,
                tokenStorage: tokenStorage,
                apiClient: context.read<ApiClient>(),
              ),
        ),
        ChangeNotifierProvider(create: (_) => CurrentUserProvider()),
        ChangeNotifierProxyProvider2<AccountService, AuthProvider, AccountProvider>(
          create: (context) => AccountProvider(
            accountService: context.read<AccountService>(),
            authProvider: context.read<AuthProvider>(),
          ),
          update: (_, accountService, authProvider, previous) =>
              previous ??
              AccountProvider(accountService: accountService, authProvider: authProvider),
        ),
        ChangeNotifierProxyProvider2<PairingService, AuthProvider, PairingProvider>(
          create: (context) => PairingProvider(
            pairingService: context.read<PairingService>(),
            authProvider: context.read<AuthProvider>(),
          ),
          update: (_, pairingService, authProvider, previous) =>
              previous ??
              PairingProvider(pairingService: pairingService, authProvider: authProvider),
        ),
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProxyProvider3<SocketService, AuthProvider, SignalService, AlarmProvider>(
          create: (context) => AlarmProvider(
            socketService: context.read<SocketService>(),
            authProvider: context.read<AuthProvider>(),
            signalService: context.read<SignalService>(),
          ),
          update: (_, socketService, authProvider, signalService, previous) =>
              previous ??
              AlarmProvider(
                socketService: socketService,
                authProvider: authProvider,
                signalService: signalService,
              ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return _SocketConnector(
            child: MaterialApp.router(
              title: 'Heart Sync',
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              routerConfig: createRouter(authProvider),
            ),
          );
        },
      ),
    );
  }
}

// Lắng nghe AuthProvider và kết nối / ngắt socket tương ứng
class _SocketConnector extends StatefulWidget {
  final Widget child;
  const _SocketConnector({required this.child});

  @override
  State<_SocketConnector> createState() => _SocketConnectorState();
}

class _SocketConnectorState extends State<_SocketConnector> {
  AuthProvider? _authProvider;
  AuthStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newAuth = context.read<AuthProvider>();
    if (_authProvider != newAuth) {
      _authProvider?.removeListener(_onAuthChanged);
      _authProvider = newAuth;
      _authProvider!.addListener(_onAuthChanged);
      _onAuthChanged();
    }
  }

  void _onAuthChanged() async {
    final status = _authProvider!.status;
    if (status == _lastStatus) return;
    _lastStatus = status;

    if (status == AuthStatus.authenticated) {
      final token = await context.read<TokenStorage>().readAccessToken();
      if (token != null && mounted) {
        context.read<SocketService>().connect(token);
      }
    } else if (status == AuthStatus.unauthenticated) {
      if (mounted) context.read<SocketService>().disconnect();
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
