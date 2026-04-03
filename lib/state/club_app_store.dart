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

  int get pendingDjCount => _songRequests.where((request) => request.status == SongRequestStatus.pendingDjApproval).length;
  int get awaitingUserCount => _songRequests.where((request) => request.status == SongRequestStatus.awaitingUserApproval).length;
  int get approvedCount => _songRequests.where((request) => request.status == SongRequestStatus.queued).length;

  ClubVenue clubById(String clubId) {
    return _clubs.firstWhere((club) => club.id == clubId);
  }

  List<SongRequest> requestsForClub(String clubId) {
    return songRequests.where((request) => request.clubId == clubId).toList(growable: false);
  }

  List<SongRequest> get pendingDjRequests => songRequests
      .where((request) => request.status == SongRequestStatus.pendingDjApproval)
      .toList(growable: false);

  List<SongRequest> get awaitingUserRequests => songRequests
      .where((request) => request.status == SongRequestStatus.awaitingUserApproval)
      .toList(growable: false);

  List<SongRequest> get approvedRequests => songRequests
      .where((request) => request.status == SongRequestStatus.queued)
      .toList(growable: false);

  List<SongRequest> get rejectedRequests => songRequests
      .where((request) => request.status == SongRequestStatus.rejected)
      .toList(growable: false);

  int totalRequestsForClub(String clubId) {
    return _songRequests.where((request) => request.clubId == clubId).length;
  }

  int pendingRequestsForClub(String clubId) {
    return _songRequests.where((request) {
      return request.clubId == clubId &&
          request.status == SongRequestStatus.pendingDjApproval;
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
    required int offeredPriceWon,
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
    if (offeredPriceWon < 5000) {
      return const SongRequestSubmissionResult(
        success: false,
        message: '제안 금액은 최소 ₩5,000 이상이어야 해요.',
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
      offeredPriceWon: offeredPriceWon,
      status: SongRequestStatus.pendingDjApproval,
      djMessage: 'DJ가 세트 흐름을 검토 중이에요.',
    );

    _songRequests = [request, ..._songRequests];
    notifyListeners();
    return const SongRequestSubmissionResult(
      success: true,
      message: '곡 요청을 보냈어요. DJ 검토 화면에서 바로 확인할 수 있어요.',
    );
  }

  bool approveRequestByDj(
    String requestId, {
    int? finalPriceWon,
    String? djMessage,
  }) {
    return _updateRequest(
      requestId,
      (request) => request.status == SongRequestStatus.pendingDjApproval
          ? request.copyWith(
              status: SongRequestStatus.awaitingUserApproval,
              finalPriceWon: finalPriceWon ?? request.offeredPriceWon,
              djMessage: djMessage ?? 'DJ가 수락했어요. 마지막 확인만 남았어요.',
            )
          : request,
    );
  }

  bool rejectRequestByDj(String requestId, {String? djMessage}) {
    return _updateRequest(
      requestId,
      (request) => request.status == SongRequestStatus.pendingDjApproval ||
              request.status == SongRequestStatus.awaitingUserApproval
          ? request.copyWith(
              status: SongRequestStatus.rejected,
              djMessage: djMessage ?? '이번 타임라인에는 맞지 않아 다음 라운드로 넘겼어요.',
            )
          : request,
    );
  }

  bool confirmRequestByUser(String requestId) {
    return _updateRequest(
      requestId,
      (request) => request.status == SongRequestStatus.awaitingUserApproval
          ? request.copyWith(
              status: SongRequestStatus.queued,
              djMessage: '양측 승인이 완료되어 플레이 큐에 올랐어요.',
            )
          : request,
    );
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
