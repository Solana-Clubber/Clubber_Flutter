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

    await tester.scrollUntilVisible(
      find.text('큐에 반영됨'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('관객 요청 상태'), findsOneWidget);
    expect(find.text('DJ 검토 중'), findsWidgets);
    expect(find.text('내 최종 확인 필요'), findsOneWidget);
    expect(find.text('큐에 반영됨'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('user-confirm-request-002')),
      findsOneWidget,
    );
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
    expect(find.text('양측 승인 완료로 전환했어요.'), findsOneWidget);
  });
}
