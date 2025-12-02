import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/screens/gym/models/gym_models.dart';
import 'package:mi_dashboard_personal/screens/gym/services/gym_firestore_service.dart';
import 'routines/routines_list_screen.dart';
import 'routines/routine_detail_screen.dart';
import 'package:mi_dashboard_personal/services/notification_service.dart'; // 🔔

class GymHomeScreen extends StatefulWidget {
  final GymFirestoreService svc;
  const GymHomeScreen({super.key, required this.svc});

  @override
  State<GymHomeScreen> createState() => _GymHomeScreenState();
}

class _GymHomeScreenState extends State<GymHomeScreen> {
  // IDs fijos para que podamos cancelar/reprogramar sin duplicados
  static const int _weeklyWeightId   = 22010;
  static const int _weeklyMeasureId  = 22011;
  static const int _inactivityId     = 22001; // mismo que en LiveSessionScreen

  Future<void> _scheduleGymReminders() async {
    // 🔔 Recordatorios semanales (próximo lunes 09:00)
    DateTime nextWeekday(int weekday, {int hour = 9, int minute = 0}) {
      final now = DateTime.now();
      int add = (weekday - now.weekday) % 7;
      if (add == 0) add = 7; // siempre la próxima semana
      final d = now.add(Duration(days: add));
      return DateTime(d.year, d.month, d.day, hour, minute);
      // Nota: se programa una vez; al volver a abrir Gym se reprograma a la próxima.
    }

    await NotificationService.I.cancel(_weeklyWeightId);
    await NotificationService.I.cancel(_weeklyMeasureId);

    final nextMon = nextWeekday(DateTime.monday, hour: 9);
    await NotificationService.I.scheduleOnce(
      id: _weeklyWeightId,
      title: 'Control semanal',
      body: 'Pésate y registra tu peso 📉',
      whenLocal: nextMon,
      useExact: false,
    );

    final nextMon2 = nextWeekday(DateTime.monday, hour: 9, minute: 5);
    await NotificationService.I.scheduleOnce(
      id: _weeklyMeasureId,
      title: 'Medidas corporales',
      body: 'Toca medir perímetros (pecho, brazo, cintura…) 📏',
      whenLocal: nextMon2,
      useExact: false,
    );

    // 🔔 Inactividad: si hace >= X días, programa para hoy 10:00; si no, desde la última
    const xDays = 3;
    await NotificationService.I.cancel(_inactivityId);
    final last = await widget.svc.lastSessionDate();
    DateTime base;
    if (last == null) {
      base = DateTime.now().add(Duration(days: xDays));
    } else {
      base = last.add(Duration(days: xDays));
      if (base.isBefore(DateTime.now())) {
        base = DateTime.now().add(const Duration(minutes: 5)); // si ya pasaste el umbral, avisa pronto
      }
    }
    final at = DateTime(base.year, base.month, base.day, 10, 0);
    await NotificationService.I.scheduleOnce(
      id: _inactivityId,
      title: 'Vuelve al gym',
      body: 'Llevas $xDays días sin entrenar. ¡Toca sesión! 💪',
      whenLocal: at,
      useExact: false,
    );
  }

  @override
  void initState() {
    super.initState();
    // Programa/actualiza recordatorios al abrir la pantalla
    _scheduleGymReminders();
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;
    return Scaffold(
      appBar: AppBar(title: const Text('Gimnasio')),
      body: StreamBuilder<Routine?>(
        stream: svc.streamDefaultRoutine(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final def = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (def != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.push_pin),
                    title: Text(def.name),
                    subtitle: const Text('Ir directamente'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoutineDetailScreen(svc: svc, routine: def),
                        ),
                      );
                    },
                    trailing: IconButton(
                      tooltip: 'Reprogramar recordatorios',
                      icon: const Icon(Icons.notifications_active_outlined),
                      onPressed: _scheduleGymReminders, // por si quieres forzar manualmente
                    ),
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('Todas mis rutinas'),
                  subtitle: const Text('Crear, editar, seleccionar predeterminada'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RoutinesListScreen(svc: svc)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
