import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/naver_map_runtime.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'club_detail_screen.dart';
const _mapCenterLat = 37.5445;
const _mapCenterLng = 126.986;

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  bool _showClubPreview = false;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(clubAppStoreProvider);
    final selectedClub = store.selectedClub;

    return Stack(
      fit: StackFit.expand,
      children: [
        _MapSurface(
          clubs: store.clubs,
          selectedClubId: store.selectedClubId,
          onClubSelected: _handleClubSelected,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _DiscoveryHeader(
            pendingDjCount: store.pendingDjCount,
            awaitingUserCount: store.awaitingUserCount,
            approvedCount: store.approvedCount,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _showClubPreview
                ? _SelectedClubSheet(
                    club: selectedClub,
                    pendingCount: store.pendingRequestsForClub(selectedClub.id),
                    totalRequests: store.totalRequestsForClub(selectedClub.id),
                    onClose: _closePreview,
                    onOpenClub: () => _openClub(selectedClub.id),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void _handleClubSelected(String clubId) {
    ref.read(clubAppStoreProvider).selectClub(clubId);
    if (_showClubPreview) {
      return;
    }
    setState(() => _showClubPreview = true);
  }

  void _closePreview() {
    if (!_showClubPreview) {
      return;
    }
    setState(() => _showClubPreview = false);
  }

  void _openClub(String clubId) {
    ref.read(clubAppStoreProvider).selectClub(clubId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ClubDetailScreen(clubId: clubId)),
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({
    required this.pendingDjCount,
    required this.awaitingUserCount,
    required this.approvedCount,
  });

  final int pendingDjCount;
  final int awaitingUserCount;
  final int approvedCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(label: 'Naver-map-first', color: AppTheme.lime),
                  StatusBadge(label: '라이브 클럽 탐색', color: AppTheme.cyan),
                  StatusBadge(label: 'DJ 승인 흐름 유지', color: AppTheme.accent),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '서울 DJ 요청 MVP',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '클럽 마커를 눌러 하단 시트에서 분위기와 요청 현황을 확인하고 바로 상세 화면으로 이동하세요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricPill(
                label: 'DJ 검토중',
                value: '$pendingDjCount',
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricPill(
                label: '사용자 확인',
                value: '$awaitingUserCount',
                color: AppTheme.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricPill(
                label: '최종 승인',
                value: '$approvedCount',
                color: AppTheme.lime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapSurface extends StatelessWidget {
  const _MapSurface({
    required this.clubs,
    required this.selectedClubId,
    required this.onClubSelected,
  });

  final List<ClubVenue> clubs;
  final String selectedClubId;
  final ValueChanged<String> onClubSelected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: naverMapAuthFailedNotifier,
      builder: (context, authFailed, _) {
        final canUseMap = (Platform.isAndroid || Platform.isIOS) && authFailed == null;
        return canUseMap
            ? _NaverClubMap(clubs: clubs, onClubSelected: onClubSelected)
            : _FallbackMap(
                clubs: clubs,
                selectedClubId: selectedClubId,
                onClubSelected: onClubSelected,
              );
      },
    );
  }
}

class _SelectedClubSheet extends StatelessWidget {
  const _SelectedClubSheet({
    required this.club,
    required this.pendingCount,
    required this.totalRequests,
    required this.onClose,
    required this.onOpenClub,
  });

  final ClubVenue club;
  final int pendingCount;
  final int totalRequests;
  final VoidCallback onClose;
  final VoidCallback onOpenClub;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      key: const Key('club-preview-sheet'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('club-preview-close'),
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusBadge(label: '선택한 클럽', color: AppTheme.accent),
                    const SizedBox(height: 10),
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      club.heroTagline,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(
                label: '도보 ${club.walkingMinutes}분',
                color: AppTheme.gold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(club.liveSignalSummary),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: '${club.neighborhood} · ${club.musicStyle}',
                color: AppTheme.cyan,
              ),
              StatusBadge(
                label: '대기 ${club.queueEtaMinutes}분',
                color: AppTheme.gold,
              ),
              StatusBadge(
                label: '검토중 $pendingCount건 / 전체 $totalRequests건',
                color: AppTheme.lime,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('club-preview-open-detail'),
                  onPressed: onOpenClub,
                  child: const Text('클럽 상세 열기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenClub,
                  child: Text('곡 요청 ${formatWon(club.coverChargeWon)}부터'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NaverClubMap extends StatefulWidget {
  const _NaverClubMap({required this.clubs, required this.onClubSelected});

  final List<ClubVenue> clubs;
  final ValueChanged<String> onClubSelected;

  @override
  State<_NaverClubMap> createState() => _NaverClubMapState();
}

class _NaverClubMapState extends State<_NaverClubMap> {
  bool _markersAdded = false;

  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: _clubLatLng(widget.clubs.first),
          zoom: 12.3,
        ),
      ),
      onMapReady: (controller) async {
        if (_markersAdded) {
          return;
        }
        _markersAdded = true;
        final markers = widget.clubs.map((club) {
          final marker = NMarker(
            id: club.id,
            position: _clubLatLng(club),
            caption: NOverlayCaption(text: club.name),
            subCaption: NOverlayCaption(text: club.neighborhood),
          );
          marker.setOnTapListener((_) => widget.onClubSelected(club.id));
          return marker;
        }).toSet();
        await controller.addOverlayAll(markers);
      },
    );
  }
}

class _FallbackMap extends StatelessWidget {
  const _FallbackMap({
    required this.clubs,
    required this.selectedClubId,
    required this.onClubSelected,
  });

  final List<ClubVenue> clubs;
  final String selectedClubId;
  final ValueChanged<String> onClubSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('map-panel-placeholder'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF12141D), Color(0xFF0A0B10)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                top: 140,
                child: Text(
                  '테스트/미설정 환경용 지도 프리뷰 · 마커를 눌러 하단 클럽 시트를 바꿔요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (final club in clubs)
                Positioned(
                  left: 20 + (constraints.maxWidth - 140) * club.mapPositionX,
                  top: 220 + (constraints.maxHeight - 420) * club.mapPositionY,
                  child: _FallbackMarker(
                    club: club,
                    isSelected: club.id == selectedClubId,
                    onTap: () => onClubSelected(club.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FallbackMarker extends StatelessWidget {
  const _FallbackMarker({
    required this.club,
    required this.isSelected,
    required this.onTap,
  });

  final ClubVenue club;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      key: Key('map-marker-${club.id}'),
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? AppTheme.accent.withValues(alpha: 0.42)
            : AppTheme.panelRaised.withValues(alpha: 0.90),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: BorderSide(
          color: isSelected
              ? AppTheme.accent
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      icon: const Icon(Icons.location_on),
      label: Text(isSelected ? '${club.name} · 선택됨' : club.name),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelRaised.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

NLatLng _clubLatLng(ClubVenue club) {
  final latitude = _mapCenterLat + ((club.mapPositionY - 0.5) * 0.18);
  final longitude = _mapCenterLng + ((club.mapPositionX - 0.5) * 0.24);
  return NLatLng(latitude, longitude);
}
