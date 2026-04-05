import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lover_cl/models/models.dart';
import 'package:lover_cl/providers/app_providers.dart';
import 'package:lover_cl/screens/root_shell.dart';
import 'package:lover_cl/services/dj_club_authorization_service.dart';
import 'package:lover_cl/services/solana_mobile_wallet_service.dart';
import 'package:lover_cl/services/wallet_session_store.dart';
import 'package:lover_cl/theme/app_theme.dart';

Widget buildRootShellHarness({
  HarnessWalletService? walletService,
  InMemoryWalletSessionStore? walletSessionStore,
  DjClubAuthorizationService? djClubAuthorizationService,
  List<Override> overrides = const [],
}) {
  final resolvedWalletService = walletService ?? HarnessWalletService();
  final resolvedWalletSessionStore =
      walletSessionStore ?? InMemoryWalletSessionStore();

  return ProviderScope(
    overrides: [
      solanaMobileWalletServiceProvider.overrideWithValue(
        resolvedWalletService,
      ),
      walletSessionStoreProvider.overrideWithValue(resolvedWalletSessionStore),
      if (djClubAuthorizationService != null)
        djClubAuthorizationServiceProvider.overrideWithValue(
          djClubAuthorizationService,
        ),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: const RootShell(),
    ),
  );
}

class HarnessWalletService extends SolanaMobileWalletService {
  HarnessWalletService({WalletSession? session})
    : session = session ?? sampleWalletSession();

  final WalletSession session;
  Future<WalletSession?> Function(String cluster)? onConnect;
  int connectCount = 0;
  int disconnectCount = 0;

  @override
  bool get isSupportedPlatform => true;

  @override
  Future<WalletSession?> connectAndSignIn({
    String cluster = SolanaMobileWalletService.defaultCluster,
  }) async {
    connectCount += 1;
    final connectOverride = onConnect;
    if (connectOverride != null) {
      return connectOverride(cluster);
    }
    return session.copyWith(cluster: cluster);
  }

  @override
  Future<WalletSession?> restoreSession(WalletSession session) async {
    return session;
  }

  @override
  Future<void> deauthorize(WalletSession session) async {
    disconnectCount += 1;
  }
}

class InMemoryWalletSessionStore implements WalletSessionStore {
  InMemoryWalletSessionStore({this.initialSession}) : _session = initialSession;

  final WalletSession? initialSession;
  WalletSession? _session;

  @override
  Future<void> clear() async {
    _session = null;
  }

  @override
  Future<WalletSession?> load() async => _session;

  @override
  Future<void> save(WalletSession session) async {
    _session = session;
  }
}

WalletSession sampleWalletSession() {
  return WalletSession(
    authToken: 'mock-auth-token',
    publicKeyBase64: 'AQIDBA==',
    cluster: SolanaMobileWalletService.defaultCluster,
    signedInMessage: 'Clubber sign-in',
    signedMessageBase64: 'AQID',
    signatureBase64: 'BAUG',
    connectedAt: DateTime.utc(2026, 4, 1),
    accountLabel: 'Mock MWA Wallet',
    walletUriBase: 'https://wallet.example',
    lastVerifiedAt: DateTime.utc(2026, 4, 1, 0, 5),
  );
}
