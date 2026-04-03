import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../viewmodels/root_shell_view_model.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';
import 'discovery_screen.dart';
import 'requests_screen.dart';
import 'user_requests_screen.dart';

class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(rootShellViewModelProvider);
    final controller = ref.read(rootShellViewModelProvider);

    if (viewModel.isInitializing) {
      return const _FullScreenStatus(
        title: '지갑 세션 확인 중',
        description: '저장된 Solana wallet 연결 상태를 복원하고 있어요.',
        child: CircularProgressIndicator(),
      );
    }

    if (!viewModel.isWalletConnected) {
      return _WalletConnectionGate(viewModel: viewModel);
    }

    return switch (viewModel.selectedRole) {
      AppRole.user => _UserShell(
        viewModel: viewModel,
        onDisconnect: controller.disconnectWallet,
      ),
      AppRole.dj =>
        viewModel.isDjOnboardingComplete
            ? _DjShell(
                onSwitchRole: controller.clearRoleSelection,
                onDisconnect: controller.disconnectWallet,
                walletSession: viewModel.walletSession!,
              )
            : _DjOnboardingScreen(
                viewModel: viewModel,
                onSwitchRole: controller.clearRoleSelection,
                onDisconnect: controller.disconnectWallet,
              ),
      null => _RoleSelectionScreen(
        walletSession: viewModel.walletSession!,
        onSelectUser: () => controller.selectRole(AppRole.user),
        onSelectDj: () => controller.selectRole(AppRole.dj),
        onDisconnect: controller.disconnectWallet,
      ),
    };
  }
}

class _FullScreenStatus extends StatelessWidget {
  const _FullScreenStatus({
    required this.title,
    required this.description,
    this.child,
  });

  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SectionCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(description),
                  if (child != null) ...[
                    const SizedBox(height: 20),
                    Center(child: child!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletConnectionGate extends StatelessWidget {
  const _WalletConnectionGate({required this.viewModel});

  final RootShellViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isUnsupported = !viewModel.isWalletSupported;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          key: const Key('wallet-connect-gate'),
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            const SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(
                        label: 'Wallet required',
                        color: AppTheme.accent,
                      ),
                      StatusBadge(
                        label: 'Android-first Solana auth',
                        color: AppTheme.gold,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('지갑 연결 필요'),
                  SizedBox(height: 8),
                  Text(
                    '역할 선택 전에 Solana Mobile Wallet Adapter로 지갑을 연결하고 서명 로그인까지 완료해야 합니다.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUnsupported ? '지원 환경 안내' : 'Android wallet sign-in',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUnsupported
                        ? '현재 호스트에서는 실제 Android wallet 연결을 열 수 없습니다. Android 기기/에뮬레이터 + Mock MWA Wallet 환경에서 테스트하세요.'
                        : '연결 시 authorize 기반으로 지갑 세션을 열고, auth token과 지갑 계정 정보를 로컬에 저장합니다.',
                  ),
                  const SizedBox(height: 16),
                  if (viewModel.walletError case final error?) ...[
                    StatusBadge(label: error, color: AppTheme.danger),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('connect-wallet-button'),
                      onPressed:
                          isUnsupported || viewModel.isAuthenticatingWallet
                          ? null
                          : viewModel.connectWallet,
                      icon: viewModel.isAuthenticatingWallet
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.account_balance_wallet_outlined),
                      label: Text(
                        viewModel.isAuthenticatingWallet
                            ? '지갑 연결 중…'
                            : 'Solana wallet 연결',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelectionScreen extends StatelessWidget {
  const _RoleSelectionScreen({
    required this.walletSession,
    required this.onSelectUser,
    required this.onSelectDj,
    required this.onDisconnect,
  });

  final WalletSession walletSession;
  final VoidCallback onSelectUser;
  final VoidCallback onSelectDj;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(
                        label: 'Wallet connected',
                        color: AppTheme.lime,
                      ),
                      StatusBadge(
                        label: 'One app / two roles',
                        color: AppTheme.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('입장 역할 선택'),
                  const SizedBox(height: 8),
                  Text(
                    '연결된 지갑 ${walletSession.accountLabel ?? walletSession.walletAddressPreview} · ${walletSession.cluster}. 같은 앱 안에서 관객/ DJ shell을 나눠 사용합니다.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const Key('disconnect-wallet-button'),
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.logout),
                    label: const Text('지갑 연결 해제'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _RoleOptionCard(
              buttonKey: const Key('role-select-user'),
              icon: Icons.person_pin_circle_outlined,
              badgeLabel: 'User mode',
              badgeColor: AppTheme.cyan,
              title: '관객으로 입장',
              description:
                  '지갑 로그인 후 서울 클럽 지도를 탐색하고, 클럽 상세에서 신청곡을 보내고, 내 요청 상태를 확인합니다.',
              bulletPoints: const [
                'wallet-auth 후 역할 진입',
                '맵 중심 클럽 발견',
                '클럽 상세 / 요청 작성',
              ],
              buttonLabel: 'User shell 열기',
              onPressed: onSelectUser,
            ),
            const SizedBox(height: 16),
            _RoleOptionCard(
              buttonKey: const Key('role-select-dj'),
              icon: Icons.headphones_outlined,
              badgeLabel: 'DJ mode',
              badgeColor: AppTheme.gold,
              title: 'DJ로 입장',
              description:
                  'DJ 이름 + 클럽 선택 + local/mock club authorization check를 통과한 뒤 승인/거절 운영 화면으로 들어갑니다.',
              bulletPoints: const [
                'wallet-auth + DJ onboarding',
                'mock club roster authorization',
                '승인/거절 액션',
              ],
              buttonLabel: 'DJ onboarding 시작',
              onPressed: onSelectDj,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.buttonKey,
    required this.icon,
    required this.badgeLabel,
    required this.badgeColor,
    required this.title,
    required this.description,
    required this.bulletPoints,
    required this.buttonLabel,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final String badgeLabel;
  final Color badgeColor;
  final String title;
  final String description;
  final List<String> bulletPoints;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(label: badgeLabel, color: badgeColor),
                    const SizedBox(height: 10),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(description),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...bulletPoints.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 8, color: AppTheme.lime),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(bullet)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: buttonKey,
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _DjOnboardingScreen extends ConsumerWidget {
  const _DjOnboardingScreen({
    required this.viewModel,
    required this.onSwitchRole,
    required this.onDisconnect,
  });

  final RootShellViewModel viewModel;
  final VoidCallback onSwitchRole;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubs = ref.watch(clubAppStoreProvider).clubs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DJ onboarding'),
        actions: [
          TextButton.icon(
            key: const Key('role-switch-button'),
            onPressed: onSwitchRole,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('역할 변경'),
          ),
          TextButton.icon(
            key: const Key('disconnect-wallet-button'),
            onPressed: onDisconnect,
            icon: const Icon(Icons.logout),
            label: const Text('지갑 해제'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(label: 'DJ gate', color: AppTheme.gold),
                    StatusBadge(label: 'Local/mock auth', color: AppTheme.cyan),
                  ],
                ),
                SizedBox(height: 16),
                Text('DJ shell 진입 확인'),
                SizedBox(height: 8),
                Text(
                  'DJ 이름, 활동 클럽, mock roster authorization check를 통과해야 DJ approval lane이 열립니다.',
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
                  'Connected wallet: ${viewModel.walletDisplayLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '최근 서명 검증: ${viewModel.walletSession?.lastVerifiedAt?.toLocal() ?? viewModel.walletSession?.connectedAt.toLocal()}',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('dj-onboarding-name-field'),
                  initialValue: viewModel.djName,
                  onChanged: viewModel.updateDjName,
                  decoration: const InputDecoration(
                    labelText: 'DJ 이름',
                    hintText: '예: DJ HYO',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('dj-onboarding-club-dropdown'),
                  initialValue: viewModel.djClubId,
                  items: clubs
                      .map(
                        (club) => DropdownMenuItem<String>(
                          value: club.id,
                          child: Text('${club.name} · ${club.neighborhood}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: viewModel.selectDjClub,
                  decoration: const InputDecoration(labelText: '활동 클럽'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('dj-onboarding-submit'),
                    onPressed: viewModel.canSubmitDjOnboarding
                        ? viewModel.submitDjOnboarding
                        : null,
                    child: viewModel.isCheckingDjAccess
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Mock club authorization 확인'),
                  ),
                ),
                if (viewModel.djAuthorizationStatusLabel
                    case final status?) ...[
                  const SizedBox(height: 16),
                  StatusBadge(
                    label: status,
                    color: viewModel.isDjAuthorized
                        ? AppTheme.lime
                        : AppTheme.danger,
                  ),
                ],
                if (viewModel.djAuthorizationDetail case final detail?) ...[
                  const SizedBox(height: 8),
                  Text(detail),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserShell extends StatelessWidget {
  const _UserShell({required this.viewModel, required this.onDisconnect});

  final RootShellViewModel viewModel;
  final Future<void> Function() onDisconnect;

  static const _pages = [DiscoveryScreen(), UserRequestsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.selectedIndex == 0 ? 'User shell' : '내 요청 상태'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusBadge(
                label: viewModel.walletDisplayLabel,
                color: AppTheme.cyan,
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('role-switch-button'),
            onPressed: viewModel.clearRoleSelection,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('역할 변경'),
          ),
          TextButton.icon(
            key: const Key('disconnect-wallet-button'),
            onPressed: onDisconnect,
            icon: const Icon(Icons.logout),
            label: const Text('지갑 해제'),
          ),
        ],
      ),
      body: _pages[viewModel.selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: viewModel.selectedIndex,
        onDestinationSelected: viewModel.selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined, key: Key('nav-user-discovery')),
            selectedIcon: Icon(
              Icons.map,
              key: Key('nav-user-discovery-selected'),
            ),
            label: '탐색',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.music_note_outlined,
              key: Key('nav-user-requests'),
            ),
            selectedIcon: Icon(
              Icons.music_note,
              key: Key('nav-user-requests-selected'),
            ),
            label: '내 요청',
          ),
        ],
      ),
    );
  }
}

class _DjShell extends StatelessWidget {
  const _DjShell({
    required this.onSwitchRole,
    required this.onDisconnect,
    required this.walletSession,
  });

  final VoidCallback onSwitchRole;
  final Future<void> Function() onDisconnect;
  final WalletSession walletSession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DJ shell'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StatusBadge(
                label:
                    walletSession.accountLabel ??
                    walletSession.walletAddressPreview,
                color: AppTheme.gold,
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('role-switch-button'),
            onPressed: onSwitchRole,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('역할 변경'),
          ),
          TextButton.icon(
            key: const Key('disconnect-wallet-button'),
            onPressed: onDisconnect,
            icon: const Icon(Icons.logout),
            label: const Text('지갑 해제'),
          ),
        ],
      ),
      body: const DjApprovalScreen(),
    );
  }
}
