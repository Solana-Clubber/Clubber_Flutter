enum MintEligibilityState { ready, warmingUp, locked }

class MintEligibility {
  const MintEligibility({
    required this.clubId,
    required this.state,
    required this.summary,
    required this.eligibilityScore,
    required this.mintedSupply,
    required this.totalSupply,
    required this.mintPriceWon,
    required this.nextRefresh,
    required this.contractLabel,
    required this.privacyLabel,
    this.benefits = const <String>[],
    this.blockers = const <String>[],
  });

  final String clubId;
  final MintEligibilityState state;
  final String summary;
  final int eligibilityScore;
  final int mintedSupply;
  final int totalSupply;
  final int mintPriceWon;
  final DateTime nextRefresh;
  final String contractLabel;
  final String privacyLabel;
  final List<String> benefits;
  final List<String> blockers;
}
