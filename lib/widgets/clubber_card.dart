import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ClubberCard extends StatelessWidget {
  const ClubberCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.pinkAccent = false,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool pinkAccent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.panel,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: pinkAccent
            ? const Border(
                left: BorderSide(color: AppTheme.pink, width: 3),
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
