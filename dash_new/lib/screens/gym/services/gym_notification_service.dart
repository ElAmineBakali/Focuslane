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
import 'package:shared_preferences/shared_preferences.dart';

class GymNotificationService {
  GymNotificationService._();
  static final GymNotificationService I = GymNotificationService._();

  static const String _keyInactivityDays = 'gym_inactivity_days';
  static const String _keyWeightReminderEnabled = 'gym_weight_reminder_enabled';
  static const String _keyWeightReminderDay = 'gym_weight_reminder_day';
  static const String _keyWeightReminderTime = 'gym_weight_reminder_time';
  static const String _keyMeasurementsReminderEnabled =
      'gym_measurements_reminder_enabled';
  static const String _keyMeasurementsReminderTime =
      'gym_measurements_reminder_time';
  static const String _keyInactivityReminderEnabled =
      'gym_inactivity_reminder_enabled';

  static const int _defaultInactivityDays = 3;
  static const int _defaultWeightDay = DateTime.monday;
  static const int _defaultWeightHour = 8;
  static const int _defaultWeightMinute = 0;
  static const int _defaultMeasurementsHour = 9;
  static const int _defaultMeasurementsMinute = 0;

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser?.uid ?? 'local';

  Future<void> scheduleRoutineDayReminder({
    required String routineId,
    required String routineName,
    required String dayId,
    required String dayName,
    required int weekday,
    required TimeOfDay time,
  }) async {
    final entity = NotificationEntityRef(
      module: NotificationModule.gym,
      kind: 'routine_day',
      id: '${routineId}_$dayId',
    );
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    await NotificationsFacade.I.cancelByEntity(entity);
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.gym,
        type: 'ROUTINE_DAY_REMINDER',
        entity: entity,
        content: NotificationContent(
          title: 'Dia de entrenamiento',
          body: '$routineName - $dayName',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/gym/routines',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.weekly,
          scheduledAtUtc: start.toUtc(),
          timezone: start.timeZoneName,
          hour: time.hour,
          minute: time.minute,
          weekdays: [weekday],
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.pushOnly,
          channel: AndroidChannelCatalog.gymReminders,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'gym:routine:$routineId:$dayId:$weekday:${time.hour}:${time.minute}',
        userId: _uid,
        source: 'gym.gym_notification_service',
        notificationId: 'ntf_gym_routine_${routineId}_$dayId',
      ),
    );
  }

  Future<void> cancelRoutineDayReminder({
    required String routineId,
    required String dayId,
  }) async {
    await NotificationsFacade.I.cancelByEntity(
      NotificationEntityRef(
        module: NotificationModule.gym,
        kind: 'routine_day',
        id: '${routineId}_$dayId',
      ),
    );
  }

  Future<void> cancelAllRoutineReminders(String routineId) async {
    await NotificationsFacade.I.cancelByDedupePrefix('gym:routine:$routineId:');
  }

  Future<void> scheduleInactivityReminder({
    int days = _defaultInactivityDays,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInactivityReminderEnabled, true);
    await prefs.setInt(_keyInactivityDays, days);

    final entity = const NotificationEntityRef(
      module: NotificationModule.gym,
      kind: 'inactivity',
      id: 'default',
    );
    await NotificationsFacade.I.cancelByEntity(entity);

    final base = DateTime.now().add(Duration(days: days));
    final at = DateTime(base.year, base.month, base.day, 10, 0);
    final epoch = at.toUtc().millisecondsSinceEpoch;
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.gym,
        type: 'INACTIVITY_REMINDER',
        entity: entity,
        content: NotificationContent(
          title: 'Vuelve al gym',
          body: 'Llevas $days días sin entrenar. Hora de una sesion.',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/gym',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.oneShot,
          scheduledAtUtc: at.toUtc(),
          timezone: at.timeZoneName,
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.pushOnly,
          channel: AndroidChannelCatalog.gymReminders,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'gym:inactivity:$days:$epoch',
        userId: _uid,
        source: 'gym.gym_notification_service',
        notificationId: 'ntf_gym_inactivity_$epoch',
      ),
    );
  }

  Future<void> cancelInactivityReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInactivityReminderEnabled, false);
    await NotificationsFacade.I.cancelByEntity(
      const NotificationEntityRef(
        module: NotificationModule.gym,
        kind: 'inactivity',
        id: 'default',
      ),
    );
  }

  Future<int> getInactivityDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyInactivityDays) ?? _defaultInactivityDays;
  }

  Future<bool> isInactivityReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyInactivityReminderEnabled) ?? false;
  }

  Future<int> getWeightReminderWeekday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWeightReminderDay) ?? _defaultWeightDay;
  }

  Future<TimeOfDay> getWeightReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final total =
        prefs.getInt(_keyWeightReminderTime) ??
        (_defaultWeightHour * 60 + _defaultWeightMinute);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  Future<TimeOfDay> getMeasurementsReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final total =
        prefs.getInt(_keyMeasurementsReminderTime) ??
        (_defaultMeasurementsHour * 60 + _defaultMeasurementsMinute);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  Future<void> scheduleWeeklyWeightReminder({
    int weekday = _defaultWeightDay,
    TimeOfDay? time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeightReminderEnabled, true);
    await prefs.setInt(_keyWeightReminderDay, weekday);

    final t =
        time ??
        const TimeOfDay(hour: _defaultWeightHour, minute: _defaultWeightMinute);
    await prefs.setInt(_keyWeightReminderTime, t.hour * 60 + t.minute);

    final entity = const NotificationEntityRef(
      module: NotificationModule.gym,
      kind: 'weekly_weight',
      id: 'default',
    );
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    await NotificationsFacade.I.cancelByEntity(entity);
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.gym,
        type: 'WEEKLY_WEIGHT_REMINDER',
        entity: entity,
        content: const NotificationContent(
          title: 'Registro de peso',
          body: 'Es momento de registrar tu peso corporal',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/gym',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.weekly,
          scheduledAtUtc: start.toUtc(),
          timezone: start.timeZoneName,
          hour: t.hour,
          minute: t.minute,
          weekdays: [weekday],
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.pushOnly,
          channel: AndroidChannelCatalog.gymReminders,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'gym:weekly_weight:$weekday:${t.hour}:${t.minute}',
        userId: _uid,
        source: 'gym.gym_notification_service',
        notificationId: 'ntf_gym_weekly_weight',
      ),
    );
  }

  Future<void> cancelWeeklyWeightReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeightReminderEnabled, false);
    await NotificationsFacade.I.cancelByEntity(
      const NotificationEntityRef(
        module: NotificationModule.gym,
        kind: 'weekly_weight',
        id: 'default',
      ),
    );
  }

  Future<bool> isWeightReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWeightReminderEnabled) ?? false;
  }

  Future<void> scheduleWeeklyMeasurementsReminder({
    int weekday = DateTime.monday,
    TimeOfDay? time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMeasurementsReminderEnabled, true);

    final t =
        time ??
        const TimeOfDay(
          hour: _defaultMeasurementsHour,
          minute: _defaultMeasurementsMinute,
        );
    await prefs.setInt(_keyMeasurementsReminderTime, t.hour * 60 + t.minute);

    final entity = const NotificationEntityRef(
      module: NotificationModule.gym,
      kind: 'weekly_measurements',
      id: 'default',
    );
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    await NotificationsFacade.I.cancelByEntity(entity);
    await NotificationsFacade.I.scheduleIntent(
      NotificationIntent(
        module: NotificationModule.gym,
        type: 'WEEKLY_MEASUREMENTS_REMINDER',
        entity: entity,
        content: const NotificationContent(
          title: 'Medidas corporales',
          body: 'Registra tus medidas fisicas de esta semana',
        ),
        action: const NotificationAction(
          kind: NotificationActionKind.openRoute,
          route: '/gym',
        ),
        schedule: NotificationSchedule(
          kind: NotificationScheduleKind.weekly,
          scheduledAtUtc: start.toUtc(),
          timezone: start.timeZoneName,
          hour: t.hour,
          minute: t.minute,
          weekdays: [weekday],
        ),
        delivery: const NotificationDelivery(
          kind: NotificationDeliveryKind.pushOnly,
          channel: AndroidChannelCatalog.gymReminders,
          priority: NotificationPriority.normal,
        ),
        dedupeKey: 'gym:weekly_measurements:$weekday:${t.hour}:${t.minute}',
        userId: _uid,
        source: 'gym.gym_notification_service',
        notificationId: 'ntf_gym_weekly_measurements',
      ),
    );
  }

  Future<void> cancelWeeklyMeasurementsReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMeasurementsReminderEnabled, false);
    await NotificationsFacade.I.cancelByEntity(
      const NotificationEntityRef(
        module: NotificationModule.gym,
        kind: 'weekly_measurements',
        id: 'default',
      ),
    );
  }

  Future<bool> isMeasurementsReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMeasurementsReminderEnabled) ?? false;
  }

  Future<void> cancelAll() async {
    await NotificationsFacade.I.cancelByModule(NotificationModule.gym);
  }
}


