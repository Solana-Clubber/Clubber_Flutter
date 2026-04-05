import 'package:flutter/material.dart';

import 'clubber_card.dart';

/// Legacy wrapper — delegates to [ClubberCard].
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClubberCard(padding: padding, child: child);
  }
}
