import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/account/providers/account_provider.dart';
import '../features/account/services/account_service.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/providers/current_user_provider.dart';
import '../features/auth/services/auth_service.dart';
import '../features/pairing/providers/pairing_provider.dart';
import '../features/pairing/services/pairing_service.dart';
import '../features/store/providers/store_provider.dart';
import '../features/store/services/store_service.dart';
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
          update: (_, storage, previous) => previous ?? ApiClient(tokenStorage: storage),
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
        ProxyProvider<ApiClient, StoreService>(
          update: (_, apiClient, previous) => previous ?? StoreService(apiClient),
        ),
        ChangeNotifierProxyProvider3<AuthService, AccountService, TokenStorage, AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
            accountService: context.read<AccountService>(),
            tokenStorage: context.read<TokenStorage>(),
          ),
          update: (_, authService, accountService, tokenStorage, previous) =>
              previous ??
              AuthProvider(
                authService: authService,
                accountService: accountService,
                tokenStorage: tokenStorage,
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
        ChangeNotifierProxyProvider<StoreService, StoreProvider>(
          create: (context) => StoreProvider(storeService: context.read<StoreService>()),
          update: (_, storeService, previous) =>
              previous ?? StoreProvider(storeService: storeService),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Heart Sync',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            routerConfig: createRouter(authProvider),
          );
        },
      ),
    );
  }
}
