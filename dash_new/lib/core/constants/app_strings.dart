class AppStrings {
  AppStrings._();

  static const dashboard = 'Panel';
  static const noDashboardDataTitle = 'No se pudo cargar el panel';
  static const noDashboardDataSubtitle = 'Comprueba la conexión e inténtalo de nuevo.';
  static const retry = 'Reintentar';

  static const buenosDias = 'BUENOS DIAS';
  static const buenasTardes = 'BUENAS TARDES';
  static const buenasNoches = 'BUENAS NOCHES';

  static String saludoSegunHora([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12 && hour > 5) return buenosDias;
    if (hour < 20) return buenasTardes;
    return buenasNoches;
  }

  static const heroTitle = 'Enfócate en el resultado.';
  static const heroSubtitle = 'La eficiencia no es hacer más, sino hacer lo que importa.';

  static const kpiTareas = 'Tareas';
  static const kpiHabitos = 'Hábitos';
  static const kpiEventos = 'Eventos';
  static const kpiEnfoque = 'Enfoque de hoy';
  static const kpiPendientesHoy = 'Pendientes hoy';
  static const kpiCompletados = 'Completados';
  static const kpiProximos = 'Próximos';
  static const sinRutina = 'Sin rutina';
  static const sinSesionEstudio = 'Sin sesión de estudio';

  static const tareasDeHoy = 'Tareas de hoy';
  static const sinTareasHoy = 'No hay tareas para hoy';

  static const accionesRapidas = 'Acciones rápidas';
  static const accionNuevaTarea = 'Crear nueva tarea';
  static const accionRegistrarHabito = 'Registrar hábito';
  static const accionNotaRapida = 'Crear nota rápida';
  static const accionAbrirCalendario = 'Abrir calendario';
  static const accionIniciarEstudio = 'Iniciar sesión de estudio';

  static const matrizHabitos = 'Matriz de hábitos';
  static const sinHabitosActivos = 'No hay hábitos activos';

  static const proximosEventos = 'Próximos eventos';
  static const sinEventosProximos = 'No hay eventos próximos';

  static const ultimaSesionGym = 'ÚLTIMA SESIÓN GYM';
  static const enfoqueEstudio = 'ENFOQUE ESTUDIO';
  static const sinRutinaActiva = 'Sin rutina activa';
  static const sinSesionesGym = 'Aún no hay sesiones de gym';
  static const sinSesion = 'Sin sesión';

  static const progresoSemanal = 'Progreso semanal';
  static const actividadReciente = 'Notas recientes';
  static const sinNotasRecientes = 'No hay notas recientes.';
  static const notaSinTitulo = 'Nota sin título';
  static const accesosRapidos = 'Accesos rápidos';

  static const usuario = 'FocusLane';
  static const portalProductividad = 'Portal de productividad';
  static const nuevaEntrada = 'Nueva entrada';
  static const ajustes = 'Ajustes';

  static const moduloTareas = 'Tareas';
  static const moduloHabitos = 'Hábitos';
  static const moduloNotas = 'Notas';
  static const moduloCalendario = 'Calendario';
  static const moduloGym = 'Gym';
  static const moduloNutricion = 'Nutrición';
  static const moduloFinanzas = 'Finanzas';
  static const moduloEstudio = 'Estudio';

  static String tareasPendientes(int total) => '$total TAREAS PENDIENTES';

  static String sesionEstudioMinutos(int minutes) => '$minutes min de estudio';

  static String resumenHabitosTareas(int completados, int totalHabitos, int tareasPendientes) =>
      'Hábitos $completados/$totalHabitos · Tareas $tareasPendientes pendientes';

  static String consistenciaSemanal(int porcentaje) => '$porcentaje% de consistencia esta semana';

  static String sesionMinutos(int minutes) => 'Sesión de $minutes min';

  static String tareasEstudioHoy(int total) => '$total tareas hoy';

  static const authSubtituloLogin = 'Introduce tus credenciales para acceder al portal';
  static const authCorreo = 'CORREO ELECTRÓNICO';
  static const authContrasena = 'CONTRASEÑA';
  static const authOlvidoContrasena = '¿Olvidaste la contraseña?';
  static const authIniciarSesion = 'Iniciar sesión';
  static const authOContinuarCon = 'O CONTINUAR CON';
  static const authGoogleNoNativo = 'Google Sign-In no está configurado en nativo.';
  static const authNoTienesCuenta = '¿No tienes cuenta? ';
  static const authRegistrarseAhora = 'Registrarse ahora';

  static const authCrearCuenta = 'Crear cuenta';
  static const authSubtituloRegistro = 'Únete al sistema de productividad.';
  static const authNombreCompleto = 'NOMBRE COMPLETO';
  static const authConfirmar = 'CONFIRMAR';
  static const authBotonCrearCuenta = 'Crear cuenta';
  static const authYaTienesCuenta = '¿Ya tienes una cuenta? ';
  static const authEntrar = 'Entrar';

  static const validacionRequerido = 'Requerido';
  static const validacionCorreoInvalido = 'Correo inválido';
  static const validacionMin6 = 'Mínimo 6 caracteres';
  static const validacionNoCoincide = 'No coincide';

  static const hintCorreo = 'correo@empresa.com';
  static const hintNombre = 'Escribe tu nombre';
}
