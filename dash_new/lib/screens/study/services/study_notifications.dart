import 'study_firestore_service.dart';
import '../models/study_models.dart';
import 'package:intl/intl.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart';

class StudyNotifications {
  final StudyFirestoreService svc;
  StudyNotifications(this.svc);

  // Schedule alerts for upcoming classes today (15 minutes before)
  Future<void> scheduleTodayClasses() async {
    final now = DateTime.now();
    final weekday = now.weekday; // 1..7
    final blocks = await svc.streamSchedule().first;
    for (final b in blocks) {
      if (!b.daysOfWeek.contains(weekday)) continue;
      final startToday = DateTime(now.year, now.month, now.day, b.start.hour, b.start.minute);
      final when = startToday.subtract(const Duration(minutes: 15));
      if (when.isAfter(now)) {
        await NotificationService.I.scheduleOnce(
          id: _id('CLASS', b, when),
          title: 'Clase próxima',
          body: 'Clase de ${b.courseId} en 15 minutos${b.room!=null? ' (${b.room})':''}',
          whenLocal: when,
          useExact: true,
        );
      }
    }
  }

  // Schedule alerts for tasks (1 day before and same day morning)
  Future<void> scheduleDueTasks() async {
    final tasks = await svc.streamTasks().first;
    for (final t in tasks) {
      if (t.due == null) continue;
      final due = DateTime(t.due!.year, t.due!.month, t.due!.day);
      final oneDayBefore = due.subtract(const Duration(days: 1));
      final sameDay = DateTime(due.year, due.month, due.day, 8, 0);

      if (oneDayBefore.isAfter(DateTime.now())) {
        await NotificationService.I.scheduleOnce(
          id: _hash('TASK1', t.id, oneDayBefore),
          title: 'Tarea próxima',
          body: 'Entrega de ${t.title} mañana',
          whenLocal: oneDayBefore,
          useExact: false,
        );
      }
      if (sameDay.isAfter(DateTime.now())) {
        await NotificationService.I.scheduleOnce(
          id: _hash('TASK2', t.id, sameDay),
          title: 'Entrega hoy',
          body: 'Hoy vence ${t.title}',
          whenLocal: sameDay,
          useExact: false,
        );
      }
    }
  }

  int _id(String prefix, StudyClassBlock b, DateTime when) => _hash(prefix, '${b.courseId}-${b.start.hour}:${b.start.minute}', when);
  int _hash(String prefix, String key, DateTime when) => (prefix + key + DateFormat('yyyyMMddHHmm').format(when)).hashCode;

  // Convenience: schedule everything based on flags
  Future<void> scheduleAll({bool classes = true, bool tasks = true}) async {
    if (classes) {
      await scheduleTodayClasses();
    }
    if (tasks) {
      await scheduleDueTasks();
    }
  }
}
