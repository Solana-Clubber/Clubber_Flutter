import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/naver_map_runtime.dart';
import '../theme/app_theme.dart';
import '../widgets/clubber_card.dart';
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
          left: 16,
          right: 16,
          bottom: 20,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _showClubPreview
                ? _SelectedClubSheet(
                    key: const Key('club-preview-sheet'),
                    club: selectedClub,
                    pendingCount:
                        store.pendingRequestsForClub(selectedClub.id),
                    totalRequests:
                        store.totalRequestsForClub(selectedClub.id),
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
    if (_showClubPreview) return;
    setState(() => _showClubPreview = true);
  }

  void _closePreview() {
    if (!_showClubPreview) return;
    setState(() => _showClubPreview = false);
  }

  void _openClub(String clubId) {
    ref.read(clubAppStoreProvider).selectClub(clubId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => ClubDetailScreen(clubId: clubId)),
    );
  }
}

// ---------------------------------------------------------------------------
// Map surface
// ---------------------------------------------------------------------------

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
        final canUseMap =
            (Platform.isAndroid || Platform.isIOS) && authFailed == null;
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

// ---------------------------------------------------------------------------
// Club preview bottom card
// ---------------------------------------------------------------------------

class _SelectedClubSheet extends StatelessWidget {
  const _SelectedClubSheet({
    required this.club,
    required this.pendingCount,
    required this.totalRequests,
    required this.onClose,
    required this.onOpenClub,
    super.key,
  });

  final ClubVenue club;
  final int pendingCount;
  final int totalRequests;
  final VoidCallback onClose;
  final VoidCallback onOpenClub;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle + close
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close,
                    size: 20, color: AppTheme.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Club name + walking time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppTheme.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.neighborhood,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MusicStyleBadge(label: club.musicStyle),
                  const SizedBox(height: 6),
                  Text(
                    '도보 ${club.walkingMinutes}분',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.music_note_rounded,
                label: '$totalRequests requests',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.pending_actions_rounded,
                label: '$pendingCount pending',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.timer_rounded,
                label: '${club.queueEtaMinutes}min wait',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('club-preview-open-detail'),
                  onPressed: onOpenClub,
                  child: const Text('View Club'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenClub,
                  child: const Text('Request Song'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MusicStyleBadge extends StatelessWidget {
  const _MusicStyleBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.pink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.pink.withValues(alpha: 0.50), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.pink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.panelRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Naver map
// ---------------------------------------------------------------------------

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
        if (_markersAdded) return;
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

// ---------------------------------------------------------------------------
// Fallback map (web / desktop / no API key)
// ---------------------------------------------------------------------------

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
              for (final club in clubs)
                Positioned(
                  left: 20 +
                      (constraints.maxWidth - 140) * club.mapPositionX,
                  top: 140 +
                      (constraints.maxHeight - 380) * club.mapPositionY,
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
    return GestureDetector(
      key: Key('map-marker-${club.id}'),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.pink.withValues(alpha: 0.30)
              : AppTheme.panelRaised.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: isSelected
                ? AppTheme.pink
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 14,
              color:
                  isSelected ? AppTheme.pink : AppTheme.grey,
            ),
            const SizedBox(width: 6),
            Text(
              club.name,
              style: TextStyle(
                color: isSelected ? AppTheme.white : AppTheme.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

NLatLng _clubLatLng(ClubVenue club) {
  final latitude =
      _mapCenterLat + ((club.mapPositionY - 0.5) * 0.18);
  final longitude =
      _mapCenterLng + ((club.mapPositionX - 0.5) * 0.24);
  return NLatLng(latitude, longitude);
}
