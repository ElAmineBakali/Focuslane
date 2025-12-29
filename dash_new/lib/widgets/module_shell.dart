import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/global_ui_theme.dart';
import 'global_ui_components.dart';

/// Shared shell for module home screens to avoid duplicating the SliverAppBar + scaffold layout.
class FocusModuleShell extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Widget body;
  final List<Widget>? actions;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry bodyPadding;
  final double expandedHeight;
  final double iconSize;
  final double iconOpacity;
  final Alignment iconAlignment;
  final Widget? floatingActionButton;

  const FocusModuleShell({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.body,
    this.actions,
    this.gradientColors,
    this.bodyPadding = const EdgeInsets.all(FocusSpacing.lg),
    this.expandedHeight = 200,
    this.iconSize = 120,
    this.iconOpacity = 0.1,
    this.iconAlignment = Alignment.topRight,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors =
        gradientColors ??
        <Color>[
          colorScheme.primaryContainer,
          colorScheme.secondaryContainer.withOpacity(0.8),
        ];

    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: expandedHeight,
            pinned: true,
            stretch: true,
            backgroundColor: colors.first,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
                child: Align(
                  alignment: iconAlignment,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 40),
                    child: Icon(
                      titleIcon,
                      size: iconSize,
                      color: Colors.white.withOpacity(iconOpacity),
                    ),
                  ),
                ),
              ),
            ),
            actions: actions,
          ),
          SliverToBoxAdapter(child: Padding(padding: bodyPadding, child: body)),
        ],
      ),
    );
  }
}
