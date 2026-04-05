import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/providers/app_providers.dart';
import 'package:lover_cl/screens/user_requests_screen.dart';
import 'package:lover_cl/state/club_app_store.dart';
import 'package:lover_cl/theme/app_theme.dart';

void main() {
  testWidgets('user requests screen shows the user-side review sections', (
    tester,
  ) async {
    final store = ClubAppStore.seeded();

    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [clubAppStoreProvider.overrideWith((ref) => store)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SafeArea(child: UserRequestsScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Requests'), findsOneWidget);
    expect(find.text('Track your song requests in real time'), findsOneWidget);
  });

  testWidgets('user requests screen confirms an awaiting-user request', (
    tester,
  ) async {
    final store = ClubAppStore.seeded();

    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [clubAppStoreProvider.overrideWith((ref) => store)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SafeArea(child: UserRequestsScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // request-002 is in 'accepted' state — verify it's tracked in the store
    expect(
      store.songRequests
          .firstWhere((request) => request.id == 'request-002')
          .status
          .name,
      'accepted',
    );
  });
}
