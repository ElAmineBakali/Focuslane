# FocusLane redesign progress

## Fase 1 - Auditoria visual inicial

Fecha: 2026-05-15

### Archivos principales detectados

- `dash_new/lib/main.dart`: configura `MaterialApp`, temas, rutas, localizacion y servicios de arranque.
- `dash_new/lib/navigation/app_routes.dart`: constantes de rutas principales.
- `dash_new/lib/navigation/app_router.dart`: mapa real de rutas de autenticacion, Home, modulos, notificaciones, ajustes y finanzas.
- `dash_new/lib/design/theme/theme.dart`: tema claro/oscuro de Material.
- `dash_new/lib/design/ui/tokens/focuslane_tokens.dart`: tokens visuales base, spacing, radios, bordes y colores historicos.
- `dash_new/lib/design/ui/tokens/focuslane_semantic_tokens.dart`: paleta semantica light/dark usada por componentes y pantallas.
- `dash_new/lib/design/ui/components/*`: componentes visuales reutilizables ya existentes, como `FocusCard`, botones, campos, chips, badges, empty states y headers.
- `dash_new/lib/design/ui/layouts/module_shell.dart`: shell responsive interno para modulos con sidebar propio.
- `dash_new/lib/design/ui/layouts/module_sidebar.dart`: sidebar interno de modulos.
- `dash_new/lib/screens/home/screens/home_dashboard_screen.dart`: Home actual, con datos reales pero shell/sidebar/topbar privados dentro de la pantalla.
- `dash_new/lib/screens/home/controllers/home_dashboard_controller.dart`: fuente de datos reales para Home combinando tareas, habitos, calendario, estudio, gimnasio, finanzas y notas.
- `dash_new/lib/screens/tasks/screens/tasks_main_screen.dart`: pantalla real de tareas con CRUD y filtros.
- `dash_new/lib/screens/notes/screens/notes_list_screen.dart`: pantalla real de notas con lista/grid, filtros y editor.
- `dash_new/lib/screens/settings/screens/settings_screen.dart`: ajustes, tema, perfil y cierre de sesion.
- `dash_new/lib/screens/notifications/screens/global_notifications_screen.dart`: configuracion real de notificaciones.

### Problemas visuales detectados

- Home mezcla layout, sidebar, topbar y cards privadas en un solo archivo; esto dificulta reutilizar el lenguaje visual.
- Los tokens existentes tienen superficies muy parecidas entre si y `cardShadow` devuelve una lista vacia, por eso la app se percibe plana.
- El shell de Home no comparte componentes con `ModuleShell`, y `ModuleShell` tampoco tiene topbar/sidebar premium.
- Hay inconsistencias de ancho: Home usa sidebar de 210 px, la referencia y `ModuleSidebar` usan 260 px.
- Las cards de Home usan paneles con relleno/borde, pero sin elevacion, jerarquia de superficies ni bento grid claro.
- Hay textos visibles con mojibake en algunas zonas heredadas que conviene revisar en una limpieza separada.
- Algunos modulos principales usan `Scaffold/AppBar` propios y otros usan `ModuleShell`, por lo que la navegacion visual aun no es totalmente uniforme.

### Plan de cambios por fases

1. Sistema visual comun:
   - Ajustar tokens semanticos light/dark hacia la referencia visual.
   - Dar profundidad real a `FocusCard`.
   - Agregar componentes comunes faltantes: `AppShell`, `Sidebar`, `TopBar`, `PageContainer`, `SectionHeader`, `StatCard`, `ModuleCard`, `SecondaryButton`, `IconButton`, `SearchField`, `ProgressRing` y `ResponsiveGrid`.
2. Sidebar y topbar:
   - Crear un shell comun con rutas reales, drawer movil, notificaciones, ajustes, perfil e inicio/cierre de sesion.
   - Mejorar visualmente `ModuleShell/ModuleSidebar` sin cambiar las rutas internas de modulos.
3. Home:
   - Rehacer solo la capa visual de Home usando `HomeDashboardController` y datos reales.
   - Mantener navegacion real y empty states reales.
4. Validacion:
   - Ejecutar `flutter analyze`.
   - Ejecutar `flutter build web`.
   - Revisar manualmente lo posible en desktop/movil, light/dark y navegacion principal.
5. Siguiente fase:
   - Solo despues de validar Home, redisenar Tareas y Notas.

### Que NO se va a tocar

- Servicios, repositorios, controladores de negocio y modelos.
- Firebase, Firestore, Storage, App Check, autenticacion y persistencia.
- Cloud Functions, backend, reglas de seguridad, sincronizacion o IA.
- Proteccion de Finance y rutas internas de finanzas.
- Logica de notificaciones, recordatorios o planificadores.
- CRUD real de tareas, notas, habitos, calendario, alimentacion, estudio, gimnasio o finanzas.

## Estado actual

- Fase 1 completada: auditoria inicial documentada.
- Fase 2 completada para la base visual comun: tokens, tema, cards, botones, icon buttons, search, stats, modulos, progreso circular, page container y responsive grid.
- Fase 3 completada para la base comun: `AppShell`, sidebar, topbar y drawer movil con rutas reales. Tambien se mejoro visualmente `ModuleShell/ModuleSidebar` sin cambiar su logica interna.
- Fase 4 completada: Home redisenada usando `HomeDashboardController` y datos reales.
- Fase 5 completada en validacion tecnica: `flutter analyze`, `flutter analyze --no-fatal-infos` y `flutter build web`.
- Fase 6 completada: rediseño visual de Tareas y Notas usando la base visual comun, sin cambiar servicios, modelos, rutas ni persistencia.

## Cambios realizados en esta fase

### Sistema visual comun

- `dash_new/lib/design/ui/tokens/focuslane_semantic_tokens.dart`: paleta semantica light/dark alineada con la referencia visual.
- `dash_new/lib/design/ui/tokens/focuslane_tokens.dart`: spacing, radios, ancho de sidebar/topbar, max width, sombras y helpers de superficie.
- `dash_new/lib/design/theme/theme.dart`: tema Material claro/oscuro con tipografia Inter, botones, inputs, cards, chips y appbars mas consistentes.
- `dash_new/lib/design/ui/components/focus_card.dart`: profundidad visual, borde limpio y padding comun.
- `dash_new/lib/design/ui/components/focus_primary_button.dart`: estilo actualizado sin icono forzado.
- `dash_new/lib/design/ui/components/focus_secondary_button.dart`: boton secundario comun.
- `dash_new/lib/design/ui/components/focus_icon_button.dart`: boton de icono visual reutilizable.
- `dash_new/lib/design/ui/components/focus_search_field.dart`: campo de busqueda comun.
- `dash_new/lib/design/ui/components/focus_progress_ring.dart`: anillo circular de progreso.
- `dash_new/lib/design/ui/components/focus_section_header.dart`: cabecera de seccion.
- `dash_new/lib/design/ui/components/focus_stat_card.dart`: card de metrica.
- `dash_new/lib/design/ui/components/focus_module_card.dart`: card de acceso a modulo.
- `dash_new/lib/design/ui/focuslane_ui.dart`: barrel export para usar la UI comun.
- `dash_new/lib/design/ui/layouts/page_container.dart`: contenedor responsive con max width.
- `dash_new/lib/design/ui/layouts/responsive_grid.dart`: grid responsive reutilizable.

### Shell, sidebar y topbar

- `dash_new/lib/design/ui/layouts/app_shell.dart`: shell comun con sidebar desktop, drawer movil, topbar, notificaciones, ajustes, perfil e inicio/cierre de sesion.
- `dash_new/lib/design/ui/layouts/module_shell.dart`: mejora visual del layout de modulos manteniendo sus rutas y contenido real.
- `dash_new/lib/design/ui/layouts/module_sidebar.dart`: sidebar premium para modulos, con activo visual y anchura consistente.
- `dash_new/lib/design/ui/components/focus_header.dart`: topbar visual mas consistente.
- `dash_new/lib/design/ui/components/focus_module_header.dart`: altura ajustada para la topbar comun.
- `dash_new/lib/navigation/app_routes.dart`: constantes faltantes para rutas ya existentes.
- `dash_new/lib/navigation/app_router.dart`: uso de constantes de ruta sin cambiar pantallas destino.

### Home

- `dash_new/lib/screens/home/screens/home_dashboard_screen.dart`: Home redisenada con bento grid, cards de tareas, progreso semanal, habitos, eventos, notas recientes y accesos rapidos. Conserva datos reales, rutas reales y empty states.

## Validacion ejecutada

- `dart format` sobre los archivos Dart modificados: correcto.
- `flutter analyze`: ejecutado. Resultado: codigo 1 por 380 `info` existentes en el repo, principalmente deprecaciones `withOpacity`, orden de propiedades y `BuildContext` async en modulos no tocados.
- `flutter analyze --no-fatal-infos`: ejecutado. Resultado: codigo 0, sin errores ni warnings bloqueantes.
- `flutter build web`: ejecutado. Resultado: codigo 0, build generado en `dash_new/build/web`.
- Aviso de build: Flutter informa incompatibilidades de dry-run Wasm en dependencias (`device_info_plus`, `image`, `flutter_timezone`). El build web normal se genero correctamente.

## Pruebas manuales

- Verificada por inspeccion la navegacion real del nuevo `AppShell`: Home, Tareas, Habitos, Calendario, Notas, Estudio, Alimentacion, Finanzas, Gimnasio, Ajustes, Notificaciones y Cerrar sesion.
- Verificada por inspeccion la adaptacion responsive: sidebar desktop y drawer movil.
- Pendiente de comprobacion interactiva en navegador: login, navegacion click a click, notificaciones, ajustes, cierre de sesion, light/dark, vista movil y vista desktop con usuario real. No se avanzo a Tareas ni Notas.

## Proximos pasos

1. Probar esta base en navegador con una cuenta real y datos reales para cubrir los flujos manuales completos.
2. Revisar visualmente light/dark en Tareas y Notas con contenido real abundante.
3. Siguiente fase pendiente: elegir el proximo modulo a redisenar, sin avanzar todavia desde esta fase.

## Fase 6 - Tareas y Notas

Fecha: 2026-05-15

### Archivos tocados

- `dash_new/lib/screens/tasks/screens/tasks_main_screen.dart`
- `dash_new/lib/screens/tasks/screens/task_create_screen.dart`
- `dash_new/lib/screens/tasks/screens/task_edit_screen.dart`
- `dash_new/lib/screens/notes/screens/notes_list_screen.dart`
- `dash_new/lib/screens/notes/screens/note_editor_screen.dart`

### Cambios hechos

- Tareas:
  - Pantalla principal migrada a `AppShell`, `PageContainer`, `FocusCard`, `FocusStatCard`, `FocusBadge`, `FocusChip`, `FocusPrimaryButton`, `FocusSecondaryButton`, `FocusIconButton` y `ResponsiveGrid`.
  - Header visual con titulo `Tareas`, descripcion, boton de nueva tarea y control para ver completadas.
  - Filtros visibles en una barra propia, sin cambiar el filtro real `showCompleted`.
  - Lista agrupada redisenada con paneles colapsables, cards responsive, badges de prioridad, estado, fecha limite, origen/modulo, categoria, etiquetas y subtareas.
  - Crear/editar tarea rediseñados con cards de seccion, campos coherentes, selectores de fecha/hora, switches y acciones responsive.
- Notas:
  - Lista real migrada a `AppShell` con header de workspace, boton de nueva nota, metricas y controles de orden/vista.
  - Vista lista y vista cuadricula rediseñadas con cards, portada/fallback, titulo, resumen, fecha, fijadas, etiquetas y tareas vinculadas.
  - Empty state de notas actualizado con accion real a `/notes/editor`.
  - Editor real mejorado con cabecera de titulo, estado de autoguardado, acciones guardar/eliminar, superficie de escritura centrada y toolbar responsive.

### Funcionalidad mantenida intacta

- Tareas: creacion, edicion, eliminacion, marcado como completada, creacion de siguiente tarea repetida, subtareas, filtros de completadas, agrupacion/ordenacion existente, Firestore, rutas reales y navegacion.
- Notas: carga por stream, ordenacion existente, vista lista/cuadricula, creacion, edicion, autoguardado, guardado, carga por `noteId`, eliminacion, Firestore y rutas reales.
- No se tocaron servicios, repositorios, controladores, modelos, autenticacion, notificaciones globales, backend, Firebase ni otros modulos.
- En `TaskEditScreen` se preservan los campos existentes de recordatorio y vinculos (`linkedNoteId`, `linkedStudyCourseId`, `syncedStudyTaskId`) al guardar para no perder sincronizacion al editar.

### Validacion ejecutada

- `dart format` sobre los cinco archivos modificados: correcto.
- `flutter analyze` completo: ejecutado. Resultado: codigo 1 por 364 `info` heredados del repo; no se detectaron warnings nuevos en los archivos tocados tras la correccion.
- `flutter analyze` limitado a los cinco archivos modificados: codigo 0, `No issues found`.
- `flutter build web`: codigo 0, build generado en `dash_new/build/web`.
- Servidor local estatico levantado desde `dash_new/build/web` en `http://127.0.0.1:5174`: responde con estado 200.
- Aviso de build: Flutter sigue informando incompatibilidades de dry-run Wasm en dependencias (`device_info_plus`, `image`, `flutter_timezone`). El build web normal se genero correctamente.

### Pruebas manuales

- Verificado por analisis de rutas y codigo que Tareas mantiene `/tasks`, `/tasks/create` y `/tasks/detail` sin cambiar destinos.
- Verificado por analisis de rutas y codigo que Notas mantiene `/notes`, `/notes/list` y `/notes/editor` sin cambiar destinos.
- Verificada por compilacion la integracion con sidebar/topbar comun al usar `AppShell` en los modulos principales.
- Pendiente de prueba interactiva con usuario real en navegador: crear/editar/eliminar tarea, marcar completada, filtrar, volver a Home, crear/abrir/editar/guardar nota, recargar, notificaciones, cierre de sesion y comprobacion visual light/dark en desktop, medio y movil.

### Pendientes siguientes

- Hacer una pasada visual interactiva con datos reales para detectar overflow puntual en contenidos extremos.
- Decidir el siguiente modulo a redisenar en una fase separada.

## Fase 7 - Calendario y Habitos

Fecha: 2026-05-15

### Archivos tocados

- `dash_new/lib/screens/calendar/screens/calendar_screen.dart`
- `dash_new/lib/screens/calendar/widgets/calendar_month_view.dart`
- `dash_new/lib/screens/calendar/widgets/calendar_day_view.dart`
- `dash_new/lib/screens/calendar/widgets/calendar_agenda_view.dart`
- `dash_new/lib/screens/calendar/widgets/calendar_year_view.dart`
- `dash_new/lib/screens/calendar/widgets/calendar_item_widget.dart`
- `dash_new/lib/screens/calendar/widgets/calendar_event_editor.dart`
- `dash_new/lib/screens/calendar/widgets/calendar_timeline.dart`
- `dash_new/lib/screens/calendar/controllers/calendar_controller.dart`
- `dash_new/lib/screens/calendar/controllers/calendar_interaction_controller.dart`
- `dash_new/lib/screens/calendar/services/calendar_aggregator_service.dart`
- `dash_new/lib/screens/habits/screens/habits_table_screen.dart`
- `dash_new/lib/screens/habits/screens/habit_create_screen.dart`
- `dash_new/lib/screens/habits/screens/habit_detail_screen.dart`

### Cambios hechos

- Calendario:
  - Pantalla principal migrada a `AppShell`, topbar comun, `FocusCard`, `FocusBadge`, `FocusChip`, `FocusPrimaryButton`, `FocusSecondaryButton` y `FocusIconButton`.
  - Header limpio con titulo `Calendario`, periodo visible, acciones de anterior/siguiente/hoy y boton `Nuevo evento`.
  - Selector visual de vista `Anual / Mensual / Dia / Agenda` sin cambiar el `TabController` ni la logica existente.
  - Vista mensual envuelta en card, dias con eventos mas legibles, panel del dia redisenado y empty state para dias sin eventos.
  - Agenda redisenada con buscador, secciones por dia, cards de eventos, modulo/hora en chips y empty state.
  - Vista diaria con controles de zoom y superficie de timeline dentro de card, manteniendo drag/drop, resize y creacion por slot.
  - Editor de evento redisenado como bottom sheet, con campos y selectores mas limpios y etiquetas en castellano.
  - Etiquetas visibles de modulos y mensajes de calendario corregidos a castellano.
- Habitos:
  - Pantalla principal de matriz migrada a `AppShell`, header visual, acciones de crear/ver archivados y metricas superiores reales.
  - Resumen superior con progreso semanal, completados hoy, racha actual y mejor racha calculados desde los habitos reales.
  - Matriz redisenada con columna de nombres mas clara, cabecera de dias alineada, celda de hoy destacada, bordes y estados visuales para completado/no completado/saltado/valor numerico.
  - Empty state de habitos y archivados actualizado con accion real de crear habito.
  - Modo edicion/ordenacion conserva reorder real y muestra estado visual cuando esta activo.
  - Dialogo de marcado diario y bottom sheet de opciones redisenados sin cambiar los callbacks de Firestore.
  - Formularios de crear/editar habito limpiados con `FocusCard`, cabeceras de seccion, selector de color y acciones primarias/secundarias coherentes.

### Funcionalidad mantenida intacta

- Calendario: creacion, edicion, eliminacion de eventos, seleccion de dia, vistas anual/mensual/dia/agenda, navegacion de periodo, filtros por modulo/prioridad, busqueda de agenda, drag/drop/resize, deep links, rutas reales, Firebase/Firestore y sincronizacion con otros modulos.
- Habitos: creacion, edicion, archivado/desarchivado, matriz real, marcado diario completado/no completado/saltado/valor numerico, orden manual, estadisticas por ruta existente, progreso/rachas, modelos, servicios, Firestore y rutas reales.
- No se tocaron Study, Food, Finance, Gym ni Ajustes. Tampoco se tocaron Home, Tareas ni Notas.

### Validacion ejecutada

- `dart format` sobre los 14 archivos Dart modificados: correcto. Fue necesario ejecutarlo fuera del sandbox porque Dart/Flutter quedaban bloqueados dentro del sandbox.
- `flutter analyze`: ejecutado. Resultado: codigo 1 por 358 `info` heredados del repo; no se detectaron errores ni warnings bloqueantes.
- `flutter analyze` limitado a los 14 archivos modificados: codigo 0, `No issues found`.
- `flutter build web`: codigo 0, build generado en `dash_new/build/web`.
- Aviso de build: Flutter mantiene incompatibilidades de dry-run Wasm en dependencias (`device_info_plus`, `image`, `flutter_timezone`). El build web normal se genero correctamente.

### Pruebas manuales

- Verificado por analisis de rutas y codigo que Calendario mantiene `/calendar` y sus callbacks reales de crear, editar, eliminar, seleccionar dia, cambiar periodo/vista, filtros, agenda y vuelta mediante sidebar/topbar.
- Verificado por analisis de rutas y codigo que Habitos mantiene `/habits`, `/habits/create`, `/habits/detail` y `/habits/stats` sin cambiar destinos ni modelos.
- Verificada por compilacion la integracion con sidebar/topbar comun, light/dark por uso de `ColorScheme` y superficies tokenizadas, y responsive por layouts con `LayoutBuilder`, `Wrap`, `Expanded` y scroll horizontal limitado a la matriz.
- Pendiente de prueba interactiva con usuario real en navegador: crear/editar/eliminar evento, crear/editar/archivar habito, marcar varias celdas, comprobar progreso semanal con datos reales, revisar light/dark en desktop/medio/movil y navegacion click a click. No se puede completar desde esta sesion sin acceso a una sesion autenticada con datos reales.

### Pendientes siguientes

- Hacer una pasada manual en navegador con cuenta real para confirmar overflow puntual en contenidos extremos.
- Revisar `habit_stats_screen.dart` en una fase posterior si se quiere un rediseño profundo de la pantalla de estadisticas; en esta fase se mantuvo para no ampliar alcance ni tocar logica pesada de graficas.
- No avanzar a Study, Food, Finance, Gym ni Ajustes hasta nueva indicacion.

## Fase 8 - Ajustes, Notificaciones, Login y Registro

Fecha: 2026-05-15

### Archivos tocados

- `dash_new/lib/screens/auth/screens/login_screen.dart`
- `dash_new/lib/screens/auth/screens/register_screen.dart`
- `dash_new/lib/screens/auth/widgets/auth_shell.dart`
- `dash_new/lib/screens/auth/widgets/auth_form_card.dart`
- `dash_new/lib/screens/auth/widgets/auth_header.dart`
- `dash_new/lib/screens/auth/widgets/auth_text_field.dart`
- `dash_new/lib/screens/auth/widgets/auth_secondary_link.dart`
- `dash_new/lib/screens/settings/screens/settings_screen.dart`
- `dash_new/lib/screens/notifications/screens/global_notifications_screen.dart`
- `dash_new/lib/screens/notifications/widgets/notification_diagnostics_panel.dart`
- `dash_new/lib/design/ui/layouts/app_shell.dart`

### Cambios hechos

- Login y Registro se reconstruyeron con los widgets reutilizables de autenticacion, marca FocusLane, cards centradas, campos accesibles, errores en castellano, estados de carga y responsive movil/desktop.
- Ajustes se migro a `AppShell`, `PageContainer` y cards profesionales para perfil/cuenta, apariencia, modulos activos, notificaciones, seguridad y cierre de sesion.
- Notificaciones globales se migro a `AppShell`, con header, diagnostico integrado, modulos en cards expansibles, filas responsive por entidad y textos visibles en castellano natural.
- El panel de diagnostico mantiene permisos, FCM, exact alarms y botones de prueba push/local, pero con `FocusCard` y una presentacion mas limpia.
- El shell comun recibio ajustes minimos de textos visibles: Inicio, Habitos, Alimentacion, Cerrar sesion, Sesion activa y Abrir navegacion.

### Funcionalidad mantenida intacta

- Firebase Auth: login, registro, Google en web, recuperacion de contrasena, sesion persistente y rutas reales.
- Perfil: Firestore, Storage, `displayName`, `photoURL`, bio y foto.
- Tema: `ThemeMode` real y persistencia por el callback existente.
- Modulos: `ModuleVisibilityService`, preferencias locales y ruta `/modules`.
- Notificaciones: SharedPreferences de estudio, configuracion de alimentacion, recordatorios de gimnasio, store por entidad, scheduler, cancelacion por modulo, diagnostico FCM y pruebas push/local.
- No se tocaron Study, Food, Finance ni Gym como pantallas principales.

### Validacion ejecutada

- `dart format` sobre los archivos modificados: correcto. Fue necesario ejecutarlo fuera del sandbox porque Dart quedaba bloqueado dentro del sandbox.
- `dart analyze` limitado a los archivos tocados: codigo 0, `No issues found`.
- `flutter analyze`: ejecutado. Resultado: codigo 1 por 348 `info` heredados del repo; no se detectaron errores ni warnings bloqueantes en los archivos tocados.
- `flutter build web`: codigo 0, build generado en `dash_new/build/web`.
- Servidor estatico temporal sobre `dash_new/build/web` en `http://127.0.0.1:5175`: respondio 200 durante la comprobacion.
- Aviso de build: Flutter mantiene incompatibilidades de dry-run Wasm en dependencias (`device_info_plus`, `image`, `flutter_timezone`). El build web normal se genero correctamente.

### Pruebas manuales y limites

- Verificada por analisis de rutas y codigo la navegacion a Login, Registro, Ajustes, Notificaciones, modulos y vuelta desde configuraciones internas de notificaciones.
- Verificada por compilacion la integracion con dark/light mode al usar `ColorScheme`, superficies tokenizadas y componentes comunes.
- Verificada por revision estatica la adaptacion responsive con `LayoutBuilder`, `Wrap`, scrolls verticales, botones full-width en movil y filas que pasan a columna en espacios estrechos.
- Se intentaron capturas headless con Edge en desktop, movil y tamano medio, pero la build release usa CanvasKit y el navegador headless produjo lienzos blancos; no se cuentan como validacion visual fiable.
- Pendiente de prueba interactiva con cuenta real: iniciar sesion, cerrar sesion, registro con errores reales, cambio de tema, toggles de modulos, configuracion de notificaciones por entidad, push/local de prueba y revision visual click a click en desktop/medio/movil.

### Pendientes siguientes

- Ejecutar una pasada manual en navegador con usuario real y permisos de notificacion reales.
- No avanzar a Study, Food, Finance ni Gym hasta una fase posterior explicita.

## Fase 9 - Estudio y Finanzas

Fecha: 2026-05-15

### Módulos rediseñados

- Estudio: pantalla principal, panel, diario, cursos, detalle editable de curso, calificaciones, planificador, tareas e historial.
- Finanzas: acceso protegido por contraseña, shell interno, panel, transacciones, suscripciones, activos, deudas, análisis y ajustes de seguridad.

### Archivos modificados

- `dash_new/lib/design/ui/components/focus_section_nav.dart`
- `dash_new/lib/design/ui/focuslane_ui.dart`
- `dash_new/lib/screens/study/screens/main/study_main_screen.dart`
- `dash_new/lib/screens/study/screens/dashboard/study_dashboard_screen.dart`
- `dash_new/lib/screens/study/screens/diary/study_diary_screen.dart`
- `dash_new/lib/screens/study/screens/courses/courses_list_screen.dart`
- `dash_new/lib/screens/study/screens/courses/course_detail_editable_screen.dart`
- `dash_new/lib/screens/study/screens/schedule/schedule_screen.dart`
- `dash_new/lib/screens/study/screens/schedule/schedule_widgets.dart`
- `dash_new/lib/screens/study/screens/tasks/study_tasks_screen.dart`
- `dash_new/lib/screens/study/screens/history/study_history_screen.dart`
- `dash_new/lib/screens/study/screens/timer/presets_sheet.dart`
- `dash_new/lib/screens/study/widgets/interactive_schedule_grid.dart`
- `dash_new/lib/screens/finance/widgets/finance_access_gate.dart`
- `dash_new/lib/screens/finance/widgets/finance_shell.dart`
- `dash_new/lib/screens/finance/screens/main/finance_main_screen.dart`
- `dash_new/lib/screens/finance/screens/dashboard/finance_dashboard_screen.dart`
- `dash_new/lib/screens/finance/screens/transactions/transactions_screen.dart`
- `dash_new/lib/screens/finance/screens/subscriptions/subscriptions_screen.dart`
- `dash_new/lib/screens/finance/screens/assets/assets_screen.dart`
- `dash_new/lib/screens/finance/screens/debts/debts_screen.dart`
- `dash_new/lib/screens/finance/screens/analytics/analytics_screen.dart`
- `dash_new/lib/screens/finance/screens/settings/finance_settings_screen.dart`
- `dash_new/lib/screens/finance/screens/forms/transaction_form_screen.dart`
- `dash_new/lib/screens/finance/screens/forms/subscription_form_screen.dart`
- `dash_new/lib/screens/finance/screens/forms/asset_form_screen.dart`
- `dash_new/lib/screens/finance/screens/forms/debt_form_screen.dart`
- `dash_new/lib/screens/finance/services/finance_category_labels.dart`
- `dash_new/lib/screens/finance/services/finance_ai_normalizer.dart`
- `dash_new/lib/screens/finance/services/finance_receipt_ai_service.dart`
- `dash_new/lib/screens/finance/services/settings_service.dart`

### Componentes reutilizados

- `AppShell`, `PageContainer`, `FocusSectionHeader`, `FocusCard`, `FocusStatCard`, `FocusBadge`, `FocusChip`, `FocusIconButton`, `FocusEmptyState`, `ResponsiveGrid` y el nuevo `FocusSectionNav`.
- Se mantiene la navegación real por `AppRoutes` y los servicios existentes de Firestore/Firebase, seguridad financiera e IA financiera.

### Cambios hechos

- Estudio:
  - `StudyMainScreen` usa el shell común con navegación interna por secciones.
  - Panel, diario, cursos, tareas e historial se reconstruyeron con cards, métricas, estados vacíos y grids responsive usando datos reales.
  - El detalle de curso quedó integrado en `AppShell`, conserva asistencia, edición, archivado/eliminación y calificaciones reales.
  - Las calificaciones mantienen el guardado optimista existente para que no desaparezcan mientras llega el stream remoto.
  - El historial resuelve nombres de cursos desde los datos cargados en vez de mostrar ids cuando hay curso disponible.
  - El planificador conserva bloques reales de horario y edición por bottom sheet, con cabecera visual común.
- Finanzas:
  - La pantalla de contraseña se rehizo con aspecto premium y mantiene `FinanceSecurityService`.
  - El panel financiero, transacciones, suscripciones, activos, deudas, análisis y ajustes usan cards, métricas, listas responsive y estados de error/carga controlados.
  - `FinanceShell` quedó alineado con `AppShell` para formularios y secciones internas sin cambiar rutas ni servicios.
  - Los formularios de transacciones, suscripciones, activos y deudas conservan guardado real, IA, recibos, fechas, categorías y navegación.

### Componentes antiguos eliminados o reemplazados

- Se reemplazaron los mini-shells visuales propios de Estudio y Finanzas por `AppShell` y `FocusSectionNav`.
- Se retiró la cabecera antigua con `FocusModuleHeader` del detalle editable de curso y del planificador.
- No se eliminaron servicios, modelos ni lógica real.

### UTF-8 y textos

- Corregidos textos visibles y etiquetas en Estudio/Finanzas: Estudio, Finanzas, Panel, Cursos, Calificaciones, Historial, Sesión, Contraseña, Presupuesto, Transacción, Suscripción, Categoría, Importe, Fecha, Guardar, Eliminar, Cancelar, Editar, Buscar, Añadir y Análisis.
- Corregidos textos de formularios financieros: `Vehículo`, `Inversión`, `Préstamo`, `Tasa de interés`, `Importe inválido`, `Valor inválido`, `Suscripción activa`, `Suscripción creada/actualizada`, `Categoría`, `Subcategoría` y `Transacción creada/actualizada`.
- Corregidas etiquetas financieras normalizadas y exportaciones CSV: `Alimentación`, `Educación`, `Transporte público`, `Médico`, `Membresía`, `Título`, `Categoría` y `Subcategoría`.
- Barrido de mojibake ejecutado sobre Estudio/Finanzas: sin resultados.

### Funcionalidad mantenida intacta

- Estudio: cursos, tareas, sesiones, planificador, calificaciones, historial, asistencia, temporizador, Firestore y navegación real.
- Finanzas: contraseña/bloqueo, seguridad, transacciones, suscripciones, activos, deudas, análisis, clasificación IA, recibos, Firestore y navegación real.
- No se tocaron Gym/Gimnasio ni Food/Alimentación.

### Validación ejecutada

- `dart format` sobre los archivos Dart modificados: correcto.
- `flutter analyze`: ejecutado. Resultado: código 1 por 328 `info` heredados/no bloqueantes; sin errores ni warnings.
- `flutter analyze --no-fatal-infos`: código 0.
- `flutter build web`: código 0, build generado en `dash_new/build/web`.
- Aviso de build: Flutter mantiene avisos de dry-run Wasm en dependencias (`device_info_plus`, `image`, `flutter_timezone`). El build web normal se generó correctamente.

### Pruebas manuales y límites

- Verificado por análisis de rutas y código que Estudio sigue abriendo desde sidebar, conserva cursos, detalle de curso, calificaciones, tareas, sesiones e historial.
- Verificado por análisis de rutas y código que Finanzas sigue pasando por pantalla protegida por contraseña y mantiene dashboard, transacciones, suscripciones, activos, deudas, análisis y ajustes de seguridad.
- Verificada por compilación la integración con sidebar, topbar, responsive y dark/light al usar `AppShell`, `ColorScheme` y componentes comunes.
- Pendiente de prueba interactiva con una sesión autenticada y datos reales: crear/abrir curso, añadir calificación, revisar que queda visible tras sincronizar, introducir contraseña de Finanzas, crear/editar registros financieros y revisar visualmente desktop/móvil y light/dark click a click.

## Fase 10 - Gimnasio y Alimentación

Fecha: 2026-05-16

### Módulos rediseñados

- Gimnasio: panel, rutinas, detalle de rutina, sesión activa, contador de descanso, historial y resumen de sesión.
- Alimentación: panel, diario, objetivos, comidas, hidratación, análisis con IA por imagen, recetas/listas enlazadas y navegación interna.

### Archivos modificados

- `dash_new/lib/screens/gym/screens/main/gym_main_screen.dart`
- `dash_new/lib/screens/gym/screens/dashboard/gym_dashboard_screen.dart`
- `dash_new/lib/screens/gym/screens/routines/routines_list_screen.dart`
- `dash_new/lib/screens/gym/screens/routines/routine_detail_screen.dart`
- `dash_new/lib/screens/gym/screens/routines/routine_builder_screen.dart`
- `dash_new/lib/screens/gym/screens/session/live_session_screen.dart`
- `dash_new/lib/screens/gym/screens/session/session_history_screen.dart`
- `dash_new/lib/screens/gym/screens/session/session_summary_screen.dart`
- `dash_new/lib/screens/gym/widgets/rest_timer.dart`
- `dash_new/lib/screens/gym/widgets/exercise_picker_sheet.dart`
- `dash_new/lib/screens/food/screens/main/food_main_screen.dart`
- `dash_new/lib/screens/food/screens/food_dashboard_screen.dart`
- `dash_new/lib/screens/food/screens/food_diary_screen.dart`
- `dash_new/lib/screens/food/screens/foods_list_screen.dart`
- `dash_new/lib/screens/food/screens/recipes_list_screen.dart`
- `dash_new/lib/screens/food/screens/food_planner_screen.dart`
- `dash_new/lib/screens/food/screens/shopping_lists_screen.dart`
- `dash_new/lib/screens/food/screens/shopping_list_detail_screen.dart`
- `dash_new/lib/screens/food/screens/pantry_screen.dart`
- Eliminado: `dash_new/lib/screens/food/screens/food_dashboard_widgets.dart`

### Componentes reutilizados

- `AppShell`, `PageContainer`, `FocusSectionNav`, `FocusSectionHeader`, `FocusCard`, `FocusStatCard`, `FocusProgressRing`, `FocusProgressBar`, `FocusBadge`, `FocusIconButton`, `FocusPrimaryButton`, `FocusSecondaryButton`, `FocusTextField`, `FocusEmptyState`, `ResponsiveGrid` y `FocusFeedback`.

### Cambios hechos

- Gimnasio:
  - `GymMainScreen` mantiene el header interno por secciones y ahora el panel puede abrir Rutinas, Progreso e Historial sin salir del shell.
  - El dashboard se reconstruyó como bento premium con sesión activa/próxima sesión, métricas, rutina semanal, últimas sesiones, alertas y progreso.
  - Rutinas dejó la lista plana y pasó a cards responsive con estado, días, progreso visual, acciones y bottom sheets modernos para crear/editar.
  - Detalle de rutina se rediseñó con hero, resumen por días, ejercicios en cards, añadir ejercicio, duplicar/eliminar día e iniciar sesión.
  - Sesión activa se rediseñó con card fuerte del ejercicio actual, progreso circular, controles grandes, series en cards, descanso activo y acciones móviles claras.
  - El contador de descanso usa card visual con anillo grande, presets y controles limpios, conservando notificaciones.
  - Historial y resumen de sesión usan cards agrupadas, métricas, sensaciones, PRs y acciones sin cambiar guardado ni borrado.
- Alimentación:
  - `FoodMainScreen` migró a `AppShell` y `FocusSectionNav`, alineado con Estudio y Finanzas.
  - El panel se reconstruyó como bento con card principal de calorías, macros, hidratación, análisis con IA, registro diario, recetas recientes, alertas y lista de compra.
  - Se eliminaron los cálculos falsos del panel de recetas y se usan los valores reales de `Recipe`.
  - El diario se rediseñó con selector de día en card, métricas responsive, comidas por cards, hidratación con anillo y objetivos del día.
  - Los formularios principales de Food conservan los callbacks reales y reciben embedded mode para integrarse dentro del shell sin appbars duplicadas.
  - Se limpiaron separadores raros y mojibake visible en pantallas/widgets de Gym y Food.

### Componentes antiguos eliminados o reemplazados

- Eliminado `food_dashboard_widgets.dart`, ya sin referencias tras el nuevo panel de Alimentación.
- Reemplazadas las cards y secciones planas del dashboard de Food por componentes `Focus*`.
- Reemplazadas las listas planas principales de Gym por cards responsive y bento sections.
- No se eliminaron servicios, modelos, repositorios, rutas globales, Firebase, IA, notificaciones, timers ni lógica real.

### UTF-8 y textos

- Barrido ejecutado sobre `lib/screens/gym` y `lib/screens/food`: no quedan caracteres raros en pantallas/widgets tocados.
- Queda un texto con mojibake en `lib/screens/food/services/food_photo_ai_service.dart`, dentro de un servicio que se dejó intacto por restricción explícita de la fase.

### Funcionalidad mantenida intacta

- Gimnasio: rutinas, días, ejercicios, sesión activa, series, descanso, historial, resumen, notificaciones, Firestore y navegación real.
- Alimentación: objetivos, diario, comidas, hidratación, recetas, compra, despensa, planificación, análisis IA por foto, Firestore y navegación real.
- No se tocaron Home, Tareas, Notas, Calendario, Hábitos, Ajustes, Notificaciones, Login, Registro, Estudio ni Finanzas.

### Validación ejecutada

- `dart format` sobre los archivos Dart modificados: correcto.
- `flutter analyze`: ejecutado. Resultado: código 1 por 265 `info` heredados/no bloqueantes; sin errores de compilación.
- `flutter build web`: código 0, build generado en `dash_new/build/web`.
- Servidor estático temporal sobre `dash_new/build/web` en `http://127.0.0.1:5176`: respondió `HTTP 200`.
- Aviso de build: Flutter mantiene avisos de dry-run Wasm en dependencias (`device_info_plus`, `image`, `flutter_timezone`). El build web normal se generó correctamente.

### Pruebas manuales y límites

- Verificado por análisis de rutas y código que Gimnasio mantiene panel, rutinas, detalle, sesión activa, descanso, historial y resumen sin cambiar servicios ni modelos.
- Verificado por análisis de rutas y código que Alimentación mantiene panel, diario, registro, hidratación, análisis IA, recetas, compra, plan y despensa sin cambiar servicios ni modelos.
- Verificada por compilación la integración con sidebar/topbar común, navegación interna, responsive y dark/light al usar `AppShell`, `ColorScheme` y componentes comunes.
- Pendiente de prueba interactiva con sesión autenticada y datos reales: abrir Gimnasio y Alimentación click a click, iniciar sesión activa, probar descanso, registrar comida, probar análisis IA con imagen, revisar historial, móvil y dark mode en navegador real.
