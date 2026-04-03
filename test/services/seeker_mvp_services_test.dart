import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/data/mock_club_repository.dart';
import 'package:lover_cl/models/models.dart';
import 'package:lover_cl/services/seeker_mvp_services.dart';

void main() {
  group('MockSeekerPopService', () {
    late MockClubRepository repository;
    late MockSeekerPopService service;

    setUp(() {
      repository = MockClubRepository.seeded();
      service = MockSeekerPopService();
    });

    test('bootstrap returns sorted clubs and proof gating for the default zone', () {
      final snapshot = service.bootstrap(repository.clubs);

      expect(snapshot.activeLocation.id, 'cheongdam-now');
      expect(
        snapshot.clubs.map((club) => club.id).toList(),
        ['club-axis-seoul', 'club-signal-hannam', 'club-pulse-hapjeong'],
      );
      expect(
        snapshot.presenceProofs['club-axis-seoul']?.status,
        VenuePresenceProofStatus.verified,
      );
      expect(
        snapshot.presenceProofs['club-axis-seoul']?.canSubmitSongRequest,
        isTrue,
      );
      expect(
        snapshot.presenceProofs['club-signal-hannam']?.status,
        VenuePresenceProofStatus.reviewRequired,
      );
      expect(
        snapshot.presenceProofs['club-pulse-hapjeong']?.status,
        VenuePresenceProofStatus.unavailable,
      );
    });

    test('switchLocation moves verified proof to the matching club zone', () {
      final snapshot = service.switchLocation(
        baseClubs: repository.clubs,
        presetId: 'hapjeong-late',
      );

      expect(snapshot.activeLocation.id, 'hapjeong-late');
      expect(snapshot.clubs.first.id, 'club-pulse-hapjeong');
      expect(
        snapshot.presenceProofs['club-pulse-hapjeong']?.status,
        VenuePresenceProofStatus.verified,
      );
      expect(
        snapshot.presenceProofs['club-axis-seoul']?.verificationLabel,
        'out-of-zone · proof locked',
      );
    });
  });

  group('MockSeekerWalletService', () {
    const service = MockSeekerWalletService();

    test('exposes iOS and Android scaffold metadata', () {
      expect(service.scaffoldInfo.platformLabel, 'iOS · Android MVP scaffold');
      expect(service.scaffoldInfo.settlementLabel, 'Mock Seeker wallet rail');
    });

    test('settleSongRequest emits traceable mock settlement receipts', () {
      final receipt = service.settleSongRequest(
        request: SongRequest(
          id: 'request-test',
          clubId: 'club-axis-seoul',
          songTitle: 'Genesis',
          artistName: 'Justice',
          requesterName: 'Verifier',
          requestedAt: DateTime(2026, 3, 29, 21),
          offeredPriceWon: 30000,
          status: SongRequestStatus.readyForPayment,
        ),
      );

      expect(receipt.reference, startsWith('seek-'));
      expect(receipt.settlementRail, 'Mock wallet hold');
      expect(receipt.note, contains('Genesis'));
    });
  });
}
