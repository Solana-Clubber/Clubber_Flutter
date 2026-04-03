import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/models/models.dart';
import 'package:lover_cl/services/wallet_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesWalletSessionStore', () {
    late SharedPreferencesWalletSessionStore store;
    late WalletSession session;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = SharedPreferencesWalletSessionStore();
      session = WalletSession(
        authToken: 'auth-token',
        publicKeyBase64: 'AQIDBA==',
        cluster: 'testnet',
        signedInMessage: 'Clubber sign-in',
        signedMessageBase64: 'AQID',
        signatureBase64: 'BAUG',
        connectedAt: DateTime.utc(2026, 4, 1),
        accountLabel: 'Test Wallet',
        walletUriBase: 'https://wallet.example',
        lastVerifiedAt: DateTime.utc(2026, 4, 1, 1),
      );
    });

    test('returns null when no persisted wallet session exists', () async {
      expect(await store.load(), isNull);
    });

    test('persists and reloads a wallet session', () async {
      await store.save(session);

      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.authToken, session.authToken);
      expect(restored.publicKeyBase64, session.publicKeyBase64);
      expect(restored.accountLabel, session.accountLabel);
      expect(restored.walletUriBase, session.walletUriBase);
      expect(restored.lastVerifiedAt, session.lastVerifiedAt);
    });

    test('clears the persisted wallet session', () async {
      await store.save(session);
      await store.clear();

      expect(await store.load(), isNull);
    });
  });
}
