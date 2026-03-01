import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService I = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final _payloadCtrl = StreamController<String>.broadcast();

  late final Map<String, AndroidNotificationChannel> _androidChannels = {
    'default': const AndroidNotificationChannel(
      'default_channel',
      'General',
      description: 'Notificaciones generales',
      importance: Importance.defaultImportance,
    ),
    'habit': const AndroidNotificationChannel(
      'habit_channel',
      'H├íbitos',
      description: 'Recordatorios de h├íbitos',
      importance: Importance.high,
    ),
    'task': const AndroidNotificationChannel(
      'task_channel',
      'Tareas',
      description: 'Recordatorios de tareas',
      importance: Importance.high,
    ),
    'meditation': const AndroidNotificationChannel(
      'meditation_channel',
      'Meditaci├│n',
      description: 'Recordatorios de meditaci├│n',
      importance: Importance.defaultImportance,
    ),
    'gym': const AndroidNotificationChannel(
      'gym_channel',
      'Gym',
      description: 'Recordatorios de entrenamiento',
      importance: Importance.defaultImportance,
    ),
    'finance': const AndroidNotificationChannel(
      'finance_channel',
      'Finanzas',
      description: 'Recordatorios financieros',
      importance: Importance.defaultImportance,
    ),
  };

  Stream<String> get onPayload => _payloadCtrl.stream;

  Future<void> initialize() async {
    await init();
  }

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      String tzName;
      try {
        tzName = (tzInfo as dynamic).name as String;
      } catch (_) {
        try {
          tzName = (tzInfo as dynamic).timezone as String;
        } catch (_) {
          tzName = tzInfo.toString();
        }
      }
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final settings = const InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (kDebugMode) {
          print('[NotificationService] onSelect payload: $payload');
        }
        if (payload != null) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            final p = (data['payload'] ?? '') as String;
            if (p.isNotEmpty) _payloadCtrl.add(p);
          } catch (_) {
            _payloadCtrl.add(payload);
          }
        }
      },
    );

    await _requestIOSPermissions();

    final androidImpl =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidImpl != null) {
      for (final ch in _androidChannels.values) {
        await androidImpl.createNotificationChannel(ch);
      }
    }

    if (kDebugMode) {
      print('[NotificationService] Initialized');
    }
  }

  Future<void> _requestIOSPermissions() async {
    try {
      final iosImpl =
          _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final granted = await iosImpl?.requestPermissions(
        alert: true,
        sound: true,
        badge: true,
      );
      if (kDebugMode) {
        print('[NotificationService] iOS permissions granted: $granted');
      }
    } catch (_) {}
  }

  AndroidNotificationDetails _androidDetailsForId(String id) {
    final module = _moduleKeyFromId(id);
    final ch = _androidChannels[module] ?? _androidChannels['default']!;
    return AndroidNotificationDetails(
      ch.id,
      ch.name,
      channelDescription: ch.description,
      importance: ch.importance,
      priority:
          ch.importance == Importance.high
              ? Priority.high
              : Priority.defaultPriority,
    );
  }

  DarwinNotificationDetails _iosDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  String _moduleKeyFromId(String id) {
    final idx = id.indexOf('_');
    if (idx > 0) return id.substring(0, idx);
    return 'default';
  }

  int _stringToIntId(String input) {
    const int fnvPrime = 16777619;
    const int fnvOffset = 2166136261;
    int hash = fnvOffset;
    for (int i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time, {tz.TZDateTime? from}) {
    final now = from ?? tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(
    int weekday,
    TimeOfDay time, {
    tz.TZDateTime? from,
  }) {
    final now = from ?? tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Map<String, dynamic> _buildPayload({
    required String id,
    required String? payload,
  }) {
    return {
      'id': id,
      'groupId': _baseGroupId(id),
      'module': _moduleKeyFromId(id),
      'payload': payload ?? '',
    };
  }

  String _baseGroupId(String id) {
    final idx = id.indexOf('#');
    return idx > 0 ? id.substring(0, idx) : id;
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: _androidDetailsForId('default_show'),
      iOS: _iosDetails(),
    );
    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: jsonEncode(
        _buildPayload(id: 'default_show_$id', payload: payload),
      ),
    );
    if (kDebugMode) {
      print('[NotificationService] showNow id=$id title="$title"');
    }
  }

  Future<void> scheduleDailyReminder({
    required String id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    final intId = _stringToIntId(id);
    final schedule = _nextInstanceOfTime(time);
    final details = NotificationDetails(
      android: _androidDetailsForId(id),
      iOS: _iosDetails(),
    );

    await _plugin.zonedSchedule(
      intId,
      title,
      body,
      schedule,
      details,
      payload: jsonEncode(_buildPayload(id: id, payload: payload)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    if (kDebugMode) {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      print('[NotificationService] scheduleDaily id=$id @ $hh:$mm');
    }
  }

  Future<void> scheduleOneTimeNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    final intId = _stringToIntId(id);
    final when = tz.TZDateTime.from(scheduledTime, tz.local);
    final details = NotificationDetails(
      android: _androidDetailsForId(id),
      iOS: _iosDetails(),
    );

    await _plugin.zonedSchedule(
      intId,
      title,
      body,
      when,
      details,
      payload: jsonEncode(_buildPayload(id: id, payload: payload)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    if (kDebugMode) {
      print('[NotificationService] scheduleOneTime id=$id @ $scheduledTime');
    }
  }

  Future<void> scheduleWeeklyReminder({
    required String id,
    required String title,
    required String body,
    required List<Day> weekdays,
    required TimeOfDay time,
    String? payload,
  }) async {
    for (final d in weekdays) {
      final weekday = _weekdayFromPluginDay(d);
      final composedId = '$id#$weekday';
      final intId = _stringToIntId(composedId);
      final schedule = _nextInstanceOfWeekday(weekday, time);
      final details = NotificationDetails(
        android: _androidDetailsForId(id),
        iOS: _iosDetails(),
      );

      await _plugin.zonedSchedule(
        intId,
        title,
        body,
        schedule,
        details,
        payload: jsonEncode(_buildPayload(id: composedId, payload: payload)),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      if (kDebugMode) {
        print(
          '[NotificationService] scheduleWeekly id=$composedId (base=$id) weekday=$weekday @ ${schedule.toLocal()}',
        );
      }
    }
  }

  int _weekdayFromPluginDay(Day d) {
    switch (d) {
      case Day.monday:
        return DateTime.monday;
      case Day.tuesday:
        return DateTime.tuesday;
      case Day.wednesday:
        return DateTime.wednesday;
      case Day.thursday:
        return DateTime.thursday;
      case Day.friday:
        return DateTime.friday;
      case Day.saturday:
        return DateTime.saturday;
      case Day.sunday:
        return DateTime.sunday;
    }
  }

  Future<void> cancelNotificationById(String id) async {
    final groupId = _baseGroupId(id);
    final pendings = await _plugin.pendingNotificationRequests();
    for (final p in pendings) {
      try {
        if (p.payload == null) continue;
        final data = jsonDecode(p.payload!) as Map<String, dynamic>;
        if (data['groupId'] == groupId) {
          await _plugin.cancel(p.id);
          if (kDebugMode) {
            print(
              '[NotificationService] cancel by groupId=$groupId -> canceled ${p.id}',
            );
          }
        }
      } catch (_) {}
    }
  }

  Future<void> cancelAllNotificationsForModule(String moduleKey) async {
    final pendings = await _plugin.pendingNotificationRequests();
    for (final p in pendings) {
      try {
        if (p.payload == null) continue;
        final data = jsonDecode(p.payload!) as Map<String, dynamic>;
        if (data['module'] == moduleKey) {
          await _plugin.cancel(p.id);
          if (kDebugMode) {
            print(
              '[NotificationService] cancel by module=$moduleKey -> canceled ${p.id}',
            );
          }
        }
      } catch (_) {}
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    if (kDebugMode) print('[NotificationService] cancelAll');
  }

  Future<void> rescheduleNotification({
    required String id,
    String? title,
    String? body,
    DateTime? scheduledTime,
    TimeOfDay? dailyTime,
    List<Day>? weekdays,
    String? payload,
  }) async {
    await cancelNotificationById(id);
    if (weekdays != null && weekdays.isNotEmpty && dailyTime != null) {
      await scheduleWeeklyReminder(
        id: id,
        title: title ?? 'Reminder',
        body: body ?? '',
        weekdays: weekdays,
        time: dailyTime,
        payload: payload,
      );
    } else if (dailyTime != null) {
      await scheduleDailyReminder(
        id: id,
        title: title ?? 'Reminder',
        body: body ?? '',
        time: dailyTime,
        payload: payload,
      );
    } else if (scheduledTime != null) {
      await scheduleOneTimeNotification(
        id: id,
        title: title ?? 'Reminder',
        body: body ?? '',
        scheduledTime: scheduledTime,
        payload: payload,
      );
    } else {
      if (kDebugMode) {
        print(
          '[NotificationService] reschedule: no scheduling data provided for id=$id',
        );
      }
    }
  }

  Future<List<PendingNotificationRequest>> pendingNotificationRequests() {
    return _plugin.pendingNotificationRequests();
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    if (kDebugMode) print('[NotificationService] cancel legacy numericId=$id');
  }

  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
    bool useExact = false,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: _androidDetailsForId('default'),
      iOS: _iosDetails(),
    );
    final tzTime = tz.TZDateTime.from(whenLocal, tz.local);
    final mode =
        useExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      payload: payload,
      androidScheduleMode: mode,
    );
    if (kDebugMode) {
      print('[NotificationService] scheduleOnce legacy id=$id @ $whenLocal');
    }
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay at,
    bool useExact = false,
    String? payload,
    String androidChannelId = 'daily_channel',
    String androidChannelName = 'Diarias',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      at.hour,
      at.minute,
    );
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        androidChannelId,
        androidChannelName,
        channelDescription: 'Recordatorios diarios',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: _iosDetails(),
    );
    final mode =
        useExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      next,
      details,
      payload: payload,
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    if (kDebugMode) {
      print(
        '[NotificationService] scheduleDaily legacy id=$id @ ${next.toLocal()}',
      );
    }
  }

  Future<void> debugStatus() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final enabled = await android?.areNotificationsEnabled();
    final pending = await _plugin.pendingNotificationRequests();
    final nowTz = tz.TZDateTime.now(tz.local);
    print(
      '[NotificationService] TZ=${tz.local} now=$nowTz enabled=$enabled pending=${pending.length}',
    );
    for (final p in pending) {
      print(
        '[NotificationService] -> id=${p.id} title=${p.title} body=${p.body} payload=${p.payload}',
      );
    }
  }

  Future<void> scheduleHabitDailyReminder(TimeOfDay time) async {
    await scheduleDailyReminder(
      id: 'habit_daily_reminder',
      title: 'Recordatorio',
      body: 'Toca para continuar',
      time: time,
      payload: 'OPEN_HABITS',
    );
  }

  Future<void> cancelHabitDailyReminder() async {
    await cancelNotificationById('habit_daily_reminder');
  }
}
