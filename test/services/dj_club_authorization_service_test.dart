import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/models/models.dart';
import 'package:lover_cl/services/dj_club_authorization_service.dart';

void main() {
  group('MockDjClubAuthorizationService', () {
    const service = MockDjClubAuthorizationService();

    final session = WalletSession(
      authToken: 'auth-token',
      publicKeyBase64: 'AQIDBA==',
      cluster: 'testnet',
      signedInMessage: 'Clubber sign-in',
      signedMessageBase64: 'AQID',
      signatureBase64: 'BAUG',
      connectedAt: DateTime.utc(2026, 4, 1),
    );

    test('approves a rostered club when wallet sign-in and DJ name are present', () async {
      final result = await service.authorizeDj(
        session: session,
        djName: 'Kana',
        clubId: 'club-axis-seoul',
      );

      expect(result.isAuthorized, isTrue);
      expect(result.statusLabel, 'Mock club auth approved');
      expect(result.detail, contains('Axis Seoul mock roster matched'));
      expect(result.detail, contains('DJ: Kana'));
    });

    test('rejects short DJ names before club lookup', () async {
      final result = await service.authorizeDj(
        session: session,
        djName: 'A',
        clubId: 'club-axis-seoul',
      );

      expect(result.isAuthorized, isFalse);
      expect(result.statusLabel, 'Name required');
      expect(result.detail, 'DJ 이름은 최소 두 글자 이상이어야 합니다.');
    });

    test('rejects clubs outside the mock roster', () async {
      final result = await service.authorizeDj(
        session: session,
        djName: 'Kana',
        clubId: 'club-pulse-hapjeong',
      );

      expect(result.isAuthorized, isFalse);
      expect(result.statusLabel, 'Mock auth denied');
      expect(result.detail, '이 클럽은 현재 mock DJ roster에 등록되어 있지 않습니다.');
    });

    test('still approves a rostered club without wallet sign-in signatures', () async {
      final result = await service.authorizeDj(
        session: session.copyWith(signatureBase64: ''),
        djName: 'Kana',
        clubId: 'club-axis-seoul',
      );

      expect(result.isAuthorized, isTrue);
      expect(result.statusLabel, 'Mock club auth approved');
      expect(result.detail, contains('DJ: Kana'));
    });
  });
}
