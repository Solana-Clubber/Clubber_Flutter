import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/dj_club_authorization_service.dart';
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
