enum WalletPaymentStatus { completed }

class WalletPayment {
  const WalletPayment({
    required this.id,
    required this.requestId,
    required this.clubId,
    required this.label,
    required this.amountWon,
    required this.createdAt,
    required this.status,
    this.reference = '',
    this.settlementRail = '',
    this.note = '',
  });

  final String id;
  final String requestId;
  final String clubId;
  final String label;
  final int amountWon;
  final DateTime createdAt;
  final WalletPaymentStatus status;
  final String reference;
  final String settlementRail;
  final String note;
}
