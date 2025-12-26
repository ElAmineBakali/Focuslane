import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_models.dart';

class StudyTasksSyncService {
  final String _fallbackUserId;
  StudyTasksSyncService([this._fallbackUserId = '']);

  String get _uid {
    final u = FirebaseAuth.instance.currentUser?.uid;
    if (u != null && u.isNotEmpty) return u;
    return _fallbackUserId.isNotEmpty ? _fallbackUserId : 'local';
  }

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _studyRoot =>
      _db.collection('users').doc(_uid).collection('study').doc('root');

  DocumentReference<Map<String, dynamic>> get _tasksRoot =>
      _db.collection('users').doc(_uid).collection('tasks').doc('root');

  Future<void> syncTaskStatusToTasks(String? syncedTaskId, TaskStatus newStatus) async {
    if (syncedTaskId == null || syncedTaskId.isEmpty) return;
    try {
      await _tasksRoot.collection('items').doc(syncedTaskId).update({
        'completed': newStatus == TaskStatus.done,
      });
    } catch (_) {}
  }

  Future<void> syncTaskStatusToStudy(String? syncedStudyTaskId, bool completed) async {
    if (syncedStudyTaskId == null || syncedStudyTaskId.isEmpty) return;
    try {
      await _studyRoot.collection('tasks').doc(syncedStudyTaskId).update({
        'status': completed ? TaskStatus.done.name : TaskStatus.todo.name,
      });
    } catch (_) {}
  }

  Future<void> syncStudyTaskDataToTasks(
    String? syncedTaskId,
    String? title,
    String? notes,
    DateTime? due,
    Priority? priority,
  ) async {
    if (syncedTaskId == null || syncedTaskId.isEmpty) return;
    try {
      final updateMap = <String, dynamic>{};
      if (title != null) updateMap['title'] = title;
      if (notes != null) updateMap['description'] = notes;
      if (due != null) updateMap['dueDate'] = Timestamp.fromDate(due);
      if (priority != null) {
        updateMap['priority'] = _studyPriorityToTaskPriorityLabel(priority);
      }
      if (updateMap.isNotEmpty) {
        await _tasksRoot.collection('items').doc(syncedTaskId).update(updateMap);
      }
    } catch (_) {}
  }

  Future<void> syncTaskDataToStudy(
    String? syncedStudyTaskId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priorityLabel,
  ) async {
    if (syncedStudyTaskId == null || syncedStudyTaskId.isEmpty) return;
    try {
      final updateMap = <String, dynamic>{};
      if (title != null) updateMap['title'] = title;
      if (description != null) updateMap['notes'] = description;
      if (dueDate != null) updateMap['due'] = dueDate.toIso8601String();
      if (priorityLabel != null) {
        updateMap['priority'] = _taskPriorityLabelToStudyPriority(priorityLabel).name;
      }
      if (updateMap.isNotEmpty) {
        await _studyRoot.collection('tasks').doc(syncedStudyTaskId).update(updateMap);
      }
    } catch (_) {}
  }

  String _studyPriorityToTaskPriorityLabel(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'alta';
      case Priority.normal:
        return 'media';
      case Priority.low:
        return 'baja';
    }
  }

  Priority _taskPriorityLabelToStudyPriority(String label) {
    switch (label.toLowerCase()) {
      case 'alta':
        return Priority.high;
      case 'media':
        return Priority.normal;
      case 'baja':
        return Priority.low;
      default:
        return Priority.normal;
    }
  }
}
