import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/clubber_card.dart';

class UserRequestsScreen extends ConsumerStatefulWidget {
  const UserRequestsScreen({super.key});

  @override
  ConsumerState<UserRequestsScreen> createState() =>
      _UserRequestsScreenState();
}

class _UserRequestsScreenState extends ConsumerState<UserRequestsScreen> {
  List<EscrowAccount> _onChainRequests = [];
  bool _loadingChain = false;
  String? _chainError;

  @override
  void initState() {
    super.initState();
    _fetchOnChainRequests();
  }

  Future<void> _fetchOnChainRequests() async {
    final escrowService = await ref.read(escrowServiceProvider.future);
    if (escrowService == null) return;

    final session = ref.read(rootShellViewModelProvider).walletSession;
    if (session == null) return;

    setState(() {
      _loadingChain = true;
      _chainError = null;
    });
    try {
      final accounts =
          await escrowService.fetchRequestsForUser(session.publicKeyBase58);
      if (mounted) {
        setState(() {
          _onChainRequests = accounts;
          _loadingChain = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chainError = e.toString();
          _loadingChain = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(clubAppStoreProvider);
    final allRequests = [
      ...store.pendingRequests,
      ...store.acceptedRequests,
      ...store.settledRequests,
      ...store.rejectedRequests,
      ...store.timedOutRequests,
    ]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

    return RefreshIndicator(
      color: AppTheme.green,
      backgroundColor: AppTheme.panel,
      onRefresh: _fetchOnChainRequests,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Page title
          Text(
            'My Requests',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Track your song requests in real time',
            style: TextStyle(color: AppTheme.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // On-chain loading indicator
          if (_loadingChain)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.green,
                  ),
                ),
              ),
            ),

          // On-chain error banner
          if (_chainError != null) ...[
            ClubberCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.orange, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'On-chain fetch failed — showing local data',
                      style: TextStyle(color: AppTheme.grey, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchOnChainRequests,
                    child: const Icon(Icons.refresh,
                        color: AppTheme.grey, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // On-chain requests section
          if (_onChainRequests.isNotEmpty) ...[
            _SectionHeading(
              label: 'On-Chain',
              count: _onChainRequests.length,
            ),
            const SizedBox(height: 10),
            ..._onChainRequests.map(
              (account) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OnChainRequestCard(account: account),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Local requests with timeline cards
          if (allRequests.isEmpty)
            const _EmptyRequests()
          else
            ...allRequests.map(
              (req) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestTimelineCard(request: req),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section heading
// ---------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.pink.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppTheme.pink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return const ClubberCard(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.queue_music, color: AppTheme.grey, size: 40),
          SizedBox(height: 12),
          Text(
            'No requests yet',
            style: TextStyle(
              color: AppTheme.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your song requests will appear here',
            style: TextStyle(color: AppTheme.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request timeline card (expandable)
// ---------------------------------------------------------------------------

class _RequestTimelineCard extends ConsumerStatefulWidget {
  const _RequestTimelineCard({required this.request});

  final SongRequest request;

  @override
  ConsumerState<_RequestTimelineCard> createState() =>
      _RequestTimelineCardState();
}

class _RequestTimelineCardState extends ConsumerState<_RequestTimelineCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final club = ref.watch(clubAppStoreProvider).clubById(request.clubId);

    return ClubberCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status dot
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: request.status._dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.songTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${request.artistName} · ${club.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatSol(request.amountLamports),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable timeline
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _StatusTimeline(request: request),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status timeline stepper
// ---------------------------------------------------------------------------

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.request});

  final SongRequest request;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(request);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;
        return _TimelineStep(step: step, isLast: isLast);
      }).toList(),
    );
  }

  List<_StepData> _buildSteps(SongRequest request) {
    final status = request.status;

    final sentAt = formatDateTime(request.requestedAt);

    // Step states based on status
    final isRejected = status == SongRequestStatus.rejected;
    final isTimedOut = status == SongRequestStatus.timedOut;
    final isAccepted = status == SongRequestStatus.accepted ||
        status == SongRequestStatus.settled;
    final isSettled = status == SongRequestStatus.settled;

    return [
      _StepData(
        icon: Icons.send,
        label: 'Request Sent',
        timestamp: sentAt,
        state: _StepState.completed,
      ),
      _StepData(
        icon: Icons.headphones,
        label: isRejected
            ? 'Rejected'
            : isTimedOut
                ? 'Timed Out'
                : 'DJ Reviewing',
        state: isRejected
            ? _StepState.rejected
            : isTimedOut
                ? _StepState.timedOut
                : isAccepted || isSettled
                    ? _StepState.completed
                    : _StepState.active,
        note: isRejected && (request.djMessage?.isNotEmpty ?? false)
            ? request.djMessage
            : null,
      ),
      if (!isRejected && !isTimedOut)
        _StepData(
          icon: Icons.check_circle_outline,
          label: 'Accepted',
          state: isAccepted ? _StepState.completed : _StepState.pending,
        ),
      if (!isRejected && !isTimedOut)
        _StepData(
          icon: Icons.play_circle_outline,
          label: 'Now Playing',
          state: isSettled ? _StepState.completed : _StepState.pending,
        ),
      if (!isRejected && !isTimedOut)
        _StepData(
          icon: Icons.verified_outlined,
          label: 'Settlement Complete',
          state: isSettled ? _StepState.completed : _StepState.pending,
        ),
    ];
  }
}

enum _StepState { completed, active, pending, rejected, timedOut }

class _StepData {
  const _StepData({
    required this.icon,
    required this.label,
    required this.state,
    this.timestamp,
    this.note,
  });

  final IconData icon;
  final String label;
  final _StepState state;
  final String? timestamp;
  final String? note;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.step, required this.isLast});

  final _StepData step;
  final bool isLast;

  Color get _iconColor => switch (step.state) {
        _StepState.completed => AppTheme.green,
        _StepState.active => AppTheme.orange,
        _StepState.rejected => AppTheme.red,
        _StepState.timedOut => AppTheme.orange,
        _StepState.pending => AppTheme.grey,
      };

  Color get _lineColor => step.state == _StepState.completed
      ? AppTheme.green.withValues(alpha: 0.4)
      : AppTheme.grey.withValues(alpha: 0.2);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: icon + vertical line
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _iconColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(step.icon, size: 14, color: _iconColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: _lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: label + optional timestamp/note
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: step.state == _StepState.pending
                              ? AppTheme.grey
                              : AppTheme.white,
                        ),
                      ),
                      if (step.timestamp != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          step.timestamp!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (step.note != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// On-chain request card
// ---------------------------------------------------------------------------

class _OnChainRequestCard extends StatelessWidget {
  const _OnChainRequestCard({required this.account});

  final EscrowAccount account;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (account.status) {
      EscrowStatus.pending => AppTheme.orange,
      EscrowStatus.accepted => AppTheme.green,
      EscrowStatus.settled => AppTheme.pink,
      EscrowStatus.rejected => AppTheme.red,
      EscrowStatus.timedOut => AppTheme.red,
    };
    final statusLabel = switch (account.status) {
      EscrowStatus.pending => 'DJ Reviewing',
      EscrowStatus.accepted => 'Accepted',
      EscrowStatus.rejected => 'Rejected',
      EscrowStatus.settled => 'Settled',
      EscrowStatus.timedOut => 'Timed Out',
    };

    final isTerminal = account.status == EscrowStatus.settled ||
        account.status == EscrowStatus.rejected ||
        account.status == EscrowStatus.timedOut;

    return Opacity(
      opacity: isTerminal ? 0.65 : 1.0,
      child: ClubberCard(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.trackId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        formatSol(account.amount),
                        style: const TextStyle(
                          color: AppTheme.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatDateTime(account.createdAt),
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (!isTerminal) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Expires: ${formatDateTime(account.timeoutAt)}',
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extension helpers
// ---------------------------------------------------------------------------

extension on SongRequestStatus {
  Color get _dotColor => switch (this) {
        SongRequestStatus.pending => AppTheme.orange,
        SongRequestStatus.accepted => AppTheme.green,
        SongRequestStatus.settled => AppTheme.pink,
        SongRequestStatus.rejected => AppTheme.red,
        SongRequestStatus.timedOut => AppTheme.orange,
      };
}
