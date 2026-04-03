import '../models/models.dart';

class SeekerDiscoverySnapshot {
  const SeekerDiscoverySnapshot({
    required this.availableLocations,
    required this.activeLocation,
    required this.clubs,
    required this.presenceProofs,
    required this.mapStrategyLabel,
    required this.mapStrategyDetail,
  });

  final List<LocationPreset> availableLocations;
  final LocationPreset activeLocation;
  final List<ClubVenue> clubs;
  final Map<String, VenuePresenceProof> presenceProofs;
  final String mapStrategyLabel;
  final String mapStrategyDetail;
}

class ReviewSubmissionDraft {
  const ReviewSubmissionDraft({
    required this.reviewerAlias,
    required this.headline,
    required this.body,
    required this.rating,
    required this.vibeTags,
  });

  final String reviewerAlias;
  final String headline;
  final String body;
  final int rating;
  final List<String> vibeTags;
}

class SettlementScaffoldInfo {
  const SettlementScaffoldInfo({
    required this.platformLabel,
    required this.privacyLabel,
    required this.settlementLabel,
    required this.detail,
  });

  final String platformLabel;
  final String privacyLabel;
  final String settlementLabel;
  final String detail;
}

class WalletScaffoldInfo {
  const WalletScaffoldInfo({
    required this.platformLabel,
    required this.settlementLabel,
    required this.detail,
  });

  final String platformLabel;
  final String settlementLabel;
  final String detail;
}

class WalletSettlementReceipt {
  const WalletSettlementReceipt({
    required this.reference,
    required this.settlementRail,
    required this.note,
    required this.processedAt,
  });

  final String reference;
  final String settlementRail;
  final String note;
  final DateTime processedAt;
}

abstract class SeekerPopService {
  SeekerDiscoverySnapshot bootstrap(List<ClubVenue> baseClubs);

  SeekerDiscoverySnapshot switchLocation({
    required List<ClubVenue> baseClubs,
    required String presetId,
  });
}

abstract class SeekerReviewService {
  VerifiedReview submitVerifiedReview({
    required ClubVenue club,
    required VenuePresenceProof proof,
    required ReviewSubmissionDraft draft,
    required int sequence,
  });
}

abstract class SeekerSettlementService {
  SettlementScaffoldInfo get scaffoldInfo;

  ArtistSettlement syncSettlement({
    required ArtistSettlement seededSettlement,
    required int verifiedReviewCount,
  });

  MintEligibility buildMintEligibility({
    required ClubVenue club,
    required VenuePresenceProof proof,
    required List<VerifiedReview> reviews,
    required ArtistSettlement settlement,
  });
}

abstract class SeekerWalletService {
  WalletScaffoldInfo get scaffoldInfo;

  WalletSettlementReceipt settleSongRequest({required SongRequest request});
}

class MockSeekerPopService implements SeekerPopService {
  MockSeekerPopService();

  final List<LocationPreset> _presets = [
    LocationPreset(
      id: 'cheongdam-now',
      label: '청담 라이브',
      subtitle: 'Axis Seoul 인근 GPS 스냅샷',
      latitude: 37.5258,
      longitude: 127.0451,
      accuracyMeters: 18,
      updatedAt: DateTime(2026, 3, 29, 20, 55),
    ),
    LocationPreset(
      id: 'hannam-switch',
      label: '한남 이동',
      subtitle: 'Signal Hannam 인근 GPS 스냅샷',
      latitude: 37.5345,
      longitude: 127.0054,
      accuracyMeters: 24,
      updatedAt: DateTime(2026, 3, 29, 21, 3),
    ),
    LocationPreset(
      id: 'hapjeong-late',
      label: '합정 심야',
      subtitle: 'Pulse Hapjeong 인근 GPS 스냅샷',
      latitude: 37.5509,
      longitude: 126.9138,
      accuracyMeters: 21,
      updatedAt: DateTime(2026, 3, 29, 21, 18),
    ),
  ];

  static const Map<String, Map<String, _ClubScenario>> _scenarios = {
    'cheongdam-now': {
      'club-axis-seoul': _ClubScenario(
        distanceMeters: 180,
        mapPositionX: 0.34,
        mapPositionY: 0.42,
        proofStatus: VenuePresenceProofStatus.verified,
        summary: 'GPS·TEE 오디오·ZK 프라이버시 증명이 모두 통과되어 검증 리뷰가 바로 열려 있어요.',
        verificationLabel: 'GPS fence + TEE fingerprint + ZK proof',
        gpsSummary: '반경 200m 이내, 정확도 ±18m',
        audioSummary: '현장 오디오 핑거프린트 일치율 98%',
        privacySummary: 'ZK venue hash 제출 완료',
        contractSummary: 'fan reward split 미리보기 동기화',
      ),
      'club-signal-hannam': _ClubScenario(
        distanceMeters: 1280,
        mapPositionX: 0.64,
        mapPositionY: 0.24,
        proofStatus: VenuePresenceProofStatus.reviewRequired,
        summary: '현장 외곽에 있어 추가 QR 또는 재스캔이 필요합니다.',
        verificationLabel: 'GPS coarse lock · review hold',
        gpsSummary: '반경 바깥쪽, 정확도 ±24m',
        audioSummary: '배경 오디오 일치율 62%',
        privacySummary: 'ZK commitment 준비 완료',
        contractSummary: '정산 카드만 미리 열림',
      ),
      'club-pulse-hapjeong': _ClubScenario(
        distanceMeters: 4100,
        mapPositionX: 0.82,
        mapPositionY: 0.72,
        proofStatus: VenuePresenceProofStatus.unavailable,
        summary: '현재 위치와 멀어 PoP 세션을 만들 수 없어요.',
        verificationLabel: 'Out of zone · proof locked',
        gpsSummary: '현장 반경 밖',
        audioSummary: '오디오 캡처 비활성화',
        privacySummary: 'proof 생성 전',
        contractSummary: '민팅 자격 잠김',
      ),
    },
    'hannam-switch': {
      'club-axis-seoul': _ClubScenario(
        distanceMeters: 930,
        mapPositionX: 0.30,
        mapPositionY: 0.34,
        proofStatus: VenuePresenceProofStatus.reviewRequired,
        summary: '청담 세션은 edge zone이라 리뷰 전 재확인이 필요합니다.',
        verificationLabel: 'Edge zone · QR rescan recommended',
        gpsSummary: '반경 경계선',
        audioSummary: '오디오 핑거프린트 유지',
        privacySummary: 'ZK commitment 유지',
        contractSummary: '정산 카드 열림, 리뷰 잠시 대기',
      ),
      'club-signal-hannam': _ClubScenario(
        distanceMeters: 140,
        mapPositionX: 0.52,
        mapPositionY: 0.36,
        proofStatus: VenuePresenceProofStatus.verified,
        summary: '현장 입구 반경에 있어 검증 리뷰와 민팅 자격 계산이 모두 열려 있어요.',
        verificationLabel: 'GPS fence + device attestation',
        gpsSummary: '반경 150m 이내',
        audioSummary: '보컬 블록 오디오 일치율 95%',
        privacySummary: '선택적 공개 ZK proof 완료',
        contractSummary: 'smart contract split preview synced',
      ),
      'club-pulse-hapjeong': _ClubScenario(
        distanceMeters: 2380,
        mapPositionX: 0.78,
        mapPositionY: 0.66,
        proofStatus: VenuePresenceProofStatus.unavailable,
        summary: '합정 현장은 현재 세션에서 잠겨 있어요.',
        verificationLabel: 'Proof unavailable',
        gpsSummary: '현장 외 지역',
        audioSummary: '오디오 캡처 없음',
        privacySummary: 'ZK proof 미생성',
        contractSummary: '민팅 자격 잠김',
      ),
    },
    'hapjeong-late': {
      'club-axis-seoul': _ClubScenario(
        distanceMeters: 4860,
        mapPositionX: 0.18,
        mapPositionY: 0.24,
        proofStatus: VenuePresenceProofStatus.unavailable,
        summary: '청담 세션은 종료되어 현장 증명을 만들 수 없어요.',
        verificationLabel: 'out-of-zone · proof locked',
        gpsSummary: '현장 반경 밖',
        audioSummary: '피크타임 세션 종료',
        privacySummary: 'proof 없음',
        contractSummary: '민팅 잠김',
      ),
      'club-signal-hannam': _ClubScenario(
        distanceMeters: 1670,
        mapPositionX: 0.44,
        mapPositionY: 0.30,
        proofStatus: VenuePresenceProofStatus.reviewRequired,
        summary: '한남 클럽은 추가 현장 스캔 후 검증 리뷰가 열립니다.',
        verificationLabel: 'GPS coarse lock · venue QR required',
        gpsSummary: '도보 이동권 밖',
        audioSummary: '라운지 음압 약화',
        privacySummary: 'commitment 유지',
        contractSummary: '정산 미리보기만 제공',
      ),
      'club-pulse-hapjeong': _ClubScenario(
        distanceMeters: 120,
        mapPositionX: 0.66,
        mapPositionY: 0.48,
        proofStatus: VenuePresenceProofStatus.verified,
        summary: '합정 새벽 세션이 열려 검증 리뷰와 민팅 자격이 활성화되었습니다.',
        verificationLabel: 'GPS fence + TEE audio fingerprint',
        gpsSummary: '반경 120m 이내',
        audioSummary: '테크 하우스 핑거프린트 일치율 97%',
        privacySummary: 'ZK anonymity proof shared',
        contractSummary: 'fan reward split preview ready',
      ),
    },
  };

  @override
  SeekerDiscoverySnapshot bootstrap(List<ClubVenue> baseClubs) {
    return switchLocation(baseClubs: baseClubs, presetId: _presets.first.id);
  }

  @override
  SeekerDiscoverySnapshot switchLocation({
    required List<ClubVenue> baseClubs,
    required String presetId,
  }) {
    final preset = _presets.firstWhere((item) => item.id == presetId);
    final scenario = _scenarios[presetId] ?? _scenarios[_presets.first.id]!;
    final updatedClubs = baseClubs
        .map((club) {
          final override = scenario[club.id];
          if (override == null) {
            return club;
          }
          return club.copyWith(
            distanceMeters: override.distanceMeters,
            walkingMinutes: _walkingMinutesFor(override.distanceMeters),
            mapPositionX: override.mapPositionX,
            mapPositionY: override.mapPositionY,
          );
        })
        .toList(growable: false)
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    final proofs = <String, VenuePresenceProof>{
      for (final club in updatedClubs)
        club.id: _proofForClub(
          clubId: club.id,
          scenario: scenario[club.id],
          updatedAt: preset.updatedAt,
        ),
    };

    return SeekerDiscoverySnapshot(
      availableLocations: List<LocationPreset>.unmodifiable(_presets),
      activeLocation: preset,
      clubs: updatedClubs,
      presenceProofs: proofs,
      mapStrategyLabel: 'Korea-first Seeker discovery scaffold',
      mapStrategyDetail:
          '실서비스에서는 기기 attestation, venue beacon, smart-contract settlement SDK를 붙이고 현재는 mock boundary로 GPS / audio / ZK / payout split을 검증합니다.',
    );
  }

  VenuePresenceProof _proofForClub({
    required String clubId,
    required _ClubScenario? scenario,
    required DateTime updatedAt,
  }) {
    final resolvedScenario = scenario ??
        const _ClubScenario(
          distanceMeters: 9999,
          mapPositionX: 0.5,
          mapPositionY: 0.5,
          proofStatus: VenuePresenceProofStatus.unavailable,
          summary: '현장 검증 정보가 아직 없어요.',
          verificationLabel: 'Proof unavailable',
          gpsSummary: 'GPS 세션 없음',
          audioSummary: '오디오 경계 없음',
          privacySummary: 'privacy proof 없음',
          contractSummary: 'contract sync 없음',
        );
    return VenuePresenceProof(
      clubId: clubId,
      status: resolvedScenario.proofStatus,
      summary: resolvedScenario.summary,
      verificationLabel: resolvedScenario.verificationLabel,
      stubBoundary: 'Mock Seeker boundary',
      updatedAt: updatedAt,
      gpsSummary: resolvedScenario.gpsSummary,
      audioSummary: resolvedScenario.audioSummary,
      privacySummary: resolvedScenario.privacySummary,
      contractSummary: resolvedScenario.contractSummary,
      canSubmitReview:
          resolvedScenario.proofStatus == VenuePresenceProofStatus.verified,
    );
  }

  int _walkingMinutesFor(int distanceMeters) {
    final minutes = (distanceMeters / 80).round();
    return minutes <= 0 ? 1 : minutes;
  }
}

class MockSeekerReviewService implements SeekerReviewService {
  const MockSeekerReviewService();

  @override
  VerifiedReview submitVerifiedReview({
    required ClubVenue club,
    required VenuePresenceProof proof,
    required ReviewSubmissionDraft draft,
    required int sequence,
  }) {
    return VerifiedReview(
      id: 'review-${sequence.toString().padLeft(3, '0')}',
      clubId: club.id,
      reviewerAlias: draft.reviewerAlias,
      headline: draft.headline,
      body: draft.body,
      rating: draft.rating,
      submittedAt: DateTime.now(),
      status: draft.rating >= 5
          ? VerifiedReviewStatus.mintedSignal
          : VerifiedReviewStatus.anchored,
      attestationLabel:
          '${proof.verificationLabel} · ${club.residentArtist} set matched',
      privacyLabel: 'ZK selective disclosure + anonymous reviewer handle',
      payoutImpactLabel: '다음 settlement refresh에서 fan reward pool 가중치 반영',
      vibeTags: List<String>.unmodifiable(draft.vibeTags),
    );
  }
}

class MockSeekerSettlementService implements SeekerSettlementService {
  const MockSeekerSettlementService();

  @override
  SettlementScaffoldInfo get scaffoldInfo => const SettlementScaffoldInfo(
        platformLabel: 'iOS / Android only',
        privacyLabel: 'TEE audio + GPS + ZK privacy',
        settlementLabel: 'Mock smart-contract settlement',
        detail:
            '실제 Seeker SDK가 없는 부분은 mock service boundary로 유지하면서, 검증 리뷰 수와 현장 proof 상태에 따라 artist split transparency와 dynamic mint eligibility를 다시 계산합니다.',
      );

  @override
  ArtistSettlement syncSettlement({
    required ArtistSettlement seededSettlement,
    required int verifiedReviewCount,
  }) {
    final addedRewardPool = verifiedReviewCount * 6000;
    final updatedStatus = switch (seededSettlement.status) {
      ArtistSettlementStatus.queued when verifiedReviewCount > 0 =>
        ArtistSettlementStatus.published,
      ArtistSettlementStatus.published when verifiedReviewCount >= 2 =>
        ArtistSettlementStatus.finalized,
      _ => seededSettlement.status,
    };

    return seededSettlement.copyWith(
      verifiedReviewCount: verifiedReviewCount,
      fanRewardPoolWon: seededSettlement.fanRewardPoolWon + addedRewardPool,
      updatedAt: DateTime.now(),
      status: updatedStatus,
      note: updatedStatus == ArtistSettlementStatus.finalized
          ? '검증 리뷰와 현장 proof가 누적되어 fan reward split이 확정됐습니다.'
          : seededSettlement.note,
    );
  }

  @override
  MintEligibility buildMintEligibility({
    required ClubVenue club,
    required VenuePresenceProof proof,
    required List<VerifiedReview> reviews,
    required ArtistSettlement settlement,
  }) {
    final anchoredReviews = reviews.where((review) {
      return review.status == VerifiedReviewStatus.anchored ||
          review.status == VerifiedReviewStatus.mintedSignal;
    }).length;
    final proofReady = proof.status == VenuePresenceProofStatus.verified;

    final score = ((proofReady ? 45 : 10) + (anchoredReviews * 20)).clamp(0, 100);
    final state = switch ((proof.status, anchoredReviews)) {
      (VenuePresenceProofStatus.verified, >= 2) => MintEligibilityState.ready,
      (VenuePresenceProofStatus.verified, _) => MintEligibilityState.warmingUp,
      (VenuePresenceProofStatus.reviewRequired, _) => MintEligibilityState.warmingUp,
      _ => MintEligibilityState.locked,
    };

    final blockers = <String>[
      if (!proofReady) '현장 PoP 재검증 필요',
      if (anchoredReviews < 2) '검증 리뷰 ${2 - anchoredReviews}건 더 필요',
      if (settlement.status == ArtistSettlementStatus.queued) '정산 미리보기 publish 대기 중',
    ];

    final benefits = <String>[
      '민트 가격 ${club.mintPriceWon ~/ 1000}k KRW equivalent',
      'fan reward pool ${settlement.fanRewardPoolWon ~/ 1000}k 공개',
      '${settlement.artistName} 세트 보상 로직 확인 가능',
    ];

    final summary = switch (state) {
      MintEligibilityState.ready => '민팅 자격이 열렸어요. 지금 리뷰와 정산 데이터를 기반으로 패스를 받을 수 있습니다.',
      MintEligibilityState.warmingUp => '거의 준비됐어요. 현장 증명 또는 리뷰 수를 조금만 더 채우면 민팅이 열립니다.',
      MintEligibilityState.locked => '현장 PoP가 잠겨 있어 민팅 자격이 아직 열리지 않았습니다.',
    };

    return MintEligibility(
      clubId: club.id,
      state: state,
      summary: summary,
      eligibilityScore: score,
      mintedSupply: 37 + anchoredReviews,
      totalSupply: 120,
      mintPriceWon: club.mintPriceWon,
      nextRefresh: DateTime.now().add(const Duration(minutes: 14)),
      contractLabel: settlement.contractLabel,
      privacyLabel: proof.privacySummary,
      benefits: List<String>.unmodifiable(benefits),
      blockers: List<String>.unmodifiable(blockers),
    );
  }
}

class MockSeekerWalletService implements SeekerWalletService {
  const MockSeekerWalletService();

  @override
  WalletScaffoldInfo get scaffoldInfo => const WalletScaffoldInfo(
        platformLabel: 'iOS · Android MVP scaffold',
        settlementLabel: 'Mock Seeker wallet rail',
        detail:
            '실제 지갑 연동 전까지 요청 승인·보류 결제·정산 투명성 검증에 필요한 mock wallet rail을 사용합니다.',
      );

  @override
  WalletSettlementReceipt settleSongRequest({required SongRequest request}) {
    return WalletSettlementReceipt(
      reference: 'seek-${request.id}',
      settlementRail: 'Mock wallet hold',
      note: '${request.songTitle} 결제를 mock rail에 보류했습니다.',
      processedAt: DateTime.now(),
    );
  }
}

class _ClubScenario {
  const _ClubScenario({
    required this.distanceMeters,
    required this.mapPositionX,
    required this.mapPositionY,
    required this.proofStatus,
    required this.summary,
    required this.verificationLabel,
    required this.gpsSummary,
    required this.audioSummary,
    required this.privacySummary,
    required this.contractSummary,
  });

  final int distanceMeters;
  final double mapPositionX;
  final double mapPositionY;
  final VenuePresenceProofStatus proofStatus;
  final String summary;
  final String verificationLabel;
  final String gpsSummary;
  final String audioSummary;
  final String privacySummary;
  final String contractSummary;
}
