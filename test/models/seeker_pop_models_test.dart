import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/models/artist_settlement.dart';
import 'package:lover_cl/models/mint_eligibility.dart';
import 'package:lover_cl/models/verified_review.dart';

void main() {
  test('ArtistSettlement copyWith updates payout transparency fields', () {
    final settlement = ArtistSettlement(
      id: 'settlement-1',
      clubId: 'club-axis-seoul',
      artistName: 'DJ KANA',
      setLabel: 'Headliner Set',
      grossRevenueWon: 1200000,
      artistShareWon: 540000,
      venueShareWon: 420000,
      fanRewardPoolWon: 240000,
      verifiedReviewCount: 18,
      payoutReference: 'settle-seek-001',
      contractLabel: 'Mock payout ledger',
      updatedAt: DateTime(2026, 3, 29, 22, 15),
      status: ArtistSettlementStatus.queued,
    );

    final published = settlement.copyWith(
      status: ArtistSettlementStatus.published,
      verifiedReviewCount: 20,
      note: 'Settlement posted to the mock contract mirror.',
    );

    expect(published.status, ArtistSettlementStatus.published);
    expect(published.verifiedReviewCount, 20);
    expect(published.payoutReference, 'settle-seek-001');
    expect(published.note, contains('mock contract'));
  });

  test('VerifiedReview copyWith preserves trust metadata while updating status', () {
    final review = VerifiedReview(
      id: 'review-1',
      clubId: 'club-axis-seoul',
      reviewerAlias: 'nightowl.eth',
      headline: 'Great booth energy',
      body: 'Crowd reaction stayed strong all set long.',
      rating: 5,
      submittedAt: DateTime(2026, 3, 29, 22),
      status: VerifiedReviewStatus.submitted,
      attestationLabel: 'Mock Seeker PoP anchored',
      privacyLabel: 'ZKP summary hidden',
      payoutImpactLabel: 'Counts toward artist share',
      vibeTags: const ['house', 'crowd-synced'],
    );

    final anchored = review.copyWith(status: VerifiedReviewStatus.anchored);

    expect(anchored.status, VerifiedReviewStatus.anchored);
    expect(anchored.attestationLabel, 'Mock Seeker PoP anchored');
    expect(anchored.vibeTags, contains('house'));
  });

  test('MintEligibility retains benefits and blockers for dynamic mint gating', () {
    final eligibility = MintEligibility(
      clubId: 'club-pulse-hapjeong',
      state: MintEligibilityState.warmingUp,
      summary: 'Needs one more anchored review before mint unlock.',
      eligibilityScore: 74,
      mintedSupply: 120,
      totalSupply: 300,
      mintPriceWon: 28000,
      nextRefresh: DateTime(2026, 3, 29, 22, 45),
      contractLabel: 'Mock mint contract',
      privacyLabel: 'Proof hidden behind ZKP boundary',
      benefits: const ['priority queue', 'fan reward boost'],
      blockers: const ['review quorum'],
    );

    expect(eligibility.state, MintEligibilityState.warmingUp);
    expect(eligibility.benefits, contains('priority queue'));
    expect(eligibility.blockers.single, 'review quorum');
  });
}
