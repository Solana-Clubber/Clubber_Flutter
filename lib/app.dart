import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/root_shell.dart';
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
      home: const RootShell(),
    );
  }
}
