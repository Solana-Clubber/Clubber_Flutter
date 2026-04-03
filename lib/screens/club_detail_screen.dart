import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class ClubDetailScreen extends ConsumerStatefulWidget {
  const ClubDetailScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _songController;
  late final TextEditingController _artistController;
  late final TextEditingController _offerController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final club = ref.read(clubAppStoreProvider).clubById(widget.clubId);
    _nameController = TextEditingController(text: 'Guest');
    _songController = TextEditingController();
    _artistController = TextEditingController();
    _offerController = TextEditingController(text: '${club.coverChargeWon}');
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _songController.dispose();
    _artistController.dispose();
    _offerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(clubAppStoreProvider);
    final club = store.clubById(widget.clubId);
    final requests = store.requestsForClub(club.id);

    return Scaffold(
      appBar: AppBar(title: Text(club.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        club.heroTagline,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const StatusBadge(
                      label: 'Live request room',
                      color: AppTheme.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(club.vibe),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: '${club.neighborhood} · ${club.musicStyle}',
                      color: AppTheme.gold,
                    ),
                    StatusBadge(
                      label: '도보 ${club.walkingMinutes}분',
                      color: AppTheme.cyan,
                    ),
                    StatusBadge(
                      label: '대기 ${club.queueEtaMinutes}분',
                      color: AppTheme.lime,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: '입장료',
                        value: formatWon(club.coverChargeWon),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: '대기 요청',
                        value: '${store.pendingRequestsForClub(club.id)}건',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: '총 요청',
                        value: '${store.totalRequestsForClub(club.id)}건',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tonight with ${club.residentArtist}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(club.liveSignalSummary),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현장 손님 곡 요청',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '관객이 곡과 희망 금액을 보내면 DJ가 먼저 검토하고, 이후 관객 최종 승인까지 끝나면 양측 승인 완료 상태가 됩니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('requester-name-field'),
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '이름 또는 닉네임'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('song-title-field'),
                  controller: _songController,
                  decoration: const InputDecoration(labelText: '곡 제목'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('artist-name-field'),
                  controller: _artistController,
                  decoration: const InputDecoration(labelText: '아티스트'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('offer-price-field'),
                  controller: _offerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '희망 금액 (원)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('request-note-field'),
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    hintText: '예: 1시 전후 드롭 직전에 부탁드려요.',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('club-request-submit'),
                    onPressed: () => _submitRequest(context),
                    child: const Text('신청곡 보내기'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '요청 현황',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (requests.isEmpty)
                  const Text('아직 들어온 요청이 없어요.')
                else
                  ...requests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RequestStatusCard(
                        request: request,
                        onConfirm: request.status == SongRequestStatus.awaitingUserApproval
                            ? () {
                                final success = ref
                                    .read(clubAppStoreProvider)
                                    .confirmRequestByUser(request.id);
                                if (!mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? '양측 승인 완료로 전환했어요.'
                                          : '지금은 최종 승인할 수 없어요.',
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitRequest(BuildContext context) {
    final amount = int.tryParse(_offerController.text.replaceAll(',', '').trim()) ?? 0;
    final result = ref.read(clubAppStoreProvider).submitSongRequest(
      clubId: widget.clubId,
      requesterName: _nameController.text.trim(),
      songTitle: _songController.text.trim(),
      artistName: _artistController.text.trim(),
      offeredPriceWon: amount,
      note: _noteController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (!result.success) {
      return;
    }

    _songController.clear();
    _artistController.clear();
    _noteController.clear();
    FocusScope.of(context).unfocus();
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _RequestStatusCard extends StatelessWidget {
  const _RequestStatusCard({required this.request, this.onConfirm});

  final SongRequest request;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
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
            Text('${request.requesterName} · ${formatDateTime(request.requestedAt)}'),
            const SizedBox(height: 6),
            Text('제안 금액 ${formatWon(request.offeredPriceWon)}'),
            if (request.finalPriceWon != null) ...[
              const SizedBox(height: 4),
              Text('DJ 승인 금액 ${formatWon(request.finalPriceWon!)}'),
            ],
            if ((request.djMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.djMessage!),
            ],
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.note),
            ],
            if (onConfirm != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: ValueKey('confirm-${request.id}'),
                onPressed: onConfirm,
                child: const Text('최종 승인하기'),
              ),
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
        SongRequestStatus.awaitingUserApproval => '관객 최종 승인 대기',
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
