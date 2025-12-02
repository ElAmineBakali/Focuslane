import 'package:flutter/material.dart';

double screenPad(BuildContext context, {double extra = 24}) {
  final vInsets = MediaQuery.of(context).viewInsets.bottom;   
  final vPad    = MediaQuery.of(context).viewPadding.bottom;
  return extra + vPad + (vInsets > 0 ? 12 : 0);
}

class PaddedListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? topLeftRight;
  const PaddedListView({super.key, required this.children, this.topLeftRight});

  @override
  Widget build(BuildContext context) {
    final base = topLeftRight ?? const EdgeInsets.fromLTRB(12, 12, 12, 0);
    return ListView(
      padding: base.add(EdgeInsets.only(bottom: screenPad(context))),
      children: children,
    );
  }
}

class TaskFormTheme extends StatelessWidget {
  final Widget child;
  const TaskFormTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cs.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant.withOpacity(.4)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: cs.secondary)),
      ),
      child: child,
    );
  }
}
