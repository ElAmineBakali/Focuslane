import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_constants.dart';

class TagSelector extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  final int maxTags;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    this.maxTags = 3,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TextEditingController _customTagController = TextEditingController();
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedTags);
  }

  @override
  void dispose() {
    _customTagController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else if (_selected.length < widget.maxTags) {
        _selected.add(tag);
      }
      widget.onTagsChanged(_selected);
    });
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isNotEmpty &&
        !_selected.contains(tag) &&
        _selected.length < widget.maxTags) {
      setState(() {
        _selected.add(tag);
        widget.onTagsChanged(_selected);
        _customTagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
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
                          'Etiquetas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecciona hasta ${widget.maxTags} etiquetas',
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

            if (_selected.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selected.map((tag) {
                        return Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _toggleTag(tag),
                          backgroundColor: cs.primaryContainer,
                          labelStyle: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTagController,
                      decoration: InputDecoration(
                        hintText: 'Crear etiqueta personalizada',
                        prefixIcon: const Icon(Icons.label_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHigh,
                      ),
                      onSubmitted: (_) => _addCustomTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed:
                        _selected.length >= widget.maxTags
                            ? null
                            : _addCustomTag,
                    icon: const Icon(Icons.add),
                    tooltip: 'Agregar',
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(
                    'Etiquetas sugeridas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        CommonTags.tags.map((tag) {
                          final isSelected = _selected.contains(tag);
                          final isDisabled =
                              !isSelected && _selected.length >= widget.maxTags;

                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected:
                                isDisabled ? null : (_) => _toggleTag(tag),
                            selectedColor: cs.primaryContainer,
                            backgroundColor: cs.surfaceContainerHigh,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? cs.onPrimaryContainer
                                      : cs.onSurface,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            showCheckmark: true,
                            checkmarkColor: cs.primary,
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selected.length}/${widget.maxTags} seleccionadas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Listo'),
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
