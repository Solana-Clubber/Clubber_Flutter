import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/models/models.dart';
import 'package:lover_cl/services/dj_club_authorization_service.dart';
import 'package:lover_cl/services/solana_mobile_wallet_service.dart';
import 'package:lover_cl/services/wallet_session_store.dart';
import 'package:lover_cl/viewmodels/root_shell_view_model.dart';

void main() {
  group('RootShellViewModel', () {
    late _FakeWalletService walletService;
    late _FakeWalletSessionStore walletSessionStore;
    late _FakeDjClubAuthorizationService djClubAuthorizationService;

    setUp(() {
      walletService = _FakeWalletService();
      walletSessionStore = _FakeWalletSessionStore();
      djClubAuthorizationService = _FakeDjClubAuthorizationService();
    });

    RootShellViewModel buildViewModel() {
      return RootShellViewModel(
        walletService: walletService,
        walletSessionStore: walletSessionStore,
        djClubAuthorizationService: djClubAuthorizationService,
      );
    }

    test('restores a persisted wallet session during initialization', () async {
      final savedSession = _sampleSession(authToken: 'persisted-token');
      walletSessionStore.loadedSession = savedSession;
      walletService.restoredSession = savedSession.copyWith(
        authToken: 'restored-token',
      );

      final viewModel = buildViewModel();
      await _settleAsyncWork();

      expect(viewModel.isInitializing, isFalse);
      expect(viewModel.isWalletConnected, isTrue);
      expect(viewModel.walletSession?.authToken, 'restored-token');
      expect(
        walletSessionStore.savedSessions.single.authToken,
        'restored-token',
      );
    });

    test(
      'selectRole ignores unauthenticated users until wallet connect succeeds',
      () async {
        walletService.connectedSession = _sampleSession();
        final viewModel = buildViewModel();
        await _settleAsyncWork();

        viewModel.selectRole(AppRole.user);
        expect(viewModel.selectedRole, isNull);

        await viewModel.connectWallet();
        viewModel.selectRole(AppRole.user);

        expect(viewModel.isWalletConnected, isTrue);
        expect(viewModel.selectedRole, AppRole.user);
        expect(walletSessionStore.savedSessions, hasLength(1));
      },
    );

    test('connectWallet recovers after a cancelled wallet approval', () async {
      final viewModel = buildViewModel();
      await _settleAsyncWork();

      await viewModel.connectWallet();

      expect(viewModel.isAuthenticatingWallet, isFalse);
      expect(viewModel.isWalletConnected, isFalse);
      expect(viewModel.walletError, '지갑 승인이 취소되었거나 연결이 완료되지 않았습니다.');
      expect(walletSessionStore.savedSessions, isEmpty);

      walletService.connectedSession = _sampleSession();

      await viewModel.connectWallet();

      expect(viewModel.isAuthenticatingWallet, isFalse);
      expect(viewModel.isWalletConnected, isTrue);
      expect(viewModel.walletError, isNull);
      expect(walletSessionStore.savedSessions, hasLength(1));
    });

    test(
      'connectWallet recovers after a timeout-style wallet failure',
      () async {
        final viewModel = buildViewModel();
        await _settleAsyncWork();

        walletService.connectHandler = () async {
          throw const WalletConnectionException(
            'Timed out waiting for wallet approval.',
          );
        };

        await viewModel.connectWallet();

        expect(viewModel.isAuthenticatingWallet, isFalse);
        expect(viewModel.isWalletConnected, isFalse);
        expect(viewModel.walletError, 'Timed out waiting for wallet approval.');

        walletService.connectHandler = () async => _sampleSession();

        await viewModel.connectWallet();

        expect(viewModel.isAuthenticatingWallet, isFalse);
        expect(viewModel.isWalletConnected, isTrue);
        expect(viewModel.walletError, isNull);
        expect(walletSessionStore.savedSessions, hasLength(1));
      },
    );

    test(
      'disconnectWallet clears local session, role state, and persisted storage',
      () async {
        walletService.connectedSession = _sampleSession();
        final viewModel = buildViewModel();
        await _settleAsyncWork();

        await viewModel.connectWallet();
        viewModel.selectRole(AppRole.user);
        viewModel.selectTab(1);

        await viewModel.disconnectWallet();

        expect(viewModel.isWalletConnected, isFalse);
        expect(viewModel.selectedRole, isNull);
        expect(viewModel.selectedIndex, 0);
        expect(walletService.deauthorizedSessions, isEmpty);
        expect(walletSessionStore.clearCallCount, 1);
      },
    );

    test(
      'DJ onboarding requires wallet, DJ name, club selection, and authorization',
      () async {
        walletService.connectedSession = _sampleSession();
        djClubAuthorizationService.result = const DjClubAuthorizationResult(
          isAuthorized: true,
          statusLabel: 'Mock club auth approved',
          detail:
              'Axis Seoul mock roster matched this connected wallet. DJ: Kana',
        );
        final viewModel = buildViewModel();
        await _settleAsyncWork();

        expect(viewModel.canSubmitDjOnboarding, isFalse);

        await viewModel.connectWallet();
        viewModel.selectRole(AppRole.dj);
        viewModel.updateDjName('Kana');
        viewModel.selectDjClub('club-axis-seoul');

        expect(viewModel.canSubmitDjOnboarding, isTrue);

        await viewModel.submitDjOnboarding();

        expect(viewModel.isDjAuthorized, isTrue);
        expect(viewModel.isDjOnboardingComplete, isTrue);
        expect(viewModel.djAuthorizationStatusLabel, 'Mock club auth approved');
        expect(djClubAuthorizationService.calls.single.djName, 'Kana');
        expect(
          djClubAuthorizationService.calls.single.clubId,
          'club-axis-seoul',
        );
      },
    );

    test('DJ onboarding surfaces authorization denial details', () async {
      walletService.connectedSession = _sampleSession();
      djClubAuthorizationService.result = const DjClubAuthorizationResult(
        isAuthorized: false,
        statusLabel: 'Mock auth denied',
        detail: '이 클럽은 현재 mock DJ roster에 등록되어 있지 않습니다.',
      );
      final viewModel = buildViewModel();
      await _settleAsyncWork();

      await viewModel.connectWallet();
      viewModel.selectRole(AppRole.dj);
      viewModel.updateDjName('Kana');
      viewModel.selectDjClub('club-pulse-hapjeong');
      await viewModel.submitDjOnboarding();

      expect(viewModel.isDjAuthorized, isFalse);
      expect(viewModel.isDjOnboardingComplete, isFalse);
      expect(viewModel.djAuthorizationStatusLabel, 'Mock auth denied');
      expect(
        viewModel.djAuthorizationDetail,
        '이 클럽은 현재 mock DJ roster에 등록되어 있지 않습니다.',
      );
    });
  });
}

Future<void> _settleAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

WalletSession _sampleSession({String authToken = 'auth-token'}) {
  return WalletSession(
    authToken: authToken,
    publicKeyBase64: 'AQIDBA==',
    cluster: SolanaMobileWalletService.defaultCluster,
    signedInMessage: 'Clubber sign-in',
    signedMessageBase64: 'AQID',
    signatureBase64: 'BAUG',
    connectedAt: DateTime.utc(2026, 4, 1),
    walletUriBase: 'https://wallet.example',
  );
}

class _FakeWalletService extends SolanaMobileWalletService {
  WalletSession? connectedSession;
  WalletSession? restoredSession;
  Future<WalletSession?> Function()? connectHandler;
  final List<WalletSession> deauthorizedSessions = [];

  @override
  bool get isSupportedPlatform => false;

  @override
  Future<WalletSession?> connectAndSignIn({
    String cluster = SolanaMobileWalletService.defaultCluster,
  }) async {
    final handler = connectHandler;
    if (handler != null) {
      return handler();
    }
    return connectedSession;
  }

  @override
  Future<WalletSession?> restoreSession(WalletSession session) async {
    return restoredSession;
  }

  @override
  Future<void> deauthorize(WalletSession session) async {
    deauthorizedSessions.add(session);
  }
}

class _FakeWalletSessionStore implements WalletSessionStore {
  WalletSession? loadedSession;
  final List<WalletSession> savedSessions = [];
  int clearCallCount = 0;

  @override
  Future<void> clear() async {
    clearCallCount += 1;
    loadedSession = null;
  }

  @override
  Future<WalletSession?> load() async => loadedSession;

  @override
  Future<void> save(WalletSession session) async {
    loadedSession = session;
    savedSessions.add(session);
  }
}

class _FakeDjClubAuthorizationService implements DjClubAuthorizationService {
  DjClubAuthorizationResult result = const DjClubAuthorizationResult(
    isAuthorized: false,
    statusLabel: 'Mock auth denied',
    detail: 'Mock auth failed',
  );
  final List<_DjAuthorizationCall> calls = [];

  @override
  Future<DjClubAuthorizationResult> authorizeDj({
    required WalletSession session,
    required String djName,
    required String clubId,
  }) async {
    calls.add(
      _DjAuthorizationCall(session: session, djName: djName, clubId: clubId),
    );
    return result;
  }
}

class _DjAuthorizationCall {
  const _DjAuthorizationCall({
    required this.session,
    required this.djName,
    required this.clubId,
  });

  final WalletSession session;
  final String djName;
  final String clubId;
}
