import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';
import 'focus_card.dart';

class FocusTabBar extends StatelessWidget {
  final TabController controller;
  final List<Tab> tabs;
  final EdgeInsetsGeometry padding;

  const FocusTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.padding = const EdgeInsets.symmetric(
      horizontal: FocuslaneTokens.spacing8,
      vertical: 6,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FocusCard(
      padding: padding,
      child: TabBar(
        controller: controller,
        indicatorColor: FocuslaneTokens.accent(context),
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: Theme.of(context).textTheme.bodySmall,
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        indicatorSize: TabBarIndicatorSize.label,
        tabs: tabs,
      ),
    );
  }
}
