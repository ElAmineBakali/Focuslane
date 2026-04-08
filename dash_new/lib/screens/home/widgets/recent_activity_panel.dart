import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_dashboard_personal/design/ui/tokens/focuslane_semantic_tokens.dart';
import 'package:mi_dashboard_personal/screens/notes/note_model.dart';

class RecentActivityPanel extends StatelessWidget {
  const RecentActivityPanel({
    super.key,
    required this.notes,
    required this.onOpenNotes,
  });

  final List<Note> notes;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Text(
        'Aun no hay actividad reciente en notas.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      children: notes
          .map(
            (note) => ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: onOpenNotes,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: FocuslaneSemanticTokens.primary(context).withOpacity(0.15),
                child: Icon(Icons.note_alt_outlined, size: 16, color: FocuslaneSemanticTokens.primary(context)),
              ),
              title: Text(
                note.title.isEmpty ? 'Nota sin titulo' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                DateFormat('d MMM, HH:mm', 'es_ES').format(note.lastEditedAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: FocuslaneSemanticTokens.textSecondary(context)),
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          )
          .toList(growable: false),
    );
  }
}
