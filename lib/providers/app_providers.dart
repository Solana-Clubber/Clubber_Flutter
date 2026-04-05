import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/acr_cloud_service.dart';
import '../services/dj_club_authorization_service.dart';
import '../services/escrow_service.dart';
import '../services/local_config_loader.dart';
import '../services/solana_mobile_wallet_service.dart';
import '../services/wallet_session_store.dart';
import '../state/club_app_store.dart';
import '../viewmodels/root_shell_view_model.dart';

final clubAppStoreProvider = ChangeNotifierProvider<ClubAppStore>((ref) {
  return ClubAppStore.seeded();
});

final solanaMobileWalletServiceProvider = Provider<SolanaMobileWalletService>((
  ref,
) {
  return const SolanaMobileWalletService();
});

final walletSessionStoreProvider = Provider<WalletSessionStore>((ref) {
  return SharedPreferencesWalletSessionStore();
});

final djClubAuthorizationServiceProvider = Provider<DjClubAuthorizationService>(
  (ref) {
    return const MockDjClubAuthorizationService();
  },
);

final rootShellViewModelProvider = ChangeNotifierProvider<RootShellViewModel>((
  ref,
) {
  return RootShellViewModel(
    walletService: ref.watch(solanaMobileWalletServiceProvider),
    walletSessionStore: ref.watch(walletSessionStoreProvider),
    djClubAuthorizationService: ref.watch(djClubAuthorizationServiceProvider),
  );
});

/// Async provider that loads config then creates EscrowService.
/// Returns null if programId is empty (no program deployed yet).
final escrowServiceProvider = FutureProvider<EscrowService?>((ref) async {
  final config = await loadLocalConfig();
  if (config.programId.isEmpty) return null;
  return EscrowService(programId: config.programId, rpcUrl: config.rpcUrl);
});

/// AcrCloudService singleton — initialized lazily on first use in screens.
final acrCloudServiceProvider = Provider<AcrCloudService>((ref) {
  return AcrCloudService();
});
