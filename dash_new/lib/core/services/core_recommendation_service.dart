import 'dart:math';

import '../models/core_daily_stats.dart';
import '../models/core_entity_ref.dart';
import '../models/core_recommendation.dart';
import '../utils/date_utils.dart';

class CoreRecommendationService {
  CoreRecommendationService._();
  static final CoreRecommendationService I = CoreRecommendationService._();

  List<CoreRecommendation> build(
    CoreDailyStats s, {
    double? targetKcal,
    double? targetProtein,
    double? targetWater,
  }) {
    final out = <CoreRecommendation>[];
    final nowId = DateTime.now().millisecondsSinceEpoch;
    final dayDate = _safeDateFromDayId(s.dayId);
    final tomorrow = dayDate.add(const Duration(days: 1));
    List<CoreEntityRef> refsOf(CoreEntityType t) =>
        s.sources.where((r) => r.type == t).take(4).toList();

    if (targetProtein != null && targetProtein > 0 && s.protein < targetProtein * 0.7) {
      out.add(
        CoreRecommendation(
          id: '${s.dayId}-protein-$nowId',
          dayId: s.dayId,
          title: 'Proteína baja',
          message: 'Vas por debajo del 70% de la proteína objetivo. Refuerza la próxima comida.',
          severity: CoreRecommendationSeverity.high,
          references: refsOf(CoreEntityType.foodIntakeEntry),
          actions: [
            CoreAction(
              id: 'act-plan-protein-$nowId',
              label: 'Añadir a plan (mañana cena)',
              type: CoreActionType.addMealPlanSlot,
              payload: {
                'type': 'food',
                'dayId': dayIdFromDateTime(tomorrow),
                'slot': 'dinner',
                'note': 'Cena alta en proteína',
              },
            ),
            CoreAction(
              id: 'act-shop-protein-$nowId',
              label: 'Añadir ingredientes a compra',
              type: CoreActionType.addShoppingItem,
              payload: {
                'items': ['Pechuga de pollo', 'Huevos', 'Yogur griego'],
              },
            ),
          ],
        ),
      );
    }

    if (s.studyMinutes < 45 && s.tasksTotal > s.tasksDone) {
      final start = dayDate.add(const Duration(hours: 18));
      final end = start.add(const Duration(minutes: 45));
      out.add(
        CoreRecommendation(
          id: '${s.dayId}-study-$nowId',
          dayId: s.dayId,
          title: 'Bloque de estudio sugerido',
          message: 'Refuerza las tareas pendientes con un bloque de 45 minutos.',
          severity: CoreRecommendationSeverity.med,
          references: refsOf(CoreEntityType.task),
          actions: [
            CoreAction(
              id: 'act-study-cal-$nowId',
              label: 'Bloquear en calendario',
              type: CoreActionType.createCalendarEvent,
              payload: {
                'title': 'Bloque de estudio',
                'start': start.toIso8601String(),
                'end': end.toIso8601String(),
                'type': 'study',
              },
            ),
            CoreAction(
              id: 'act-study-session-$nowId',
              label: 'Crear sesión de estudio',
              type: CoreActionType.createStudySessionPreset,
              payload: {
                'minutes': 45,
                'method': 'pomodoro',
                'taskId':
                    refsOf(CoreEntityType.task).isNotEmpty
                        ? refsOf(CoreEntityType.task).first.id
                        : null,
              },
            ),
          ],
        ),
      );
    }

    if (targetWater != null && targetWater > 0 && s.waterMl < targetWater * 0.8) {
      out.add(
        CoreRecommendation(
          id: '${s.dayId}-water-$nowId',
          dayId: s.dayId,
          title: 'Hidratación baja',
          message: 'Te falta beber ${(targetWater - s.waterMl).clamp(0, targetWater).toStringAsFixed(0)} ml para llegar al objetivo.',
          severity: CoreRecommendationSeverity.low,
          actions: [
            CoreAction(
              id: 'act-water-$nowId',
              label: 'Agregar 300 ml',
              type: CoreActionType.createTask,
              payload: {
                'title': 'Beber 300 ml de agua',
                'due': dayDate.toIso8601String(),
                'priority': 'media',
              },
            ),
          ],
        ),
      );
    }

    if (s.financeSpentFood > 0 && s.financeSpentTotal > 0 && s.financeSpentFood > s.financeSpentTotal * 0.45) {
      final planned = max(5, s.financeSpentFood * 0.2);
      out.add(
        CoreRecommendation(
          id: '${s.dayId}-fin-food-$nowId',
          dayId: s.dayId,
          title: 'Gasto alto en comida',
          message: 'Más del 45% del gasto del día es comida. Ajusta el presupuesto.',
          severity: CoreRecommendationSeverity.med,
          references: refsOf(CoreEntityType.financeTransaction),
          actions: [
            CoreAction(
              id: 'act-fin-draft-$nowId',
              label: 'Crear presupuesto comida',
              type: CoreActionType.createFinanceTransactionDraft,
              payload: {
                'amount': planned,
                'category': 'food',
                'title': 'Presupuesto diario comida',
                'planned': true,
                'date': dayIdFromDateTime(tomorrow),
              },
            ),
            CoreAction(
              id: 'act-fin-review-$nowId',
              label: 'Revisar gastos de comida',
              type: CoreActionType.createTask,
              payload: {
                'title': 'Revisar gastos de comida',
                'due': dayDate.toIso8601String(),
                'priority': 'alta',
              },
            ),
          ],
        ),
      );
    }

    if (s.workoutsCount == 0) {
      final start = dayDate.add(const Duration(days: 1, hours: 7));
      final end = start.add(const Duration(minutes: 60));
      out.add(
        CoreRecommendation(
          id: '${s.dayId}-gym-$nowId',
          dayId: s.dayId,
          title: 'Programa tu entrenamiento',
          message: 'No hay entrenos registrados. Agenda uno para mañana.',
          severity: CoreRecommendationSeverity.med,
          actions: [
            CoreAction(
              id: 'act-gym-cal-$nowId',
              label: 'Programar entreno mañana',
              type: CoreActionType.createCalendarEvent,
              payload: {
                'title': 'Entrenamiento',
                'start': start.toIso8601String(),
                'end': end.toIso8601String(),
                'type': 'gym',
              },
            ),
          ],
        ),
      );
    }

    return out;
  }

  DateTime _safeDateFromDayId(String dayId) {
    try {
      return DateTime.parse(dayId);
    } catch (_) {
      return DateTime.now();
    }
  }
}