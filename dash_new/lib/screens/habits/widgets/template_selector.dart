import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_constants.dart';

/// Selector de plantillas predefinidas
class TemplateSelector extends StatelessWidget {
  final Function(HabitTemplate) onSelect;

  const TemplateSelector({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plantillas de hábitos',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Elige una plantilla para empezar rápido',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Lista de plantillas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: HabitTemplates.templates.length,
                itemBuilder: (context, index) {
                  final template = HabitTemplates.templates[index];
                  final color = Color(int.parse(template.colorHex));

                  return Card(
                    elevation: 0,
                    color: cs.surfaceContainerHigh,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                    ),
                    child: InkWell(
                      onTap: () {
                        onSelect(template);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 14 : 16),
                        child: Row(
                          children: [
                            // Icono/Emoji
                            Container(
                              width: isMobile ? 50 : 56,
                              height: isMobile ? 50 : 56,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child:
                                    template.emoji != null
                                        ? Text(
                                          template.emoji!,
                                          style: TextStyle(
                                            fontSize: isMobile ? 24 : 28,
                                          ),
                                        )
                                        : Icon(
                                          HabitIcons.getIcon(template.iconCode),
                                          color: color,
                                          size: isMobile ? 26 : 30,
                                        ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Información
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.name,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isMobile ? 15 : 16,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    template.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: isMobile ? 12 : 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (template.suggestedTags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children:
                                          template.suggestedTags.take(3).map((
                                            tag,
                                          ) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: color.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                tag,
                                                style: TextStyle(
                                                  fontSize: isMobile ? 10 : 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: color,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Indicador
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: isMobile ? 16 : 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
