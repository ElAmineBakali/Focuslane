import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/design/widgets/ui_scaffold.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_constants.dart';
import 'package:mi_dashboard_personal/screens/habits/widgets/emoji_icon_picker.dart';
import 'package:mi_dashboard_personal/screens/habits/widgets/tag_selector.dart';
import 'package:mi_dashboard_personal/screens/habits/widgets/reminder_manager.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _reminderController;
  late String _frequency;
  late bool _isQuantitative;
  late String _unit;
  late Color _selectedColor;
  late bool _isActive;
  late String? _emoji;
  late String? _iconCode;
  late List<String> _tags;
  late List<HabitReminder> _reminders;

  @override
  void initState() {
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit.name);
    _descriptionController = TextEditingController(text: habit.description);
    _reminderController = TextEditingController(text: habit.reminderTime);
    _frequency = habit.frequency;
    _isQuantitative = habit.isQuantitative;
    _unit = habit.unit;
    _selectedColor = Color(int.parse(habit.colorHex));
    _isActive = habit.isActive;
    _emoji = habit.emoji;
    _iconCode = habit.iconCode;
    _tags = List.from(habit.tags);
    _reminders = List.from(habit.reminders);
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selecciona un color'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged:
                    (color) => setState(() => _selectedColor = color),
                enableAlpha: false,
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  void _pickEmojiIcon() async {
    await showDialog(
      context: context,
      builder:
          (context) => EmojiIconPicker(
            selectedEmoji: _emoji,
            selectedIconCode: _iconCode,
            onSelect: (emoji, iconCode) {
              setState(() {
                _emoji = emoji;
                _iconCode = iconCode;
              });
            },
          ),
    );
  }

  void _manageTags() async {
    await showDialog(
      context: context,
      builder:
          (context) => TagSelector(
            selectedTags: _tags,
            onTagsChanged: (tags) {
              setState(() => _tags = tags);
            },
          ),
    );
  }

  void _manageReminders() async {
    await showDialog(
      context: context,
      builder:
          (context) => ReminderManager(
            reminders: _reminders,
            onRemindersChanged: (reminders) {
              setState(() => _reminders = reminders);
            },
          ),
    );
  }

  String _asHex(Color c) =>
      '0x${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedHabit = widget.habit.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      frequency: _frequency,
      reminderTime: _reminderController.text.trim(),
      isQuantitative: _isQuantitative,
      unit: _unit,
      colorHex: _asHex(_selectedColor),
      isActive: _isActive,
      emoji: _emoji,
      iconCode: _iconCode,
      tags: _tags,
      reminders: _reminders,
      lastUpdated: DateTime.now(),
    );

    await HabitFirestoreService.updateHabit(updatedHabit);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar hÃ¡bito'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: TaskFormTheme(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, screenPad(context)),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                  ),
                  child: InkWell(
                    onTap: _pickEmojiIcon,
                    borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14 : 16),
                      child: Row(
                        children: [
                          Container(
                            width: isMobile ? 50 : 56,
                            height: isMobile ? 50 : 56,
                            decoration: BoxDecoration(
                              color: _selectedColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child:
                                  _emoji != null
                                      ? Text(
                                        _emoji!,
                                        style: TextStyle(
                                          fontSize: isMobile ? 24 : 28,
                                        ),
                                      )
                                      : _iconCode != null
                                      ? Icon(
                                        HabitIcons.getIcon(_iconCode),
                                        color: _selectedColor,
                                        size: isMobile ? 26 : 30,
                                      )
                                      : Icon(
                                        Icons.emoji_emotions_outlined,
                                        color: cs.onSurfaceVariant,
                                        size: isMobile ? 26 : 30,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Icono del hÃ¡bito',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Toca para cambiar',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: cs.onSurfaceVariant,
                            size: isMobile ? 20 : 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'DescripciÃ³n'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  items: const [
                    DropdownMenuItem(value: 'Diario', child: Text('Diario')),
                    DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
                    DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
                  ],
                  onChanged:
                      (val) => setState(() => _frequency = val ?? 'Diario'),
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                  ),
                  child: InkWell(
                    onTap: _manageTags,
                    borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label_outlined,
                                color: cs.primary,
                                size: isMobile ? 20 : 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Etiquetas (${_tags.length}/3)',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.edit_outlined,
                                color: cs.onSurfaceVariant,
                                size: isMobile ? 20 : 22,
                              ),
                            ],
                          ),
                          if (_tags.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _tags.map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      backgroundColor: cs.primaryContainer,
                                      labelStyle: TextStyle(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile ? 12 : 13,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 0,
                  color: cs.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                  ),
                  child: InkWell(
                    onTap: _manageReminders,
                    borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14 : 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: cs.primary,
                            size: isMobile ? 20 : 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recordatorios (${_reminders.length})',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _reminders.isEmpty
                                      ? 'Sin recordatorios'
                                      : '${_reminders.where((r) => r.enabled).length} activos',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit_outlined,
                            color: cs.onSurfaceVariant,
                            size: isMobile ? 20 : 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Â¿Es cuantitativo?'),
                  value: _isQuantitative,
                  onChanged: (val) => setState(() => _isQuantitative = val),
                ),
                if (_isQuantitative)
                  TextFormField(
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad (opcional)',
                    ),
                    onChanged: (val) => _unit = val,
                  ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Color'),
                  leading: CircleAvatar(backgroundColor: _selectedColor),
                  trailing: TextButton(
                    onPressed: _pickColor,
                    child: const Text('Cambiar color'),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Â¿EstÃ¡ activo?'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

