import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/providers/app_providers.dart';
import 'package:lover_cl/screens/club_detail_screen.dart';
import 'package:lover_cl/screens/discovery_screen.dart';
import 'package:lover_cl/screens/requests_screen.dart';
import 'package:lover_cl/screens/user_requests_screen.dart';
import 'package:lover_cl/state/club_app_store.dart';
import 'package:lover_cl/theme/app_theme.dart';

void main() {
  testWidgets(
    'discovery keeps markers visible and reveals the preview sheet only after a marker tap',
    (tester) async {
      final store = ClubAppStore.seeded();

      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [clubAppStoreProvider.overrideWith((ref) => store)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(body: SafeArea(child: DiscoveryScreen())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('map-marker-club-axis-seoul')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('map-marker-club-signal-hannam')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('club-preview-sheet')), findsNothing);
      expect(find.byKey(const Key('club-preview-open-detail')), findsNothing);

      await tester.tap(find.byKey(const Key('map-marker-club-signal-hannam')));
      await tester.pumpAndSettle();

      expect(store.selectedClubId, 'club-signal-hannam');
      expect(find.byKey(const Key('club-preview-sheet')), findsOneWidget);
      expect(find.text('Signal Hannam'), findsOneWidget);
      expect(find.byKey(const Key('club-preview-open-detail')), findsOneWidget);
    },
  );

  testWidgets('marker preview entry point opens club detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SafeArea(child: DiscoveryScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('map-marker-club-signal-hannam')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('club-preview-open-detail')));
    await tester.pumpAndSettle();

    expect(find.text('현장 손님 곡 요청'), findsOneWidget);
    expect(find.byKey(const Key('club-request-submit')), findsOneWidget);
  });

  testWidgets('club detail submits a new attendee request into store state', (
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
          home: const ClubDetailScreen(clubId: 'club-axis-seoul'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('offer-price-field')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(
      find.byKey(const Key('requester-name-field')),
      'Taylor',
    );
    await tester.enterText(find.byKey(const Key('song-title-field')), 'Saturn');
    await tester.enterText(find.byKey(const Key('artist-name-field')), 'SZA');
    await tester.enterText(find.byKey(const Key('offer-price-field')), '27000');
    await tester.enterText(
      find.byKey(const Key('request-note-field')),
      '보컬 블록 첫 곡으로 부탁해요.',
    );

    await tester.tap(find.byKey(const Key('club-request-submit')));
    await tester.pumpAndSettle();

    expect(store.songRequests.first.songTitle, 'Saturn');
    expect(store.songRequests.first.status.name, 'pendingDjApproval');
    expect(find.text('곡 요청을 보냈어요. DJ 검토 화면에서 바로 확인할 수 있어요.'), findsOneWidget);
  });

  testWidgets('DJ approval screen can approve a pending request', (
    tester,
  ) async {
    final store = ClubAppStore.seeded();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [clubAppStoreProvider.overrideWith((ref) => store)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SafeArea(child: DjApprovalScreen())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('dj-approve-request-001')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('dj-approve-request-001')));
    await tester.pumpAndSettle();

    expect(
      store.songRequests
          .firstWhere((request) => request.id == 'request-001')
          .status
          .name,
      'awaitingUserApproval',
    );
  });

  testWidgets('user request screen can confirm an awaiting request', (
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

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('user-confirm-request-002')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('user-confirm-request-002')));
    await tester.pumpAndSettle();

    expect(
      store.songRequests
          .firstWhere((request) => request.id == 'request-002')
          .status
          .name,
      'queued',
    );
  });
}
