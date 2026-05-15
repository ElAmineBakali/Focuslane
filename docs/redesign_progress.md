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
