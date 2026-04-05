import 'package:flutter/foundation.dart';

import '../data/data.dart';
import '../models/models.dart';

class SongRequestSubmissionResult {
  const SongRequestSubmissionResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class ClubAppStore extends ChangeNotifier {
  ClubAppStore({MockClubRepository? repository})
    : _repository = repository ?? MockClubRepository.seeded(),
      _clubs = List<ClubVenue>.from((repository ?? MockClubRepository.seeded()).clubs),
      _songRequests = List<SongRequest>.from((repository ?? MockClubRepository.seeded()).songRequests) {
    _selectedClubId = _clubs.first.id;
  }

  factory ClubAppStore.seeded() => ClubAppStore();

  final MockClubRepository _repository;
  final List<ClubVenue> _clubs;
  List<SongRequest> _songRequests;
  late String _selectedClubId;

  List<ClubVenue> get clubs => List<ClubVenue>.unmodifiable(_clubs);
  List<SongRequest> get songRequests => List<SongRequest>.unmodifiable(_sortedRequests(_songRequests));
  String get selectedClubId => _selectedClubId;
  ClubVenue get selectedClub => clubById(_selectedClubId);

  int get pendingCount => _songRequests.where((r) => r.status == SongRequestStatus.pending).length;
  int get acceptedCount => _songRequests.where((r) => r.status == SongRequestStatus.accepted).length;
  int get settledCount => _songRequests.where((r) => r.status == SongRequestStatus.settled).length;

  // Legacy count getters for screen compatibility
  int get pendingDjCount => pendingCount;
  int get awaitingUserCount => acceptedCount;
  int get approvedCount => settledCount;

  ClubVenue clubById(String clubId) {
    return _clubs.firstWhere((club) => club.id == clubId);
  }

  List<SongRequest> requestsForClub(String clubId) {
    return songRequests.where((request) => request.clubId == clubId).toList(growable: false);
  }

  List<SongRequest> get pendingRequests => songRequests
      .where((r) => r.status == SongRequestStatus.pending)
      .toList(growable: false);

  List<SongRequest> get acceptedRequests => songRequests
      .where((r) => r.status == SongRequestStatus.accepted)
      .toList(growable: false);

  List<SongRequest> get settledRequests => songRequests
      .where((r) => r.status == SongRequestStatus.settled)
      .toList(growable: false);

  List<SongRequest> get rejectedRequests => songRequests
      .where((r) => r.status == SongRequestStatus.rejected)
      .toList(growable: false);

  List<SongRequest> get timedOutRequests => songRequests
      .where((r) => r.status == SongRequestStatus.timedOut)
      .toList(growable: false);

  // Legacy getters kept for screen compatibility during migration
  List<SongRequest> get pendingDjRequests => pendingRequests;
  List<SongRequest> get awaitingUserRequests => acceptedRequests;
  List<SongRequest> get approvedRequests => settledRequests;

  void setDjWalletForClub(String clubId, String walletAddress) {
    final index = _clubs.indexWhere((c) => c.id == clubId);
    if (index == -1) return;
    _clubs[index] = _clubs[index].copyWith(djWalletAddress: walletAddress);
    notifyListeners();
  }

  int totalRequestsForClub(String clubId) {
    return _songRequests.where((request) => request.clubId == clubId).length;
  }

  int pendingRequestsForClub(String clubId) {
    return _songRequests.where((request) {
      return request.clubId == clubId &&
          request.status == SongRequestStatus.pending;
    }).length;
  }

  void selectClub(String clubId) {
    if (_selectedClubId == clubId || !_clubs.any((club) => club.id == clubId)) {
      return;
    }
    _selectedClubId = clubId;
    notifyListeners();
  }

  SongRequestSubmissionResult submitSongRequest({
    required String clubId,
    required String requesterName,
    required String songTitle,
    required String artistName,
    required int amountLamports,
    required String trackId,
    required String userPubkey,
    required String djPubkey,
    String? escrowPda,
    String note = '',
  }) {
    final normalizedName = requesterName.trim();
    final normalizedSong = songTitle.trim();
    final normalizedArtist = artistName.trim();
    final normalizedNote = note.trim();

    if (normalizedName.isEmpty || normalizedSong.isEmpty || normalizedArtist.isEmpty) {
      return const SongRequestSubmissionResult(
        success: false,
        message: '이름, 곡 제목, 아티스트는 모두 입력해 주세요.',
      );
    }
    if (amountLamports <= 0) {
      return const SongRequestSubmissionResult(
        success: false,
        message: '금액을 입력해 주세요.',
      );
    }

    final request = SongRequest(
      id: 'request-${_songRequests.length + 1}',
      clubId: clubId,
      requesterName: normalizedName,
      songTitle: normalizedSong,
      artistName: normalizedArtist,
      note: normalizedNote,
      requestedAt: DateTime.now(),
      amountLamports: amountLamports,
      status: SongRequestStatus.pending,
      trackId: trackId,
      userPubkey: userPubkey,
      djPubkey: djPubkey,
      escrowPda: escrowPda,
      djMessage: 'DJ가 세트 흐름을 검토 중이에요.',
    );

    _songRequests = [request, ..._songRequests];
    notifyListeners();
    return const SongRequestSubmissionResult(
      success: true,
      message: '곡 요청을 보냈어요. DJ 검토 화면에서 바로 확인할 수 있어요.',
    );
  }

  bool acceptRequestByDj(String requestId, {String? djMessage}) {
    return _updateRequest(
      requestId,
      (request) => request.status == SongRequestStatus.pending
          ? request.copyWith(
              status: SongRequestStatus.accepted,
              djMessage: djMessage ?? 'DJ가 수락했어요.',
            )
          : request,
    );
  }

  bool rejectRequestByDj(String requestId, {String? djMessage}) {
    return _updateRequest(
      requestId,
      (request) => request.status == SongRequestStatus.pending ||
              request.status == SongRequestStatus.accepted
          ? request.copyWith(
              status: SongRequestStatus.rejected,
              djMessage: djMessage ?? '이번 타임라인에는 맞지 않아 다음 라운드로 넘겼어요.',
            )
          : request,
    );
  }

  bool settleRequest(String requestId, {String? djMessage}) {
    return _updateRequest(
      requestId,
      (request) => request.status == SongRequestStatus.accepted
          ? request.copyWith(
              status: SongRequestStatus.settled,
              djMessage: djMessage ?? '정산 완료됐어요.',
            )
          : request,
    );
  }

  // Legacy method kept for screen compatibility
  bool approveRequestByDj(String requestId, {int? finalPriceWon, String? djMessage}) {
    return acceptRequestByDj(requestId, djMessage: djMessage);
  }

  // Legacy method kept for screen compatibility
  bool confirmRequestByUser(String requestId) {
    return settleRequest(requestId);
  }

  bool _updateRequest(
    String requestId,
    SongRequest Function(SongRequest request) transform,
  ) {
    final index = _songRequests.indexWhere((request) => request.id == requestId);
    if (index == -1) {
      return false;
    }

    final current = _songRequests[index];
    final updated = transform(current);
    if (identical(updated, current)) {
      return false;
    }

    _songRequests[index] = updated;
    _songRequests = List<SongRequest>.from(_songRequests);
    notifyListeners();
    return true;
  }

  List<SongRequest> _sortedRequests(List<SongRequest> requests) {
    final copy = List<SongRequest>.from(requests);
    copy.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return copy;
  }

  @visibleForTesting
  MockClubRepository get repository => _repository;
}
