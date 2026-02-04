import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget>? actions;

  const FocusDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
        side: BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
    );
  }
}

Future<T?> showFocusBottomSheet<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(FocuslaneTokens.radius20),
          ),
          border: Border.all(
            color: FocuslaneTokens.borderColor(context),
            width: FocuslaneTokens.borderW,
          ),
        ),
        child: SafeArea(
          child: child,
        ),
      );
    },
  );
}
