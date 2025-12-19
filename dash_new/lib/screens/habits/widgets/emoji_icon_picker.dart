import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_constants.dart';

 class EmojiIconPicker extends StatefulWidget {
  final String? selectedEmoji;
  final String? selectedIconCode;
  final Function(String? emoji, String? iconCode) onSelect;

  const EmojiIconPicker({
    super.key,
    this.selectedEmoji,
    this.selectedIconCode,
    required this.onSelect,
  });

  @override
  State<EmojiIconPicker> createState() => _EmojiIconPickerState();
}

class _EmojiIconPickerState extends State<EmojiIconPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _tempEmoji;
  String? _tempIconCode;

     static const Map<String, List<String>> emojiCategories = {
    'Salud': ['💪', '🏃', '🧘', '💧', '🥗', '😴', '❤️', '🩺', '💊'],
    'Educación': ['📚', '📖', '✍️', '🎓', '📝', '🗣️', '🧠', '💡', '🔬'],
    'Deporte': ['⚽', '🏀', '🎾', '🏐', '🏊', '🚴', '🏋️', '🧗', '🤸'],
    'Arte': ['🎨', '🎭', '🎬', '🎵', '🎸', '🎹', '🎤', '📷', '🖼️'],
    'Casa': ['🏠', '🧹', '🧺', '🛁', '🛏️', '🍳', '🌿', '🔧', '🔨'],
    'Trabajo': ['💼', '💻', '📊', '📈', '⚙️', '🔨', '✉️', '📞', '🎯'],
    'Social': ['👨‍👩‍👧‍👦', '👫', '🤝', '💬', '📱', '🎉', '☕', '🍕', '🎂'],
    'Otros': ['⭐', '🏆', '🎯', '🔔', '⏰', '📅', '✅', '🚀', '🌟'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tempEmoji = widget.selectedEmoji;
    _tempIconCode = widget.selectedIconCode;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    child: Text(
                      'Selecciona un ícono',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.emoji_emotions_rounded), text: 'Emojis'),
                Tab(icon: Icon(Icons.apps_rounded), text: 'Iconos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildEmojiGrid(), _buildIconGrid()],
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onSelect(null, null);
                      Navigator.pop(context);
                    },
                    child: const Text('Ninguno'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      widget.onSelect(_tempEmoji, _tempIconCode);
                      Navigator.pop(context);
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiGrid() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          emojiCategories.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 60,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final emoji = entry.value[index];
                    final isSelected =
                        _tempEmoji == emoji && _tempIconCode == null;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _tempEmoji = emoji;
                          _tempIconCode = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? cs.primaryContainer
                                  : cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cs.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildIconGrid() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final icons = HabitIcons.icons;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 70,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final entry = icons.entries.elementAt(index);
        final code = entry.key;
        final icon = entry.value;
        final isSelected = _tempIconCode == code && _tempEmoji == null;

        return InkWell(
          onTap: () {
            setState(() {
              _tempIconCode = code;
              _tempEmoji = null;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? cs.primaryContainer : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
