enum EscrowStatus {
  pending,
  accepted,
  rejected,
  settled,
  timedOut,
}

class EscrowAccount {
  const EscrowAccount({
    required this.user,
    required this.dj,
    required this.trackId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.timeoutAt,
    required this.bump,
  });

  final String user;
  final String dj;
  final String trackId;
  final int amount;
  final EscrowStatus status;
  final DateTime createdAt;
  final DateTime timeoutAt;
  final int bump;
}
