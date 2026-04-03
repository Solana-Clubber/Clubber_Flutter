enum ArtistSettlementStatus { queued, published, finalized }

class ArtistSettlement {
  const ArtistSettlement({
    required this.id,
    required this.clubId,
    required this.artistName,
    required this.setLabel,
    required this.grossRevenueWon,
    required this.artistShareWon,
    required this.venueShareWon,
    required this.fanRewardPoolWon,
    required this.verifiedReviewCount,
    required this.payoutReference,
    required this.contractLabel,
    required this.updatedAt,
    required this.status,
    this.note = '',
  });

  final String id;
  final String clubId;
  final String artistName;
  final String setLabel;
  final int grossRevenueWon;
  final int artistShareWon;
  final int venueShareWon;
  final int fanRewardPoolWon;
  final int verifiedReviewCount;
  final String payoutReference;
  final String contractLabel;
  final DateTime updatedAt;
  final ArtistSettlementStatus status;
  final String note;

  ArtistSettlement copyWith({
    String? id,
    String? clubId,
    String? artistName,
    String? setLabel,
    int? grossRevenueWon,
    int? artistShareWon,
    int? venueShareWon,
    int? fanRewardPoolWon,
    int? verifiedReviewCount,
    String? payoutReference,
    String? contractLabel,
    DateTime? updatedAt,
    ArtistSettlementStatus? status,
    String? note,
  }) {
    return ArtistSettlement(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      artistName: artistName ?? this.artistName,
      setLabel: setLabel ?? this.setLabel,
      grossRevenueWon: grossRevenueWon ?? this.grossRevenueWon,
      artistShareWon: artistShareWon ?? this.artistShareWon,
      venueShareWon: venueShareWon ?? this.venueShareWon,
      fanRewardPoolWon: fanRewardPoolWon ?? this.fanRewardPoolWon,
      verifiedReviewCount: verifiedReviewCount ?? this.verifiedReviewCount,
      payoutReference: payoutReference ?? this.payoutReference,
      contractLabel: contractLabel ?? this.contractLabel,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}
