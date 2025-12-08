# 🚀 Quick Start - Usando el Módulo Study Refactorizado

## Para Desarrolladores

### 1️⃣ Entender la Arquitectura

```
lib/screens/study/
├── models/
│   └── study_models.dart         # Course, StudyTask, StudySession, StudyClassBlock
├── services/
│   ├── study_firestore_service.dart       # CRUD de datos
│   ├── study_tasks_sync_service.dart      # ✨ Sincronización Study ↔ Tasks
│   └── study_notifications.dart    # Notificaciones
├── widgets/
│   ├── sync_indicators.dart        # Componentes de sincronización
│   ├── responsive_widgets.dart     # Widgets responsivos
│   └── interactive_schedule_grid.dart # Grid del horario
└── screens/
    ├── study_home_screen.dart      # Pantalla raíz
    ├── courses/                     # Gestión de cursos
    ├── tasks/                       # Gestión de tareas
    ├── timer/                       # Temporizador
    ├── analytics/                   # Estadísticas
    ├── attendance/                  # Asistencia
    └── schedule/                    # Horario
```

### 2️⃣ Flujos Principales

#### A. Crear un Curso
```dart
final svc = StudyFirestoreService();
final courseId = await svc.createCourse(
  Course(
    id: '',  // Firestore asigna el ID
    name: 'Matemáticas I',
    colorHex: '0xFF2563EB',
    teacher: 'Dr. García',
    credits: 4,
    goalHours: 40,
  ),
);
```

#### B. Crear una Tarea de Estudio
```dart
final svc = StudyFirestoreService();
final taskId = await svc.createTask(
  StudyTask(
    id: '',
    courseId: 'course_123',
    title: 'Examen Parcial',
    type: StudyItemType.exam,
    due: DateTime.now().add(Duration(days: 7)),
    priority: Priority.high,
  ),
);

// ✨ PRÓXIMOS: Esto automáticamente creará también un Task en módulo general
```

#### C. Sincronizar cambios
```dart
final syncSvc = StudyTasksSyncService();

// Cambiar status y sincronizar
await syncSvc.syncTaskStatusToTasks(
  syncedTaskId: 'task_456',
  newStatus: TaskStatus.done,
);

// O actualizar datos completos
await syncSvc.syncStudyTaskDataToTasks(
  syncedTaskId: 'task_456',
  title: 'Nuevo título',
  priority: Priority.normal,
);
```

### 3️⃣ Componentes Clave a Usar

#### Responsive Padding
```dart
// ✅ Usa esto en listas
ListView.builder(
  padding: EdgeInsets.only(
    left: 12,
    right: 12,
    top: 12,
    bottom: 12 + context.safeAreaBottomPadding,  // ← Clave!
  ),
)

// ✅ O usa el widget
ResponsiveListView(
  itemCount: items.length,
  itemBuilder: (ctx, i) => ItemWidget(items[i]),
)
```

#### Indicadores de Sincronización
```dart
// En cualquier task widget
if (task.syncedTaskId != null && task.syncedTaskId!.isNotEmpty) {
  SyncIndicators.syncBadge(context)
}
```

#### Grid del Horario
```dart
InteractiveScheduleGrid(
  blocks: classBlocks,
  courseById: {'course_1': course1, 'course_2': course2},
  onBlockTap: (block) {
    // Abrir editor
    editBlock(block);
  },
  onBlockLongPress: (block) {
    // Borrar
    deleteBlock(block);
  },
)
```

### 4️⃣ Extending para Nuevas Funcionalidades

#### Agregar un nuevo campo a StudyTask
```dart
// 1. En study_models.dart, StudyTask class:
final String? customField;  // Agregar

// 2. En fromMap():
customField: m['customField'],

// 3. En toMap():
if (customField != null) 'customField': customField,

// 4. En constructor:
this.customField,
```

#### Crear un nuevo widget responsivo
```dart
// En responsive_widgets.dart
class MyResponsiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isPhone = context.isMobile;
    final bottomPadding = context.safeAreaBottomPadding;
    
    return isPhone
      ? MobileLayout(bottomPadding: bottomPadding)
      : DesktopLayout(bottomPadding: bottomPadding);
  }
}
```

### 5️⃣ Testing Localmente

```bash
# Compilar sin errores
flutter pub get

# Revisar errores
dart analyze

# Formatear código
dart format lib/screens/study/

# Run (necesitas device/emulator)
flutter run
```

### 6️⃣ Debugging

#### Ver Firestore data
```dart
// En study_firestore_service.dart, agrega:
print('Cursos: ${await svc.streamCourses().first}');
```

#### Rastrear sync
```dart
// En study_tasks_sync_service.dart:
debugPrint('Sincronizando task: $syncedTaskId con status: $newStatus');
```

#### Monitorear safe area
```dart
debugPrint('SafArea bottom: ${context.safeAreaBottomPadding}');
debugPrint('Has notch: ${context.hasNotch}');
```

### 7️⃣ Comandos Útiles

```bash
# Limpiar build
flutter clean

# Ver warnings
dart analyze lib/screens/study/

# Formatear todo
dart format lib/screens/study/ -r

# Rebuild con verbose
flutter run -v

# Profile (performance)
flutter run --profile

# Simular baja memoria
flutter run --profile --trace-skia

# Cambiar idioma
flutter run -d emulator-5554 --locale es_ES
```

### 8️⃣ Patrones a Seguir

✅ **DO:**
```dart
// Usar Streams para datos en tiempo real
StreamBuilder<List<Course>>(
  stream: svc.streamCourses(),
  builder: (ctx, snap) { ... }
)

// Manejar errors silenciosamente en sync
try {
  await syncSvc.syncTaskStatusToTasks(...);
} catch (_) {
  // Silent fail
}

// Usar extensiones para safety
bottom: context.safeAreaBottomPadding
```

❌ **DON'T:**
```dart
// No usar FutureBuilder para datos "en vivo"
// No duplicar datos en variables locales
// No hardcodear padding
// No assumir que sync siempre funciona
```

### 9️⃣ Documentación Clave

Leer en este orden:
1. 📖 **EXECUTIVE_SUMMARY.md** - Overview rápido
2. 🔄 **SYNC_GUIDE.dart** - Ejemplos prácticos de código
3. 📋 **REFACTORIZATION_STATUS.md** - Detalles técnicos
4. ✅ **DEPLOYMENT_CHECKLIST.md** - Antes de ir a producción

### 🔟 Soporte & Contacto

Si tienes dudas:
1. Busca en SYNC_GUIDE.dart (7 ejemplos)
2. Lee comentarios en responsive_widgets.dart
3. Revisa study_tasks_sync_service.dart (bien documentado)
4. Pregunta al equipo

---

## Cheat Sheet Rápido

```dart
// Crear servicio
final svc = StudyFirestoreService();
final syncSvc = StudyTasksSyncService();

// Operaciones comunes
await svc.createCourse(course);           // Crear curso
await svc.createTask(task);               // Crear tarea
await svc.updateTask(id, {'status': ...}); // Actualizar
await svc.deleteTask(id);                 // Eliminar

// Sincronización
await syncSvc.syncTaskStatusToTasks(id, status);
await syncSvc.syncStudyTaskDataToTasks(id, title: ..., priority: ...);

// Responsive
context.safeAreaBottomPadding     // Double
context.isMobile                   // bool
context.screenWidth                // double
SyncIndicators.syncBadge(context)  // Widget

// Streams
svc.streamCourses()                // Stream<List<Course>>
svc.streamTasks()                  // Stream<List<StudyTask>>
svc.streamSchedule()               // Stream<List<StudyClassBlock>>
svc.streamAttendanceMap(courseId)  // Stream<Map<String, String>>
```

---

**Última actualización:** 2025-12-08  
**Para:** Desarrolladores trabajando en Study  
**Versión:** 2.0.0+
