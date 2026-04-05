import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/onboarding_screen.dart';
import 'screens/root_shell.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class ClubberApp extends StatelessWidget {
  const ClubberApp({super.key, this.overrides = const []});

  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(overrides: overrides, child: const _AppBootstrap());
  }
}

class _AppBootstrap extends StatelessWidget {
  const _AppBootstrap();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clubber DJ Request MVP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _AppEntry(),
    );
  }
}

enum _AppPhase { splash, onboarding, main }

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  _AppPhase _phase = _AppPhase.splash;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (_phase) {
        _AppPhase.splash => SplashScreen(
            key: const ValueKey('splash'),
            onFinished: () => setState(() => _phase = _AppPhase.onboarding),
          ),
        _AppPhase.onboarding => OnboardingScreen(
            key: const ValueKey('onboarding'),
            onGetStarted: () => setState(() => _phase = _AppPhase.main),
            onSkip: () => setState(() => _phase = _AppPhase.main),
          ),
        _AppPhase.main => const RootShell(key: ValueKey('main')),
      },
    );
  }
}
