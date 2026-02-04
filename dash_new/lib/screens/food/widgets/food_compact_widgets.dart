import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/ui/app_card.dart';
import '../../../shared/ui/app_module_header.dart';
import '../../../shared/ui/app_text_field.dart';
import '../../../shared/ui/app_feedback.dart';
import '../../../theme/focuslane_ui.dart';

class FoodCompactCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double maxHeight;
  final double? maxWidth;
  final Color? background;
  final BorderRadiusGeometry borderRadius;

  const FoodCompactCard({
    super.key,
    required this.child,
    this.padding = FocuslaneUI.cardPaddingCompact,
    this.onTap,
    this.maxHeight = 150,
    this.maxWidth,
    this.background,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(FocuslaneUI.radius),
    ),
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface(
      padding: padding,
      onTap: onTap,
      backgroundColor: background,
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: FocuslaneUI.borderColor(context),
        width: FocuslaneUI.borderW,
      ),
      child: child,
    );

    if (maxHeight == null && maxWidth == null) {
      return surface;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? double.infinity,
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: surface,
    );
  }
}

class FoodCompactTile extends StatelessWidget {
  final Widget? leading;
  final Widget? trailing;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double height;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const FoodCompactTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.height = 44,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveTitleStyle =
        titleStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final effectiveSubtitleStyle =
        subtitleStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.2,
        );

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(height: height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: effectiveTitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: effectiveSubtitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodCompactTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? suffix;
  final bool obscureText;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const FoodCompactTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.obscureText = false,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffix: suffix,
      obscureText: obscureText,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
    );
  }
}

class FoodInlineBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FoodInlineBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 52),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FocuslaneUI.accentSurface(context, opacity: 0.12),
          borderRadius: BorderRadius.circular(FocuslaneUI.radius),
          border: Border.all(
            color: FocuslaneUI.borderColor(context),
            width: FocuslaneUI.borderW,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: FocuslaneUI.accent(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

class FoodModuleTheme extends StatelessWidget {
  final Widget child;
  const FoodModuleTheme({super.key, required this.child});

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
        borderRadius: BorderRadius.circular(FocuslaneUI.radius),
        borderSide: BorderSide(
          color: FocuslaneUI.borderColor(context),
          width: FocuslaneUI.borderW,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FocuslaneUI.radius),
        borderSide: BorderSide(
          color: FocuslaneUI.borderColor(context),
          width: FocuslaneUI.borderW,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FocuslaneUI.radius),
        borderSide: BorderSide(
          color: FocuslaneUI.accent(context),
          width: FocuslaneUI.borderW,
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
        dividerColor: FocuslaneUI.dividerColor(context),
        dividerTheme: DividerThemeData(
          color: FocuslaneUI.dividerColor(context),
          thickness: FocuslaneUI.dividerW,
          space: FocuslaneUI.dividerW,
        ),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: cs.surface,
          foregroundColor: FocuslaneUI.accent(context),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: FocuslaneUI.accent(context).withOpacity(0.25),
          iconTheme: IconThemeData(color: FocuslaneUI.accent(context)),
          titleTextStyle: base.textTheme.titleMedium?.copyWith(
            color: FocuslaneUI.accent(context),
            fontWeight: FontWeight.w700,
          ),
          shape: Border(
            bottom: BorderSide(
              color: FocuslaneUI.dividerColor(context),
              width: FocuslaneUI.dividerW,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: FocuslaneUI.borderColor(context),
              width: FocuslaneUI.borderW,
            ),
            foregroundColor: FocuslaneUI.accent(context),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: FocuslaneUI.accent(context),
            foregroundColor: cs.onPrimary,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: FocuslaneUI.accent(context),
          foregroundColor: cs.onPrimary,
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: FocuslaneUI.accentSurface(
            context,
            opacity: 0.14,
          ),
          selectedColor: FocuslaneUI.accentSurface(
            context,
            opacity: 0.18,
          ),
          side: BorderSide(
            color: FocuslaneUI.borderColor(context),
            width: FocuslaneUI.borderW,
          ),
          labelStyle: base.textTheme.bodySmall?.copyWith(
            color: FocuslaneUI.accent(context),
          ),
        ),
        inputDecorationTheme: input,
        visualDensity: VisualDensity.compact,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cs.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocuslaneUI.radius),
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

class FoodCompactAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showExit;
  final VoidCallback? onExit;

  const FoodCompactAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.showExit = true,
    this.onExit,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return AppModuleHeader(
      title: title,
      subtitle: subtitle,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      showExit: showExit,
      onExit: onExit,
      useSoftGradient: true,
    );
  }
}

class FoodFeedback {
  static void showSuccess(BuildContext context, String message) {
    AppFeedback.showSuccess(context, message);
  }

  static void showError(BuildContext context, String message) {
    AppFeedback.showError(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    AppFeedback.showInfo(context, message);
  }
}
