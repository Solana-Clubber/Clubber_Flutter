import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';

import '../models/models.dart';

class SolanaMobileWalletService {
  const SolanaMobileWalletService();

  static final Uri _identityUri = Uri.parse('https://solana.com');
  static final Uri _iconUri = Uri.parse('favicon.ico');
  static const String _identityName = 'Solana';
  static const String defaultCluster = 'devnet';
  static const bool _useIdentityUri = bool.fromEnvironment(
    'SOLANA_WALLET_USE_IDENTITY_URI',
    defaultValue: true,
  );
  static const bool _useIconUri = bool.fromEnvironment(
    'SOLANA_WALLET_USE_ICON_URI',
    defaultValue: true,
  );
  static const bool _useIdentityName = bool.fromEnvironment(
    'SOLANA_WALLET_USE_IDENTITY_NAME',
    defaultValue: true,
  );
  static const String configuredCluster = String.fromEnvironment(
    'SOLANA_CLUSTER',
    defaultValue: defaultCluster,
  );
  static const Duration _connectStepTimeout = Duration(
    milliseconds: int.fromEnvironment(
      'SOLANA_WALLET_STEP_TIMEOUT_MS',
      defaultValue: 45000,
    ),
  );
  static const Duration _sessionStepTimeout = Duration(
    milliseconds: int.fromEnvironment(
      'SOLANA_WALLET_SESSION_TIMEOUT_MS',
      defaultValue: 25000,
    ),
  );

  bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;
  String get activeCluster => configuredCluster;

  Future<WalletSession?> connectAndSignIn({
    String cluster = configuredCluster,
  }) async {
    _ensureSupportedPlatform();
    _logStage(
      'connect:config',
      'cluster=$cluster stepTimeout=${_describeDuration(_connectStepTimeout)} identityUri=${_resolvedIdentityUri?.toString() ?? 'null'} iconUri=${_resolvedIconUri?.toString() ?? 'null'} identityName=${_resolvedIdentityName ?? 'null'}',
    );
    if (!await LocalAssociationScenario.isAvailable()) {
      throw const WalletConnectionException(
        'No Solana Mobile Wallet Adapter wallet is available on this Android device.',
      );
    }

    final scenario = await LocalAssociationScenario.create();
    try {
      _logStage('connect:startActivityForResult', 'launch');
      unawaited(scenario.startActivityForResult(null));
      final client = await _runStep(
        'connect:start',
        () => scenario.start(),
        timeout: _connectStepTimeout,
      );
      final authorization = await _runStep(
        'connect:authorize',
        () => client.authorize(
          identityUri: _resolvedIdentityUri,
          iconUri: _resolvedIconUri,
          identityName: _resolvedIdentityName,
          cluster: cluster,
        ),
        timeout: _connectStepTimeout,
      );
      if (authorization == null) {
        _logStage(
          'connect:authorize:empty',
          'wallet returned no authorization result',
        );
        return null;
      }

      final now = DateTime.now().toUtc();
      return WalletSession(
        authToken: authorization.authToken,
        publicKeyBase64: base64Encode(authorization.publicKey),
        cluster: cluster,
        signedInMessage: _buildSignInMessage(cluster),
        signedMessageBase64: '',
        signatureBase64: '',
        connectedAt: now,
        accountLabel: authorization.accountLabel,
        walletUriBase: _normalizeWalletUriBase(authorization.walletUriBase),
        lastVerifiedAt: now,
      );
    } on WalletConnectionException {
      rethrow;
    } catch (error, stackTrace) {
      if (_isCancellationError(error)) {
        _logStage('connect:cancelled', '$error');
        debugPrint(stackTrace.toString());
        return null;
      }
      _logStage('connect:error', '$error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _logStage('connect:close', 'closing local association scenario');
      await scenario.close();
    }
  }

  Future<WalletSession?> restoreSession(WalletSession session) async {
    if (!isSupportedPlatform) {
      return session;
    }
    _logStage(
      'restore:local',
      'restoring cached session without reopening wallet app',
    );
    return session.copyWith(lastVerifiedAt: DateTime.now().toUtc());
  }

  Future<void> deauthorize(WalletSession session) async {
    _ensureSupportedPlatform();
    if (!await LocalAssociationScenario.isAvailable()) {
      return;
    }

    final scenario = await LocalAssociationScenario.create();
    try {
      _logStage(
        'disconnect:config',
        'cluster=${session.cluster} stepTimeout=${_describeDuration(_sessionStepTimeout)} uriBase=${session.walletUriBase}',
      );
      _logStage('disconnect:startActivityForResult', 'launch');
      unawaited(scenario.startActivityForResult(null));
      final client = await _runStep(
        'disconnect:start',
        () => scenario.start(),
        timeout: _sessionStepTimeout,
      );
      await _runStep(
        'disconnect:deauthorize',
        () => client.deauthorize(authToken: session.authToken),
        timeout: _sessionStepTimeout,
      );
    } finally {
      await scenario.close();
    }
  }

  Future<List<int>?> signAndSendTransaction(
    WalletSession session,
    Uint8List transactionBytes,
  ) async {
    _ensureSupportedPlatform();
    if (!await LocalAssociationScenario.isAvailable()) {
      throw const WalletConnectionException('No MWA wallet available.');
    }

    final scenario = await LocalAssociationScenario.create();
    try {
      _logStage('signAndSend:startActivityForResult', 'launch');
      unawaited(scenario.startActivityForResult(null));

      final client = await _runStep(
        'signAndSend:start',
        () => scenario.start(),
        timeout: _connectStepTimeout,
      );

      // CRITICAL: Reauthorize with stored auth token
      _logStage('signAndSend:reauthorize', 'begin');
      final reauth = await _runStep(
        'signAndSend:reauthorize',
        () => client.reauthorize(
          identityUri: _resolvedIdentityUri,
          iconUri: _resolvedIconUri,
          identityName: _resolvedIdentityName,
          authToken: session.authToken,
        ),
        timeout: _connectStepTimeout,
      );
      if (reauth == null) {
        _logStage('signAndSend:reauthorize', 'failed - null result');
        return null;
      }

      // Sign the transaction (wallet returns signed TX bytes)
      final signResult = await _runStep(
        'signAndSend:signTransactions',
        () => client.signTransactions(
          transactions: [transactionBytes],
        ),
        timeout: _connectStepTimeout,
      );

      if (signResult.signedPayloads.isEmpty) {
        _logStage('signAndSend:result', 'no signed payloads returned');
        return null;
      }

      final signedTx = signResult.signedPayloads.first;
      _logStage('signAndSend:result', 'signed TX=${signedTx.length} bytes');
      return signedTx;
    } catch (error, stackTrace) {
      if (_isCancellationError(error)) {
        _logStage('signAndSend:cancelled', '$error');
        debugPrint(stackTrace.toString());
        return null;
      }
      _logStage('signAndSend:error', '$error');
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      await scenario.close();
    }
  }

  Future<T> _runStep<T>(
    String stage,
    Future<T> Function() action, {
    required Duration timeout,
  }) async {
    _logStage(stage, 'begin');
    try {
      final result = await action().timeout(timeout);
      _logStage(stage, 'done');
      return result;
    } on TimeoutException {
      _logStage(stage, 'timeout after ${timeout.inSeconds}s');
      throw WalletConnectionException(
        'Wallet connection timed out during $stage after ${_describeDuration(timeout)}. Return to Clubber and try again.',
      );
    } catch (error) {
      _logStage(stage, 'error=$error');
      rethrow;
    }
  }

  bool _isCancellationError(Object error) {
    final normalized = error.toString().toLowerCase();
    const hints = <String>[
      'cancel',
      'cancelled',
      'canceled',
      'closed',
      'dismissed',
      'aborted',
      'back pressed',
      'user rejected',
      'declined',
    ];
    return hints.any(normalized.contains);
  }

  String _buildSignInMessage(String cluster) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    return 'Clubber sign-in\n'
        'cluster=$cluster\n'
        'ts=$timestamp\n'
        'purpose=wallet-gated-role-entry';
  }

  void _ensureSupportedPlatform() {
    if (!isSupportedPlatform) {
      throw UnsupportedError(
        'solana_mobile_client is currently intended for Android. '
        'iOS support has known MWA standard issues.',
      );
    }
  }

  String? _normalizeWalletUriBase(Uri? walletUriBase) {
    final serialized = walletUriBase?.toString();
    if (serialized == null || serialized.isEmpty) {
      return null;
    }
    return serialized;
  }

  String _describeDuration(Duration duration) {
    final milliseconds = duration.inMilliseconds;
    if (milliseconds % 1000 == 0) {
      return '${duration.inSeconds}s';
    }
    return '${(milliseconds / 1000).toStringAsFixed(1)}s';
  }

  Uri? get _resolvedIdentityUri => _useIdentityUri ? _identityUri : null;

  Uri? get _resolvedIconUri => _useIconUri ? _iconUri : null;

  String? get _resolvedIdentityName => _useIdentityName ? _identityName : null;

  void _logStage(String stage, String detail) {
    debugPrint('[SolanaMobileWalletService] $stage | $detail');
  }
}

class WalletConnectionException implements Exception {
  const WalletConnectionException(this.message);

  final String message;

  @override
  String toString() => 'WalletConnectionException($message)';
}
