import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_routes.dart';

import '../models/note_model.dart';
import '../services/note_firestore_service.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  bool _grid = false;
  final Set<String> _tagFilter = {};
  NotesSortField _sortField = NotesSortField.lastEditedAt;
  NotesSortDirection _sortDirection = NotesSortDirection.descending;

  bool get _isDescending => _sortDirection == NotesSortDirection.descending;

  int _compareBySortField(Note a, Note b) {
    switch (_sortField) {
      case NotesSortField.createdAt:
        return a.createdAt.compareTo(b.createdAt);
      case NotesSortField.title:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case NotesSortField.lastEditedAt:
        return a.lastEditedAt.compareTo(b.lastEditedAt);
    }
  }

  List<Note> _applyFilters(List<Note> notes) {
    var list = notes.toList(growable: false);
    if (_tagFilter.isNotEmpty) {
      list = list
          .where((note) => _tagFilter.every((tag) => note.tags.contains(tag)))
          .toList(growable: false);
    }

    list.sort((a, b) {
      final base = _compareBySortField(a, b);
      if (base != 0) return _isDescending ? -base : base;
      final tie = a.createdAt.compareTo(b.createdAt);
      return _isDescending ? -tie : tie;
    });

    final pinned = list.where((note) => note.isPinned).toList(growable: false);
    final unpinned = list
        .where((note) => !note.isPinned)
        .toList(growable: false);
    return [...pinned, ...unpinned];
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Notas',
      subtitle: 'Un espacio limpio para ideas, apuntes y borradores.',
      activeRoute: AppRoutes.notesDashboard,
      child: StreamBuilder<List<Note>>(
        stream: NoteFirestoreService.getNotes(
          sortField: _sortField,
          direction: _sortDirection,
        ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return PageContainer(
              child: FocusEmptyState(
                icon: Icons.error_outline_rounded,
                message: 'Error cargando notas',
                subtitle: 'No se pudo obtener la lista en este momento.',
                actionLabel: 'Reintentar',
                onAction: () => setState(() {}),
              ),
            );
          }

          final notes = _applyFilters(snap.data ?? const <Note>[]);
          return _NotesWorkspace(
            notes: notes,
            grid: _grid,
            sortField: _sortField,
            sortDirection: _sortDirection,
            onGridChanged: (value) => setState(() => _grid = value),
            onSortFieldChanged: (value) => setState(() => _sortField = value),
            onSortDirectionChanged:
                (value) => setState(() => _sortDirection = value),
          );
        },
      ),
    );
  }
}

class _NotesWorkspace extends StatelessWidget {
  const _NotesWorkspace({
    required this.notes,
    required this.grid,
    required this.sortField,
    required this.sortDirection,
    required this.onGridChanged,
    required this.onSortFieldChanged,
    required this.onSortDirectionChanged,
  });

  final List<Note> notes;
  final bool grid;
  final NotesSortField sortField;
  final NotesSortDirection sortDirection;
  final ValueChanged<bool> onGridChanged;
  final ValueChanged<NotesSortField> onSortFieldChanged;
  final ValueChanged<NotesSortDirection> onSortDirectionChanged;

  @override
  Widget build(BuildContext context) {
    final pinnedCount = notes.where((note) => note.isPinned).length;
    final editedToday = notes.where(_editedToday).length;

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotesHeader(
              notesCount: notes.length,
              pinnedCount: pinnedCount,
              editedToday: editedToday,
              grid: grid,
              onNewNote: () => Navigator.pushNamed(context, '/notes/editor'),
              onGridChanged: onGridChanged,
            ),
            SizedBox(height: FocuslaneTokens.pageGapFor(context)),
            _NotesControls(
              sortField: sortField,
              sortDirection: sortDirection,
              grid: grid,
              onSortFieldChanged: onSortFieldChanged,
              onSortDirectionChanged: onSortDirectionChanged,
              onGridChanged: onGridChanged,
            ),
            SizedBox(height: FocuslaneTokens.pageGapFor(context)),
            if (notes.isEmpty)
              FocusCard(
                child: FocusEmptyState(
                  icon: Icons.note_add_outlined,
                  message: 'No hay notas todavia',
                  subtitle: 'Crea tu primera nota para empezar tu espacio.',
                  actionLabel: 'Nueva nota',
                  onAction: () => Navigator.pushNamed(context, '/notes/editor'),
                ),
              )
            else if (grid)
              ResponsiveGrid(
                minItemWidth: 240,
                spacing: FocuslaneTokens.gridGapFor(context),
                children: [
                  for (final note in notes)
                    _NoteCard(key: ValueKey(note.id), note: note),
                ],
              )
            else
              Column(
                children: [
                  for (int index = 0; index < notes.length; index++) ...[
                    _NoteTile(
                      key: ValueKey(notes[index].id),
                      note: notes[index],
                    ),
                    if (index != notes.length - 1)
                      SizedBox(height: FocuslaneTokens.pageGapFor(context)),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NotesHeader extends StatelessWidget {
  const _NotesHeader({
    required this.notesCount,
    required this.pinnedCount,
    required this.editedToday,
    required this.grid,
    required this.onNewNote,
    required this.onGridChanged,
  });

  final int notesCount;
  final int pinnedCount;
  final int editedToday;
  final bool grid;
  final VoidCallback onNewNote;
  final ValueChanged<bool> onGridChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      backgroundColor: scheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FocusPrimaryButton(
                label: 'Nueva nota',
                icon: Icons.edit_note_rounded,
                onPressed: onNewNote,
              ),
              FocusSecondaryButton(
                label: grid ? 'Vista lista' : 'Vista cuadricula',
                icon:
                    grid
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_outlined,
                onPressed: () => onGridChanged(!grid),
              ),
            ],
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Revisa tus apuntes recientes con una lista clara y un editor centrado en escribir.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FocusBadge(label: '$notesCount notas', color: scheme.primary),
                  FocusBadge(
                    label: '$pinnedCount fijadas',
                    color: scheme.secondary,
                  ),
                  FocusBadge(
                    label: '$editedToday editadas hoy',
                    color: scheme.tertiary,
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _NotesControls extends StatelessWidget {
  const _NotesControls({
    required this.sortField,
    required this.sortDirection,
    required this.grid,
    required this.onSortFieldChanged,
    required this.onSortDirectionChanged,
    required this.onGridChanged,
  });

  final NotesSortField sortField;
  final NotesSortDirection sortDirection;
  final bool grid;
  final ValueChanged<NotesSortField> onSortFieldChanged;
  final ValueChanged<NotesSortDirection> onSortDirectionChanged;
  final ValueChanged<bool> onGridChanged;

  bool get _isDescending => sortDirection == NotesSortDirection.descending;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FocusCard(
      padding: FocuslaneTokens.cardPaddingFor(context),
      elevated: false,
      backgroundColor: scheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final sortDropdown = SizedBox(
            width: compact ? double.infinity : 220,
            child: DropdownButtonFormField<NotesSortField>(
              initialValue: sortField,
              decoration: _controlDecoration(
                context,
                label: 'Ordenar por',
                icon: Icons.sort_rounded,
              ),
              items: const [
                DropdownMenuItem(
                  value: NotesSortField.lastEditedAt,
                  child: Text('Ultima edicion'),
                ),
                DropdownMenuItem(
                  value: NotesSortField.createdAt,
                  child: Text('Fecha de creacion'),
                ),
                DropdownMenuItem(
                  value: NotesSortField.title,
                  child: Text('Alfabetico'),
                ),
              ],
              onChanged: (value) {
                if (value != null) onSortFieldChanged(value);
              },
            ),
          );
          final iconControls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FocusIconButton(
                icon:
                    _isDescending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                tooltip: _isDescending ? 'Descendente' : 'Ascendente',
                isActive: true,
                onPressed:
                    () => onSortDirectionChanged(
                      _isDescending
                          ? NotesSortDirection.ascending
                          : NotesSortDirection.descending,
                    ),
              ),
              const SizedBox(width: 10),
              FocusIconButton(
                icon:
                    grid
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view_outlined,
                tooltip: grid ? 'Vista lista' : 'Vista cuadricula',
                isActive: grid,
                onPressed: () => onGridChanged(!grid),
              ),
            ],
          );
          final controls = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [sortDropdown, iconControls],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FocusSectionHeader(
                  title: 'Espacio',
                  subtitle: 'Orden y tipo de vista',
                  icon: Icons.dashboard_customize_rounded,
                ),
                SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
                sortDropdown,
                const SizedBox(height: 10),
                iconControls,
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                child: FocusSectionHeader(
                  title: 'Espacio',
                  subtitle: 'Orden y tipo de vista',
                  icon: Icons.dashboard_customize_rounded,
                ),
              ),
              const SizedBox(width: 16),
              controls,
            ],
          );
        },
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = _preview(note, lines: 3);
    final lastUpdate = DateFormat(
      'dd MMM yyyy · HH:mm',
      'es_ES',
    ).format(note.lastEditedAt);

    return FocusCard(
      onTap:
          () => Navigator.pushNamed(context, '/notes/editor', arguments: note),
      backgroundColor: scheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final visual = _NoteVisual(note: note, compact: compact);
          final content = _NoteTextBlock(
            note: note,
            preview: preview,
            lastUpdate: lastUpdate,
            compact: compact,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                visual,
                SizedBox(height: FocuslaneTokens.sectionGapFor(context)),
                content,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              visual,
              const SizedBox(width: 16),
              Expanded(child: content),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          );
        },
      ),
    );
  }
}

class _NoteTextBlock extends StatelessWidget {
  const _NoteTextBlock({
    required this.note,
    required this.preview,
    required this.lastUpdate,
    required this.compact,
  });

  final Note note;
  final String preview;
  final String lastUpdate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                note.title.isEmpty ? 'Sin titulo' : note.title,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (note.isPinned) ...[
              const SizedBox(width: 8),
              Icon(Icons.push_pin_rounded, size: 18, color: scheme.primary),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          preview.isEmpty ? 'Nota vacia' : preview,
          maxLines: compact ? 4 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FocusChip(
              label: 'Editado: $lastUpdate',
              icon: Icons.access_time_rounded,
              color: scheme.secondary,
            ),
            if (note.tags.isNotEmpty)
              for (final tag in note.tags.take(3))
                FocusChip(
                  label: tag,
                  icon: Icons.label_outline_rounded,
                  color: scheme.tertiary,
                ),
            if (note.linkedTaskIds.isNotEmpty)
              FocusChip(
                label: '${note.linkedTaskIds.length} tareas vinculadas',
                icon: Icons.task_alt_rounded,
                color: scheme.primary,
              ),
          ],
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _preview(note, lines: 4);
    final lastUpdate = DateFormat(
      'dd MMM · HH:mm',
      'es_ES',
    ).format(note.lastEditedAt);

    return FocusCard(
      onTap:
          () => Navigator.pushNamed(context, '/notes/editor', arguments: note),
      padding: EdgeInsets.zero,
      backgroundColor: scheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NoteCover(
            note: note,
            height: FocuslaneTokens.isCompact(context) ? 96 : 112,
          ),
          Padding(
            padding: FocuslaneTokens.cardPaddingFor(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Sin titulo' : note.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (note.isPinned) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.push_pin_rounded,
                        size: 17,
                        color: scheme.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview.isEmpty ? 'Nota vacia' : preview,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FocusBadge(
                  label: 'Editado: $lastUpdate',
                  color: scheme.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteVisual extends StatelessWidget {
  const _NoteVisual({required this.note, required this.compact});

  final Note note;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _NoteCover(note: note, height: 104);
    }

    return SizedBox(width: 148, child: _NoteCover(note: note, height: 112));
  }
}

class _NoteCover extends StatelessWidget {
  const _NoteCover({required this.note, required this.height});

  final Note note;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
    final coverUrl = note.coverUrl ?? '';

    if (coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          coverUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
                  _FallbackNoteCover(height: height, radius: radius),
        ),
      );
    }

    return _FallbackNoteCover(height: height, radius: radius);
  }
}

class _FallbackNoteCover extends StatelessWidget {
  const _FallbackNoteCover({required this.height, required this.radius});

  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.description_rounded, color: scheme.primary),
        ),
      ),
    );
  }
}

InputDecoration _controlDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
}) {
  final scheme = Theme.of(context).colorScheme;

  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 19),
    isDense: true,
    filled: true,
    fillColor: scheme.surfaceContainerLowest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: scheme.primary),
    ),
  );
}

String _preview(Note note, {required int lines}) {
  return note.content
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .take(lines)
      .join('\n');
}

bool _editedToday(Note note) {
  final now = DateTime.now();
  final edited = note.lastEditedAt;
  return edited.year == now.year &&
      edited.month == now.month &&
      edited.day == now.day;
}
