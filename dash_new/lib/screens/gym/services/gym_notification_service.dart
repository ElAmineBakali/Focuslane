import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

  class GymNotificationService {
  GymNotificationService._();
  static final GymNotificationService I = GymNotificationService._();

     static const int _inactivityId = 22001;
  static const int _weeklyWeightId = 22002;
  static const int _mondayMeasurementsId = 22003;

     static const String _keyInactivityDays = 'gym_inactivity_days';
  static const String _keyWeightReminderEnabled = 'gym_weight_reminder_enabled';
  static const String _keyWeightReminderDay = 'gym_weight_reminder_day';
  static const String _keyWeightReminderTime = 'gym_weight_reminder_time';
  static const String _keyMeasurementsReminderEnabled = 'gym_measurements_reminder_enabled';
  static const String _keyMeasurementsReminderTime = 'gym_measurements_reminder_time';

     static const int _defaultInactivityDays = 3;
  static const int _defaultWeightDay = DateTime.monday;
  static const int _defaultWeightHour = 8;
  static const int _defaultWeightMinute = 0;
  static const int _defaultMeasurementsHour = 9;
  static const int _defaultMeasurementsMinute = 0;

     
                    Future<void> scheduleRoutineDayReminder({
    required String routineId,
    required String routineName,
    required String dayId,
    required String dayName,
    required int weekday,
    required TimeOfDay time,
  }) async {
    final id = 'gym_routine_${routineId}_$dayId';
    await NotificationService.I.scheduleWeeklyReminder(
      id: id,
      title: '💪 Día de entrenamiento',
      body: '$routineName - $dayName',
      weekdays: [_dayIntToEnum(weekday)],
      time: time,
      payload: 'GYM_ROUTINE|$routineId|$dayId',
    );
  }

     Future<void> cancelRoutineDayReminder({
    required String routineId,
    required String dayId,
  }) async {
    final id = 'gym_routine_${routineId}_$dayId';
    await NotificationService.I.cancelNotificationById(id);
  }

     Future<void> cancelAllRoutineReminders(String routineId) async {
    final id = 'gym_routine_$routineId';
    await NotificationService.I.cancelNotificationById(id);
  }

   
        Future<void> scheduleInactivityReminder({int days = _defaultInactivityDays}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyInactivityDays, days);

    await NotificationService.I.cancel(_inactivityId);
    
    final base = DateTime.now().add(Duration(days: days));
    final at = DateTime(base.year, base.month, base.day, 10, 0);      
    await NotificationService.I.scheduleOnce(
      id: _inactivityId,
      title: '🏋️ Vuelve al gym',
      body: 'Llevas $days días sin entrenar. ¡Hora de una sesión!',
      whenLocal: at,
      useExact: false,
      payload: 'GYM_INACTIVITY',
    );
  }

     Future<void> cancelInactivityReminder() async {
    await NotificationService.I.cancel(_inactivityId);
  }

     Future<int> getInactivityDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyInactivityDays) ?? _defaultInactivityDays;
  }

   
     Future<void> scheduleWeeklyWeightReminder({
    int weekday = _defaultWeightDay,
    TimeOfDay? time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeightReminderEnabled, true);
    await prefs.setInt(_keyWeightReminderDay, weekday);
    
    final t = time ?? const TimeOfDay(hour: _defaultWeightHour, minute: _defaultWeightMinute);
    await prefs.setInt(_keyWeightReminderTime, t.hour * 60 + t.minute);

    await NotificationService.I.cancel(_weeklyWeightId);
    await NotificationService.I.scheduleWeeklyReminder(
      id: 'gym_weekly_weight',
      title: '⚖️ Registro de peso',
      body: 'Es momento de registrar tu peso corporal',
      weekdays: [_dayIntToEnum(weekday)],
      time: t,
      payload: 'GYM_WEIGHT',
    );
  }

     Future<void> cancelWeeklyWeightReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeightReminderEnabled, false);
    await NotificationService.I.cancel(_weeklyWeightId);
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
    
    final t = time ?? const TimeOfDay(hour: _defaultMeasurementsHour, minute: _defaultMeasurementsMinute);
    await prefs.setInt(_keyMeasurementsReminderTime, t.hour * 60 + t.minute);

    await NotificationService.I.cancel(_mondayMeasurementsId);
    await NotificationService.I.scheduleWeeklyReminder(
      id: 'gym_weekly_measurements',
      title: '📏 Medidas corporales',
      body: 'Registra tus medidas físicas de esta semana',
      weekdays: [_dayIntToEnum(weekday)],
      time: t,
      payload: 'GYM_MEASUREMENTS',
    );
  }

     Future<void> cancelWeeklyMeasurementsReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMeasurementsReminderEnabled, false);
    await NotificationService.I.cancel(_mondayMeasurementsId);
  }

     Future<bool> isMeasurementsReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMeasurementsReminderEnabled) ?? false;
  }

   
     Day _dayIntToEnum(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return Day.monday;
      case DateTime.tuesday:
        return Day.tuesday;
      case DateTime.wednesday:
        return Day.wednesday;
      case DateTime.thursday:
        return Day.thursday;
      case DateTime.friday:
        return Day.friday;
      case DateTime.saturday:
        return Day.saturday;
      case DateTime.sunday:
        return Day.sunday;
      default:
        return Day.monday;
    }
  }

     Future<void> cancelAll() async {
    await NotificationService.I.cancel(_inactivityId);
    await NotificationService.I.cancel(_weeklyWeightId);
    await NotificationService.I.cancel(_mondayMeasurementsId);
    await NotificationService.I.cancelAllNotificationsForModule('gym');
  }
}
