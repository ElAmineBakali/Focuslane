import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_dashboard_personal/design/blocks/dropdown/app_dropdown.dart';
import 'note_model.dart';
import 'note_firestore_service.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});
  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  bool _grid = false;
  final Set<String> _tagFilter = {};
  String _sort = 'updated';
  List<Note> _applyFilters(List<Note> notes) {
    var list = notes.toList();
    if (_tagFilter.isNotEmpty) {
      list =
          list
              .where((n) => _tagFilter.every((t) => n.tags.contains(t)))
              .toList();
    }
    switch (_sort) {
      case 'created':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'title':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'updated':
      default:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final pinned = list.where((n) => n.isPinned).toList();
    final unpinned = list.where((n) => !n.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        actions: [
          if (isPhone)
            IconButton(
              icon: Icon(
                _grid ? Icons.view_agenda_outlined : Icons.grid_view_outlined,
              ),
              onPressed: () => setState(() => _grid = !_grid),
              tooltip: _grid ? 'Vista lista' : 'Vista grid',
            ),
          if (isPhone)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Ordenar',
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(value: 'updated', child: Text('Recientes')),
                    PopupMenuItem(
                      value: 'created',
                      child: Text('Más antiguos'),
                    ),
                    PopupMenuItem(value: 'title', child: Text('Por título')),
                  ],
            ),
          if (!isPhone) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 120,
                child: AppDropdown<String>(
                  value: _sort,
                  hint: 'Ordenar',
                  icon: Icons.sort_rounded,
                  isCompact: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'updated',
                      child: Text('Recientes'),
                    ),
                    DropdownMenuItem(
                      value: 'created',
                      child: Text('Más antiguos'),
                    ),
                    DropdownMenuItem(value: 'title', child: Text('Por título')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _sort = v);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  _grid ? Icons.view_agenda_outlined : Icons.grid_view_outlined,
                ),
                onPressed: () => setState(() => _grid = !_grid),
                tooltip: _grid ? 'Vista lista' : 'Vista grid',
              ),
            ),
          ],
        ],
      ),
      body: StreamBuilder<List<Note>>(
        stream: NoteFirestoreService.getNotes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error cargando notas'));
          }
          final notes = _applyFilters(snap.data ?? const []);
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 64,
                    color: color.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay notas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón + para crear una',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (_grid) {
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isPhone ? 200 : 280,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: notes.length,
              itemBuilder: (c, i) => _NoteCard(note: notes[i]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (c, i) => _NoteTile(note: notes[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/notes/editor'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva nota'),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final preview = note.content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(3)
        .join('\n');
    final lastUpdate = DateFormat('dd MMM, HH:mm').format(note.updatedAt);

    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
      ),
      child: InkWell(
        onTap:
            () =>
                Navigator.pushNamed(context, '/notes/editor', arguments: note),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.coverUrl != null && note.coverUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isMobile ? 14 : 16),
                ),
                child: Image.network(
                  note.coverUrl!,
                  height: isMobile ? 100 : 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          _buildFallbackCover(color, isMobile ? 100 : 120),
                ),
              )
            else
              _buildFallbackCover(color, isMobile ? 100 : 120),
            Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? 'Sin título' : note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color.onSurface,
                            fontSize: isMobile ? 16 : 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isPinned) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.push_pin,
                          size: isMobile ? 16 : 18,
                          color: color.primary,
                        ),
                      ],
                    ],
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      preview,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color.onSurfaceVariant,
                        fontSize: isMobile ? 13 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: isMobile ? 10 : 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: isMobile ? 13 : 14,
                        color: color.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lastUpdate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color.onSurfaceVariant,
                          fontSize: isMobile ? 12 : 13,
                        ),
                      ),
                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.label_outline,
                          size: isMobile ? 13 : 14,
                          color: color.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            note.tags.take(2).join(', '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color.onSurfaceVariant,
                              fontSize: isMobile ? 12 : 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final preview = note.content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(4)
        .join('\n');
    final lastUpdate = DateFormat('dd MMM').format(note.updatedAt);

    return Card(
      elevation: 0,
      color: color.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
      ),
      child: InkWell(
        onTap:
            () =>
                Navigator.pushNamed(context, '/notes/editor', arguments: note),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.coverUrl != null && note.coverUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isMobile ? 14 : 16),
                ),
                child: Image.network(
                  note.coverUrl!,
                  height: isMobile ? 90 : 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          _buildFallbackCover(color, isMobile ? 90 : 100),
                ),
              )
            else
              _buildFallbackCover(color, isMobile ? 90 : 100),
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? 'Sin título' : note.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color.onSurface,
                            fontSize: isMobile ? 14 : 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isPinned)
                        Icon(
                          Icons.push_pin,
                          size: isMobile ? 14 : 16,
                          color: color.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    preview.isEmpty ? 'Nota vacía' : preview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontSize: isMobile ? 12 : 13,
                    ),
                    maxLines: isMobile ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lastUpdate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color.onSurfaceVariant,
                      fontSize: isMobile ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildFallbackCover(ColorScheme color, double height) {
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    child: Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.primaryContainer, color.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.note_outlined,
          size: 48,
          color: color.onPrimaryContainer.withOpacity(0.3),
        ),
      ),
    ),
  );
}

