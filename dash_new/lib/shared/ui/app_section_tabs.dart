import 'package:flutter/material.dart';
import '../../ui/components/focus_tab_bar.dart';

class AppSectionTabs extends StatelessWidget {
  final TabController controller;
  final List<Tab> tabs;
  final EdgeInsetsGeometry padding;

  const AppSectionTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return FocusTabBar(
      controller: controller,
      tabs: tabs,
      padding: padding,
    );
  }
}
