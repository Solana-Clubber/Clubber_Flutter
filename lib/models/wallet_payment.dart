enum WalletPaymentStatus { completed }

class WalletPayment {
  const WalletPayment({
    required this.id,
    required this.requestId,
    required this.clubId,
    required this.label,
    required this.amountLamports,
    required this.createdAt,
    required this.status,
    required this.txSignature,
    this.reference = '',
    this.settlementRail = '',
    this.note = '',
  });

  final String id;
  final String requestId;
  final String clubId;
  final String label;
  final int amountLamports;
  final DateTime createdAt;
  final WalletPaymentStatus status;
  final String txSignature;
  final String reference;
  final String settlementRail;
  final String note;
}
