import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/models/models.dart';
import 'package:lover_cl/services/solana_mobile_wallet_service.dart';

void main() {
  group('SolanaMobileWalletService', () {
    const service = SolanaMobileWalletService();
    final sampleSession = WalletSession(
      authToken: 'test-auth-token',
      publicKeyBase64: 'AQIDBA==',
      cluster: SolanaMobileWalletService.defaultCluster,
      signedInMessage: 'Clubber sign-in',
      signedMessageBase64: 'AQID',
      signatureBase64: 'BAUG',
      connectedAt: DateTime.utc(2026, 4, 1),
      walletUriBase: 'https://wallet.example',
    );

    test('reports unsupported on non-Android test hosts', () {
      expect(service.isSupportedPlatform, isFalse);
    });

    test(
      'connectAndSignIn fails fast behind the unsupported-platform boundary',
      () async {
        await expectLater(
          service.connectAndSignIn(),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );

    test(
      'deauthorize fails fast behind the unsupported-platform boundary',
      () async {
        await expectLater(
          service.deauthorize(sampleSession),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );

    test(
      'restoreSession returns the cached session on non-Android hosts',
      () async {
        final restored = await service.restoreSession(sampleSession);

        expect(restored, isNotNull);
        expect(restored!.authToken, sampleSession.authToken);
        expect(restored.signatureBase64, sampleSession.signatureBase64);
        expect(restored.walletUriBase, sampleSession.walletUriBase);
      },
    );
  });
}
