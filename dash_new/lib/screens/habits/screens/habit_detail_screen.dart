import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/design/widgets/ui_scaffold.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:focuslane/screens/habits/models/habit_model.dart';
import 'package:focuslane/screens/habits/services/habit_firestore_service.dart';
import 'package:focuslane/screens/habits/utils/habit_constants.dart';
import 'package:focuslane/screens/habits/widgets/emoji_icon_picker.dart';
import 'package:focuslane/screens/habits/widgets/tag_selector.dart';
import 'package:focuslane/screens/habits/utils/habit_utils.dart';

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
  late TextEditingController _goalValueController;
  late TextEditingController _goalUnitController;
  late String _frequency;
  late bool _isQuantitative;
  late String _unit;
  late Color _selectedColor;
  late bool _isActive;
  late String? _emoji;
  late String? _iconCode;
  late List<String> _tags;

  @override
  void initState() {
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit.name);
    _descriptionController = TextEditingController(text: habit.description);
    _goalValueController = TextEditingController(
      text:
          habit.goalValue == null ? '' : formatHabitStatNumber(habit.goalValue),
    );
    _goalUnitController = TextEditingController(text: habit.goalUnit ?? '');
    _frequency = habit.frequency;
    _isQuantitative = habit.isQuantitative;
    _unit = habit.unit;
    _selectedColor = Color(int.parse(habit.colorHex));
    _isActive = habit.isActive;
    _emoji = habit.emoji;
    _iconCode = habit.iconCode;
    _tags = List.from(habit.tags);
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalValueController.dispose();
    _goalUnitController.dispose();
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

  String _asHex(Color c) =>
      '0x${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  double? _parseGoalValue() {
    final raw = _goalValueController.text.trim();
    if (raw.isEmpty) {
      return null;
    }

    final parsed = parseHabitNumericValue(raw);
    return parsed > 0 ? parsed : null;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final goalValue = _isQuantitative ? _parseGoalValue() : null;
    final goalUnit =
        _isQuantitative
            ? _goalUnitController.text.trim().isEmpty
                ? null
                : _goalUnitController.text.trim()
            : null;

    await HabitFirestoreService.updateHabitFields(widget.habit.id, {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'frequency': _frequency,
      'reminderTime': '',
      'isQuantitative': _isQuantitative,
      'unit': _isQuantitative ? _unit.trim() : '',
      'goalValue': goalValue,
      'goalUnit': goalUnit,
      'colorHex': _asHex(_selectedColor),
      'isActive': _isActive,
      'emoji': _emoji,
      'iconCode': _iconCode,
      'tags': _tags,
      'reminders': const <Map<String, dynamic>>[],
      'lastUpdated': DateTime.now(),
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final currentGoalValue = _isQuantitative ? _parseGoalValue() : null;
    final currentGoalUnit =
        _goalUnitController.text.trim().isEmpty
            ? (_unit.trim().isEmpty ? '' : _unit.trim())
            : _goalUnitController.text.trim();
    final currentValue = parseHabitNumericValue(
      habitHistoryValueForDate(widget.habit.history, DateTime.now()),
    );
    final remainingValue =
        currentGoalValue == null
            ? 0.0
            : (currentGoalValue - currentValue).clamp(0.0, double.infinity);
    final currentPercent =
        currentGoalValue == null || currentGoalValue <= 0
            ? 0.0
            : ((currentValue / currentGoalValue) * 100).clamp(0.0, 999999.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar hábito'),
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
                FocusCard(
                  backgroundColor: cs.surfaceContainerLowest,
                  child: const FocusSectionHeader(
                    title: 'Editar hábito',
                    subtitle: 'Actualiza datos, estado y meta del hábito.',
                    icon: Icons.edit_note_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                FocusCard(
                  padding: EdgeInsets.zero,
                  elevated: false,
                  backgroundColor: cs.surfaceContainerLow,
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
                              color: _selectedColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedColor.withValues(alpha: 0.3),
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
                  decoration: const InputDecoration(labelText: 'Descripción'),
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

                FocusCard(
                  padding: EdgeInsets.zero,
                  elevated: false,
                  backgroundColor: cs.surfaceContainerLow,
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

                SwitchListTile(
                  title: const Text('¿Es cuantitativo?'),
                  value: _isQuantitative,
                  onChanged: (val) => setState(() => _isQuantitative = val),
                ),
                if (_isQuantitative) ...[
                  TextFormField(
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad (opcional)',
                    ),
                    onChanged: (val) => setState(() => _unit = val),
                  ),
                  const SizedBox(height: 12),
                  FocusCard(
                    padding: EdgeInsets.zero,
                    elevated: false,
                    backgroundColor: cs.surfaceContainerLow,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meta opcional',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Puedes añadirla ahora o modificar la existente.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _goalValueController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Valor objetivo',
                              hintText: 'Ej: 2000',
                            ),
                            validator: (value) {
                              final raw = value?.trim() ?? '';
                              if (raw.isEmpty) {
                                return null;
                              }

                              final parsed = parseHabitNumericValue(raw);
                              if (parsed <= 0) {
                                return 'Introduce una meta válida';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _goalUnitController,
                            decoration: InputDecoration(
                              labelText: 'Unidad de meta',
                              hintText:
                                  _unit.trim().isEmpty
                                      ? 'Ej: ml, páginas, pasos'
                                      : 'Ej: ${_unit.trim()}',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          if (currentGoalValue != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer.withValues(
                                  alpha: 0.55,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Progreso actual',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${formatHabitStatNumber(currentValue)} / ${formatHabitStatNumber(currentGoalValue)} ${currentGoalUnit.trim()}'
                                        .trim(),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: cs.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatHabitStatNumber(currentPercent)}% completado · faltan ${formatHabitStatNumber(remainingValue)} ${currentGoalUnit.trim()}'
                                        .trim(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FocusCard(
                  padding: const EdgeInsets.all(14),
                  elevated: false,
                  backgroundColor: cs.surfaceContainerLow,
                  child: InkWell(
                    onTap: _pickColor,
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        Icon(Icons.palette_outlined, color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Color',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CircleAvatar(backgroundColor: _selectedColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FocusCard(
                  padding: EdgeInsets.zero,
                  elevated: false,
                  backgroundColor: cs.surfaceContainerLow,
                  child: SwitchListTile(
                    title: const Text('¿Está activo?'),
                    secondary: const Icon(Icons.toggle_on_outlined),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    FocusSecondaryButton(
                      label: 'Cancelar',
                      icon: Icons.close_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                    FocusPrimaryButton(
                      label: 'Guardar cambios',
                      icon: Icons.save_rounded,
                      onPressed: _saveChanges,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
