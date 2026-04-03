import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/dj_club_authorization_service.dart';
import '../services/solana_mobile_wallet_service.dart';
import '../services/wallet_session_store.dart';

enum AppRole { user, dj }

class RootShellViewModel extends ChangeNotifier {
  RootShellViewModel({
    required SolanaMobileWalletService walletService,
    required WalletSessionStore walletSessionStore,
    required DjClubAuthorizationService djClubAuthorizationService,
    Duration walletConnectionTimeout = _defaultWalletConnectionTimeout,
    void Function(String message)? walletLogSink,
  }) : _walletService = walletService,
       _walletSessionStore = walletSessionStore,
       _djClubAuthorizationService = djClubAuthorizationService,
       _walletConnectionTimeout = walletConnectionTimeout,
       _walletLogSink = walletLogSink {
    unawaited(_restoreWalletSession());
  }

  static const Duration _defaultWalletConnectionTimeout = Duration(
    milliseconds: int.fromEnvironment(
      'SOLANA_WALLET_TOTAL_TIMEOUT_MS',
      defaultValue: 90000,
    ),
  );

  final SolanaMobileWalletService _walletService;
  final WalletSessionStore _walletSessionStore;
  final DjClubAuthorizationService _djClubAuthorizationService;
  final Duration _walletConnectionTimeout;
  final void Function(String message)? _walletLogSink;

  AppRole? _selectedRole;
  int _userSelectedIndex = 0;
  bool _isInitializing = true;
  bool _isAuthenticatingWallet = false;
  bool _isCheckingDjAccess = false;
  WalletSession? _walletSession;
  String? _walletError;
  String _djName = '';
  String? _djClubId;
  bool _isDjAuthorized = false;
  String? _djAuthorizationStatusLabel;
  String? _djAuthorizationDetail;

  AppRole? get selectedRole => _selectedRole;
  bool get hasSelectedRole => _selectedRole != null;
  int get selectedIndex =>
      _selectedRole == AppRole.user ? _userSelectedIndex : 0;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticatingWallet => _isAuthenticatingWallet;
  bool get isCheckingDjAccess => _isCheckingDjAccess;
  bool get isWalletConnected => _walletSession != null;
  WalletSession? get walletSession => _walletSession;
  String? get walletError => _walletError;
  bool get isWalletSupported => _walletService.isSupportedPlatform;
  String get djName => _djName;
  String? get djClubId => _djClubId;
  bool get isDjAuthorized => _isDjAuthorized;
  String? get djAuthorizationStatusLabel => _djAuthorizationStatusLabel;
  String? get djAuthorizationDetail => _djAuthorizationDetail;
  bool get isDjOnboardingComplete => _isDjAuthorized;
  bool get canSubmitDjOnboarding =>
      !_isCheckingDjAccess &&
      _djName.trim().isNotEmpty &&
      _djClubId != null &&
      _walletSession != null;

  String get walletDisplayLabel {
    final session = _walletSession;
    if (session == null) {
      return 'Wallet disconnected';
    }
    return session.accountLabel ?? session.walletAddressPreview;
  }

  Future<void> _restoreWalletSession() async {
    try {
      final savedSession = await _walletSessionStore.load();
      if (savedSession == null) {
        _logWalletEvent('restore:skipped', 'no persisted session');
        return;
      }

      final restoredSession = await _walletService.restoreSession(savedSession);
      if (restoredSession == null) {
        await _walletSessionStore.clear();
        _walletError = '저장된 지갑 세션을 다시 확인하지 못해 연결을 초기화했어요.';
        _logWalletEvent(
          'restore:cleared',
          'wallet did not confirm persisted session',
        );
        return;
      }

      _walletSession = restoredSession;
      await _walletSessionStore.save(restoredSession);
      _logWalletEvent('restore:success', 'persisted session revalidated');
    } catch (_) {
      _walletSession = null;
      _walletError = '저장된 지갑 세션을 복원하지 못했습니다.';
      await _walletSessionStore.clear();
      _logWalletEvent('restore:error', 'failed to recover persisted session');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> connectWallet() async {
    if (_isAuthenticatingWallet) {
      return;
    }

    _isAuthenticatingWallet = true;
    _walletError = null;
    _logWalletEvent('connect:start', 'requesting wallet authorization');
    notifyListeners();

    try {
      final session = await _walletService.connectAndSignIn().timeout(
        _walletConnectionTimeout,
        onTimeout: () {
          _logWalletEvent(
            'connect:timeout',
            'no wallet response within ${_formatDuration(_walletConnectionTimeout)}',
          );
          throw const WalletConnectionException(
            '지갑 앱 응답이 지연되어 연결을 종료했습니다. 다시 시도해 주세요.',
          );
        },
      );
      if (session == null) {
        _walletSession = null;
        _walletError = '지갑 승인이 취소되었거나 연결이 완료되지 않았습니다.';
        _logWalletEvent(
          'connect:cancelled',
          'wallet authorization returned no session',
        );
        return;
      }

      _walletSession = session;
      await _walletSessionStore.save(session);
      _logWalletEvent('connect:success', 'wallet session saved locally');
    } on UnsupportedError catch (error) {
      _walletSession = null;
      _walletError = error.message?.toString() ?? error.toString();
      _logWalletEvent(
        'connect:unsupported',
        'platform boundary prevented wallet launch',
      );
    } on WalletConnectionException catch (error) {
      _walletSession = null;
      _walletError = error.message;
      _logWalletEvent('connect:error', error.message);
    } catch (_) {
      _walletSession = null;
      _walletError = '지갑 연결 중 알 수 없는 오류가 발생했습니다.';
      _logWalletEvent(
        'connect:error',
        'unexpected exception during wallet auth',
      );
    } finally {
      _isAuthenticatingWallet = false;
      _logWalletEvent('connect:finish', 'wallet loading state cleared');
      notifyListeners();
    }
  }

  Future<void> disconnectWallet() async {
    final session = _walletSession;
    if (session == null) {
      return;
    }

    _logWalletEvent('disconnect:start', 'clearing connected wallet session');
    try {
      if (_walletService.isSupportedPlatform) {
        await _walletService.deauthorize(session);
      }
    } catch (_) {
      // Keep local cleanup even if remote deauthorization fails.
      _logWalletEvent(
        'disconnect:error',
        'wallet deauthorization failed; local cleanup continues',
      );
    }

    _walletSession = null;
    _walletError = null;
    _selectedRole = null;
    _userSelectedIndex = 0;
    _resetDjOnboarding();
    await _walletSessionStore.clear();
    _logWalletEvent('disconnect:success', 'local wallet session cleared');
    notifyListeners();
  }

  void selectRole(AppRole role) {
    if (!isWalletConnected) {
      return;
    }

    final roleChanged = _selectedRole != role;
    _selectedRole = role;

    if (role == AppRole.user) {
      _userSelectedIndex = 0;
    }

    if (roleChanged) {
      notifyListeners();
    }
  }

  void clearRoleSelection() {
    if (_selectedRole == null) {
      return;
    }

    _selectedRole = null;
    notifyListeners();
  }

  void selectIndex(int index) {
    if (_selectedRole != AppRole.user ||
        index == _userSelectedIndex ||
        index < 0 ||
        index > 1) {
      return;
    }

    _userSelectedIndex = index;
    notifyListeners();
  }

  void selectTab(int index) => selectIndex(index);

  void updateDjName(String value) {
    if (_djName == value) {
      return;
    }

    _djName = value;
    _clearDjAuthorizationResult();
    notifyListeners();
  }

  void selectDjClub(String? clubId) {
    if (_djClubId == clubId) {
      return;
    }

    _djClubId = clubId;
    _clearDjAuthorizationResult();
    notifyListeners();
  }

  Future<void> submitDjOnboarding() async {
    final session = _walletSession;
    final clubId = _djClubId;
    if (session == null || clubId == null || _djName.trim().isEmpty) {
      return;
    }

    _isCheckingDjAccess = true;
    _clearDjAuthorizationResult();
    notifyListeners();

    try {
      final result = await _djClubAuthorizationService.authorizeDj(
        session: session,
        djName: _djName,
        clubId: clubId,
      );
      _isDjAuthorized = result.isAuthorized;
      _djAuthorizationStatusLabel = result.statusLabel;
      _djAuthorizationDetail = result.detail;
    } catch (_) {
      _isDjAuthorized = false;
      _djAuthorizationStatusLabel = 'Mock auth error';
      _djAuthorizationDetail = 'DJ 권한 확인 중 오류가 발생했습니다.';
    } finally {
      _isCheckingDjAccess = false;
      notifyListeners();
    }
  }

  void _resetDjOnboarding() {
    _djName = '';
    _djClubId = null;
    _clearDjAuthorizationResult();
  }

  void _clearDjAuthorizationResult() {
    _isDjAuthorized = false;
    _djAuthorizationStatusLabel = null;
    _djAuthorizationDetail = null;
  }

  void _logWalletEvent(String event, String detail) {
    final message = '[RootShellViewModel][wallet] $event | $detail';
    final sink = _walletLogSink;
    if (sink != null) {
      sink(message);
      return;
    }
    debugPrint(message);
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    }
    if (duration.inMilliseconds % 1000 == 0) {
      return '${duration.inSeconds}s';
    }
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
  }
}
