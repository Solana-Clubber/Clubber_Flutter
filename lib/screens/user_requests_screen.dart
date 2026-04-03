import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class UserRequestsScreen extends ConsumerWidget {
  const UserRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(clubAppStoreProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(label: 'User request lane', color: AppTheme.cyan),
              SizedBox(height: 12),
              Text('관객 요청 상태'),
              SizedBox(height: 8),
              Text(
                '내가 보낸 곡 요청을 DJ 검토, 최종 확인, 큐 진입 상태까지 한 화면에서 확인하는 MVP 화면입니다.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _UserRequestSection(
          title: 'DJ 검토 중',
          emptyLabel: 'DJ 검토 중인 요청이 없어요.',
          requests: store.pendingDjRequests,
          itemBuilder: (request) => _UserRequestCard(request: request),
        ),
        const SizedBox(height: 16),
        _UserRequestSection(
          title: '내 최종 확인 필요',
          emptyLabel: '최종 확인이 필요한 요청이 없어요.',
          requests: store.awaitingUserRequests,
          itemBuilder: (request) => _UserRequestCard(
            request: request,
            actionLabel: '최종 승인',
            actionKey: ValueKey('user-confirm-${request.id}'),
            onAction: () {
              final success = ref
                  .read(clubAppStoreProvider)
                  .confirmRequestByUser(request.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '양측 승인 완료로 전환했어요.' : '지금은 최종 승인할 수 없어요.',
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _UserRequestSection(
          title: '큐에 반영됨',
          emptyLabel: '큐에 반영된 요청이 아직 없어요.',
          requests: store.approvedRequests,
          itemBuilder: (request) => _UserRequestCard(request: request),
        ),
        const SizedBox(height: 16),
        _UserRequestSection(
          title: '거절됨',
          emptyLabel: '거절된 요청이 없어요.',
          requests: store.rejectedRequests,
          itemBuilder: (request) => _UserRequestCard(request: request),
        ),
      ],
    );
  }
}

class _UserRequestSection extends StatelessWidget {
  const _UserRequestSection({
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

class _UserRequestCard extends ConsumerWidget {
  const _UserRequestCard({
    required this.request,
    this.actionLabel,
    this.actionKey,
    this.onAction,
  });

  final SongRequest request;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onAction;

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
                  label: request.status.userLabel,
                  color: request.status.badgeColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${club.name} · ${request.requesterName} · ${formatDateTime(request.requestedAt)}',
            ),
            const SizedBox(height: 6),
            Text('제안 금액 ${formatWon(request.offeredPriceWon)}'),
            if (request.finalPriceWon != null) ...[
              const SizedBox(height: 4),
              Text('DJ 제안 금액 ${formatWon(request.finalPriceWon!)}'),
            ],
            if ((request.djMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.djMessage!),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: actionKey,
                  onPressed: onAction,
                  child: Text(actionLabel ?? '확인'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on SongRequestStatus {
  String get userLabel => switch (this) {
    SongRequestStatus.pendingDjApproval => 'DJ 검토 중',
    SongRequestStatus.awaitingUserApproval => '최종 확인 필요',
    SongRequestStatus.readyForPayment => '결제 대기',
    SongRequestStatus.queued => '큐 반영 완료',
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
