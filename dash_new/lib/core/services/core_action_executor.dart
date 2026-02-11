import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/calendar_aggregator_service.dart';
import '../../ui/feedback/focus_feedback.dart';
import '../../screens/tasks/task_model.dart';
import '../../screens/finance/models/transaction_model.dart';
import '../../screens/finance/services/transaction_service.dart';
import '../../screens/food/services/food_firestore_service.dart';
import '../../screens/study/models/study_models.dart';
import '../models/core_entity_ref.dart';
import '../models/core_recommendation.dart';
import '../utils/date_utils.dart';

class CoreActionExecutor {
  CoreActionExecutor._();
  static final CoreActionExecutor I = CoreActionExecutor._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<void> executeAction(
    BuildContext context,
    CoreAction action, {
    CoreEntityRef? origin,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      FocusFeedback.showError(context, 'Inicia sesión para ejecutar acciones');
      return;
    }
    final actionId = _computeActionId(uid, action, origin: origin);
    try {
      switch (action.type) {
        case CoreActionType.createTask:
          await _createTask(uid, action.payload, actionId);
          FocusFeedback.showSuccess(context, 'Tarea creada');
          break;
        case CoreActionType.createCalendarEvent:
        case CoreActionType.addMealPlanSlot:
          await CalendarAggregatorService.I.addEventFromCoreAction(
            action,
            actionId: actionId,
            ref: origin,
          );
          FocusFeedback.showSuccess(context, 'Evento creado');
          break;
        case CoreActionType.addShoppingItem:
          await _addShoppingItems(uid, action.payload, actionId);
          FocusFeedback.showSuccess(context, 'Añadido a la lista de compra');
          break;
        case CoreActionType.createFinanceTransactionDraft:
          await _createFinanceDraft(uid, action.payload, actionId);
          FocusFeedback.showSuccess(context, 'Movimiento creado');
          break;
        case CoreActionType.createStudySessionPreset:
          await _createStudySession(uid, action.payload, actionId);
          FocusFeedback.showSuccess(context, 'Sesión de estudio creada');
          break;
      }
    } catch (_) {
      FocusFeedback.showError(context, 'No se pudo completar la acción');
    }
  }

  String _computeActionId(String uid, CoreAction action, {CoreEntityRef? origin}) {
    final payload = Map<String, dynamic>.from(action.payload);
    final dayId = _extractDayId(payload, origin: origin);
    final entries = payload.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final payloadStr = entries.map((e) => '${e.key}:${e.value}').join('|');
    final raw = '$uid|${dayId ?? ''}|${action.type.name}|$payloadStr';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  String? _extractDayId(Map<String, dynamic> payload, {CoreEntityRef? origin}) {
    final raw = payload['dayId'] ?? payload['date'] ?? payload['due'] ?? payload['start'];
    if (raw is Timestamp) return dayIdFromTimestamp(raw);
    if (raw is DateTime) return dayIdFromDateTime(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        return dayIdFromDateTime(DateTime.parse(raw));
      } catch (_) {}
    }
    return origin?.dayId;
  }

  Future<void> _createTask(String uid, Map<String, dynamic> payload, String actionId) async {
    final title = (payload['title'] ?? 'Tarea rápida').toString();
    final description = (payload['description'] ?? '').toString();
    final priorityRaw = (payload['priority'] ?? 'media').toString();
    final priority = TaskPriority.fromString(priorityRaw);
    final dueRaw = payload['due'];
    DateTime? dueDate;
    if (dueRaw is String) {
      dueDate = DateTime.tryParse(dueRaw);
    }
    final dup = await _db
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('relatedActionId', isEqualTo: actionId)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) return;

    final task = Task(
      id: '',
      title: title,
      description: description,
      priority: priority,
      category: null,
      dueDate: dueDate,
      reminderTime: null,
      completed: false,
      order: null,
      tags: const [],
      remindAt: null,
      isPinned: false,
      repeatRule: RepeatRule.none,
      subtasks: const [],
      isCalendarVisible: true,
      linkedNoteId: null,
      linkedStudyCourseId: null,
      syncedStudyTaskId: null,
    );
    final map = task.toMap()
      ..remove('id')
      ..['relatedActionId'] = actionId
      ..['origin'] = 'coreAction';
    await _db.collection('users').doc(uid).collection('tasks').add(map);
  }

  Future<void> _addShoppingItems(String uid, Map<String, dynamic> payload, String actionId) async {
    final itemsRaw = payload['items'] ?? payload['item'] ?? payload['name'];
    final list = <String>[];
    if (itemsRaw is List) {
      list.addAll(itemsRaw.map((e) => e.toString()));
    } else if (itemsRaw != null) {
      list.add(itemsRaw.toString());
    }
    if (list.isEmpty) return;

    final listsCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('food')
        .doc('root')
        .collection('shoppingLists');
    DocumentSnapshot<Map<String, dynamic>>? doc;
    var target = await listsCol.where('isDefault', isEqualTo: true).limit(1).get();
    if (target.docs.isNotEmpty) {
      doc = target.docs.first;
    } else {
      target = await listsCol.limit(1).get();
      if (target.docs.isNotEmpty) {
        doc = target.docs.first;
      }
    }

    if (doc == null) {
      final svc = FoodFirestoreService(uid);
      final id = await svc.createShoppingList('Automática', isDefault: true);
      doc = await listsCol.doc(id).get();
    }

    if (doc == null || !doc.exists) return;

    final ref = doc.reference;
    final data = doc.data() ?? {};
    final items = ((data['items'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (items.any((e) => e['relatedActionId']?.toString() == actionId)) return;
    for (final name in list) {
      if (items.any((e) => (e['name'] ?? '').toString().toLowerCase() == name.toLowerCase())) {
        continue;
      }
      items.add({
        'name': name,
        'category': payload['category'] ?? 'General',
        'checked': false,
        'relatedActionId': actionId,
      });
    }
    await ref.set({'items': items, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  Future<void> _createFinanceDraft(String uid, Map<String, dynamic> payload, String actionId) async {
    final dup = await FirebaseFirestore.instance
        .collection('finance_transactions')
        .where('userId', isEqualTo: uid)
        .where('relatedTxId', isEqualTo: actionId)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) return;
    final amount = (payload['amount'] as num?)?.toDouble() ?? 0;
    final title = (payload['title'] ?? 'Movimiento planificado').toString();
    final category = (payload['category'] ?? '').toString();
    final typeRaw = (payload['type'] ?? 'expense').toString();
    final type = typeRaw == 'income' ? TxType.income : TxType.expense;
    final dateRaw = payload['date'];
    DateTime date = DateTime.now();
    if (dateRaw is String) {
      date = DateTime.tryParse(dateRaw) ?? date;
    }
    final tx = FinanceTransaction(
      id: '',
      userId: uid,
      date: date,
      type: type,
      title: title,
      amount: amount,
      category: category.isEmpty ? null : category,
      subCategory: null,
      accountId: null,
      notes: payload['notes']?.toString(),
      tags: const [],
      originalCurrency: null,
      fxRate: null,
      recurrence: null,
      envelopeId: null,
      relatedTxId: actionId,
    );
    await TransactionService.I.create(tx);
  }

  Future<void> _createStudySession(String uid, Map<String, dynamic> payload, String actionId) async {
    final minutes = (payload['minutes'] as num?)?.toInt() ?? 45;
    final methodRaw = (payload['method'] ?? 'pomodoro').toString();
    final method = StudyMethod.values.firstWhere(
      (m) => m.name == methodRaw,
      orElse: () => StudyMethod.pomodoro,
    );
    final taskId = payload['taskId']?.toString();
    final courseId = payload['courseId']?.toString() ?? '';
    final dateRaw = payload['date'];
    DateTime date = DateTime.now();
    if (dateRaw is String) {
      date = DateTime.tryParse(dateRaw) ?? date;
    }
    final dup = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('sessions')
        .where('relatedActionId', isEqualTo: actionId)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) return;
    final session = StudySession(
      id: '',
      courseId: courseId,
      taskId: taskId?.isEmpty ?? true ? null : taskId,
      method: method,
      minutes: minutes,
      laps: null,
      cycles: null,
      configSnapshot: {'origin': 'coreAction'},
      notes: payload['notes']?.toString(),
      date: date,
    );
    final map = session.toMap()..['relatedActionId'] = actionId;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('study')
        .doc('root')
        .collection('sessions')
        .add(map);
  }
}
