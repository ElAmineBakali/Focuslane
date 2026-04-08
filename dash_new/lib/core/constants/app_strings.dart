class AppStrings {
  AppStrings._();

  static const dashboard = 'Panel';
  static const noDashboardDataTitle = 'No se pudo cargar el panel';
  static const noDashboardDataSubtitle = 'Comprueba la conexion e intentalo de nuevo.';
  static const retry = 'Reintentar';

  static const buenasTardes = 'BUENAS TARDES';
  static const buscarEntradas = 'Buscar entradas...';

  static const heroTitle = 'Enfocate en el resultado.';
  static const heroSubtitle = 'La eficiencia no es hacer mas, sino hacer lo que importa.';

  static const kpiTareas = 'Tareas';
  static const kpiHabitos = 'Habitos';
  static const kpiEventos = 'Eventos';
  static const kpiGymStudy = 'Gym/Estudio';
  static const kpiPendientesHoy = 'Pendientes hoy';
  static const kpiCompletados = 'Completados';
  static const kpiProximos = 'Proximos';
  static const sinRutina = 'Sin rutina';
  static const sinSesionEstudio = 'Sin sesion de estudio';

  static const tareasDeHoy = 'Tareas de hoy';
  static const sinTareasHoy = 'No hay tareas para hoy';

  static const accionesRapidas = 'Acciones rapidas';
  static const accionNuevaTarea = 'Crear nueva tarea';
  static const accionRegistrarHabito = 'Registrar habito';
  static const accionNotaRapida = 'Crear nota rapida';
  static const accionAbrirCalendario = 'Abrir calendario';
  static const accionIniciarEstudio = 'Iniciar sesion de estudio';

  static const matrizHabitos = 'Matriz de habitos';
  static const sinHabitosActivos = 'No hay habitos activos';

  static const proximosEventos = 'Proximos eventos';
  static const sinEventosProximos = 'No hay eventos proximos';

  static const ultimaSesionGym = 'ULTIMA SESION GYM';
  static const enfoqueEstudio = 'ENFOQUE ESTUDIO';
  static const sinRutinaActiva = 'Sin rutina activa';
  static const sinSesionesGym = 'Aun no hay sesiones de gym';
  static const sinSesion = 'Sin sesion';

  static const progresoSemanal = 'Progreso semanal';
  static const actividadReciente = 'Actividad reciente';
  static const sinNotasRecientes = 'No hay notas recientes.';
  static const notaSinTitulo = 'Nota sin titulo';
  static const accesosRapidos = 'Accesos rapidos';

  static const usuario = 'EL Amine';
  static const portalProductividad = 'Portal de productividad';
  static const nuevaEntrada = 'Nueva entrada';
  static const ajustes = 'Ajustes';

  static const moduloTareas = 'Tareas';
  static const moduloHabitos = 'Habitos';
  static const moduloNotas = 'Notas';
  static const moduloCalendario = 'Calendario';
  static const moduloGym = 'Gym';
  static const moduloNutricion = 'Nutricion';
  static const moduloFinanzas = 'Finanzas';
  static const moduloEstudio = 'Estudio';

  static String tareasPendientes(int total) => '$total TAREAS PENDIENTES';

  static String sesionEstudioMinutos(int minutes) => '$minutes min de estudio';

  static String resumenHabitosTareas(int completados, int totalHabitos, int tareasPendientes) =>
      'Habitos $completados/$totalHabitos · Tareas $tareasPendientes pendientes';

  static String consistenciaSemanal(int porcentaje) => '$porcentaje% de consistencia esta semana';

  static String sesionMinutos(int minutes) => 'Sesion de $minutes min';

  static String tareasEstudioHoy(int total) => '$total tareas hoy';

  static const authSubtituloLogin = 'Introduce tus credenciales para acceder al portal';
  static const authCorreo = 'CORREO ELECTRONICO';
  static const authContrasena = 'CONTRASENA';
  static const authOlvidoContrasena = 'Olvidaste la contrasena?';
  static const authIniciarSesion = 'Iniciar sesion  ->';
  static const authOContinuarCon = 'O CONTINUAR CON';
  static const authGoogleNoNativo = 'Google Sign-In no esta configurado en nativo.';
  static const authNoTienesCuenta = 'No tienes cuenta? ';
  static const authRegistrarseAhora = 'Registrarse ahora';

  static const authCrearCuenta = 'Crear cuenta';
  static const authSubtituloRegistro = 'Unete al sistema de productividad.';
  static const authNombreCompleto = 'NOMBRE COMPLETO';
  static const authConfirmar = 'CONFIRMAR';
  static const authBotonCrearCuenta = 'Crear cuenta  ->';
  static const authYaTienesCuenta = 'Ya tienes una cuenta? ';
  static const authEntrar = 'Entrar';

  static const validacionRequerido = 'Requerido';
  static const validacionCorreoInvalido = 'Correo invalido';
  static const validacionMin6 = 'Minimo 6 caracteres';
  static const validacionNoCoincide = 'No coincide';

  static const hintCorreo = 'correo@empresa.com';
  static const hintNombre = 'Escribe tu nombre';
}
