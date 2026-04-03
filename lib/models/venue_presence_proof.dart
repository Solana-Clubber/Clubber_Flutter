enum VenuePresenceProofStatus { verified, reviewRequired, unavailable }

class VenuePresenceProof {
  const VenuePresenceProof({
    required this.clubId,
    required this.status,
    required this.summary,
    required this.verificationLabel,
    required this.stubBoundary,
    required this.updatedAt,
    required this.gpsSummary,
    required this.audioSummary,
    required this.privacySummary,
    required this.contractSummary,
    required this.canSubmitReview,
  });

  final String clubId;
  final VenuePresenceProofStatus status;
  final String summary;
  final String verificationLabel;
  final String stubBoundary;
  final DateTime updatedAt;
  final String gpsSummary;
  final String audioSummary;
  final String privacySummary;
  final String contractSummary;
  final bool canSubmitReview;

  bool get canSubmitSongRequest => canSubmitReview;
}
