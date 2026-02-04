import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class ModuleScaffold extends StatelessWidget {
  final Widget child;

  const ModuleScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final cs = base.colorScheme;
    final input = base.inputDecorationTheme.copyWith(
      filled: true,
      isDense: true,
      fillColor: cs.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
        borderSide: BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
        borderSide: BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
        borderSide: BorderSide(
          color: FocuslaneTokens.accent(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      hintStyle: base.textTheme.bodySmall?.copyWith(
        color: cs.onSurfaceVariant,
      ),
      labelStyle: base.textTheme.bodySmall?.copyWith(
        color: cs.onSurfaceVariant,
      ),
    );

    return Theme(
      data: base.copyWith(
        dividerColor: FocuslaneTokens.dividerColor(context),
        dividerTheme: DividerThemeData(
          color: FocuslaneTokens.dividerColor(context),
          thickness: FocuslaneTokens.dividerW,
          space: FocuslaneTokens.dividerW,
        ),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: cs.surface,
          foregroundColor: FocuslaneTokens.accent(context),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: FocuslaneTokens.accent(context).withOpacity(0.25),
          iconTheme: IconThemeData(color: FocuslaneTokens.accent(context)),
          titleTextStyle: base.textTheme.titleMedium?.copyWith(
            color: FocuslaneTokens.accent(context),
            fontWeight: FontWeight.w700,
          ),
          shape: Border(
            bottom: BorderSide(
              color: FocuslaneTokens.dividerColor(context),
              width: FocuslaneTokens.dividerW,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: FocuslaneTokens.borderColor(context),
              width: FocuslaneTokens.borderW,
            ),
            foregroundColor: FocuslaneTokens.accent(context),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: FocuslaneTokens.accent(context),
            foregroundColor: cs.onPrimary,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: FocuslaneTokens.accent(context),
          foregroundColor: cs.onPrimary,
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: FocuslaneTokens.accentSurface(
            context,
            opacity: 0.14,
          ),
          selectedColor: FocuslaneTokens.accentSurface(
            context,
            opacity: 0.18,
          ),
          side: BorderSide(
            color: FocuslaneTokens.borderColor(context),
            width: FocuslaneTokens.borderW,
          ),
          labelStyle: base.textTheme.bodySmall?.copyWith(
            color: FocuslaneTokens.accent(context),
          ),
        ),
        inputDecorationTheme: input,
        visualDensity: VisualDensity.compact,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cs.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
          ),
          contentTextStyle: base.textTheme.bodySmall?.copyWith(
            color: cs.onSurface,
          ),
        ),
      ),
      child: child,
    );
  }
}
