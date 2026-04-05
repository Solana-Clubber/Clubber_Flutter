import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/models/models.dart';
import 'package:lover_cl/state/club_app_store.dart';

void main() {
  group('ClubAppStore', () {
    test('submitSongRequest validates required fields', () {
      final store = ClubAppStore.seeded();

      final result = store.submitSongRequest(
        clubId: 'club-axis-seoul',
        requesterName: '',
        songTitle: 'Levels',
        artistName: 'Avicii',
        amountLamports: 100000000,
        trackId: 'spotify-track-id',
        userPubkey: '11111111111111111111111111111111',
        djPubkey: '22222222222222222222222222222222',
      );

      expect(result.success, isFalse);
      expect(store.songRequests.length, 3);
    });

    test('submitSongRequest creates a pending request', () {
      final store = ClubAppStore.seeded();

      final result = store.submitSongRequest(
        clubId: 'club-axis-seoul',
        requesterName: 'Tester',
        songTitle: 'Levels',
        artistName: 'Avicii',
        amountLamports: 100000000,
        trackId: 'spotify-track-id',
        userPubkey: '11111111111111111111111111111111',
        djPubkey: '22222222222222222222222222222222',
      );

      expect(result.success, isTrue);
      expect(store.songRequests.first.status, SongRequestStatus.pending);
      expect(store.songRequests.first.songTitle, 'Levels');
    });

    test('DJ accept moves request to accepted', () {
      final store = ClubAppStore.seeded();

      final accepted = store.acceptRequestByDj(
        'request-001',
        djMessage: '다음 블록에서 가능해요.',
      );

      expect(accepted, isTrue);
      expect(
        store.songRequests.firstWhere((item) => item.id == 'request-001').status,
        SongRequestStatus.accepted,
      );
    });

    test('settle moves accepted request to settled', () {
      final store = ClubAppStore.seeded();

      final settled = store.settleRequest('request-002');

      expect(settled, isTrue);
      expect(
        store.songRequests.firstWhere((item) => item.id == 'request-002').status,
        SongRequestStatus.settled,
      );
    });

    test('rejectRequestByDj moves request to rejected', () {
      final store = ClubAppStore.seeded();

      final success = store.rejectRequestByDj(
        'request-001',
        djMessage: '이번 셋 무드와 맞지 않아요.',
      );

      expect(success, isTrue);
      expect(
        store.songRequests.firstWhere((item) => item.id == 'request-001').status,
        SongRequestStatus.rejected,
      );
    });

    test('selection and per-club counters stay in sync', () {
      final store = ClubAppStore.seeded();

      store.selectClub('club-signal-hannam');

      expect(store.selectedClubId, 'club-signal-hannam');
      expect(store.selectedClub.name, 'Signal Hannam');
      expect(store.totalRequestsForClub('club-signal-hannam'), 1);
      expect(store.pendingRequestsForClub('club-axis-seoul'), 1);
    });
  });
}
