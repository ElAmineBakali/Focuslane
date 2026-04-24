import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/models/notification_action.dart';
import 'package:focuslane/core/notifications/models/notification_content.dart';
import 'package:focuslane/core/notifications/models/notification_delivery.dart';
import 'package:focuslane/core/notifications/models/notification_entity_ref.dart';
import 'package:focuslane/core/notifications/models/notification_intent.dart';
import 'package:focuslane/core/notifications/models/notification_schedule.dart';
import 'package:focuslane/core/notifications/notifications_facade.dart';
import 'package:focuslane/design/ui/shared/app_card.dart';
import 'package:focuslane/design/ui/feedback/focus_feedback.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';
import 'package:focuslane/screens/food/models/food_notification_models.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/food/widgets/food_compact_widgets.dart';

enum FoodSettingsSection { notificaciones, configuracion }

class FoodSettingsNotificationsScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  final FoodSettingsSection initialSection;
  final VoidCallback? onBack;

  const FoodSettingsNotificationsScreen({
    super.key,
    required this.svc,
    this.initialSection = FoodSettingsSection.notificaciones,
    this.onBack,
  });

  @override
  State<FoodSettingsNotificationsScreen> createState() =>
      _FoodSettingsNotificationsScreenState();
}

class _FoodSettingsNotificationsScreenState
    extends State<FoodSettingsNotificationsScreen> {
  final _scrollController = ScrollController();
  final _notifKey = GlobalKey();
  final _configKey = GlobalKey();
  final _scheduler = FoodReminderScheduler();

  bool _loading = true;
  bool _masterEnabled = true;
  List<FoodReminderDefinition> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final data = await widget.svc.getRemindersConfig();
      if (!mounted) return;
      final master = data['enabled'] as bool? ?? true;
      final rawReminders = (data['reminders'] as List?) ?? const [];
      final parsed = rawReminders
          .whereType<Map>()
          .map((e) => FoodReminderDefinition.fromMap(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      final merged = _mergeWithDefaults(parsed);

      setState(() {
        _masterEnabled = master;
        _reminders = merged;
        _loading = false;
      });

      await _scheduler.applyReminders(
        masterEnabled: _masterEnabled,
        reminders: _reminders,
      );
      if (!mounted) return;

      _scrollToInitialSection();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToInitialSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = widget.initialSection == FoodSettingsSection.configuracion
          ? _configKey
          : _notifKey;
      final ctx = key.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  List<FoodReminderDefinition> _mergeWithDefaults(
    List<FoodReminderDefinition> incoming,
  ) {
    final defaults = _defaultReminders();
    final byId = {for (final r in incoming) r.id: r};
    return defaults
        .map((d) => byId[d.id] ?? d)
        .toList(growable: false);
  }

  List<FoodReminderDefinition> _defaultReminders() {
    return const [
      FoodReminderDefinition(
        id: 'food_agua',
        title: 'Agua',
        description: 'Recordatorio para hidratarte',
        enabled: true,
        channel: 'food',
        trigger: FoodReminderTrigger(type: 'daily_time', hour: 9, minute: 0),
        payload: {'route': '/food', 'args': {'seccion': 'diario'}},
      ),
      FoodReminderDefinition(
        id: 'food_desayuno',
        title: 'Desayuno',
        description: 'Empieza el día con energía',
        enabled: true,
        channel: 'food',
        trigger: FoodReminderTrigger(type: 'daily_time', hour: 8, minute: 30),
        payload: {'route': '/food', 'args': {'seccion': 'diario'}},
      ),
      FoodReminderDefinition(
        id: 'food_comida',
        title: 'Comida',
        description: 'Planifica tu comida del día',
        enabled: true,
        channel: 'food',
        trigger: FoodReminderTrigger(type: 'daily_time', hour: 13, minute: 30),
        payload: {'route': '/food', 'args': {'seccion': 'diario'}},
      ),
      FoodReminderDefinition(
        id: 'food_cena',
        title: 'Cena',
        description: 'Cierra el día con una cena ligera',
        enabled: true,
        channel: 'food',
        trigger: FoodReminderTrigger(type: 'daily_time', hour: 20, minute: 30),
        payload: {'route': '/food', 'args': {'seccion': 'diario'}},
      ),
    ];
  }

  Future<void> _persistAndSchedule() async {
    await widget.svc.saveRemindersConfig({
      'notification_channel': 'food',
      'enabled': _masterEnabled,
      'reminders': _reminders.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _scheduler.applyReminders(
      masterEnabled: _masterEnabled,
      reminders: _reminders,
    );
  }

  Future<void> _toggleMaster(bool value) async {
    setState(() => _masterEnabled = value);
    await _persistAndSchedule();
    if (!mounted) return;
    if (mounted) {
      FocusFeedback.showSuccess(
        context,
        value ? 'Notificaciones activadas' : 'Notificaciones desactivadas',
      );
    }
  }

  Future<void> _toggleReminder(int index, bool value) async {
    if (index < 0 || index >= _reminders.length) return;
    final reminder = _reminders[index];
    setState(() {
      _reminders[index] = reminder.copyWith(enabled: value);
    });
    await _persistAndSchedule();
    if (!mounted) return;
  }

  Future<void> _changeReminderTime(int index) async {
    if (index < 0 || index >= _reminders.length) return;
    final reminder = _reminders[index];
    final current = reminder.trigger.timeOfDay ??
        const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (!mounted) return;
    if (picked == null) return;

    final updatedTrigger = FoodReminderTrigger(
      type: reminder.trigger.type,
      hour: picked.hour,
      minute: picked.minute,
      intervalMinutes: reminder.trigger.intervalMinutes,
      eventData: reminder.trigger.eventData,
    );

    setState(() {
      _reminders[index] = reminder.copyWith(trigger: updatedTrigger);
    });

    await _persistAndSchedule();
    if (!mounted) return;
  }

  Future<void> _resetDefaults() async {
    setState(() {
      _masterEnabled = true;
      _reminders = _defaultReminders();
    });
    await _persistAndSchedule();
    if (!mounted) return;
    FocusFeedback.showSuccess(context, 'Recordatorios restablecidos');
  }

  Future<void> _cancelAll() async {
    await NotificationsFacade.I.cancelByModule(NotificationModule.food);
    if (!mounted) return;
    setState(() => _masterEnabled = false);
    await _persistAndSchedule();
    if (!mounted) return;
    FocusFeedback.showInfo(context, 'Notificaciones del módulo canceladas');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: FoodCompactAppBar(
          title: 'Notificaciones y recordatorios',
          subtitle: 'Módulo de nutrición',
          onBack: widget.onBack,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: FoodCompactAppBar(
        title: 'Notificaciones y recordatorios',
        subtitle: 'Módulo de nutrición',
        onBack: widget.onBack,
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionHeader(
            key: _notifKey,
            icon: Icons.notifications_active,
            title: 'Notificaciones',
            subtitle: 'Controla tus recordatorios diarios',
          ),
          AppSurface(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Notificaciones del módulo', style: AppTypography.heading3(context)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activar notificaciones'),
                  subtitle: const Text('Recordatorios diarios del módulo de nutrición'),
                  value: _masterEnabled,
                  onChanged: _toggleMaster,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSurface(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Recordatorios diarios', style: AppTypography.heading3(context)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._reminders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reminder = entry.value;
                  return _ReminderTile(
                    reminder: reminder,
                    enabled: _masterEnabled,
                    onToggle: (v) => _toggleReminder(index, v),
                    onChangeTime: () => _changeReminderTime(index),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            key: _configKey,
            icon: Icons.settings,
            title: 'Configuración',
            subtitle: 'Acciones rápidas y mantenimiento',
          ),
          AppSurface(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.build_circle, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Acciones rápidas', style: AppTypography.heading3(context)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _resetDefaults,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Restablecer recordatorios'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _cancelAll,
                  icon: const Icon(Icons.notifications_off, size: 18),
                  label: const Text('Cancelar notificaciones'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FoodReminderScheduler {
  String get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';

  Future<void> applyReminders({
    required bool masterEnabled,
    required List<FoodReminderDefinition> reminders,
  }) async {
    if (!masterEnabled) {
      await NotificationsFacade.I.cancelByModule(NotificationModule.food);
      return;
    }

    for (final reminder in reminders) {
      final entity = NotificationEntityRef(
        module: NotificationModule.food,
        kind: 'food_reminder',
        id: reminder.id,
      );

      if (!reminder.enabled) {
        await NotificationsFacade.I.cancelByEntity(entity);
        continue;
      }

      final time = reminder.trigger.timeOfDay;
      if (reminder.trigger.type == 'daily_time' && time != null) {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        await NotificationsFacade.I.cancelByEntity(entity);
        await NotificationsFacade.I.scheduleIntent(
          NotificationIntent(
            module: NotificationModule.food,
            type: 'FOOD_DAILY_REMINDER',
            entity: entity,
            content: NotificationContent(
              title: reminder.title,
              body: reminder.description,
            ),
            action: const NotificationAction(
              kind: NotificationActionKind.openRoute,
              route: '/food',
            ),
            schedule: NotificationSchedule(
              kind: NotificationScheduleKind.daily,
              scheduledAtUtc: start.toUtc(),
              timezone: start.timeZoneName,
              hour: time.hour,
              minute: time.minute,
            ),
            delivery: const NotificationDelivery(
              kind: NotificationDeliveryKind.localOnly,
              channel: AndroidChannelCatalog.foodReminders,
              priority: NotificationPriority.normal,
            ),
            dedupeKey: 'food:reminder:${reminder.id}:daily:${time.hour}:${time.minute}',
            userId: _uid,
            source: 'food.settings_notifications',
            notificationId: 'ntf_food_reminder_${reminder.id}',
          ),
        );
      } else {
        await NotificationsFacade.I.cancelByEntity(entity);
      }
    }
  }
}

class _ReminderTile extends StatelessWidget {
  final FoodReminderDefinition reminder;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChangeTime;

  const _ReminderTile({
    required this.reminder,
    required this.enabled,
    required this.onToggle,
    required this.onChangeTime,
  });

  @override
  Widget build(BuildContext context) {
    final time = reminder.trigger.timeOfDay ?? const TimeOfDay(hour: 9, minute: 0);
    final timeLabel = time.format(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.alarm, size: 18, color: cs.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.title, style: AppTypography.body(context).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    reminder.description,
                    style: AppTypography.caption(context).copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: enabled ? onChangeTime : null,
              child: Text(timeLabel),
            ),
            Switch.adaptive(
              value: reminder.enabled,
              onChanged: enabled ? onToggle : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.heading2(context)),
                Text(
                  subtitle,
                  style: AppTypography.body(context)
                      .copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



