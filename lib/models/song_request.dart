enum SongRequestStatus {
  pendingDjApproval,
  awaitingUserApproval,
  readyForPayment,
  queued,
  rejected,
}

class SongRequest {
  const SongRequest({
    required this.id,
    required this.clubId,
    required this.songTitle,
    required this.artistName,
    required this.requesterName,
    required this.requestedAt,
    required this.offeredPriceWon,
    required this.status,
    this.note = '',
    this.finalPriceWon,
    this.djMessage,
  });

  final String id;
  final String clubId;
  final String songTitle;
  final String artistName;
  final String requesterName;
  final String note;
  final DateTime requestedAt;
  final int offeredPriceWon;
  final int? finalPriceWon;
  final String? djMessage;
  final SongRequestStatus status;

  int get payableAmountWon => finalPriceWon ?? offeredPriceWon;

  SongRequest copyWith({
    String? id,
    String? clubId,
    String? songTitle,
    String? artistName,
    String? requesterName,
    String? note,
    DateTime? requestedAt,
    int? offeredPriceWon,
    int? finalPriceWon,
    bool clearFinalPriceWon = false,
    String? djMessage,
    bool clearDjMessage = false,
    SongRequestStatus? status,
  }) {
    return SongRequest(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      songTitle: songTitle ?? this.songTitle,
      artistName: artistName ?? this.artistName,
      requesterName: requesterName ?? this.requesterName,
      note: note ?? this.note,
      requestedAt: requestedAt ?? this.requestedAt,
      offeredPriceWon: offeredPriceWon ?? this.offeredPriceWon,
      finalPriceWon: clearFinalPriceWon
          ? null
          : (finalPriceWon ?? this.finalPriceWon),
      djMessage: clearDjMessage ? null : (djMessage ?? this.djMessage),
      status: status ?? this.status,
    );
  }
}
