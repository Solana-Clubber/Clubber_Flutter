import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../viewmodels/root_shell_view_model.dart';
import '../widgets/clubber_card.dart';
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
      return const _FullScreenLoading();
    }

    if (!viewModel.isWalletConnected) {
      return _WalletConnectionGate(viewModel: viewModel);
    }

    return switch (viewModel.selectedRole) {
      AppRole.user => _UserShell(
        viewModel: viewModel,
        onSwitchRole: controller.clearRoleSelection,
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

class _FullScreenLoading extends StatelessWidget {
  const _FullScreenLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.pink),
      ),
    );
  }
}

// ─── Wallet Connection Gate ───────────────────────────────────────────────────

class _WalletConnectionGate extends StatelessWidget {
  const _WalletConnectionGate({required this.viewModel});

  final RootShellViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isUnsupported = !viewModel.isWalletSupported;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            key: const Key('wallet-connect-gate'),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Text(
                  'CLUBBER',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.pink,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to continue your nightlife journey',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(height: 64),
                // Error text
                if (viewModel.walletError case final error?) ...[
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Connect button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    key: const Key('connect-wallet-button'),
                    onPressed:
                        isUnsupported || viewModel.isAuthenticatingWallet
                        ? null
                        : viewModel.connectWallet,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.pink,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      ),
                    ),
                    child: viewModel.isAuthenticatingWallet
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Continue with Seeker',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Role Selection ───────────────────────────────────────────────────────────

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
    final addressLabel =
        walletSession.accountLabel ?? walletSession.walletAddressPreview;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet badge
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    addressLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Choose your role',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You can switch roles at any time.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey,
                ),
              ),
              const SizedBox(height: 32),
              // Role cards
              _RoleCard(
                buttonKey: const Key('role-select-user'),
                icon: Icons.person_outline,
                title: 'Guest',
                description: 'Explore clubs, discover events, and send song requests.',
                onTap: onSelectUser,
              ),
              const SizedBox(height: 16),
              _RoleCard(
                buttonKey: const Key('role-select-dj'),
                icon: Icons.headphones_outlined,
                title: 'DJ',
                description: 'Manage requests, control the queue, and run the night.',
                onTap: onSelectDj,
              ),
              const Spacer(),
              // Disconnect
              Center(
                child: TextButton(
                  key: const Key('disconnect-wallet-button'),
                  onPressed: onDisconnect,
                  child: const Text('Disconnect wallet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.buttonKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Key buttonKey;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(
      key: buttonKey,
      pinkAccent: true,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.pink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.pink, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DJ Onboarding ────────────────────────────────────────────────────────────

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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('role-switch-button'),
                    onPressed: onSwitchRole,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: AppTheme.white,
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('disconnect-wallet-button'),
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.logout, size: 20),
                    color: AppTheme.grey,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  // Icon illustration
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.pink.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_outlined,
                        color: AppTheme.pink,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Join the Stage',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your DJ profile to start managing requests.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.grey,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Form
                  TextFormField(
                    key: const Key('dj-onboarding-name-field'),
                    initialValue: viewModel.djName,
                    onChanged: viewModel.updateDjName,
                    style: const TextStyle(color: AppTheme.white),
                    decoration: const InputDecoration(
                      labelText: 'DJ Name',
                      hintText: 'e.g. DJ HYO',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('dj-onboarding-club-dropdown'),
                    initialValue: viewModel.djClubId,
                    dropdownColor: AppTheme.panel,
                    style: const TextStyle(color: AppTheme.white),
                    items: clubs
                        .map(
                          (club) => DropdownMenuItem<String>(
                            value: club.id,
                            child: Text('${club.name} · ${club.neighborhood}'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: viewModel.selectDjClub,
                    decoration: const InputDecoration(
                      labelText: 'Club',
                      prefixIcon: Icon(Icons.nightlife_outlined, color: AppTheme.grey),
                    ),
                  ),
                  if (viewModel.djAuthorizationStatusLabel case final status?) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (viewModel.isDjAuthorized
                                ? AppTheme.green
                                : AppTheme.red)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: viewModel.isDjAuthorized
                              ? AppTheme.green
                              : AppTheme.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (viewModel.djAuthorizationDetail case final detail?) ...[
                      const SizedBox(height: 6),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      key: const Key('dj-onboarding-submit'),
                      onPressed: viewModel.canSubmitDjOnboarding
                          ? () async {
                              await viewModel.submitDjOnboarding();
                              if (viewModel.isDjOnboardingComplete &&
                                  viewModel.walletSession != null) {
                                ref
                                    .read(clubAppStoreProvider)
                                    .setDjWalletForClub(
                                      viewModel.djClubId!,
                                      viewModel.walletSession!.publicKeyBase58,
                                    );
                              }
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.pink,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                        ),
                      ),
                      child: viewModel.isCheckingDjAccess
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Submit Application',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
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

// ─── User Shell ───────────────────────────────────────────────────────────────

class _UserShell extends StatelessWidget {
  const _UserShell({
    required this.viewModel,
    required this.onSwitchRole,
    required this.onDisconnect,
  });

  final RootShellViewModel viewModel;
  final VoidCallback onSwitchRole;
  final Future<void> Function() onDisconnect;

  static const _pages = [
    DiscoveryScreen(),
    DiscoveryScreen(), // Search tab placeholder
    UserRequestsScreen(),
    _ProfilePlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar with wallet info + switch/disconnect
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          viewModel.walletDisplayLabel,
                          style: const TextStyle(color: AppTheme.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('role-switch-button'),
                    icon: const Icon(Icons.swap_horiz, color: AppTheme.pink),
                    onPressed: onSwitchRole,
                    tooltip: 'Switch role',
                  ),
                  IconButton(
                    key: const Key('disconnect-wallet-button'),
                    icon: const Icon(Icons.logout, color: AppTheme.grey),
                    onPressed: onDisconnect,
                    tooltip: 'Disconnect',
                  ),
                ],
              ),
            ),
            Expanded(child: _pages[viewModel.selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: _UserBottomNav(
        selectedIndex: viewModel.selectedIndex,
        onTap: viewModel.selectTab,
      ),
    );
  }
}

class _UserBottomNav extends StatelessWidget {
  const _UserBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Home', key: 'nav-user-discovery'),
    _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search'),
    _NavItem(icon: Icons.music_note_outlined, activeIcon: Icons.music_note, label: 'Requests', key: 'nav-user-requests'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppTheme.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 8 + bottomPad),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final selected = i == selectedIndex;
                return Expanded(
                  child: GestureDetector(
                    key: item.key != null ? Key(item.key!) : null,
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected ? AppTheme.pink : AppTheme.grey,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? AppTheme.pink : AppTheme.grey,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.key,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? key;
}

// ─── DJ Shell ─────────────────────────────────────────────────────────────────

class _DjShell extends StatefulWidget {
  const _DjShell({
    required this.onSwitchRole,
    required this.onDisconnect,
    required this.walletSession,
  });

  final VoidCallback onSwitchRole;
  final Future<void> Function() onDisconnect;
  final WalletSession walletSession;

  @override
  State<_DjShell> createState() => _DjShellState();
}

class _DjShellState extends State<_DjShell> {
  int _selectedIndex = 0;

  static const _pages = [
    DjApprovalScreen(),
    _QueuePlaceholder(),
    _InboxPlaceholder(),
    _SettingsPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    final djLabel =
        widget.walletSession.accountLabel ??
        widget.walletSession.walletAddressPreview;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Minimal header with DJ badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              child: Row(
                children: [
                  // DJ name badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.pink.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.headphones,
                          color: AppTheme.pink,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          djLabel,
                          style: const TextStyle(
                            color: AppTheme.pink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const Key('role-switch-button'),
                    onPressed: widget.onSwitchRole,
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    color: AppTheme.grey,
                  ),
                  IconButton(
                    key: const Key('disconnect-wallet-button'),
                    onPressed: widget.onDisconnect,
                    icon: const Icon(Icons.logout, size: 20),
                    color: AppTheme.grey,
                  ),
                ],
              ),
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder Screens ──────────────────────────────────────────────────────

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile',
        style: TextStyle(color: AppTheme.grey),
      ),
    );
  }
}

class _QueuePlaceholder extends StatelessWidget {
  const _QueuePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Queue',
        style: TextStyle(color: AppTheme.grey),
      ),
    );
  }
}

class _InboxPlaceholder extends StatelessWidget {
  const _InboxPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Inbox',
        style: TextStyle(color: AppTheme.grey),
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Settings',
        style: TextStyle(color: AppTheme.grey),
      ),
    );
  }
}
