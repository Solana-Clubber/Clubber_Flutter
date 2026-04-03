import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class DjApprovalScreen extends ConsumerWidget {
  const DjApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(clubAppStoreProvider);
    final pending = store.pendingDjRequests;
    final awaitingUser = store.awaitingUserRequests;
    final approved = store.approvedRequests;
    final rejected = store.rejectedRequests;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(label: 'DJ approval lane', color: AppTheme.accent),
              SizedBox(height: 12),
              Text('들어온 곡 요청'),
              SizedBox(height: 8),
              Text('DJ가 먼저 검토하고, 관객 최종 승인까지 이어지는 요청 운영 화면입니다.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _RequestSection(
          title: '바로 검토할 요청',
          emptyLabel: 'DJ 검토가 필요한 요청이 없어요.',
          requests: pending,
          itemBuilder: (request) => _PendingRequestCard(request: request),
        ),
        const SizedBox(height: 16),
        _RequestSection(
          title: '관객 최종 승인 대기',
          emptyLabel: '관객 최종 승인을 기다리는 요청이 없어요.',
          requests: awaitingUser,
          itemBuilder: (request) => _RequestSummaryCard(request: request),
        ),
        const SizedBox(height: 16),
        _RequestSection(
          title: '양측 승인 완료',
          emptyLabel: '양측 승인 완료 요청이 아직 없어요.',
          requests: approved,
          itemBuilder: (request) => _RequestSummaryCard(request: request),
        ),
        const SizedBox(height: 16),
        _RequestSection(
          title: '거절됨',
          emptyLabel: '거절된 요청이 없어요.',
          requests: rejected,
          itemBuilder: (request) => _RequestSummaryCard(request: request),
        ),
      ],
    );
  }
}

class _RequestSection extends StatelessWidget {
  const _RequestSection({
    required this.title,
    required this.emptyLabel,
    required this.requests,
    required this.itemBuilder,
  });

  final String title;
  final String emptyLabel;
  final List<SongRequest> requests;
  final Widget Function(SongRequest request) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            Text(emptyLabel)
          else
            ...requests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: itemBuilder(request),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends ConsumerWidget {
  const _PendingRequestCard({required this.request});

  final SongRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubAppStoreProvider).clubById(request.clubId);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${request.songTitle} · ${request.artistName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const StatusBadge(label: '새 요청', color: AppTheme.gold),
              ],
            ),
            const SizedBox(height: 8),
            Text('${club.name} · ${request.requesterName}'),
            const SizedBox(height: 6),
            Text('제안 금액 ${formatWon(request.offeredPriceWon)}'),
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.note),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: ValueKey('dj-approve-${request.id}'),
                    onPressed: () {
                      ref.read(clubAppStoreProvider).approveRequestByDj(
                            request.id,
                            finalPriceWon: request.offeredPriceWon,
                            djMessage: '좋아요. 이번 블록 안에 반영할게요.',
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('DJ 승인 완료. 관객 최종 승인 대기 상태로 이동했어요.')),
                      );
                    },
                    child: const Text('승인'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('dj-reject-${request.id}'),
                    onPressed: () {
                      ref.read(clubAppStoreProvider).rejectRequestByDj(
                            request.id,
                            djMessage: '이번 셋 분위기와 맞지 않아 다음 기회에 부탁드려요.',
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('요청을 거절 상태로 옮겼어요.')),
                      );
                    },
                    child: const Text('거절'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestSummaryCard extends ConsumerWidget {
  const _RequestSummaryCard({required this.request});

  final SongRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubAppStoreProvider).clubById(request.clubId);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${request.songTitle} · ${request.artistName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: request.status.label,
                  color: request.status.badgeColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${club.name} · ${request.requesterName} · ${formatDateTime(request.requestedAt)}'),
            const SizedBox(height: 6),
            Text('제안 금액 ${formatWon(request.offeredPriceWon)}'),
            if (request.finalPriceWon != null) ...[
              const SizedBox(height: 4),
              Text('승인 금액 ${formatWon(request.finalPriceWon!)}'),
            ],
            if ((request.djMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.djMessage!),
            ],
          ],
        ),
      ),
    );
  }
}

extension on SongRequestStatus {
  String get label => switch (this) {
        SongRequestStatus.pendingDjApproval => 'DJ 검토 중',
        SongRequestStatus.awaitingUserApproval => '관객 승인 대기',
        SongRequestStatus.readyForPayment => '결제 대기',
        SongRequestStatus.queued => '양측 승인 완료',
        SongRequestStatus.rejected => '거절됨',
      };

  Color get badgeColor => switch (this) {
        SongRequestStatus.pendingDjApproval => AppTheme.gold,
        SongRequestStatus.awaitingUserApproval => AppTheme.cyan,
        SongRequestStatus.readyForPayment => AppTheme.lime,
        SongRequestStatus.queued => AppTheme.accent,
        SongRequestStatus.rejected => AppTheme.danger,
      };
}
