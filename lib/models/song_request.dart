enum SongRequestStatus {
  pending,
  accepted,
  rejected,
  settled,
  timedOut,
}

class SongRequest {
  const SongRequest({
    required this.id,
    required this.clubId,
    required this.songTitle,
    required this.artistName,
    required this.requesterName,
    required this.requestedAt,
    required this.amountLamports,
    required this.status,
    required this.trackId,
    required this.userPubkey,
    required this.djPubkey,
    this.note = '',
    this.djMessage,
    this.escrowPda,
    this.timeoutAt,
  });

  final String id;
  final String clubId;
  final String songTitle;
  final String artistName;
  final String requesterName;
  final String note;
  final DateTime requestedAt;
  final int amountLamports;
  final String? djMessage;
  final SongRequestStatus status;
  final String trackId;
  final String userPubkey;
  final String djPubkey;
  final String? escrowPda;
  final DateTime? timeoutAt;

  SongRequest copyWith({
    String? id,
    String? clubId,
    String? songTitle,
    String? artistName,
    String? requesterName,
    String? note,
    DateTime? requestedAt,
    int? amountLamports,
    String? djMessage,
    bool clearDjMessage = false,
    SongRequestStatus? status,
    String? trackId,
    String? userPubkey,
    String? djPubkey,
    String? escrowPda,
    bool clearEscrowPda = false,
    DateTime? timeoutAt,
    bool clearTimeoutAt = false,
  }) {
    return SongRequest(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      songTitle: songTitle ?? this.songTitle,
      artistName: artistName ?? this.artistName,
      requesterName: requesterName ?? this.requesterName,
      note: note ?? this.note,
      requestedAt: requestedAt ?? this.requestedAt,
      amountLamports: amountLamports ?? this.amountLamports,
      djMessage: clearDjMessage ? null : (djMessage ?? this.djMessage),
      status: status ?? this.status,
      trackId: trackId ?? this.trackId,
      userPubkey: userPubkey ?? this.userPubkey,
      djPubkey: djPubkey ?? this.djPubkey,
      escrowPda: clearEscrowPda ? null : (escrowPda ?? this.escrowPda),
      timeoutAt: clearTimeoutAt ? null : (timeoutAt ?? this.timeoutAt),
    );
  }
}
