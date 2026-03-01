import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;

  const FocusDivider({
    super.key,
    this.indent,
    this.endIndent,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: FocuslaneTokens.dividerW,
      thickness: FocuslaneTokens.dividerW,
      color: FocuslaneTokens.dividerColor(context),
      indent: indent,
      endIndent: endIndent,
    );
  }
}
