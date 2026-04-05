import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';
import 'status_badge.dart';

class VenueCard extends StatelessWidget {
  const VenueCard({
    required this.club,
    required this.proof,
    required this.eligibility,
    required this.onTap,
    super.key,
  });

  final ClubVenue club;
  final VenuePresenceProof proof;
  final MintEligibility eligibility;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('${club.neighborhood} · ${club.musicStyle}'),
                  ],
                ),
              ),
              StatusBadge(
                label: proof.status.label,
                color: proof.status.badgeColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(club.heroTagline, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: '도보 ${club.walkingMinutes}분',
                color: AppTheme.lime,
              ),
              StatusBadge(
                label: eligibility.state.label,
                color: eligibility.state.badgeColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(club.liveSignalSummary),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: ValueKey('club-card-open-${club.id}'),
              onPressed: onTap,
              child: const Text('클럽 상세 보기'),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: club.tags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

extension on VenuePresenceProofStatus {
  String get label => switch (this) {
        VenuePresenceProofStatus.verified => 'PoP 검증 완료',
        VenuePresenceProofStatus.reviewRequired => '현장 재확인 필요',
        VenuePresenceProofStatus.unavailable => '잠김',
      };

  Color get badgeColor => switch (this) {
        VenuePresenceProofStatus.verified => AppTheme.lime,
        VenuePresenceProofStatus.reviewRequired => AppTheme.gold,
        VenuePresenceProofStatus.unavailable => AppTheme.danger,
      };
}

extension on MintEligibilityState {
  String get label => switch (this) {
        MintEligibilityState.ready => '민트 가능',
        MintEligibilityState.warmingUp => '거의 준비',
        MintEligibilityState.locked => '민트 잠김',
      };

  Color get badgeColor => switch (this) {
        MintEligibilityState.ready => AppTheme.accent,
        MintEligibilityState.warmingUp => AppTheme.gold,
        MintEligibilityState.locked => AppTheme.danger,
      };
}
