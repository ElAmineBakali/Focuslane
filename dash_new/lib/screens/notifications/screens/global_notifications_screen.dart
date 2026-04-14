import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/screens/finance/services/subscription_service.dart';
import 'package:focuslane/screens/food/models/food_notification_models.dart';
import 'package:focuslane/screens/food/screens/food_settings_notifications_screen.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/gym/services/gym_notification_service.dart';
import 'package:focuslane/screens/study/screens/notifications/study_notifications_screen.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/study/services/study_notifications.dart';

class GlobalNotificationsScreen extends StatefulWidget {
  const GlobalNotificationsScreen({
    super.key,
    required this.foodService,
    required this.studyService,
  });

  final FoodFirestoreService foodService;
  final StudyFirestoreService studyService;

  @override
  State<GlobalNotificationsScreen> createState() => _GlobalNotificationsScreenState();
}

class _GlobalNotificationsScreenState extends State<GlobalNotificationsScreen> {
  static const _kStudyNotifyClasses = 'study_notify_classes';
  static const _kStudyNotifyTasks = 'study_notify_tasks';

  bool _loading = true;

  bool _studyClasses = true;
  bool _studyTasks = true;

  bool _foodMaster = true;
  List<FoodReminderDefinition> _foodReminders = const [];

  bool _gymWeightEnabled = false;
  bool _gymMeasurementsEnabled = false;
  bool _gymInactivityEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final studyClasses = prefs.getBool(_kStudyNotifyClasses) ?? true;
    final studyTasks = prefs.getBool(_kStudyNotifyTasks) ?? true;

    final foodConfig = await widget.foodService.getRemindersConfig();
    final rawReminders = (foodConfig['reminders'] as List?) ?? const [];
    final parsedReminders = rawReminders
        .whereType<Map>()
        .map((e) => FoodReminderDefinition.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final gymWeight = await GymNotificationService.I.isWeightReminderEnabled();
    final gymMeasures = await GymNotificationService.I.isMeasurementsReminderEnabled();
    final gymInactivity = await GymNotificationService.I.isInactivityReminderEnabled();

    if (!mounted) return;
    setState(() {
      _studyClasses = studyClasses;
      _studyTasks = studyTasks;
      _foodMaster = foodConfig['enabled'] as bool? ?? true;
      _foodReminders = parsedReminders;
      _gymWeightEnabled = gymWeight;
      _gymMeasurementsEnabled = gymMeasures;
      _gymInactivityEnabled = gymInactivity;
      _loading = false;
    });
  }

  Future<void> _setStudyClasses(bool value) async {
    setState(() => _studyClasses = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStudyNotifyClasses, value);
    await StudyNotifications(widget.studyService).scheduleAll(
      classes: _studyClasses,
      tasks: _studyTasks,
    );
  }

  Future<void> _setStudyTasks(bool value) async {
    setState(() => _studyTasks = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStudyNotifyTasks, value);
    await StudyNotifications(widget.studyService).scheduleAll(
      classes: _studyClasses,
      tasks: _studyTasks,
    );
  }

  Future<void> _setFoodMaster(bool value) async {
    setState(() => _foodMaster = value);
    await widget.foodService.saveRemindersConfig({
      'notification_channel': 'food',
      'enabled': value,
      'reminders': _foodReminders.map((e) => e.toMap()).toList(),
    });
    await FoodReminderScheduler().applyReminders(
      masterEnabled: value,
      reminders: _foodReminders,
    );
  }

  Future<void> _cancelByModule(NotificationModule module, String label) async {
    await NotificationsFacade.I.cancelByModule(module);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notificaciones de $label canceladas')),
    );
  }

  Future<void> _rescheduleFinance() async {
    await SubscriptionService.I.scheduleAllReminders();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recordatorios de Finance reprogramados')),
    );
  }

  Future<void> _openStudyDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyNotificationsScreen(svc: widget.studyService),
      ),
    );
    await _loadState();
  }

  Future<void> _openFoodDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodSettingsNotificationsScreen(
          svc: widget.foodService,
          initialSection: FoodSettingsSection.notificaciones,
        ),
      ),
    );
    await _loadState();
  }

  Future<void> _openGymDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _GymModuleNotificationsScreen()),
    );
    await _loadState();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: _GlobalNotificationsAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final enabledModules = [
      _studyClasses || _studyTasks,
      _foodMaster,
      _gymWeightEnabled || _gymMeasurementsEnabled || _gymInactivityEnabled,
    ].where((v) => v).length;

    return Scaffold(
      appBar: const _GlobalNotificationsAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GestiÃ³n global',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$enabledModules mÃ³dulos con notificaciones activas en configuraciÃ³n persistida.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Tareas'),
          _actionCard(
            context,
            subtitle: 'Los recordatorios se configuran por tarea. Desde aquÃ­ puedes limpiar pendientes del mÃ³dulo.',
            actions: [
              FilledButton.icon(
                onPressed: () => _cancelByModule(NotificationModule.tasks, 'Tareas'),
                icon: const Icon(Icons.notifications_off_outlined),
                label: const Text('Cancelar pendientes'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, 'HÃ¡bitos'),
          _actionCard(
            context,
            subtitle: 'Recordatorios asociados a hÃ¡bitos. Limpieza central por mÃ³dulo.',
            actions: [
              FilledButton.icon(
                onPressed: () => _cancelByModule(NotificationModule.habits, 'HÃ¡bitos'),
                icon: const Icon(Icons.notifications_off_outlined),
                label: const Text('Cancelar pendientes'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Estudio'),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _studyClasses,
                  onChanged: _setStudyClasses,
                  title: const Text('Recordatorios de clases'),
                  subtitle: const Text('Usa SharedPreferences + StudyNotifications existentes.'),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: _studyTasks,
                  onChanged: _setStudyTasks,
                  title: const Text('Recordatorios de tareas'),
                  subtitle: const Text('Usa SharedPreferences + StudyNotifications existentes.'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: _openStudyDetails,
                      icon: const Icon(Icons.tune),
                      label: const Text('ConfiguraciÃ³n de estudio'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Calendario'),
          _actionCard(
            context,
            subtitle: 'Los eventos programados usan el mÃ³dulo calendar en el core unificado.',
            actions: [
              FilledButton.icon(
                onPressed: () => _cancelByModule(NotificationModule.calendar, 'Calendario'),
                icon: const Icon(Icons.notifications_off_outlined),
                label: const Text('Cancelar recordatorios'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Finance'),
          _actionCard(
            context,
            subtitle: 'Recordatorios ligados a suscripciones existentes en SubscriptionService.',
            actions: [
              FilledButton.icon(
                onPressed: _rescheduleFinance,
                icon: const Icon(Icons.schedule),
                label: const Text('Reprogramar suscripciones'),
              ),
              OutlinedButton.icon(
                onPressed: () => _cancelByModule(NotificationModule.finance, 'Finance'),
                icon: const Icon(Icons.notifications_off_outlined),
                label: const Text('Cancelar recordatorios'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Food'),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _foodMaster,
                  onChanged: _setFoodMaster,
                  title: const Text('Activar notificaciones de Food'),
                  subtitle: const Text('Config real en Firestore (food/config/reminders).'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 12),
                    child: OutlinedButton.icon(
                      onPressed: _openFoodDetails,
                      icon: const Icon(Icons.tune),
                      label: const Text('ConfiguraciÃ³n de Food'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionTitle(context, 'Gym'),
          _actionCard(
            context,
            subtitle:
                'Peso: ${_gymWeightEnabled ? 'activo' : 'inactivo'} Â· Medidas: ${_gymMeasurementsEnabled ? 'activo' : 'inactivo'} Â· Inactividad: ${_gymInactivityEnabled ? 'activo' : 'inactivo'}',
            actions: [
              FilledButton.icon(
                onPressed: _openGymDetails,
                icon: const Icon(Icons.tune),
                label: const Text('ConfiguraciÃ³n de Gym'),
              ),
              OutlinedButton.icon(
                onPressed: () => _cancelByModule(NotificationModule.gym, 'Gym'),
                icon: const Icon(Icons.notifications_off_outlined),
                label: const Text('Cancelar recordatorios'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required String subtitle,
    required List<Widget> actions,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

class _GlobalNotificationsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _GlobalNotificationsAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Notificaciones'),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GymModuleNotificationsScreen extends StatefulWidget {
  const _GymModuleNotificationsScreen();

  @override
  State<_GymModuleNotificationsScreen> createState() => _GymModuleNotificationsScreenState();
}

class _GymModuleNotificationsScreenState extends State<_GymModuleNotificationsScreen> {
  bool _loading = true;
  bool _weightEnabled = false;
  bool _measurementsEnabled = false;
  bool _inactivityEnabled = false;
  int _weightWeekday = DateTime.monday;
  TimeOfDay _weightTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _measurementsTime = const TimeOfDay(hour: 9, minute: 0);
  int _inactivityDays = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = GymNotificationService.I;
    final wEnabled = await service.isWeightReminderEnabled();
    final mEnabled = await service.isMeasurementsReminderEnabled();
    final iEnabled = await service.isInactivityReminderEnabled();
    final weekday = await service.getWeightReminderWeekday();
    final wTime = await service.getWeightReminderTime();
    final mTime = await service.getMeasurementsReminderTime();
    final days = await service.getInactivityDays();

    if (!mounted) return;
    setState(() {
      _weightEnabled = wEnabled;
      _measurementsEnabled = mEnabled;
      _inactivityEnabled = iEnabled;
      _weightWeekday = weekday;
      _weightTime = wTime;
      _measurementsTime = mTime;
      _inactivityDays = days;
      _loading = false;
    });
  }

  Future<void> _toggleWeight(bool value) async {
    setState(() => _weightEnabled = value);
    if (value) {
      await GymNotificationService.I.scheduleWeeklyWeightReminder(
        weekday: _weightWeekday,
        time: _weightTime,
      );
    } else {
      await GymNotificationService.I.cancelWeeklyWeightReminder();
    }
  }

  Future<void> _toggleMeasurements(bool value) async {
    setState(() => _measurementsEnabled = value);
    if (value) {
      await GymNotificationService.I.scheduleWeeklyMeasurementsReminder(
        weekday: _weightWeekday,
        time: _measurementsTime,
      );
    } else {
      await GymNotificationService.I.cancelWeeklyMeasurementsReminder();
    }
  }

  Future<void> _toggleInactivity(bool value) async {
    setState(() => _inactivityEnabled = value);
    if (value) {
      await GymNotificationService.I.scheduleInactivityReminder(days: _inactivityDays);
    } else {
      await GymNotificationService.I.cancelInactivityReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: _GymNotificationsAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gym Â· Notificaciones')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _weightEnabled,
                  onChanged: _toggleWeight,
                  title: const Text('Recordatorio de peso'),
                ),
                SwitchListTile.adaptive(
                  value: _measurementsEnabled,
                  onChanged: _toggleMeasurements,
                  title: const Text('Recordatorio de medidas'),
                ),
                SwitchListTile.adaptive(
                  value: _inactivityEnabled,
                  onChanged: _toggleInactivity,
                  title: const Text('Recordatorio de inactividad'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DÃ­a semanal', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: _weightWeekday,
                    items: const [
                      DropdownMenuItem(value: DateTime.monday, child: Text('Lunes')),
                      DropdownMenuItem(value: DateTime.tuesday, child: Text('Martes')),
                      DropdownMenuItem(value: DateTime.wednesday, child: Text('MiÃ©rcoles')),
                      DropdownMenuItem(value: DateTime.thursday, child: Text('Jueves')),
                      DropdownMenuItem(value: DateTime.friday, child: Text('Viernes')),
                      DropdownMenuItem(value: DateTime.saturday, child: Text('SÃ¡bado')),
                      DropdownMenuItem(value: DateTime.sunday, child: Text('Domingo')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _weightWeekday = v);
                      if (_weightEnabled) {
                        await GymNotificationService.I.scheduleWeeklyWeightReminder(
                          weekday: _weightWeekday,
                          time: _weightTime,
                        );
                      }
                      if (_measurementsEnabled) {
                        await GymNotificationService.I.scheduleWeeklyMeasurementsReminder(
                          weekday: _weightWeekday,
                          time: _measurementsTime,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text('Hora peso: ${_weightTime.format(context)}')),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _weightTime,
                          );
                          if (picked == null) return;
                          setState(() => _weightTime = picked);
                          if (_weightEnabled) {
                            await GymNotificationService.I.scheduleWeeklyWeightReminder(
                              weekday: _weightWeekday,
                              time: _weightTime,
                            );
                          }
                        },
                        child: const Text('Cambiar'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Hora medidas: ${_measurementsTime.format(context)}')),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _measurementsTime,
                          );
                          if (picked == null) return;
                          setState(() => _measurementsTime = picked);
                          if (_measurementsEnabled) {
                            await GymNotificationService.I.scheduleWeeklyMeasurementsReminder(
                              weekday: _weightWeekday,
                              time: _measurementsTime,
                            );
                          }
                        },
                        child: const Text('Cambiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('DÃ­as de inactividad: $_inactivityDays'),
                  Slider(
                    value: _inactivityDays.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_inactivityDays',
                    onChanged: (v) => setState(() => _inactivityDays = v.round()),
                    onChangeEnd: (v) async {
                      if (_inactivityEnabled) {
                        await GymNotificationService.I.scheduleInactivityReminder(
                          days: v.round(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GymNotificationsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _GymNotificationsAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Gym Â· Notificaciones'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

