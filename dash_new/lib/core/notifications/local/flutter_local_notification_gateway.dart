import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:focuslane/core/notifications/local/android_channel_catalog.dart';
import 'package:focuslane/core/notifications/local/local_notification_gateway.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  FlutterLocalNotificationGateway({
    Future<void> Function(String rawPayload)? onTapPayload,
  }) : _onTapPayload = onTapPayload;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void> Function(String rawPayload)? _onTapPayload;
  bool _initialized = false;

  late final Map<String, AndroidNotificationChannel> _androidChannels = {
    AndroidChannelCatalog.defaultChannel: const AndroidNotificationChannel(
      'default_channel',
      'General',
      description: 'Notificaciones generales',
      importance: Importance.defaultImportance,
    ),
    AndroidChannelCatalog.tasksReminders: const AndroidNotificationChannel(
      'tasks_reminders_channel',
      'Recordatorios de tareas',
      description: 'Recordatorios de tareas',
      importance: Importance.high,
    ),
    AndroidChannelCatalog.habitsReminders: const AndroidNotificationChannel(
      'habits_reminders_channel',
      'Recordatorios de habitos',
      description: 'Recordatorios de habitos',
      importance: Importance.high,
    ),
    AndroidChannelCatalog.calendarReminders: const AndroidNotificationChannel(
      'calendar_reminders_channel',
      'Recordatorios de calendario',
      description: 'Recordatorios de calendario',
      importance: Importance.defaultImportance,
    ),
    AndroidChannelCatalog.financeReminders: const AndroidNotificationChannel(
      'finance_reminders_channel',
      'Recordatorios de finanzas',
      description: 'Recordatorios de finanzas',
      importance: Importance.defaultImportance,
    ),
    AndroidChannelCatalog.studyReminders: const AndroidNotificationChannel(
      'study_reminders_channel',
      'Recordatorios de estudio',
      description: 'Recordatorios de estudio',
      importance: Importance.high,
    ),
    AndroidChannelCatalog.foodReminders: const AndroidNotificationChannel(
      'food_reminders_channel',
      'Recordatorios de comida',
      description: 'Recordatorios de comida',
      importance: Importance.defaultImportance,
    ),
    AndroidChannelCatalog.gymReminders: const AndroidNotificationChannel(
      'gym_reminders_channel',
      'Recordatorios de gym',
      description: 'Recordatorios de gym',
      importance: Importance.defaultImportance,
    ),
  };

  void setTapHandler(Future<void> Function(String rawPayload) onTapPayload) {
    _onTapPayload = onTapPayload;
  }

  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tzdata.initializeTimeZones();
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();
      final tzName = tzInfo.toString();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;
        _handleTapPayload(payload);
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchPayload != null && launchPayload.isNotEmpty) {
      _handleTapPayload(launchPayload);
    }

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      for (final ch in _androidChannels.values) {
        await androidImpl.createNotificationChannel(ch);
      }
    }

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, sound: true, badge: true);
  }

  void _handleTapPayload(String rawPayload) {
    final handler = _onTapPayload;
    if (handler == null) return;
    handler(rawPayload);
  }

  @override
  Future<void> showNow({
    required int localId,
    required String title,
    required String body,
    required String payload,
    required String channel,
  }) {
    return _plugin.show(
      localId,
      title,
      body,
      NotificationDetails(
        android: _androidDetails(channel),
        iOS: _iosDetails(),
      ),
      payload: payload,
    );
  }

  @override
  Future<void> zonedSchedule({
    required int localId,
    required DateTime whenUtc,
    required String title,
    required String body,
    required String payload,
    required String channel,
    required bool allowWhileIdle,
    required LocalRepeatRule repeatRule,
    List<int> weekdays = const [],
  }) async {
    final local = whenUtc.toLocal();
    final schedule = tz.TZDateTime.from(local, tz.local);

    final details = NotificationDetails(
      android: _androidDetails(channel),
      iOS: _iosDetails(),
    );

    if (repeatRule == LocalRepeatRule.none) {
      await _plugin.zonedSchedule(
        localId,
        title,
        body,
        schedule,
        details,
        payload: payload,
        androidScheduleMode:
            allowWhileIdle ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return;
    }

    if (repeatRule == LocalRepeatRule.daily) {
      await _plugin.zonedSchedule(
        localId,
        title,
        body,
        schedule,
        details,
        payload: payload,
        androidScheduleMode:
            allowWhileIdle ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return;
    }

    if (repeatRule == LocalRepeatRule.weekly) {
      for (final weekday in weekdays) {
        final nextForDay = _nextInstanceOfWeekday(
          weekday,
          local.hour,
          local.minute,
        );
        await _plugin.zonedSchedule(
          _derivedWeeklyId(localId, weekday),
          title,
          body,
          nextForDay,
          details,
          payload: payload,
          androidScheduleMode:
              allowWhileIdle ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      return;
    }
  }

  @override
  Future<void> cancel(int localId) async {
    await _plugin.cancel(localId);
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(_derivedWeeklyId(localId, weekday));
    }
  }

  @override
  Future<List<PendingLocalNotification>> pending() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending
        .map((p) => PendingLocalNotification(localId: p.id, payload: p.payload))
        .toList(growable: false);
  }

  AndroidNotificationDetails _androidDetails(String channelKey) {
    final channel = _androidChannels[channelKey] ?? _androidChannels[AndroidChannelCatalog.defaultChannel]!;
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority:
          channel.importance == Importance.high ? Priority.high : Priority.defaultPriority,
    );
  }

  DarwinNotificationDetails _iosDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _derivedWeeklyId(int baseLocalId, int weekday) {
    final input = 'weekly:$baseLocalId:$weekday';
    const fnvPrime = 16777619;
    const fnvOffset = 2166136261;
    var hash = fnvOffset;
    for (var i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}

