# 📊 INFORME TÉCNICO: ARQUITECTURA SaaS CLIENTE-SERVIDOR
## Proyecto Focuslane - Firebase + Backend Serverless

---

## 📝 RESUMEN EJECUTIVO

**Proyecto:** Focuslane - Dashboard Personal Multimodular  
**Estado actual:** Aplicación Flutter monolítica con Firebase (Auth + Firestore)  
**Objetivo:** Evolución hacia arquitectura SaaS cliente-servidor profesional  

### Hallazgos clave:
- ✅ **12 módulos funcionales** con CRUD completo y datos reales
- ⚠️ **100% lógica en cliente**: Todos los cálculos, validaciones y reglas de negocio están en Flutter
- ❌ **Sin backend serverless**: No hay Cloud Functions ni Cloud Run implementadas
- ⚠️ **Riesgo de inconsistencias**: Cálculos de métricas se repiten en múltiples pantallas
- ✅ **Firebase Auth + Firestore** funcionando con estructura por usuario (`users/{uid}/...`)
- ⚠️ **Observabilidad ausente**: No hay Analytics, Crashlytics ni Performance Monitoring
- ✅ **Notificaciones locales + FCM** implementadas parcialmente

### Evaluación general:
- **Funcionalidad:** 90% - App completamente funcional
- **Arquitectura:** 40% - Falta separación de capas y backend
- **Escalabilidad:** 30% - No está preparada para SaaS multiusuario
- **Mantenibilidad:** 50% - Código bien estructurado pero sin separación clara

---

## 📦 INVENTARIO DE MÓDULOS Y ESTADO REAL

### 1. **TASKS (Tareas)** - 🟢 COMPLETO

**Pantallas principales:**
- [tasks_main_screen.dart](lib/screens/tasks/tasks_main_screen.dart) - Vista principal con filtros
- [task_create_screen.dart](lib/screens/tasks/task_create_screen.dart) - Formulario de creación
- [task_edit_screen.dart](lib/screens/tasks/task_edit_screen.dart) - Edición de tareas

**Funcionalidades implementadas:**
- ✅ CRUD completo (Create, Read, Update, Delete)
- ✅ Checkbox done/undone con persistencia
- ✅ Filtros por estado (pendiente/completado)
- ✅ Fechas de vencimiento
- ✅ Prioridades
- ✅ Categorías
- ✅ Tareas recurrentes
- ✅ Notificaciones locales programadas
- ✅ Batch operations (marcar/desmarcar todo)

**Qué está incompleto o roto:**
- ❌ No hay estadísticas de productividad (tareas completadas por día/semana)
- ❌ Sin sugerencias automáticas de tareas
- ❌ Sin sincronización con Calendar para visualización temporal
- ⚠️ Notificaciones podrían fallar si la app no tiene permisos

**Servicios:**
- `TaskFirestoreService` - CRUD directo a Firestore
- Colección: `users/{uid}/tasks`

---

### 2. **HABITS (Hábitos)** - 🟢 COMPLETO

**Pantallas principales:**
- [habits_table_screen.dart](lib/screens/habits/habits_table_screen.dart) - Tabla de seguimiento diario
- [habit_create_screen.dart](lib/screens/habits/habit_create_screen.dart) - Crear hábito
- [habit_detail_screen.dart](lib/screens/habits/habit_detail_screen.dart) - Detalle y edición
- [habit_stats_screen.dart](lib/screens/habits/habit_stats_screen.dart) - Estadísticas y gráficos

**Funcionalidades implementadas:**
- ✅ CRUD completo con orden personalizable (drag & drop)
- ✅ Tracking diario (boolean, number, time)
- ✅ Historial completo en Firestore
- ✅ Estadísticas con gráficos (rachas, cumplimiento)
- ✅ Archivar/desarchivar
- ✅ Notificación diaria programable (hora customizable)
- ✅ Vista de calendario mensual

**Qué está incompleto o roto:**
- ⚠️ Cálculo de rachas se hace en cliente (debería ser en backend)
- ❌ Sin análisis de correlaciones entre hábitos
- ❌ Sin recomendaciones inteligentes basadas en patrones
- ❌ Sin exportación de datos CSV

**Servicios:**
- `HabitFirestoreService` - CRUD + batch updates
- Colección: `users/{uid}/habits`
- Campo: `history` (mapa con fechas como keys)

---

### 3. **STUDY (Estudio)** - 🟢 COMPLETO

**Pantallas principales:**
- [study_home_screen.dart](lib/screens/study/study_home_screen.dart) - Dashboard con cursos
- [study_timer_screen.dart](lib/screens/study/timer/study_timer_screen.dart) - Timer Pomodoro
- [study_analytics_screen.dart](lib/screens/study/analytics/study_analytics_screen.dart) - Analytics

**Funcionalidades implementadas:**
- ✅ Gestión de cursos (CRUD)
- ✅ Tareas por curso con prioridades
- ✅ Timer Pomodoro con presets personalizables
- ✅ Sesiones de estudio registradas
- ✅ Gráficos de tiempo por curso/materia
- ✅ Integración con Calendar
- ✅ Notificaciones de sesión terminada

**Qué está incompleto o roto:**
- ⚠️ Estadísticas calculadas en cliente (horas totales, promedios)
- ❌ Sin análisis de productividad por horario
- ❌ Sin recordatorios inteligentes de repaso espaciado
- ❌ Sin sincronización con tareas de Study

**Servicios:**
- `StudyFirestoreService` - Servicio completo
- Colecciones: `users/{uid}/study/root/{courses, tasks, sessions, presets}`

---

### 4. **CALENDAR (Calendario)** - 🟡 PARCIALMENTE COMPLETO

**Pantallas principales:**
- [calendar_screen.dart](lib/screens/calendar/calendar_screen.dart) - Vista mensual agregada
- [timetable_editor_screen.dart](lib/screens/calendar/timetable_editor_screen.dart) - Editor de horarios
- [timetable_list_screen.dart](lib/screens/calendar/timetable_list_screen.dart) - Lista de plantillas

**Funcionalidades implementadas:**
- ✅ Eventos manuales CRUD
- ✅ Agregación de eventos de otros módulos (Tasks, Study, Gym, Food, Finance)
- ✅ Filtros por tipo de evento y prioridad
- ✅ Timetables (horarios semanales recurrentes)
- ✅ Vista mensual con TableCalendar
- ✅ Preferencias de visibilidad por módulo

**Qué está incompleto o roto:**
- ⚠️ Agregación se hace en cliente (`CalendarAggregatorService`) - debería ser backend
- ❌ Sin vista semanal/diaria detallada
- ❌ Sin detección de conflictos de horario
- ❌ Sin sincronización con Google Calendar
- ❌ Performance degradada con muchos eventos (streams múltiples)

**Servicios:**
- `CalendarService` - Eventos manuales y timetables
- `CalendarAggregatorService` - Combina 6 streams diferentes (cliente)
- Colección: `users/{uid}/calendar_events`

---

### 5. **NOTES (Notas)** - 🟢 COMPLETO

**Pantallas principales:**
- [notes_list_screen.dart](lib/screens/notes/notes_list_screen.dart) - Lista ordenada por fecha
- [note_editor_screen.dart](lib/screens/notes/note_editor_screen.dart) - Editor rich text (Quill)

**Funcionalidades implementadas:**
- ✅ CRUD completo
- ✅ Editor rich text con Flutter Quill
- ✅ Ordenado por `updatedAt` descendente
- ✅ Búsqueda en tiempo real (título y contenido)
- ✅ Imágenes embebidas vía Supabase Storage

**Qué está incompleto o roto:**
- ❌ Sin categorías/etiquetas
- ❌ Sin favoritos
- ❌ Sin archivado
- ❌ Sin compartir notas entre usuarios
- ❌ Sin búsqueda full-text indexada (usa filtrado local)

**Servicios:**
- `NoteFirestoreService` - CRUD simple
- `MediaService` / `SupabaseMediaService` - Upload de imágenes
- Colección: `users/{uid}/notes`
- Storage: Supabase (no Firebase Storage para notas)

---

### 6. **GYM (Gimnasio)** - 🟢 COMPLETO (Referencia de calidad)

**Pantallas principales:**
- [gym_home_screen.dart](lib/screens/gym/gym_home_screen.dart) - Dashboard con rutina activa
- [routines_list_screen.dart](lib/screens/gym/routines/routines_list_screen.dart) - Gestión de rutinas
- [gym_analytics_screen_v2.dart](lib/screens/gym/analytics/gym_analytics_screen_v2.dart) - Gráficos avanzados
- [gym_goals_screen.dart](lib/screens/gym/goals/gym_goals_screen.dart) - Metas personales
- [bodyweight_screen.dart](lib/screens/gym/body/bodyweight_screen.dart) - Peso corporal
- [measurements_screen.dart](lib/screens/gym/body/measurements_screen.dart) - Medidas corporales

**Funcionalidades implementadas:**
- ✅ CRUD de rutinas con split types
- ✅ Días de entrenamiento con ejercicios
- ✅ Sets, reps, peso con historial
- ✅ Gráficos de progreso por ejercicio
- ✅ Metas de peso/reps con tracking
- ✅ Peso corporal con gráfico temporal
- ✅ Medidas corporales (pecho, brazos, piernas, etc.)
- ✅ Duplicar rutinas
- ✅ Rutina por defecto
- ✅ Timer de descanso entre sets
- ✅ Notificaciones de entrenamiento

**Qué está incompleto o roto:**
- ⚠️ Cálculos de volumen, 1RM, PR están en cliente
- ❌ Sin análisis de recuperación muscular
- ❌ Sin recomendaciones de ejercicios complementarios
- ❌ Sin detección de plateau/estancamiento

**Servicios:**
- `GymFirestoreService` (852 líneas) - Servicio más completo del proyecto
- Estructura: `users/{uid}/gym/root/{routines, exercises, sessions, goals, bodyweight, measurements}`

---

### 7. **FINANCE (Finanzas)** - 🟢 COMPLETO AL 90%

**Pantallas principales:**
- [finance_home_screen_v2.dart](lib/screens/finance/finance_home_screen_v2.dart) - Dashboard con KPIs
- Módulos: Transactions, Budgets, Subscriptions, Debts, Assets, Deposits, Variable Expenses, Analytics

**Funcionalidades implementadas:**
- ✅ Transacciones con categorías y plantillas
- ✅ Presupuestos mensuales con progreso
- ✅ Suscripciones recurrentes con alertas
- ✅ Deudas (préstamos y personas)
- ✅ Activos (físicos y financieros) con fotos
- ✅ Depósitos bancarios con movimientos
- ✅ Gastos variables planificados
- ✅ Gráficos de ingresos/gastos por mes
- ✅ Filtros avanzados (fecha, categoría, tipo)
- ✅ Exportación CSV
- ✅ Seguridad biométrica + PIN
- ✅ Notificaciones de presupuesto excedido

**Qué está incompleto o roto:**
- ⚠️ Cálculos de balance, estadísticas en cliente
- ⚠️ Sin recalculo automático de suscripciones vencidas (debería ser Cloud Function)
- ❌ Sin conversión de divisas
- ❌ Sin proyecciones financieras
- ❌ Sin integración bancaria (Open Banking)

**Servicios:**
- 9 servicios especializados:
  - `TransactionService` (finance_transactions)
  - `BudgetService` (finance_budgets)
  - `SubscriptionService` (finance_subscriptions)
  - `DebtService` / `DebtServiceLoans`
  - `AssetService` (finance_assets)
  - `DepositService` (finance_deposit_accounts, finance_deposit_movements)
  - `VariableExpenseService` (finance_variable_expenses)
  - `FinanceSettingsService` (users/{uid}/settings/finance)

---

### 8. **FOOD (Alimentación)** - 🟢 COMPLETO

**Pantallas principales:**
- [food_home_screen_v2.dart](lib/screens/food/dashboard/food_home_screen_v2.dart) - Dashboard nutricional
- [food_diary_screen_v2.dart](lib/screens/food/diary/food_diary_screen_v2.dart) - Diario de comidas
- [foods_list_screen_v2.dart](lib/screens/food/foods/foods_list_screen_v2.dart) - Base de datos de alimentos
- [recipes_list_screen_v2.dart](lib/screens/food/recipes/recipes_list_screen_v2.dart) - Recetas
- [food_planner_screen_v2.dart](lib/screens/food/planner/food_planner_screen_v2.dart) - Planificador semanal
- [shopping_lists_screen_v2.dart](lib/screens/food/shopping/shopping_lists_screen_v2.dart) - Listas de compra
- [pantry_screen_v2.dart](lib/screens/food/pantry/pantry_screen_v2.dart) - Despensa
- [food_history_screen_v2.dart](lib/screens/food/history/food_history_screen_v2.dart) - Historial

**Funcionalidades implementadas:**
- ✅ Base de datos de alimentos con macros
- ✅ Diario diario con registro de comidas
- ✅ Cálculo de macros en tiempo real (kcal, proteína, carbos, grasa, fibra)
- ✅ Objetivos nutricionales configurables
- ✅ Recetas con ingredientes y macros totales
- ✅ Favoritos (comidas frecuentes)
- ✅ Planificador semanal de comidas
- ✅ Listas de compra con checkbox
- ✅ Control de despensa con expiración
- ✅ Gráficos de progreso nutricional
- ✅ Agua diaria

**Qué está incompleto o roto:**
- ⚠️ Cálculo de macros totales en cliente
- ❌ Sin escaneo de códigos de barras
- ❌ Sin base de datos global compartida de alimentos
- ❌ Sin análisis de deficiencias nutricionales
- ❌ Sin recomendaciones de recetas según objetivos

**Servicios:**
- `FoodFirestoreService` (759 líneas) - Servicio completo
- Estructura: `users/{uid}/food/root/{foods, recipes, favorites, intake, plans, shopping, pantry}`

---

### 9. **MEDITATION (Meditación)** - 🟢 COMPLETO

**Módulos:**
- Timer con ambientes sonoros
- Sesiones guiadas
- Programas de meditación
- Breathing exercises (respiración guiada)
- Analytics con rachas y tiempo total
- Tags y categorización

**Funcionalidades implementadas:**
- ✅ Timer configurable con presets
- ✅ Audio ambiente (rain, forest, fireplace, river)
- ✅ Sesiones registradas con tipo y duración
- ✅ Programas estructurados con días
- ✅ Ejercicios de respiración con patrones (4-7-8, box breathing)
- ✅ Estadísticas con rachas (streak/bestStreak)
- ✅ Minutos totales y mensuales
- ✅ Tags personalizables
- ✅ Recordatorios programables

**Qué está incompleto o roto:**
- ⚠️ Cálculo de rachas en transacción Firestore (correcto pero en cliente)
- ❌ Sin análisis de mejora de focus/bienestar
- ❌ Sin integración con wearables (Heart Rate)

**Servicios:**
- `MeditationFirestoreService` (260 líneas)
- Estructura: `users/{uid}/meditation/data/{sessions, programs, breath_presets, reminders, tags, guided}`

---

### 10. **CULTURE (Cultura)** - 🟢 COMPLETO

**Módulos:**
- Libros (books)
- Películas (movies)
- Series (series)
- Música (music)
- Videojuegos (games)
- Biblioteca personal

**Funcionalidades implementadas:**
- ✅ CRUD completo para cada tipo de contenido
- ✅ Estados (pendiente, en progreso, completado)
- ✅ Ratings (1-5 estrellas)
- ✅ Notas y reseñas
- ✅ Tracking de progreso (páginas leídas, episodios vistos, horas jugadas)
- ✅ Gráficos de consumo cultural
- ✅ Filtros por género, año, plataforma
- ✅ Portadas/imágenes vía Supabase

**Qué está incompleto o roto:**
- ❌ Sin recomendaciones basadas en gustos
- ❌ Sin integración con APIs externas (TMDB, Goodreads, IGDB)
- ❌ Sin comunidad/social features

**Servicios:**
- `CultureFirestoreService`
- Colección: `users/{uid}/culture/{books, movies, series, music, games}`

---

### 11. **SKILLS (Habilidades)** - 🟡 BÁSICO

**Módulos:**
- Skills tracking
- Projects vinculados a skills
- Reviews de proyectos

**Funcionalidades implementadas:**
- ✅ Lista de habilidades con nivel
- ✅ Proyectos asociados
- ✅ Reviews de progreso

**Qué está incompleto o roto:**
- ⚠️ Módulo simple, poco desarrollado comparado con otros
- ❌ Sin roadmaps de aprendizaje
- ❌ Sin tracking de tiempo dedicado
- ❌ Sin certificaciones

**Servicios:**
- `SkillsFirestoreService`
- Colección: `users/{uid}/skills/root/{skills, projects, reviews}`

---

### 12. **TRADING (Trading)** - 🟢 COMPLETO

**Módulos:**
- Trades (operaciones)
- Journal (diario de trading)
- Strategies (estrategias)
- Watchlists (listas de seguimiento)
- Analytics (análisis de performance)
- Live charts (gráficos en tiempo real)

**Funcionalidades implementadas:**
- ✅ Registro de trades con entry/exit, P&L, fees
- ✅ Journal con análisis emocional y screenshots
- ✅ Estrategias con reglas
- ✅ Watchlists de activos
- ✅ Gráficos de performance (win rate, P&L curve, R-multiple)
- ✅ Live charts con TradingView style
- ✅ Tags y categorización

**Qué está incompleto o roto:**
- ❌ Sin datos de mercado en tiempo real (necesita API externa)
- ❌ Sin backtesting de estrategias
- ❌ Sin integración con brokers
- ❌ Gráficos en vivo simulados (no datos reales)

**Servicios:**
- `TradingFirestoreService`
- Colección: `users/{uid}/trading/root/{trades, journal, strategies, watchlists}`

---

### 13. **GOALS (Metas)** - 🟢 COMPLETO

**Funcionalidades:**
- ✅ Goals con subgoals
- ✅ Progreso tracking
- ✅ Deadline y prioridades
- ✅ Vista kanban

**Servicios:**
- `GoalsFirestoreService`
- Colección: `users/{uid}/goals`

---

### 14. **ROPA (Vestuario)** - 🟡 BÁSICO

**Pantallas:**
- Wardrobe (armario de prendas)
- Outfit builder (crear conjuntos)
- Planner (planificador de outfits)

**Funcionalidades implementadas:**
- ✅ CRUD de prendas con fotos
- ✅ Crear outfits combinando prendas
- ✅ Planificador de vestuario para fechas
- ✅ Filtros por tipo, color, temporada
- ✅ Favoritos y archivados

**Qué está incompleto o roto:**
- ⚠️ Módulo poco integrado con el resto
- ❌ Sin sugerencias de outfits por clima
- ❌ Sin tracking de uso de prendas

**Servicios:**
- `PrendaFirestoreService`
- `OutfitFirestoreService`
- `PlanOutfitFirestoreService`
- Colección: `users/{uid}/{wardrobe_items, wardrobe_outfits, wardrobe_plans}`

---

## 🔧 INVENTARIO DE SERVICIOS ACTUALES

| Servicio | Estado | Implementación | Observaciones |
|----------|--------|----------------|---------------|
| **Firebase Auth** | ✅ PRESENTE | Anónimo + Email/Password + Google (web) | - `fb_auth.FirebaseAuth.instance`<br>- Sign in anónimo en startup<br>- Persistencia LOCAL en web<br>- **Falta:** OAuth nativo móvil, phone auth |
| **Firestore** | ✅ PRESENTE | 12 módulos con colecciones por usuario | - Estructura: `users/{uid}/{module}/...`<br>- Persistencia habilitada<br>- Cache ilimitado<br>- **Problema:** Múltiples streams simultáneos degradan performance |
| **Firebase Storage** | 🟡 PARCIAL | Solo Assets (Finance) | - `FirebaseStorage.instance`<br>- **Usado solo en:** `AssetService` para fotos de activos<br>- **Problema:** Mayoría de uploads van a Supabase |
| **Supabase Storage** | ✅ PRESENTE | Notas, Culture, Ropa, Trading | - Bucket: `notes-media`<br>- Upload de imágenes en Notes, Books, Movies, Prenda, Journal<br>- **Problema:** Dos sistemas de storage duplican complejidad |
| **Notificaciones Locales** | ✅ PRESENTE | flutter_local_notifications | - `NotificationService.I`<br>- Programación de recordatorios (Habits, Tasks)<br>- Timezone support<br>- Payload routing funcionando |
| **Firebase Messaging (FCM)** | 🟡 PARCIAL | Push en foreground + background handler | - `FirebaseMessaging`<br>- Listener activo en `main.dart`<br>- Background handler: `_fcmBackgroundHandler`<br>- **Problema:** No hay lógica para enviar push desde backend |
| **Cloud Functions** | ❌ AUSENTE | No implementadas | - **No existe carpeta `functions/`**<br>- Sin callable functions<br>- Sin triggers de Firestore<br>- Sin scheduled jobs |
| **Cloud Run** | ❌ AUSENTE | No implementado | - Sin APIs REST custom<br>- Sin workers de backend |
| **Crashlytics** | ❌ AUSENTE | No configurado | - Sin reporte de crashes<br>- Debugging manual con print |
| **Analytics** | ❌ AUSENTE | No configurado | - Sin tracking de eventos<br>- Sin métricas de uso<br>- Sin funnels |
| **Performance Monitoring** | ❌ AUSENTE | No configurado | - Sin tracing de operaciones lentas<br>- Sin alertas de performance |
| **Remote Config** | ❌ AUSENTE | No configurado | - Sin feature flags<br>- Sin A/B testing |
| **App Check** | ❌ AUSENTE | No configurado | - Sin protección contra abuso de API<br>- Firestore Security Rules son la única defensa |

### 📊 Estructura Firestore actual

```
firestore/
├── users/
│   └── {uid}/
│       ├── tasks/                         # Tasks module
│       ├── habits/                        # Habits module
│       ├── notes/                         # Notes module
│       ├── calendar_events/               # Calendar events
│       ├── timetables/                    # Calendar timetables
│       ├── wardrobe_items/                # Ropa: prendas
│       ├── wardrobe_outfits/              # Ropa: conjuntos
│       ├── wardrobe_plans/                # Ropa: planes
│       ├── goals/                         # Goals module
│       ├── gym/
│       │   └── root/
│       │       ├── routines/
│       │       ├── exercises/
│       │       ├── sessions/
│       │       ├── goals/
│       │       ├── bodyweight/
│       │       └── measurements/
│       ├── study/
│       │   └── root/
│       │       ├── courses/
│       │       ├── tasks/
│       │       ├── sessions/
│       │       └── presets/
│       ├── food/
│       │   └── root/
│       │       ├── foods/
│       │       ├── recipes/
│       │       ├── favorites/
│       │       ├── intake/               # Daily diaries
│       │       ├── plans/                # Weekly meal plans
│       │       ├── shopping/             # Shopping lists
│       │       ├── pantry/
│       │       └── config/
│       ├── meditation/
│       │   └── data/
│       │       ├── sessions/
│       │       ├── programs/
│       │       ├── breath_presets/
│       │       ├── reminders/
│       │       ├── tags/
│       │       └── guided/
│       ├── culture/
│       │   ├── books/
│       │   ├── movies/
│       │   ├── series/
│       │   ├── music/
│       │   └── games/
│       ├── skills/
│       │   └── root/
│       │       ├── skills/
│       │       ├── projects/
│       │       └── reviews/
│       ├── trading/
│       │   └── root/
│       │       ├── trades/
│       │       ├── journal/
│       │       ├── strategies/
│       │       └── watchlists/
│       └── settings/
│           └── finance/                  # Finance settings (PIN, biometrics)
│
├── finance_transactions/                 # Global (shared by userId field)
├── finance_budgets/
├── finance_subscriptions/
├── finance_loans/                        # Debts (loans)
├── finance_debt_persons/                 # Debts (people)
├── finance_debt_entries/                 # Debt entries
├── finance_deposit_accounts/
├── finance_deposit_movements/
├── finance_variable_expenses/
└── finance_assets/
```

**⚠️ PROBLEMA DE DISEÑO:** Finance usa colecciones globales con campo `userId`, mientras otros módulos usan subcolecciones. Esto dificulta queries y security rules.

---

## 🏗️ DÓNDE ESTÁ LA LÓGICA DE NEGOCIO HOY

### Cálculos en el cliente (Flutter)

**⚠️ RIESGO ALTO:** Todos estos cálculos deberían estar en backend para garantizar consistencia y evitar manipulación.

| Módulo | Cálculos en cliente | Archivo | Riesgo |
|--------|---------------------|---------|--------|
| **Habits** | - Streak (racha consecutiva)<br>- Best streak<br>- Percentage de cumplimiento<br>- Stats por periodo | `habit_stats_screen.dart` | 🔴 Alto |
| **Finance** | - Balance mensual (ingresos - gastos)<br>- Progreso de presupuestos<br>- Total de activos<br>- P&L de inversiones<br>- Próximas suscripciones | `finance_home_screen_v2.dart`<br>`TransactionService.monthlyStats()`<br>`BudgetService.watchAllWithProgress()` | 🔴 Crítico |
| **Food** | - Macros diarios totales (kcal, proteína, etc.)<br>- Progreso vs objetivos<br>- Macros de recetas | `food_home_screen_v2.dart`<br>`food_diary_screen_v2.dart`<br>`FoodFirestoreService.recalcDay()` | 🟡 Medio |
| **Gym** | - Volumen total por sesión<br>- 1RM estimado<br>- Personal Records<br>- Progresión de peso | `gym_analytics_screen_v2.dart`<br>Widgets de ejercicios | 🟡 Medio |
| **Study** | - Tiempo total por curso<br>- Sesiones por día<br>- Promedio de productividad | `study_analytics_screen.dart`<br>`StudyFirestoreService` | 🟡 Medio |
| **Meditation** | - Streak diario<br>- Minutos totales/mensuales<br>- Best streak | `MeditationFirestoreService._updateMetaAfterSession()`<br>**(USA TRANSACTION)** | 🟢 Bajo (transacción protege) |
| **Trading** | - Win rate<br>- P&L total<br>- R-multiple promedio<br>- Sharpe ratio | `analytics/` screens | 🟡 Medio |
| **Calendar** | - **Agregación de eventos** de 6 módulos<br>- Conflictos de horario | `CalendarAggregatorService.combined()` | 🔴 Alto (performance) |
| **Tasks** | - Tareas completadas hoy/semana<br>- Tasa de completitud | UI local | 🟢 Bajo |

### Validaciones en el cliente

**⚠️ PROBLEMA:** Todas las validaciones están en el cliente, un usuario malicioso podría escribir directamente en Firestore.

- **Precios/montos:** Validados solo en UI (TextField validators)
- **Fechas:** Validados solo en DatePicker
- **Categorías:** No hay enum estricto, se aceptan strings libres
- **Rangos numéricos:** No hay validación en backend

### Reglas de negocio duplicadas

**📍 ANTI-PATRÓN DETECTADO:** La misma lógica se repite en múltiples pantallas.

Ejemplo: Cálculo de balance mensual en Finance
- `finance_home_screen_v2.dart` - Lo calcula para mostrar KPI
- `transactions_screen_v3.dart` - Lo recalcula para el total de la lista
- `analytics/finance_analytics_screen.dart` - Lo recalcula para gráficos

**Consecuencias:**
- ❌ Código duplicado (DRY violation)
- ❌ Inconsistencias si uno se actualiza y otro no
- ❌ Testing complicado (hay que probar múltiples lugares)

---

## 🏛️ PROPUESTA DE SEPARACIÓN POR CAPAS

### Arquitectura objetivo: Clean Architecture + BLoC/Provider

```
lib/
├── core/                                 # ⭐ NUEVO
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── utils/
│
├── domain/                               # ⭐ NUEVO - Entities + Repositorios abstractos
│   ├── entities/                         # POJOs puros sin dependencias
│   │   ├── task.dart
│   │   ├── habit.dart
│   │   ├── note.dart
│   │   ├── transaction.dart
│   │   ├── ...
│   ├── repositories/                     # Interfaces abstractas
│   │   ├── task_repository.dart
│   │   ├── habit_repository.dart
│   │   └── ...
│   └── usecases/                         # Lógica de negocio pura
│       ├── tasks/
│       │   ├── create_task.dart
│       │   ├── complete_task.dart
│       │   ├── get_tasks_by_date.dart
│       │   └── calculate_task_stats.dart
│       ├── habits/
│       │   ├── track_habit.dart
│       │   ├── calculate_streak.dart
│       │   └── get_habit_stats.dart
│       └── finance/
│           ├── create_transaction.dart
│           ├── calculate_monthly_balance.dart
│           ├── check_budget_exceeded.dart
│           └── process_recurring_subscription.dart
│
├── data/                                 # ⭐ REFACTORIZAR - Implementaciones concretas
│   ├── models/                           # DTOs con toMap/fromMap
│   │   ├── task_model.dart
│   │   ├── habit_model.dart
│   │   └── ...
│   ├── repositories/                     # Implementaciones de domain/repositories
│   │   ├── task_repository_impl.dart
│   │   ├── habit_repository_impl.dart
│   │   └── ...
│   ├── datasources/
│   │   ├── remote/                       # Firebase, Cloud Functions
│   │   │   ├── firestore_datasource.dart
│   │   │   ├── functions_datasource.dart
│   │   │   └── storage_datasource.dart
│   │   └── local/                        # Hive, SharedPreferences
│   │       ├── cache_datasource.dart
│   │       └── preferences_datasource.dart
│   └── services/                         # MANTENER servicios legacy envueltos
│       ├── firebase/
│       │   ├── firestore_service.dart    # Wrapper genérico
│       │   ├── auth_service.dart
│       │   └── storage_service.dart
│       └── notifications/
│           └── notification_service.dart
│
├── presentation/                         # ⭐ REFACTORIZAR - UI + State Management
│   ├── tasks/
│   │   ├── bloc/                         # O provider/riverpod/getx
│   │   │   ├── tasks_bloc.dart
│   │   │   ├── tasks_event.dart
│   │   │   └── tasks_state.dart
│   │   ├── screens/
│   │   │   ├── tasks_main_screen.dart
│   │   │   ├── task_create_screen.dart
│   │   │   └── task_edit_screen.dart
│   │   └── widgets/
│   │       ├── task_card.dart
│   │       └── task_filter.dart
│   ├── habits/
│   │   ├── bloc/
│   │   ├── screens/
│   │   └── widgets/
│   └── ... (resto de módulos)
│
├── shared/                               # MANTENER - Widgets comunes
│   ├── widgets/
│   │   ├── app_background.dart
│   │   ├── avoid_fab.dart
│   │   └── ...
│   └── theme/
│       ├── theme.dart
│       └── prefs.dart
│
└── main.dart                             # SIMPLIFICAR - Solo setup + routing
```

### Plan de Refactorización (sin romper la app)

#### Fase 1: Crear capa Domain (1-2 semanas)
1. Crear carpeta `lib/domain/`
2. Mover modelos actuales a `domain/entities/` y hacerlos POJOs puros
3. Crear interfaces `*Repository` en `domain/repositories/`
4. Crear use cases básicos en `domain/usecases/`

**Ejemplo: Habits**
```dart
// domain/entities/habit.dart
class Habit {
  final String id;
  final String name;
  final HabitType type;
  final Map<String, dynamic> history;
  // ... sin dependencias de Firestore
}

// domain/repositories/habit_repository.dart
abstract class HabitRepository {
  Stream<List<Habit>> watchHabits({bool activeOnly});
  Future<void> trackHabit(String id, DateTime date, dynamic value);
  Future<HabitStats> getStats(String id, DateTime from, DateTime to);
}

// domain/usecases/habits/calculate_streak.dart
class CalculateStreak {
  final HabitRepository repository;
  CalculateStreak(this.repository);
  
  Future<int> execute(String habitId) async {
    // Lógica de cálculo aquí (o mejor, llamar a Cloud Function)
  }
}
```

#### Fase 2: Implementar Data Layer (2-3 semanas)
1. Crear `data/repositories/*_repository_impl.dart` que implementen interfaces
2. Envolver servicios actuales como datasources
3. Añadir capa de caché local con Hive

#### Fase 3: Refactorizar Presentation (3-4 semanas, por módulo)
1. Implementar BLoC o Provider por módulo
2. Separar lógica de UI de los screens
3. Usar use cases desde los BLoCs

#### Fase 4: Cloud Functions (2-3 semanas)
1. Mover cálculos a backend (ver sección siguiente)
2. Reemplazar llamadas locales por llamadas a Functions

---

## ☁️ QUÉ DEBERÍA IR EN BACKEND SERVERLESS

### 🎯 10 TAREAS PRIORITARIAS PARA CLOUD FUNCTIONS/RUN

#### 1. 🔴 **Recalculo de Métricas Financieras** (Prioridad: CRÍTICA)
**Cloud Function:** `recalculateMonthlyFinanceStats`
- **Trigger:** Firestore onWrite en `finance_transactions`, `finance_budgets`, etc.
- **Función:**
  - Calcular balance mensual (ingresos - gastos)
  - Actualizar progreso de presupuestos
  - Detectar presupuestos excedidos → enviar push notification
  - Guardar en colección `users/{uid}/finance_stats/{month}`
- **Beneficio:** 
  - ✅ Consistencia garantizada
  - ✅ Cliente solo lee stats precalculadas
  - ✅ Performance mejorada (no calcula en cada render)

```javascript
// functions/src/finance/recalculateMonthlyStats.ts
export const recalculateMonthlyFinanceStats = functions.firestore
  .document('finance_transactions/{txId}')
  .onWrite(async (change, context) => {
    const userId = change.after.data()?.userId;
    const month = getMonthKey(change.after.data()?.date);
    
    // Recalcular stats del mes
    const stats = await calculateMonthlyStats(userId, month);
    
    // Guardar stats
    await admin.firestore()
      .doc(`users/${userId}/finance_stats/${month}`)
      .set(stats, { merge: true });
    
    // Check budget exceeded
    if (stats.budgetExceeded.length > 0) {
      await sendPushNotification(userId, {
        title: '⚠️ Presupuesto excedido',
        body: `Has superado el límite en ${stats.budgetExceeded[0].category}`,
      });
    }
  });
```

#### 2. 🔴 **Procesamiento de Suscripciones Recurrentes** (Prioridad: CRÍTICA)
**Cloud Function:** `processRecurringSubscriptions`
- **Trigger:** Scheduled (diario a las 00:00 UTC)
- **Función:**
  - Buscar suscripciones con `nextPaymentDate <= hoy`
  - Crear transacción automática
  - Actualizar `nextPaymentDate` según `billingCycle`
  - Enviar notificación 3 días antes del cargo
- **Beneficio:**
  - ✅ Subscripciones se procesan automáticamente
  - ✅ Usuario no tiene que recordar anotarlas

```javascript
export const processRecurringSubscriptions = functions.pubsub
  .schedule('0 0 * * *') // Diario a medianoche
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const today = admin.firestore.Timestamp.now();
    
    // Buscar subs que vencen hoy
    const subs = await admin.firestore()
      .collection('finance_subscriptions')
      .where('nextPaymentDate', '<=', today)
      .get();
    
    for (const subDoc of subs.docs) {
      const sub = subDoc.data();
      
      // Crear transacción
      await admin.firestore()
        .collection('finance_transactions')
        .add({
          userId: sub.userId,
          amount: -sub.amount,
          category: 'Subscripción',
          title: sub.name,
          date: today,
          type: 'expense',
          relatedSubscriptionId: subDoc.id,
          createdAt: today,
        });
      
      // Update next payment
      const nextDate = calculateNextPaymentDate(sub.billingCycle, today);
      await subDoc.ref.update({ nextPaymentDate: nextDate });
    }
  });
```

#### 3. 🟡 **Cálculo de Rachas (Streaks) para Habits** (Prioridad: ALTA)
**Cloud Function:** `calculateHabitStreak`
- **Trigger:** Firestore onWrite en `users/{uid}/habits/{habitId}`
- **Función:**
  - Calcular streak actual
  - Actualizar best streak
  - Guardar en campo `streakCurrent` y `streakBest`
- **Beneficio:**
  - ✅ Evita cálculo pesado en cliente
  - ✅ Dato siempre correcto

```javascript
export const calculateHabitStreak = functions.firestore
  .document('users/{uid}/habits/{habitId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const history = newData.history || {};
    
    // Calcular streak
    const streak = computeStreak(history);
    const bestStreak = Math.max(streak, newData.streakBest || 0);
    
    // Update
    await change.after.ref.update({
      streakCurrent: streak,
      streakBest: bestStreak,
    });
  });

function computeStreak(history: Record<string, any>): number {
  const sortedDates = Object.keys(history)
    .map(k => new Date(k))
    .sort((a, b) => b.getTime() - a.getTime());
  
  let streak = 0;
  let currentDate = new Date();
  
  for (const date of sortedDates) {
    const daysDiff = Math.floor((currentDate.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));
    if (daysDiff === streak) {
      streak++;
      currentDate = date;
    } else {
      break;
    }
  }
  
  return streak;
}
```

#### 4. 🟡 **Agregación de Eventos de Calendar** (Prioridad: ALTA)
**Cloud Function:** `aggregateCalendarEvents`
- **Trigger:** Firestore onWrite en eventos de múltiples módulos
- **Función:**
  - Escuchar cambios en tasks, study sessions, gym workouts, etc.
  - Agregar en colección `users/{uid}/calendar_aggregated/{eventId}`
  - Marcar tipo y prioridad
- **Beneficio:**
  - ✅ Cliente no ejecuta 6 streams simultáneos
  - ✅ Performance drásticamente mejorada

#### 5. 🟢 **Envío de Push Notifications Programadas** (Prioridad: ALTA)
**Cloud Function:** `sendScheduledNotifications`
- **Trigger:** Scheduled (cada hora)
- **Función:**
  - Buscar recordatorios/notificaciones pendientes
  - Enviar vía FCM a dispositivos del usuario
  - Marcar como enviado
- **Beneficio:**
  - ✅ Notificaciones no dependen de que la app esté abierta
  - ✅ Escalable a miles de usuarios

```javascript
export const sendScheduledNotifications = functions.pubsub
  .schedule('0 * * * *') // Cada hora
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    
    // Tasks con deadline hoy
    const tasks = await admin.firestore()
      .collectionGroup('tasks')
      .where('due', '<=', now)
      .where('done', '==', false)
      .where('notificationSent', '==', false)
      .get();
    
    for (const taskDoc of tasks.docs) {
      const task = taskDoc.data();
      const userId = taskDoc.ref.parent.parent?.id;
      
      // Get FCM token
      const userDoc = await admin.firestore().doc(`users/${userId}`).get();
      const fcmToken = userDoc.data()?.fcmToken;
      
      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: '⏰ Tarea pendiente',
            body: task.title,
          },
          data: { route: '/tasks', taskId: taskDoc.id },
        });
        
        await taskDoc.ref.update({ notificationSent: true });
      }
    }
  });
```

#### 6. 🟢 **Endpoint para IA: Recomendaciones de Hábitos** (Prioridad: MEDIA)
**Cloud Function HTTP:** `generateHabitRecommendations`
- **Tipo:** Callable function
- **Función:**
  - Analizar historial de hábitos del usuario
  - Detectar patrones (mejor hora, días de éxito)
  - Generar recomendaciones personalizadas con OpenAI/Gemini
  - Retornar JSON con sugerencias
- **Beneficio:**
  - ✅ Inteligencia artificial sin exponer API keys en cliente
  - ✅ Procesamiento pesado en servidor

```typescript
export const generateHabitRecommendations = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  
  // Get user habits
  const habitsSnap = await admin.firestore()
    .collection(`users/${userId}/habits`)
    .where('isActive', '==', true)
    .get();
  
  const habits = habitsSnap.docs.map(d => d.data());
  
  // Analyze patterns
  const analysis = analyzeHabitPatterns(habits);
  
  // Call OpenAI
  const recommendations = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      { role: 'system', content: 'Eres un coach de productividad.' },
      { role: 'user', content: `Analiza estos hábitos y sugiere mejoras: ${JSON.stringify(analysis)}` },
    ],
  });
  
  return {
    recommendations: recommendations.choices[0].message.content,
    patterns: analysis,
  };
});
```

#### 7. 🟢 **Endpoint para IA: Resumen Semanal de Study** (Prioridad: MEDIA)
**Cloud Function:** `generateWeeklyStudySummary`
- **Trigger:** Scheduled (domingos a las 20:00)
- **Función:**
  - Recopilar sesiones de estudio de la semana
  - Generar insights con IA (cursos con más tiempo, horarios productivos)
  - Enviar notificación con resumen
- **Beneficio:**
  - ✅ Gamificación y engagement
  - ✅ Usuario ve su progreso sin esfuerzo

#### 8. 🟡 **Validación de Transacciones Financieras** (Prioridad: MEDIA)
**Cloud Function:** `validateFinanceTransaction`
- **Trigger:** Firestore onCreate en `finance_transactions`
- **Función:**
  - Validar que amount > 0
  - Validar que category existe en categorías permitidas
  - Validar que userId coincide con auth
  - Rechazar si es inválida (eliminar documento)
- **Beneficio:**
  - ✅ Seguridad: Usuario no puede crear transacciones falsas
  - ✅ Integridad de datos

#### 9. 🟢 **Exportación CSV/PDF de Módulos** (Prioridad: BAJA)
**Cloud Function HTTP:** `exportModuleData`
- **Tipo:** Callable function
- **Función:**
  - Generar CSV o PDF de datos del usuario (Finance, Habits, Study)
  - Subir a Firebase Storage
  - Retornar download URL temporal
- **Beneficio:**
  - ✅ Exportación pesada no bloquea UI
  - ✅ Archivos grandes se procesan en backend

#### 10. 🟡 **Análisis de Nutrición con IA** (Prioridad: BAJA)
**Cloud Function:** `analyzeDailyNutrition`
- **Trigger:** Firestore onWrite en `users/{uid}/food/root/intake/{dayId}`
- **Función:**
  - Analizar macros del día
  - Comparar con objetivos
  - Detectar deficiencias (ej. baja proteína)
  - Sugerir alimentos/recetas para completar macros
  - Guardar en campo `aiSuggestions`
- **Beneficio:**
  - ✅ Coach nutricional automático
  - ✅ Mejora adherencia a objetivos

---

### 📋 Tabla Priorizada de Mejoras Backend

| # | Tarea | Prioridad | Complejidad | Impacto | Estimación |
|---|-------|-----------|-------------|---------|------------|
| 1 | Recalculo métricas Finance | 🔴 Crítica | Media | 🔥 Muy Alto | 3-5 días |
| 2 | Procesamiento suscripciones | 🔴 Crítica | Media | 🔥 Muy Alto | 3-4 días |
| 3 | Cálculo streaks Habits | 🟡 Alta | Baja | 🔥 Alto | 2-3 días |
| 4 | Agregación Calendar | 🟡 Alta | Alta | 🔥 Alto | 5-7 días |
| 5 | Push notifications scheduled | 🟢 Alta | Media | 🔥 Alto | 3-4 días |
| 6 | IA: Recomendaciones Habits | 🟢 Media | Alta | 🔵 Medio | 5-7 días |
| 7 | IA: Resumen Study | 🟢 Media | Media | 🔵 Medio | 3-4 días |
| 8 | Validación transacciones | 🟡 Media | Baja | 🔥 Alto | 2-3 días |
| 9 | Exportación CSV/PDF | 🟢 Baja | Media | 🔵 Bajo | 4-5 días |
| 10 | IA: Análisis nutrición | 🟡 Baja | Alta | 🔵 Medio | 5-7 días |

**Total estimado:** 35-50 días de desarrollo (7-10 semanas con 1 dev)

---

## 🚀 ROADMAP DE IMPLEMENTACIÓN SUGERIDO

### Sprint 1-2: Fundaciones (2 semanas)
- [ ] Setup Cloud Functions project (`firebase init functions`)
- [ ] Configurar TypeScript + ESLint
- [ ] Implementar función #1: Recalculo Finance Stats
- [ ] Implementar función #2: Procesamiento Suscripciones
- [ ] Testing básico con emuladores

### Sprint 3-4: Notificaciones y Streaks (2 semanas)
- [ ] Implementar función #5: Push Notifications Scheduled
- [ ] Implementar función #3: Cálculo Streaks Habits
- [ ] Migrar NotificationService a usar FCM tokens guardados en Firestore
- [ ] Testing end-to-end de notificaciones

### Sprint 5-6: Refactorización Cliente (2 semanas)
- [ ] Crear capa `domain/` en Flutter
- [ ] Mover entities y crear repositories abstractos
- [ ] Implementar use cases para Finance y Habits
- [ ] Actualizar UI para usar use cases

### Sprint 7-8: Calendar y Validaciones (2 semanas)
- [ ] Implementar función #4: Agregación Calendar
- [ ] Implementar función #8: Validación Transacciones
- [ ] Refactorizar CalendarScreen para leer de `calendar_aggregated`
- [ ] Security Rules estrictas en Firestore

### Sprint 9-10: IA y Features Premium (2 semanas)
- [ ] Implementar función #6: Recomendaciones Habits con OpenAI
- [ ] Implementar función #7: Resumen Study
- [ ] Implementar función #10: Análisis Nutrición
- [ ] UI para mostrar insights de IA

### Sprint 11-12: Observabilidad y Polish (2 semanas)
- [ ] Configurar Firebase Analytics
- [ ] Configurar Crashlytics
- [ ] Configurar Performance Monitoring
- [ ] Función #9: Exportación CSV/PDF
- [ ] Testing integral y QA

---

## 📊 LISTA PRIORIZADA DE MEJORAS GENERALES

### 🔴 Prioridad CRÍTICA (Semana 1-4)

1. **Implementar Cloud Functions básicas**
   - Finance stats recalculation
   - Subscription processing
   - Habit streak calculation
   - **Beneficio:** Consistencia de datos + Performance

2. **Refactorizar estructura Finance**
   - Migrar de colecciones globales a `users/{uid}/finance/...`
   - Unificar con el patrón del resto de módulos
   - **Beneficio:** Security Rules más simples + Escalabilidad

3. **Configurar Firebase Analytics + Crashlytics**
   - Track eventos clave (create_task, complete_habit, etc.)
   - Reporte automático de crashes
   - **Beneficio:** Observabilidad + Debugging

4. **Security Rules estrictas**
   - Revisar y endurecer todas las rules
   - Validar ownership de documentos
   - Rate limiting en writes
   - **Beneficio:** Seguridad + Prevención de abuso

---

### 🟡 Prioridad ALTA (Semana 5-8)

5. **Separación en capas (Domain/Data/Presentation)**
   - Empezar con 2-3 módulos (Finance, Habits, Tasks)
   - Crear use cases
   - Implementar repositories
   - **Beneficio:** Arquitectura mantenible + Testeable

6. **Agregación de Calendar en backend**
   - Eliminar CalendarAggregatorService del cliente
   - Implementar en Cloud Function
   - **Beneficio:** Performance drástica + Menos batería

7. **Sistema de notificaciones unificado**
   - Notificaciones locales + Push en un solo servicio
   - FCM tokens guardados en Firestore
   - Scheduled push desde backend
   - **Beneficio:** Engagement + Retención

8. **Migrar de Supabase Storage a Firebase Storage**
   - Unificar en un solo sistema
   - Simplificar dependencias
   - **Beneficio:** Menor complejidad + Costos

---

### 🟢 Prioridad MEDIA (Semana 9-12)

9. **Features de IA**
   - Recomendaciones de hábitos
   - Análisis nutricional
   - Sugerencias de tareas
   - **Beneficio:** Diferenciación + Premium features

10. **Exportación de datos**
    - CSV/PDF de todos los módulos
    - Backup automático a Google Drive/Dropbox
    - **Beneficio:** Trust del usuario + Compliance (GDPR)

11. **Análisis avanzados**
    - Correlaciones entre módulos (Gym + Food, Study + Sleep)
    - Dashboards ejecutivos
    - **Beneficio:** Insights valiosos

12. **Testing integral**
    - Unit tests para use cases
    - Integration tests para repositories
    - Widget tests para UI crítica
    - **Beneficio:** Calidad + Confianza en deploys

---

### 🔵 Prioridad BAJA (Backlog)

13. **Multi-tenant SaaS**
    - Workspaces compartidos (equipos, familia)
    - Roles y permisos
    - **Beneficio:** B2B opportunities

14. **Integraciones externas**
    - Google Calendar sync
    - Fitbit/Apple Health
    - Plaid (Open Banking)
    - **Beneficio:** Ecosystem + Network effects

15. **Gamificación**
    - Achievements y badges
    - Leaderboards (opcional, privado)
    - Streaks globales
    - **Beneficio:** Engagement + Viral growth

16. **Web app completa**
    - Desktop-optimized UI
    - Keyboard shortcuts
    - **Beneficio:** Expansión de mercado

---

## 🎯 MÉTRICAS DE ÉXITO

### Técnicas
- ✅ 100% de cálculos críticos movidos a backend
- ✅ Latencia de agregación Calendar < 500ms
- ✅ Crash rate < 0.1%
- ✅ Test coverage > 70% en use cases

### Negocio
- ✅ Retención D7 > 40%
- ✅ Session length +30% (mejor engagement)
- ✅ Notificaciones abiertas > 20%
- ✅ NPS > 50

---

## 📚 RECURSOS Y PRÓXIMOS PASOS

### 1. Configurar Firebase Functions
```bash
cd dash_new
firebase init functions
# Seleccionar TypeScript
# Instalar dependencias
cd functions
npm install firebase-admin firebase-functions
```

### 2. Estructura de Functions sugerida
```
functions/
├── src/
│   ├── index.ts                   # Entry point
│   ├── finance/
│   │   ├── recalculateStats.ts
│   │   └── processSubscriptions.ts
│   ├── habits/
│   │   └── calculateStreak.ts
│   ├── calendar/
│   │   └── aggregateEvents.ts
│   ├── notifications/
│   │   └── sendScheduled.ts
│   ├── ai/
│   │   ├── habitRecommendations.ts
│   │   ├── studySummary.ts
│   │   └── nutritionAnalysis.ts
│   └── utils/
│       ├── auth.ts
│       ├── validation.ts
│       └── notifications.ts
├── package.json
└── tsconfig.json
```

### 3. Documentación recomendada
- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)
- [Scheduled Functions](https://firebase.google.com/docs/functions/schedule-functions)
- [Clean Architecture Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [BLoC Pattern](https://bloclibrary.dev/)

---

## 🏁 CONCLUSIÓN

**Focuslane es una aplicación Flutter impresionantemente completa con 12 módulos funcionales**, pero está limitada por su arquitectura monolítica cliente-pesada. La migración a una arquitectura SaaS con backend serverless desbloqueará:

✅ **Escalabilidad:** Soportar miles de usuarios sin degradación  
✅ **Consistencia:** Datos siempre correctos, calculados en backend  
✅ **Seguridad:** Validaciones y lógica crítica protegidas  
✅ **Inteligencia:** Features de IA imposibles de implementar en cliente  
✅ **Mantenibilidad:** Código organizado, testeable y evolucionable  

**La inversión estimada de 10-12 semanas transformará Focuslane de una app personal a un producto SaaS profesional listo para escalar.**

---

**Autor:** GitHub Copilot  
**Fecha:** Enero 2026  
**Versión:** 1.0  
