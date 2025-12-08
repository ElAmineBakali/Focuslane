# 🔄 Guía de Sincronización Study ↔ Tasks

## Métodos Disponibles en `StudyTasksSyncService`

### 1. Sincronizar Status de StudyTask → Tasks

```dart
await syncSvc.syncTaskStatusToTasks(
  syncedTaskId: 'task_456',  // ID del Task en módulo general
  newStatus: TaskStatus.done, // Nuevo status
);
```

**Resultado:** El Task en el módulo general se actualiza a `completed: true`

---

### 2. Sincronizar Status de Task → StudyTask

```dart
await syncSvc.syncTaskStatusToStudy(
  syncedStudyTaskId: 'study_task_123', // ID del StudyTask
  completed: true,                      // Status del Task
);
```

**Resultado:** El StudyTask se actualiza a `status: TaskStatus.done`

---

### 3. Sincronizar Datos Completos de StudyTask → Tasks

```dart
await syncSvc.syncStudyTaskDataToTasks(
  'study_task_123',  // ID del StudyTask
  title: 'Examen Final',
  notes: 'Capítulos 1-8',
  due: DateTime.now().add(Duration(days: 7)),
  priority: Priority.high,
);
```

**Resultado:** El Task en general se actualiza con los nuevos datos

---

### 4. Sincronizar Datos Completos de Task → StudyTask

```dart
await syncSvc.syncTaskDataToStudy(
  'task_456',  // ID del Task
  title: 'Proyecto de Física',
  description: 'Resolver problemas 5.1-5.8',
  dueDate: DateTime.now().add(Duration(days: 5)),
  priorityLabel: 'alta',  // 'baja', 'media', 'alta'
);
```

**Resultado:** El StudyTask se actualiza con los nuevos datos

---

## Ejemplo: Crear StudyTask con Sincronización

### Paso 1: Crear el StudyTask en Firestore

```dart
final newTask = StudyTask(
  id: '', // Será reemplazado
  courseId: 'course_123',
  title: 'Examen Final de Matemáticas',
  type: StudyItemType.exam,
  due: DateTime.now().add(const Duration(days: 7)),
  priority: Priority.high,
  notes: 'Incluye temas 1-8',
  status: TaskStatus.todo,
);

final docRef = await studySvc.addTask(newTask);
final studyTaskId = docRef.id;
```

### Paso 2: Sincronizar a Tasks (Crear Task automáticamente)

```dart
final syncSvc = StudyTasksSyncService();

// Obtener el ID de la tarea creada en Tasks
// (En una app real, el sync service devuelve esto)
await syncSvc.syncStudyTaskDataToTasks(
  studyTaskId,
  title: 'Examen Final de Matemáticas',
  notes: 'Incluye temas 1-8',
  due: DateTime.now().add(const Duration(days: 7)),
  priority: Priority.high,
);

print('✅ StudyTask y Task sincronizados');
```

---

## Ejemplo: Actualizar StudyTask y Sincronizar

```dart
Future<void> updateStudyTask(
  StudyTask task,
  StudyFirestoreService studySvc,
) async {
  final syncSvc = StudyTasksSyncService();
  
  try {
    // 1. Actualizar en StudyTask
    await studySvc.updateTask(task.id, {
      'title': 'Examen Final (Modificado)',
      'priority': Priority.normal.name,
      'status': TaskStatus.doing.name,
    });

    // 2. Sincronizar a Tasks si existe vinculación
    if (task.syncedTaskId != null && task.syncedTaskId!.isNotEmpty) {
      await syncSvc.syncStudyTaskDataToTasks(
        task.id,
        title: 'Examen Final (Modificado)',
        priority: Priority.normal,
      );
    }

    print('✅ Cambios sincronizados');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## Ejemplo: Completar Tarea y Sincronizar

```dart
Future<void> completeStudyTask(
  StudyTask task,
  StudyFirestoreService studySvc,
) async {
  final syncSvc = StudyTasksSyncService();
  
  try {
    // 1. Marcar como completada en StudyTask
    await studySvc.updateTask(task.id, {
      'status': TaskStatus.done.name,
    });

    // 2. Sincronizar status a Tasks
    if (task.syncedTaskId != null && task.syncedTaskId!.isNotEmpty) {
      await syncSvc.syncTaskStatusToTasks(
        task.syncedTaskId,
        TaskStatus.done,
      );
    }

    print('✅ Tarea completada y sincronizada');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## Ejemplo: Crear Task General Vinculado a Study

```dart
Future<void> createTaskLinkedToStudy(
  String taskTitle,
  String courseId,
  DateTime dueDate,
  TaskFirestoreService taskSvc,
  StudyFirestoreService studySvc,
) async {
  try {
    // 1. Crear Task en módulo general
    final newTask = Task(
      id: '', // Será reemplazado
      title: taskTitle,
      category: 'Study',
      linkedStudyCourseId: courseId,
      dueDate: dueDate,
      priority: TaskPriority.high,
      completed: false,
    );

    final taskDocRef = await taskSvc.addTask(newTask);
    final taskId = taskDocRef.id;

    // 2. Crear StudyTask correspondiente
    final studyTask = StudyTask(
      id: '', // Será reemplazado
      courseId: courseId,
      title: taskTitle,
      type: StudyItemType.task,
      due: dueDate,
      priority: Priority.high,
      syncedTaskId: taskId, // ← Vincular a Task
      status: TaskStatus.todo,
    );

    final studyDocRef = await studySvc.addTask(studyTask);
    final studyTaskId = studyDocRef.id;

    // 3. Actualizar referencias cruzadas en Firestore
    await taskSvc.updateTask(taskId, {
      'syncedStudyTaskId': studyTaskId,
    });

    await studySvc.updateTask(studyTaskId, {
      'syncedTaskId': taskId,
    });

    print('✅ Task creado y vinculado a Study');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## Mostrar Indicador de Sincronización en UI

```dart
class SyncIndicator extends StatelessWidget {
  final String? syncedTaskId;
  
  const SyncIndicator({super.key, this.syncedTaskId});

  @override
  Widget build(BuildContext context) {
    final isSynced = syncedTaskId != null && syncedTaskId!.isNotEmpty;
    
    if (!isSynced) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Sincronizado',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Buenas Prácticas

### ✅ DO

- Usar `StudyTasksSyncService` para todas las operaciones de sync
- Siempre capturar `syncedTaskId`/`syncedStudyTaskId` en tus modelos
- Mostrar indicador visual cuando una tarea está sincronizada
- Usar try-catch para manejar errores sin interrumpir la UX
- Mantener los datos en Firestore como fuente única de verdad
- Validar que el `syncedTaskId` no esté vacío antes de sincronizar

### ❌ DON'T

- Duplicar datos en memoria (usar Streams de Firestore)
- Olvidar actualizar los IDs de sincronización
- Dejar errores de sync sin manejo
- Hacer operaciones síncronas (usar async/await)
- Assumir que la sincronización siempre funciona (conexión puede fallar)
- Sincronizar sin verificar que el otro lado exista

---

## Checklist de Integración

- [ ] Importar `StudyTasksSyncService` en tu pantalla
- [ ] Crear instancia: `final syncSvc = StudyTasksSyncService();`
- [ ] Después de crear/actualizar tarea, llamar método de sync
- [ ] Verificar que `syncedTaskId` existe antes de sincronizar
- [ ] Manejar errores con try-catch
- [ ] Mostrar indicador visual en la UI si está sincronizado
- [ ] Testear creación, actualización y borrado de tareas
- [ ] Testear en Android e iOS

---

## Debugging

### Ver si una tarea está sincronizada

```dart
print('Tarea sincronizada: ${task.syncedTaskId}');
print('Task sincronizado: ${task.syncedTaskId != null && task.syncedTaskId!.isNotEmpty}');
```

### Ver datos en Firestore

- Ir a Firebase Console
- Seleccionar colección `users/{uid}/study/root/tasks`
- Verificar que cada tarea tiene `syncedTaskId` poblado
- Seleccionar colección `users/{uid}/tasks`
- Verificar que cada tarea tiene `syncedStudyTaskId` poblado

### Logs de Sincronización

```dart
// En StudyTasksSyncService, descomentar debugPrint para ver logs
debugPrint('✅ Sync iniciado para task: $syncedTaskId');
```

---

## Preguntas Frecuentes

**P: ¿Qué pasa si falla la sincronización?**  
R: Los errores se capturan silenciosamente. La tarea se crea/actualiza en Study pero no en Tasks. Usar logs para debuggear.

**P: ¿Puedo crear una tarea sin sincronización?**  
R: Sí, dejar `syncedTaskId` en null. Se pueden sincronizar después.

**P: ¿Qué prioridades mapean a qué?**  
R: Mirar `_priorityStudyToTasks()` en `study_tasks_sync_service.dart`

**P: ¿Se sincroniza automáticamente?**  
R: No, necesitas llamar explícitamente a `syncXXX()` métodos.

