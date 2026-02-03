import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../theme/global_ui_theme.dart';
import '../../../services/notification_service.dart';

class FoodNotificationsScreen extends StatefulWidget {
  const FoodNotificationsScreen({super.key});

  @override
  State<FoodNotificationsScreen> createState() => _FoodNotificationsScreenState();
}

class _FoodNotificationsScreenState extends State<FoodNotificationsScreen> {
  Map<String, bool> _notificationTypes = {
    'water': true,
    'breakfast': true,
    'lunch': true,
    'dinner': true,
    'pantry_low': false,
    'weekly_plan': false,
  };

  List<Map<String, dynamic>> _customReminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final typesJson = prefs.getString('food_notification_types');
      if (typesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(typesJson);
        _notificationTypes = decoded.map((key, value) => MapEntry(key, value as bool));
      }
      
      final remindersJson = prefs.getString('food_custom_reminders');
      if (remindersJson != null) {
        final List<dynamic> decoded = jsonDecode(remindersJson);
        _customReminders = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('food_notification_types', jsonEncode(_notificationTypes));
      await prefs.setString('food_custom_reminders', jsonEncode(_customReminders));
      
      await _scheduleAllNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configuración guardada'),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _scheduleAllNotifications() async {
    for (var reminder in _customReminders) {
      if (reminder['enabled'] == true) {
        final hour = reminder['hour'] as int;
        final minute = reminder['minute'] as int;
        final message = reminder['message'] as String;
        
        await NotificationService.I.scheduleHabitDailyReminder(
          TimeOfDay(hour: hour, minute: minute),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: ModernGradientAppBar(
          title: 'Notificaciones',
          icon: Icons.notifications,
          useThemeColors: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: ModernGradientAppBar(
        title: 'Notificaciones',
        icon: Icons.notifications,
        useThemeColors: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            elevation: AppSpacing.elevationSm,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.category, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Tipos de Notificación',
                        style: AppTypography.heading3(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildNotificationTypeSwitch(
                    'water',
                    'Recordatorios de agua',
                    'Te recordará beber agua regularmente',
                    Icons.water_drop,
                  ),
                  _buildNotificationTypeSwitch(
                    'breakfast',
                    'Recordatorio de desayuno',
                    'Notificación matutina para desayunar',
                    Icons.wb_sunny,
                  ),
                  _buildNotificationTypeSwitch(
                    'lunch',
                    'Recordatorio de comida',
                    'Notificación al mediodía',
                    Icons.restaurant,
                  ),
                  _buildNotificationTypeSwitch(
                    'dinner',
                    'Recordatorio de cena',
                    'Notificación por la noche',
                    Icons.dinner_dining,
                  ),
                  _buildNotificationTypeSwitch(
                    'pantry_low',
                    'Stock bajo en despensa',
                    'Aviso cuando falten alimentos',
                    Icons.inventory_2,
                  ),
                  _buildNotificationTypeSwitch(
                    'weekly_plan',
                    'Planificación semanal',
                    'Recordatorio para planear la semana',
                    Icons.calendar_month,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          
          const SizedBox(height: AppSpacing.lg),
          
          Card(
            elevation: AppSpacing.elevationSm,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alarm, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Recordatorios Personalizados',
                          style: AppTypography.heading3(context),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _addCustomReminder,
                        tooltip: 'Añadir recordatorio',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_customReminders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.alarm_off,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'No hay recordatorios personalizados',
                              style: AppTypography.body(context).copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._customReminders.asMap().entries.map((entry) {
                      final index = entry.key;
                      final reminder = entry.value;
                      return _buildCustomReminderTile(index, reminder);
                    }).toList(),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          
          const SizedBox(height: AppSpacing.xl),
          
          Card(
            elevation: AppSpacing.elevationSm,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Información',
                        style: AppTypography.heading3(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Las notificaciones locales se programan en tu dispositivo. '
                    'Asegúrate de tener los permisos de notificación activados en la configuración del sistema.',
                    style: AppTypography.body(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Las notificaciones push requieren conexión a internet y están disponibles cuando inicies sesión.',
                    style: AppTypography.body(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeSwitch(
    String key,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, color: colorScheme.primary),
      ),
      title: Text(title, style: AppTypography.body(context)),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption(context).copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: _notificationTypes[key] ?? false,
        onChanged: (value) {
          setState(() => _notificationTypes[key] = value);
        },
        activeColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildCustomReminderTile(int index, Map<String, dynamic> reminder) {
    final enabled = reminder['enabled'] as bool;
    final hour = reminder['hour'] as int;
    final minute = reminder['minute'] as int;
    final message = reminder['message'] as String;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Switch(
          value: enabled,
          onChanged: (value) {
            setState(() => reminder['enabled'] = value);
          },
          activeColor: colorScheme.primary,
        ),
        title: Text(
          message,
          style: AppTypography.body(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
          style: AppTypography.caption(context),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editCustomReminder(index, reminder),
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                setState(() => _customReminders.removeAt(index));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustomReminder() async {
    await _showReminderDialog(null, null);
  }

  Future<void> _editCustomReminder(int index, Map<String, dynamic> reminder) async {
    await _showReminderDialog(index, reminder);
  }

  Future<void> _showReminderDialog(int? index, Map<String, dynamic>? existing) async {
    final messageController = TextEditingController(text: existing?['message'] ?? '');
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(hour: existing['hour'] as int, minute: existing['minute'] as int)
        : const TimeOfDay(hour: 12, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(index == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernTextField(
                label: 'Mensaje',
                hint: 'Ej: Beber agua',
                controller: messageController,
                prefixIcon: Icons.message,
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Hora'),
                subtitle: Text(
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setDialogState(() => selectedTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final message = messageController.text.trim();
                if (message.isNotEmpty) {
                  final reminder = {
                    'enabled': true,
                    'hour': selectedTime.hour,
                    'minute': selectedTime.minute,
                    'message': message,
                  };
                  
                  setState(() {
                    if (index == null) {
                      _customReminders.add(reminder);
                    } else {
                      _customReminders[index] = reminder;
                    }
                  });
                  
                  Navigator.pop(context);
                }
              },
              child: Text(index == null ? 'Añadir' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
