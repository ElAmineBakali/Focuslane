import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final EdgeInsetsGeometry padding;
  final IconData? icon;
  final bool isExpanded;
  final bool isCompact;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.icon,
    this.isExpanded = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final compactPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
    
    return Container(
      padding: isCompact ? compactPadding : padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerLow,
            cs.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null && !isCompact) ...[
            Icon(icon, size: isMobile ? 18 : 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isDense: isCompact,
                isExpanded: isCompact ? false : isExpanded,
                value: value,
                items: items,
                onChanged: onChanged,
                dropdownColor: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurfaceVariant, size: isCompact ? 18 : (isMobile ? 20 : 22)),
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: isCompact ? 13 : (isMobile ? 14 : 15),
                  fontWeight: FontWeight.w500,
                ),
                hint: hint != null
                    ? Text(
                        hint!,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: isCompact ? 13 : (isMobile ? 14 : 15),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
