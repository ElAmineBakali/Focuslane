import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focuslane/design/blocks/toast/app_toast.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/screens/calendar/models/calendar_models.dart';
import 'package:focuslane/screens/calendar/services/calendar_service.dart';
import 'package:focuslane/screens/finance/models/subscription_model.dart';
import 'package:focuslane/screens/finance/services/subscription_service.dart';
import 'package:focuslane/screens/food/models/food_notification_models.dart';
import 'package:focuslane/screens/food/screens/food_settings_notifications_screen.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/gym/services/gym_firestore_service.dart';
import 'package:focuslane/screens/gym/services/gym_notification_service.dart';
import 'package:focuslane/screens/habits/models/habit_model.dart';
import 'package:focuslane/screens/habits/services/habit_firestore_service.dart';
import 'package:focuslane/screens/notifications/models/entity_notification_config.dart';
import 'package:focuslane/screens/notifications/services/entity_notification_config_store.dart';
import 'package:focuslane/screens/notifications/services/entity_notification_scheduler.dart';
import 'package:focuslane/screens/notifications/widgets/notification_diagnostics_panel.dart';
import 'package:focuslane/screens/study/models/study_models.dart';
import 'package:focuslane/screens/study/screens/notifications/study_notifications_screen.dart';
import 'package:focuslane/screens/study/services/study_firestore_service.dart';
import 'package:focuslane/screens/study/services/study_notifications.dart';
import 'package:focuslane/screens/tasks/models/task_model.dart';
import 'package:focuslane/screens/tasks/services/task_firestore_service.dart';

class GlobalNotificationsScreen extends StatefulWidget {
  const GlobalNotificationsScreen({
    super.key,
    required this.foodService,
    required this.studyService,
  });

  final FoodFirestoreService foodService;
  final StudyFirestoreService studyService;

  @override
  State<GlobalNotificationsScreen> createState() =>
      _GlobalNotificationsScreenState();
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
  Map<String, EntityNotificationConfig> _configs =
      const <String, EntityNotificationConfig>{};

  final _calendarService = CalendarService.I;
  final _gymService = GymFirestoreService();

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
        .map(
          (e) => FoodReminderDefinition.fromMap(Map<String, dynamic>.from(e)),
        )
        .toList(growable: false);

    final gymWeight = await GymNotificationService.I.isWeightReminderEnabled();
    final gymMeasures =
        await GymNotificationService.I.isMeasurementsReminderEnabled();
    final gymInactivity =
        await GymNotificationService.I.isInactivityReminderEnabled();
    final configs = await EntityNotificationConfigStore.I.loadAll();

    if (!mounted) return;
    setState(() {
      _studyClasses = studyClasses;
      _studyTasks = studyTasks;
      _foodMaster = foodConfig['enabled'] as bool? ?? true;
      _foodReminders = parsedReminders;
      _gymWeightEnabled = gymWeight;
      _gymMeasurementsEnabled = gymMeasures;
      _gymInactivityEnabled = gymInactivity;
      _configs = configs;
      _loading = false;
    });
  }

  Future<void> _setStudyClasses(bool value) async {
    setState(() => _studyClasses = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStudyNotifyClasses, value);
    await StudyNotifications(
      widget.studyService,
    ).scheduleAll(classes: _studyClasses, tasks: _studyTasks);
  }

  Future<void> _setStudyTasks(bool value) async {
    setState(() => _studyTasks = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kStudyNotifyTasks, value);
    await StudyNotifications(
      widget.studyService,
    ).scheduleAll(classes: _studyClasses, tasks: _studyTasks);
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
    AppToast.success(context, 'Notificaciones de $label canceladas');
  }

  Future<void> _openStudyDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (childContext) => StudyNotificationsScreen(
              svc: widget.studyService,
              onBack: () => Navigator.of(childContext).maybePop(),
            ),
      ),
    );
    await _loadState();
  }

  Future<void> _openFoodDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (childContext) => FoodSettingsNotificationsScreen(
              svc: widget.foodService,
              initialSection: FoodSettingsSection.notificaciones,
              onBack: () => Navigator.of(childContext).maybePop(),
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

  String _fmtDateTime(DateTime value) {
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  String _cfgSummary(_EntityNotificationTarget target) {
    final config = _configs[target.configKey];
    if (config == null || !config.enabled) {
      return 'Sin configuración personalizada';
    }
    if (config.scheduleMode == EntityNotificationScheduleMode.absolute) {
      final at = config.absoluteAtUtc;
      if (at == null) return 'Activo, pendiente de fecha';
      return '${target.labelForType(config.notificationType)} · programado para ${_fmtDateTime(at)}';
    }
    final mins = config.minutesBefore ?? 0;
    final ref = target.referenceAtLocal;
    if (ref == null) {
      return '${target.labelForType(config.notificationType)} · sin fecha base disponible';
    }
    return '${target.labelForType(config.notificationType)} · $mins min antes de ${_fmtDateTime(ref)}';
  }

  Future<void> _openEntityConfig(_EntityNotificationTarget target) async {
    final existing = _configs[target.configKey];
    EntityNotificationScheduleMode mode =
        existing?.scheduleMode ??
        (target.referenceAtLocal == null
            ? EntityNotificationScheduleMode.absolute
            : EntityNotificationScheduleMode.relative);
    DateTime? absoluteAt =
        existing?.absoluteAtUtc?.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    int minutesBefore = existing?.minutesBefore ?? 30;
    bool enabled = existing?.enabled ?? true;
    String selectedType = existing?.notificationType ?? target.defaultType;
    bool deleted = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickAbsoluteDateTime() async {
              final current = absoluteAt ?? DateTime.now();
              final date = await showDatePicker(
                context: ctx,
                initialDate: current,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime(2100),
              );
              if (date == null) return;
              if (!ctx.mounted) return;
              final time = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.fromDateTime(current),
              );
              if (time == null) return;
              if (!ctx.mounted) return;
              setModalState(() {
                absoluteAt = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            final canUseRelative = target.referenceAtLocal != null;
            final bottomPad = MediaQuery.of(ctx).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPad),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Configurar aviso · ${target.label}',
                            style: Theme.of(ctx).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: enabled,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notificación activa'),
                      onChanged:
                          (value) => setModalState(() => enabled = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de aviso',
                        border: OutlineInputBorder(),
                      ),
                      items: target.typeLabels.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<EntityNotificationScheduleMode>(
                      segments: const [
                        ButtonSegment<EntityNotificationScheduleMode>(
                          value: EntityNotificationScheduleMode.absolute,
                          label: Text('Fecha exacta'),
                          icon: Icon(Icons.event_available_outlined),
                        ),
                        ButtonSegment<EntityNotificationScheduleMode>(
                          value: EntityNotificationScheduleMode.relative,
                          label: Text('Relativa'),
                          icon: Icon(Icons.schedule_outlined),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (value) {
                        final next = value.first;
                        if (next == EntityNotificationScheduleMode.relative &&
                            !canUseRelative) {
                          AppToast.warning(
                            context,
                            'Esta entidad no tiene fecha base para un aviso relativo.',
                          );
                          return;
                        }
                        setModalState(() => mode = next);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (mode == EntityNotificationScheduleMode.absolute)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: Text(
                          absoluteAt == null
                              ? 'Seleccionar fecha y hora'
                              : _fmtDateTime(absoluteAt!),
                        ),
                        onTap: pickAbsoluteDateTime,
                      ),
                    if (mode == EntityNotificationScheduleMode.relative)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha base: ${target.referenceAtLocal == null ? 'No disponible' : _fmtDateTime(target.referenceAtLocal!)}',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                                  5,
                                  10,
                                  15,
                                  30,
                                  45,
                                  60,
                                  90,
                                  120,
                                  180,
                                  1440,
                                ]
                                .map(
                                  (value) => ChoiceChip(
                                    label: Text(
                                      value == 1440 ? '1 día' : '$value min',
                                    ),
                                    selected: minutesBefore == value,
                                    onSelected:
                                        (_) => setModalState(
                                          () => minutesBefore = value,
                                        ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final compact = constraints.maxWidth < 420;
                        final deleteButton =
                            existing == null
                                ? null
                                : TextButton.icon(
                                  onPressed: () async {
                                    await EntityNotificationConfigStore.I
                                        .remove(target.configKey);
                                    await EntityNotificationScheduler.I.cancel(
                                      existing,
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      final copy = Map<
                                        String,
                                        EntityNotificationConfig
                                      >.from(_configs);
                                      copy.remove(target.configKey);
                                      _configs = copy;
                                    });
                                    deleted = true;
                                    if (!ctx.mounted) return;
                                    Navigator.of(ctx).pop(true);
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Eliminar'),
                                );
                        final cancelButton = TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        );
                        final saveButton = FilledButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar'),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              saveButton,
                              const SizedBox(height: 8),
                              cancelButton,
                              if (deleteButton != null) ...[
                                const SizedBox(height: 4),
                                deleteButton,
                              ],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            if (deleteButton != null) deleteButton,
                            const Spacer(),
                            cancelButton,
                            const SizedBox(width: 8),
                            saveButton,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true) {
      return;
    }

    if (deleted) {
      if (!mounted) return;
      AppToast.success(context, 'Configuración eliminada para ${target.label}');
      return;
    }

    final config = EntityNotificationConfig(
      module: target.module,
      entityKind: target.entityKind,
      entityId: target.entityId,
      entityLabel: target.label,
      notificationType: selectedType,
      scheduleMode: mode,
      enabled: enabled,
      absoluteAtUtc: absoluteAt?.toUtc(),
      minutesBefore:
          mode == EntityNotificationScheduleMode.relative
              ? minutesBefore
              : null,
      updatedAtUtc: DateTime.now().toUtc(),
    );

    await EntityNotificationConfigStore.I.upsert(config);

    if (enabled) {
      await EntityNotificationScheduler.I.apply(
        config: config,
        title: target.title,
        body: target.body,
        route: target.route,
        referenceAtLocal: target.referenceAtLocal,
      );
    } else {
      await EntityNotificationScheduler.I.cancel(config);
    }

    if (!mounted) return;
    setState(() {
      final next = Map<String, EntityNotificationConfig>.from(_configs);
      next[target.configKey] = config;
      _configs = next;
    });

    AppToast.success(context, 'Configuración guardada para ${target.label}');
  }

  Widget _buildEntityList({
    required String title,
    required String subtitle,
    required List<_EntityNotificationTarget> targets,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.surfaceContainerLow,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle),
          const SizedBox(height: 8),
          if (targets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No hay elementos disponibles para configurar.'),
            ),
          ...targets.map(
            (target) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(target.label),
              subtitle: Text(_cfgSummary(target)),
              trailing: FilledButton.tonal(
                onPressed: () => _openEntityConfig(target),
                child: const Text('Configurar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modulePanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: colorScheme.primaryContainer,
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer),
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle),
          ),
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: _GlobalNotificationsAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeModules = <NotificationModule>{
      for (final config in _configs.values)
        if (config.enabled) config.module,
      if (_studyClasses || _studyTasks) NotificationModule.study,
      if (_foodMaster) NotificationModule.food,
      if (_gymWeightEnabled || _gymMeasurementsEnabled || _gymInactivityEnabled)
        NotificationModule.gym,
    };
    const totalModules = 7;
    final gymState =
        'Peso: ${_gymWeightEnabled ? 'activo' : 'inactivo'} · '
        'Medidas: ${_gymMeasurementsEnabled ? 'activo' : 'inactivo'} · '
        'Inactividad: ${_gymInactivityEnabled ? 'activo' : 'inactivo'}';

    return Scaffold(
      appBar: const _GlobalNotificationsAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de notificaciones',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '${activeModules.length} de $totalModules módulos tienen avisos activos. Aquí puedes ajustar avisos generales, recordatorios por elemento y acciones rápidas sin mezclarlo todo.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip(
                      label: 'Estudio',
                      active: _studyClasses || _studyTasks,
                    ),
                    _statusChip(label: 'Nutrición', active: _foodMaster),
                    _statusChip(
                      label: 'Gimnasio',
                      active:
                          _gymWeightEnabled ||
                          _gymMeasurementsEnabled ||
                          _gymInactivityEnabled,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const NotificationDiagnosticsPanel(),
          const SizedBox(height: 18),
          _ScreenGroupHeader(
            title: 'Recordatorios por módulo',
            subtitle:
                'Cada bloque reúne la configuración general y los avisos propios de ese módulo.',
          ),
          const SizedBox(height: 12),
          _modulePanel(
            title: 'Tareas',
            subtitle: 'Avisos por tareas pendientes y fechas límite',
            icon: Icons.task_alt_outlined,
            children: [
              StreamBuilder<List<Task>>(
                stream: TaskFirestoreService.getTasks(),
                builder: (context, snapshot) {
                  final tasks = (snapshot.data ?? const <Task>[])
                      .where((task) => !task.completed)
                      .toList(growable: false);
                  final targets = tasks
                      .map((task) {
                        final ref = task.dueDate ?? task.remindAt;
                        return _EntityNotificationTarget(
                          module: NotificationModule.tasks,
                          entityKind: 'task',
                          entityId: task.id,
                          label: task.title,
                          title: task.title,
                          body: 'Recordatorio de tarea pendiente',
                          route: '/tasks',
                          defaultType: 'TASK_REMINDER',
                          typeLabels: const {
                            'TASK_REMINDER': 'Recordatorio de tarea',
                            'TASK_DUE': 'Aviso de fecha límite',
                            'TASK_FOCUS': 'Bloque de enfoque',
                          },
                          referenceAtLocal: ref,
                        );
                      })
                      .toList(growable: false);
                  return _buildEntityList(
                    title: 'Recordatorios por tarea',
                    subtitle:
                        'Configura cada tarea con fecha exacta o minutos antes.',
                    targets: targets,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _modulePanel(
            title: 'Calendario',
            subtitle: 'Recordatorios por evento y preparación previa',
            icon: Icons.calendar_today_outlined,
            children: [
              StreamBuilder<List<CalendarEvent>>(
                stream: _calendarService.watchRange(
                  DateTime.now().subtract(const Duration(days: 7)),
                  DateTime.now().add(const Duration(days: 365)),
                ),
                builder: (context, snapshot) {
                  final events = (snapshot.data ?? const <CalendarEvent>[])
                      .where(
                        (event) => event.start.isAfter(
                          DateTime.now().subtract(const Duration(minutes: 1)),
                        ),
                      )
                      .toList(growable: false);
                  final targets = events
                      .map((event) {
                        return _EntityNotificationTarget(
                          module: NotificationModule.calendar,
                          entityKind: 'planner_event',
                          entityId: event.id,
                          label: event.title,
                          title: event.title,
                          body: event.notes ?? 'Recordatorio de evento',
                          route: '/calendar',
                          defaultType: 'PLANNER_EVENT_REMINDER',
                          typeLabels: const {
                            'PLANNER_EVENT_REMINDER':
                                'Recordatorio antes del evento',
                            'EVENT_PREP': 'Preparación previa al evento',
                            'EVENT_CUSTOM': 'Aviso personalizado del evento',
                          },
                          referenceAtLocal: event.start,
                        );
                      })
                      .toList(growable: false);
                  return _buildEntityList(
                    title: 'Recordatorios por evento',
                    subtitle:
                        'Cada evento puede tener aviso exacto o relativo antes de su inicio.',
                    targets: targets,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _modulePanel(
            title: 'Estudio',
            subtitle: 'Clases, tareas, exámenes y cursos',
            icon: Icons.school_outlined,
            initiallyExpanded: true,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _studyClasses,
                      onChanged: _setStudyClasses,
                      title: const Text('Recordatorios base de clases'),
                      subtitle: const Text(
                        'Mantiene la lógica automática de clases.',
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: _studyTasks,
                      onChanged: _setStudyTasks,
                      title: const Text('Recordatorios base de tareas'),
                      subtitle: const Text(
                        'Mantiene la lógica automática de tareas.',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, bottom: 12),
                        child: OutlinedButton.icon(
                          onPressed: _openStudyDetails,
                          icon: const Icon(Icons.tune),
                          label: const Text(
                            'Configuración avanzada de estudio',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<StudyTask>>(
                stream: widget.studyService.streamTasks(),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? const <StudyTask>[];
                  final targets = tasks
                      .map((task) {
                        final type =
                            task.type == StudyItemType.exam
                                ? 'EXAM_REMINDER'
                                : 'STUDY_TASK_REMINDER';
                        return _EntityNotificationTarget(
                          module: NotificationModule.study,
                          entityKind: 'study_task',
                          entityId: task.id,
                          label: task.title,
                          title: task.title,
                          body:
                              task.type == StudyItemType.exam
                                  ? 'Recordatorio de examen'
                                  : 'Recordatorio de tarea de estudio',
                          route: '/study',
                          defaultType: type,
                          typeLabels: const {
                            'STUDY_TASK_REMINDER':
                                'Recordatorio de tarea de estudio',
                            'EXAM_REMINDER': 'Recordatorio de examen',
                            'GRADE_REMINDER': 'Aviso de calificación',
                          },
                          referenceAtLocal: task.due,
                        );
                      })
                      .toList(growable: false);
                  return _buildEntityList(
                    title: 'Recordatorios por tarea y examen',
                    subtitle: 'Avisos personalizados para cada tarea o examen.',
                    targets: targets,
                  );
                },
              ),
              StreamBuilder<List<Course>>(
                stream: widget.studyService.streamCourses(
                  includeArchived: false,
                ),
                builder: (context, snapshot) {
                  final courses = snapshot.data ?? const <Course>[];
                  final targets = courses
                      .map((course) {
                        return _EntityNotificationTarget(
                          module: NotificationModule.study,
                          entityKind: 'study_course',
                          entityId: course.id,
                          label: course.name,
                          title: course.name,
                          body: 'Recordatorio del curso',
                          route: '/study',
                          defaultType: 'COURSE_REMINDER',
                          typeLabels: const {
                            'COURSE_REMINDER': 'Recordatorio del curso',
                            'COURSE_REVIEW': 'Repaso del curso',
                            'COURSE_CLASS': 'Aviso de clase del curso',
                          },
                          referenceAtLocal: null,
                        );
                      })
                      .toList(growable: false);
                  return _buildEntityList(
                    title: 'Recordatorios por curso',
                    subtitle: 'Permite avisos personalizados por cada curso.',
                    targets: targets,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _modulePanel(
            title: 'Hábitos',
            subtitle: 'Recordatorios para mantener tus rachas',
            icon: Icons.checklist_outlined,
            children: [
              StreamBuilder<List<Habit>>(
                stream: HabitFirestoreService.getHabits(activeOnly: true),
                builder: (context, snapshot) {
                  final habits = snapshot.data ?? const <Habit>[];
                  final targets = habits
                      .map((habit) {
                        return _EntityNotificationTarget(
                          module: NotificationModule.habits,
                          entityKind: 'habit',
                          entityId: habit.id,
                          label: habit.name,
                          title: 'Hábito: ${habit.name}',
                          body: 'Recordatorio para completar el hábito',
                          route: '/habits',
                          defaultType: 'HABIT_REMINDER',
                          typeLabels: const {
                            'HABIT_REMINDER': 'Recordatorio del hábito',
                            'HABIT_STREAK': 'Aviso de racha',
                            'HABIT_CUSTOM': 'Aviso personalizado del hábito',
                          },
                          referenceAtLocal: null,
                        );
                      })
                      .toList(growable: false);
                  return _buildEntityList(
                    title: 'Recordatorios por hábito',
                    subtitle: 'Define avisos exactos por hábito concreto.',
                    targets: targets,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _modulePanel(
            title: 'Gimnasio',
            subtitle: 'Recordatorios de sesión, peso, medidas e inactividad',
            icon: Icons.fitness_center_outlined,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gymState),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _openGymDetails,
                      icon: const Icon(Icons.tune),
                      label: const Text('Ajustes automáticos de gimnasio'),
                    ),
                  ],
                ),
              ),
              StreamBuilder<List<SessionDoc>>(
                stream: _gymService.streamSessions(limit: 30),
                builder: (context, snapshot) {
                  final sessions = snapshot.data ?? const <SessionDoc>[];
                  final targets = sessions
                      .map((session) {
                        final label =
                            '${session.routineName} · ${_fmtDateTime(session.date)}';
                        return _EntityNotificationTarget(
                          module: NotificationModule.gym,
                          entityKind: 'gym_session',
                          entityId: session.id,
                          label: label,
                          title: 'Sesión de gym',
                          body: session.dayName,
                          route: '/gym',
                          defaultType: 'GYM_SESSION_REMINDER',
                          typeLabels: const {
                            'GYM_SESSION_REMINDER': 'Recordatorio de sesión',
                            'GYM_PREP': 'Preparación antes de entrenar',
                            'GYM_CUSTOM': 'Aviso personalizado del gym',
                          },
                          referenceAtLocal: session.date,
                        );
                      })
                      .toList(growable: false);
                  return _buildEntityList(
                    title: 'Recordatorios por sesión de gym',
                    subtitle: 'Permite configurar avisos por sesión concreta.',
                    targets: targets,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _modulePanel(
            title: 'Finanzas',
            subtitle: 'Avisos de suscripciones y pagos próximos',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              StreamBuilder<List<Subscription>>(
                stream: SubscriptionService.I.watchAll(activeOnly: true),
                builder: (context, snapshot) {
                  final subscriptions = snapshot.data ?? const <Subscription>[];
                  final targets = subscriptions
                      .map((subscription) {
                        return _EntityNotificationTarget(
                          module: NotificationModule.finance,
                          entityKind: 'subscription',
                          entityId: subscription.id,
                          label: subscription.name,
                          title: 'Pago próximo: ${subscription.name}',
                          body:
                              'Monto ${subscription.amount.toStringAsFixed(2)}',
                          route: '/finance',
                          defaultType: 'SUBSCRIPTION_DUE_SOON',
                          typeLabels: const {
                            'SUBSCRIPTION_DUE_SOON': 'Próximo pago',
                            'PAYMENT_WARNING': 'Aviso de pago',
                            'FINANCE_CUSTOM': 'Aviso financiero personalizado',
                          },
                          referenceAtLocal: subscription.nextDue,
                        );
                      })
                      .toList(growable: false);
                  return _buildEntityList(
                    title: 'Recordatorios por suscripción',
                    subtitle:
                        'Configura aviso exacto o relativo por cada suscripción.',
                    targets: targets,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _modulePanel(
            title: 'Nutrición',
            subtitle: 'Recordatorios de nutrición y horarios diarios',
            icon: Icons.restaurant_outlined,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      value: _foodMaster,
                      onChanged: _setFoodMaster,
                      title: const Text('Activar notificaciones de nutrición'),
                      subtitle: const Text(
                        'Persistido en Firestore para recordatorios de comida.',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, bottom: 12),
                        child: OutlinedButton.icon(
                          onPressed: _openFoodDetails,
                          icon: const Icon(Icons.tune),
                          label: const Text('Configuración de nutrición'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _quickActionsCard(context),
        ],
      ),
    );
  }

  Widget _statusChip({required String label, required bool active}) {
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle_outline : Icons.remove_circle_outline,
        size: 16,
      ),
      label: Text('$label · ${active ? 'activo' : 'inactivo'}'),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _quickActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones rápidas',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Utiliza estas acciones para cancelar notificaciones por módulo cuando necesites una limpieza rápida.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      () => _cancelByModule(NotificationModule.tasks, 'tareas'),
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Cancelar Tareas'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      () => _cancelByModule(
                        NotificationModule.calendar,
                        'calendario',
                      ),
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Cancelar Calendario'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      () =>
                          _cancelByModule(NotificationModule.habits, 'hábitos'),
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Cancelar Hábitos'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      () =>
                          _cancelByModule(NotificationModule.study, 'estudio'),
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Cancelar Estudio'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      () => _cancelByModule(NotificationModule.gym, 'gimnasio'),
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Cancelar Gimnasio'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      () => _cancelByModule(
                        NotificationModule.finance,
                        'finanzas',
                      ),
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Cancelar Finanzas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityNotificationTarget {
  const _EntityNotificationTarget({
    required this.module,
    required this.entityKind,
    required this.entityId,
    required this.label,
    required this.title,
    required this.body,
    required this.route,
    required this.defaultType,
    required this.typeLabels,
    required this.referenceAtLocal,
  });

  final NotificationModule module;
  final String entityKind;
  final String entityId;
  final String label;
  final String title;
  final String body;
  final String route;
  final String defaultType;
  final Map<String, String> typeLabels;
  final DateTime? referenceAtLocal;

  String get configKey => '${module.name}|$entityKind|$entityId';

  String labelForType(String type) {
    final mapped = typeLabels[type];
    if (mapped != null && mapped.trim().isNotEmpty) {
      return mapped;
    }

    switch (type) {
      case 'PLANNER_EVENT_REMINDER':
        return 'Recordatorio antes del evento';
      case 'EVENT_PREP':
        return 'Preparación previa al evento';
      case 'EVENT_CUSTOM':
        return 'Aviso personalizado del evento';
      case 'TASK_DUE_TODAY':
        return 'Vence hoy';
      case 'TASK_DUE_TOMORROW':
        return 'Vence mañana';
      case 'TASK_REMINDER':
        return 'Recordatorio de tarea';
      case 'TASK_DUE':
        return 'Aviso de fecha límite';
      case 'TASK_FOCUS':
        return 'Bloque de enfoque';
      case 'STUDY_TASK_REMINDER':
        return 'Recordatorio de tarea de estudio';
      case 'EXAM_REMINDER':
        return 'Recordatorio de examen';
      case 'GRADE_REMINDER':
        return 'Aviso de calificación';
      case 'COURSE_REMINDER':
        return 'Recordatorio del curso';
      case 'COURSE_REVIEW':
        return 'Repaso del curso';
      case 'COURSE_CLASS':
        return 'Aviso de clase';
      case 'HABIT_REMINDER':
        return 'Recordatorio del hábito';
      case 'HABIT_STREAK':
        return 'Aviso de racha';
      case 'HABIT_CUSTOM':
        return 'Aviso personalizado del hábito';
      case 'GYM_SESSION_REMINDER':
        return 'Recordatorio de sesión';
      case 'GYM_PREP':
        return 'Preparación antes de entrenar';
      case 'GYM_CUSTOM':
        return 'Aviso personalizado del entrenamiento';
      case 'SUBSCRIPTION_DUE_SOON':
        return 'Próximo cobro';
      case 'PAYMENT_WARNING':
        return 'Aviso de pago';
      case 'FINANCE_CUSTOM':
        return 'Aviso financiero personalizado';
      default:
        final natural = type
            .toLowerCase()
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => part == 'prep' ? 'preparación' : part)
            .join(' ');
        return 'Aviso $natural';
    }
  }
}

class _ScreenGroupHeader extends StatelessWidget {
  const _ScreenGroupHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalNotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _GlobalNotificationsAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Notificaciones globales'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GymModuleNotificationsScreen extends StatefulWidget {
  const _GymModuleNotificationsScreen();

  @override
  State<_GymModuleNotificationsScreen> createState() =>
      _GymModuleNotificationsScreenState();
}

class _GymModuleNotificationsScreenState
    extends State<_GymModuleNotificationsScreen> {
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
      await GymNotificationService.I.scheduleInactivityReminder(
        days: _inactivityDays,
      );
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
      appBar: AppBar(title: const Text('Gym · Notificaciones')),
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
                  Text(
                    'Día semanal',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    value: _weightWeekday,
                    items: const [
                      DropdownMenuItem(
                        value: DateTime.monday,
                        child: Text('Lunes'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.tuesday,
                        child: Text('Martes'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.wednesday,
                        child: Text('Miércoles'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.thursday,
                        child: Text('Jueves'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.friday,
                        child: Text('Viernes'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.saturday,
                        child: Text('Sábado'),
                      ),
                      DropdownMenuItem(
                        value: DateTime.sunday,
                        child: Text('Domingo'),
                      ),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _weightWeekday = v);
                      if (_weightEnabled) {
                        await GymNotificationService.I
                            .scheduleWeeklyWeightReminder(
                              weekday: _weightWeekday,
                              time: _weightTime,
                            );
                      }
                      if (_measurementsEnabled) {
                        await GymNotificationService.I
                            .scheduleWeeklyMeasurementsReminder(
                              weekday: _weightWeekday,
                              time: _measurementsTime,
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hora peso: ${_weightTime.format(context)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _weightTime,
                          );
                          if (picked == null) return;
                          setState(() => _weightTime = picked);
                          if (_weightEnabled) {
                            await GymNotificationService.I
                                .scheduleWeeklyWeightReminder(
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
                      Expanded(
                        child: Text(
                          'Hora medidas: ${_measurementsTime.format(context)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _measurementsTime,
                          );
                          if (picked == null) return;
                          setState(() => _measurementsTime = picked);
                          if (_measurementsEnabled) {
                            await GymNotificationService.I
                                .scheduleWeeklyMeasurementsReminder(
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
                  Text('Días de inactividad: $_inactivityDays'),
                  Slider(
                    value: _inactivityDays.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_inactivityDays',
                    onChanged:
                        (v) => setState(() => _inactivityDays = v.round()),
                    onChangeEnd: (v) async {
                      if (_inactivityEnabled) {
                        await GymNotificationService.I
                            .scheduleInactivityReminder(days: v.round());
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

class _GymNotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _GymNotificationsAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Gym · Notificaciones'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
