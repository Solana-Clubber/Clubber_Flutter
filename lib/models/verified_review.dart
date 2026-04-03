enum VerifiedReviewStatus { submitted, anchored, mintedSignal }

class VerifiedReview {
  const VerifiedReview({
    required this.id,
    required this.clubId,
    required this.reviewerAlias,
    required this.headline,
    required this.body,
    required this.rating,
    required this.submittedAt,
    required this.status,
    required this.attestationLabel,
    required this.privacyLabel,
    required this.payoutImpactLabel,
    this.vibeTags = const <String>[],
  });

  final String id;
  final String clubId;
  final String reviewerAlias;
  final String headline;
  final String body;
  final int rating;
  final DateTime submittedAt;
  final VerifiedReviewStatus status;
  final String attestationLabel;
  final String privacyLabel;
  final String payoutImpactLabel;
  final List<String> vibeTags;

  VerifiedReview copyWith({
    String? id,
    String? clubId,
    String? reviewerAlias,
    String? headline,
    String? body,
    int? rating,
    DateTime? submittedAt,
    VerifiedReviewStatus? status,
    String? attestationLabel,
    String? privacyLabel,
    String? payoutImpactLabel,
    List<String>? vibeTags,
  }) {
    return VerifiedReview(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      reviewerAlias: reviewerAlias ?? this.reviewerAlias,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      rating: rating ?? this.rating,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      attestationLabel: attestationLabel ?? this.attestationLabel,
      privacyLabel: privacyLabel ?? this.privacyLabel,
      payoutImpactLabel: payoutImpactLabel ?? this.payoutImpactLabel,
      vibeTags: vibeTags ?? this.vibeTags,
    );
  }
}
