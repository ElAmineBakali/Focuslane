import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_model.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_firestore_service.dart';
import 'package:mi_dashboard_personal/screens/habits/habit_constants.dart';
import 'package:mi_dashboard_personal/screens/habits/widgets/emoji_icon_picker.dart';
import 'package:mi_dashboard_personal/screens/habits/widgets/tag_selector.dart';
import 'package:mi_dashboard_personal/screens/habits/widgets/template_selector.dart';
import 'package:mi_dashboard_personal/screens/habits/widgets/reminder_manager.dart';
import 'package:mi_dashboard_personal/widgets/ui_scaffold.dart';

class HabitCreateScreen extends StatefulWidget {
  final Habit? habit; // null => crear, !null => editar
  const HabitCreateScreen({super.key, this.habit});

  @override
  State<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

class _HabitCreateScreenState extends State<HabitCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reminderController = TextEditingController();

  String _frequency = 'Diario';
  bool _isQuantitative = false;
  String _unit = '';
  Color _selectedColor = Colors.blue;

  // Nuevos campos
  String? _emoji;
  String? _iconCode;
  List<String> _tags = [];
  List<HabitReminder> _reminders = [];

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    if (h != null) {
      _nameController.text = h.name;
      _descriptionController.text = h.description;
      _reminderController.text = h.reminderTime;
      _frequency = h.frequency;
      _isQuantitative = h.isQuantitative;
      _unit = h.unit;
      _selectedColor = Color(int.parse(h.colorHex));
      _emoji = h.emoji;
      _iconCode = h.iconCode;
      _tags = List.from(h.tags);
      _reminders = List.from(h.reminders);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  String _asHex(Color c) =>
      '0x${c.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      await HabitFirestoreService.updateHabitFields(widget.habit!.id, {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'frequency': _frequency,
        'reminderTime': _reminderController.text.trim(),
        'isQuantitative': _isQuantitative,
        'unit': _isQuantitative ? _unit : '',
        'colorHex': _asHex(_selectedColor),
        'emoji': _emoji,
        'iconCode': _iconCode,
        'tags': _tags,
        'reminders': _reminders.map((r) => r.toMap()).toList(),
        'lastUpdated': DateTime.now(),
      });
    } else {
      final now = DateTime.now();
      final habit = Habit(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        frequency: _frequency,
        reminderTime: _reminderController.text.trim(),
        unit: _isQuantitative ? _unit : '',
        isQuantitative: _isQuantitative,
        history: const {},
        isActive: true,
        createdAt: now,
        order: 0,
        completedDates: const [],
        daily: _frequency == 'Diario',
        lastUpdated: now,
        colorHex: _asHex(_selectedColor),
        emoji: _emoji,
        iconCode: _iconCode,
        tags: _tags,
        reminders: _reminders,
      );
      await HabitFirestoreService().addHabit(habit);
    }

    if (mounted) Navigator.pop(context);
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selecciona un color'),
            content: SingleChildScrollView(
              child: BlockPicker(
                pickerColor: _selectedColor,
                onColorChanged: (c) {
                  setState(() => _selectedColor = c);
                  Navigator.of(context).pop();
                },
              ),
            ),
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

  void _loadTemplate() async {
    await showDialog(
      context: context,
      builder:
          (context) => TemplateSelector(
            onSelect: (template) {
              setState(() {
                _nameController.text = template.name;
                _descriptionController.text = template.description;
                _emoji = template.emoji;
                _iconCode = template.iconCode;
                _tags = List.from(template.suggestedTags);
                _frequency = template.frequency;
                _isQuantitative = template.isQuantitative;
                _unit = template.unit;
                _selectedColor = Color(int.parse(template.colorHex));
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar hábito' : 'Crear nuevo hábito'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.dashboard_customize_rounded),
              onPressed: _loadTemplate,
              tooltip: 'Usar plantilla',
            ),
        ],
      ),
      body: TaskFormTheme(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, screenPad(context)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono/Emoji selector
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
                                  'Icono del hábito',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _emoji != null || _iconCode != null
                                      ? 'Toca para cambiar'
                                      : 'Toca para seleccionar (opcional)',
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

                // Nombre
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del hábito',
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Campo requerido'
                              : null,
                ),

                const SizedBox(height: 12),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 2,
                ),

                const SizedBox(height: 12),

                // Frecuencia
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frecuencia'),
                  items: const [
                    DropdownMenuItem(value: 'Diario', child: Text('Diario')),
                    DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
                    DropdownMenuItem(value: 'Mensual', child: Text('Mensual')),
                  ],
                  onChanged: (v) => setState(() => _frequency = v!),
                ),

                const SizedBox(height: 16),

                // Etiquetas
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
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Sin etiquetas asignadas',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Recordatorios
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
                                      ? 'Sin recordatorios configurados'
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

                // Cuantitativo
                SwitchListTile(
                  title: const Text('¿Es cuantitativo?'),
                  subtitle: Text(
                    'Permite registrar números (ej: páginas leídas, km corridos)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  value: _isQuantitative,
                  onChanged: (v) => setState(() => _isQuantitative = v),
                ),

                if (_isQuantitative) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad (ej. páginas, km, vasos...)',
                    ),
                    onChanged: (v) => _unit = v.trim(),
                    validator:
                        (v) =>
                            _isQuantitative && (v == null || v.trim().isEmpty)
                                ? 'Campo requerido'
                                : null,
                  ),
                ],

                const SizedBox(height: 20),

                // Color
                Row(
                  children: [
                    const Text(
                      'Color del hábito:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _pickColor,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Botón guardar
                Center(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: Icon(
                      _isEditing ? Icons.save_rounded : Icons.add_rounded,
                    ),
                    label: Text(
                      _isEditing ? 'Guardar cambios' : 'Crear hábito',
                    ),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 32,
                        vertical: isMobile ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
