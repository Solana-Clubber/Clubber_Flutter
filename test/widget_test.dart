import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lover_cl/models/models.dart';
import 'package:lover_cl/services/solana_mobile_wallet_service.dart';

import 'test_helpers/root_shell_harness.dart';

void main() {
  testWidgets('starts on wallet gate flow before role selection', (
    tester,
  ) async {
    await tester.pumpWidget(buildRootShellHarness());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('connect-wallet-button')), findsOneWidget);
    expect(find.byKey(const Key('role-select-user')), findsNothing);
    expect(find.byKey(const Key('role-select-dj')), findsNothing);
    expect(find.byKey(const Key('nav-user-discovery')), findsNothing);
    expect(find.byKey(const Key('nav-dj-approval')), findsNothing);
  });

  testWidgets('opens the user shell with map-first discovery surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRootShellHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('connect-wallet-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('role-select-user')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map-marker-club-axis-seoul')), findsOneWidget);
    expect(find.byKey(const Key('club-preview-sheet')), findsNothing);
    expect(find.byKey(const Key('nav-user-requests')), findsOneWidget);
    expect(find.byKey(const Key('nav-user-discovery')), findsOneWidget);
    expect(find.byKey(const Key('nav-dj-approval')), findsNothing);
  });

  testWidgets('wallet gate recovers after a cancelled wallet connect attempt', (
    tester,
  ) async {
    final walletService = HarnessWalletService();
    final cancelledAttempt = Completer<WalletSession?>();
    walletService.onConnect = (_) => cancelledAttempt.future;

    await tester.pumpWidget(
      buildRootShellHarness(walletService: walletService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('connect-wallet-button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    cancelledAttempt.complete(null);
    await tester.pumpAndSettle();

    expect(find.text('지갑 승인이 취소되었거나 연결이 완료되지 않았습니다.'), findsOneWidget);
    expect(find.byKey(const Key('connect-wallet-button')), findsOneWidget);

    walletService.onConnect = null;

    await tester.tap(find.byKey(const Key('connect-wallet-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('role-select-user')), findsOneWidget);
  });

  testWidgets('wallet gate recovers after a timeout-style wallet failure', (
    tester,
  ) async {
    final walletService = HarnessWalletService();
    walletService.onConnect = (_) async {
      throw const WalletConnectionException(
        'Timed out waiting for wallet approval.',
      );
    };

    await tester.pumpWidget(
      buildRootShellHarness(walletService: walletService),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('connect-wallet-button')));
    await tester.pumpAndSettle();

    expect(find.text('Timed out waiting for wallet approval.'), findsOneWidget);
    expect(find.byKey(const Key('connect-wallet-button')), findsOneWidget);

    walletService.onConnect = null;

    await tester.tap(find.byKey(const Key('connect-wallet-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('role-select-user')), findsOneWidget);
  });

  testWidgets(
    'user shell can open club detail from the map marker preview entry point',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildRootShellHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('connect-wallet-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('role-select-user')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('map-marker-club-axis-seoul')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('club-preview-open-detail')));
      await tester.pumpAndSettle();

      expect(find.text('Request a Song'), findsOneWidget);
    },
  );

  testWidgets('opens the DJ shell after wallet auth and DJ onboarding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildRootShellHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('connect-wallet-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('role-select-dj')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('dj-onboarding-name-field')),
      'Kana',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('dj-onboarding-club-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Axis Seoul · 청담').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dj-onboarding-submit')));
    await tester.pumpAndSettle();

    expect(find.text('DJ Mode'), findsOneWidget);
    expect(find.byKey(const Key('role-switch-button')), findsOneWidget);
    expect(find.byKey(const Key('disconnect-wallet-button')), findsOneWidget);
    expect(find.byKey(const Key('nav-user-discovery')), findsNothing);
    expect(find.byKey(const Key('nav-user-requests')), findsNothing);
  });
}
