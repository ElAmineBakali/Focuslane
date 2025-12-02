import 'package:flutter/material.dart';

class KpiCompact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  const KpiCompact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 480;
    final w =
        isNarrow ? (MediaQuery.of(context).size.width - 16 - 12) / 2 : 220.0;

    return SizedBox(
      width: w,
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(sub!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
