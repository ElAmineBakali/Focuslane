import 'package:flutter/material.dart';

const double kFabAvoidHeight = 96.0;

EdgeInsets safeListPadding(
  BuildContext context, {
  EdgeInsets base = EdgeInsets.zero,
}) {
  final bottom = MediaQuery.of(context).viewPadding.bottom + kFabAvoidHeight;
  return base.copyWith(bottom: (base.bottom) + bottom);
}

EdgeInsets safeScrollPadding(
  BuildContext context, {
  EdgeInsets base = EdgeInsets.zero,
}) {
  final bottom = MediaQuery.of(context).viewPadding.bottom + kFabAvoidHeight;
  return base.copyWith(bottom: (base.bottom) + bottom);
}

class AvoidFabInset extends StatelessWidget {
  final Widget child;
  const AvoidFabInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom + kFabAvoidHeight;
    return Padding(padding: EdgeInsets.only(bottom: bottom), child: child);
  }
}
