import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class WalletScreen extends SettlementScreen {
  const WalletScreen({super.key});
}

class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusBadge(label: 'Surface removed', color: AppTheme.gold),
              const SizedBox(height: 12),
              Text('정산/지갑 화면은 이번 MVP 범위에서 제거되었어요.', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                '현재 앱은 지도 탐색, 클럽 상세, 곡 요청 제출, DJ 승인, 사용자 최종 확인 흐름만 남겼습니다.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
