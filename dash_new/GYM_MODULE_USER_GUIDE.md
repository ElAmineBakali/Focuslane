# 🏋️ Guía de Uso - Nuevas Funcionalidades del Módulo Gym

## 🔔 Notificaciones

### Configuración Automática
Las notificaciones se configuran automáticamente cuando:
- Completas una sesión de entrenamiento → Se programa recordatorio de inactividad
- Abres el módulo Gym → Se programan recordatorios semanales de peso y medidas

### Recordatorios Disponibles

#### 1. Inactividad (3 días sin entrenar)
**Activación**: Automática después de cada sesión  
**Configuración**: Se puede modificar el número de días en `gym_notification_service.dart` (constante `_defaultInactivityDays`)  
**Notificación**: "Vuelve al gym - Llevas X días sin entrenar"

#### 2. Peso Corporal Semanal
**Activación**: Automática (lunes 8:00 AM por defecto)  
**Personalización**: Modificar día/hora llamando a `GymNotificationService.I.scheduleWeeklyWeightReminder(weekday: DateTime.monday, time: TimeOfDay(hour: 8, minute: 0))`  
**Notificación**: "Registro de peso - Es momento de registrar tu peso corporal"

#### 3. Medidas Físicas Semanales
**Activación**: Automática (lunes 9:00 AM por defecto)  
**Personalización**: Similar al peso corporal  
**Notificación**: "Medidas corporales - Registra tus medidas físicas de esta semana"

### Reprogramar Notificaciones
Toca el icono 🔔 en la parte superior derecha del módulo Gym para reprogramar todas las notificaciones.

---

## 📊 Sensaciones Post-Entrenamiento

### Cómo Registrar

1. **Completa una sesión**: Al finalizar un entrenamiento y guardar la sesión
2. **Pantalla de resumen**: Automáticamente aparecerá una tarjeta "¿Cómo te sentiste?"
3. **Ajusta los 3 sliders**:
   - ⚡ **Energía** (1-5): ¿Qué nivel de energía tuviste?
   - 💪 **Fatiga física** (1-5): ¿Cuánto cansancio muscular sientes?
   - ❤️ **Motivación** (1-5): ¿Cómo estaba tu ánimo?
4. **Guarda**: Toca "Guardar sensaciones"

### Interpretación de Valores
- **1-2**: Bajo/Malo
- **3**: Normal/Medio
- **4-5**: Alto/Excelente

### Ver Análisis de Sensaciones

1. Ve a **Analíticas** (botón en pantalla principal)
2. Toca la pestaña **"Sensaciones"**
3. Verás:
   - Promedios de energía, fatiga y motivación del periodo
   - Barras de progreso visuales
   - Interpretación inteligente de tu estado

**Consejo**: Si la fatiga es alta (4-5) varias sesiones seguidas, considera tomar un día de descanso.

---

## 📜 Historial de Sesiones

### Acceder al Historial

**Opción 1**: Desde pantalla principal del Gym  
→ Toca el botón **"Historial"** (icono de reloj)

**Opción 2**: Desde Analíticas  
→ Toca el icono de historial 📜 en la barra superior

### Funcionalidades

#### Búsqueda
Escribe en el campo de búsqueda para filtrar sesiones por:
- Nombre de rutina
- Nombre de día

#### Filtros por Rutina
Toca los chips de rutina para ver solo sesiones de esa rutina específica.  
"Todas" muestra todas las sesiones.

#### Información por Sesión
Cada tarjeta muestra:
- 🏋️ Rutina y día
- 📅 Fecha completa
- ⏱️ Duración en minutos
- ⚖️ Volumen total levantado
- 🏆 PRs conseguidos (si los hay)
- 🧠 Sensaciones registradas (si las completaste)

#### Ver Detalle
Toca cualquier sesión para ver el resumen completo con:
- Todos los ejercicios realizados
- Series, repeticiones y pesos por ejercicio
- Notas de la sesión
- PRs logrados
- Sensaciones detalladas

---

## 🗑️ Eliminar Sesiones

### Proceso Seguro

1. **Abre una sesión**: Desde historial o analíticas
2. **Toca el icono de papelera** (🗑️) en la barra superior
3. **Confirma**: Lee la advertencia y toca "Eliminar"

### ⚠️ Importante
- La eliminación es **permanente**
- Las estadísticas se actualizan automáticamente
- Los gráficos se recalculan sin esa sesión
- Los PRs se mantienen si aún son válidos en otras sesiones

### Casos de Uso
Elimina sesiones cuando:
- Registraste datos incorrectos
- Quieres limpiar tu historial
- Una sesión fue incompleta y prefieres no contarla

---

## 📈 Gráficos Mejorados

### Interpretación

#### Volumen Semanal (Barras)
- **Eje Y**: Kilogramos totales levantados
- **Eje X**: Número de semana
- **Tooltip**: Toca una barra para ver volumen exacto
- **Objetivo**: Mantener volumen consistente o progresivo

#### Evolución de Peso (Línea)
- **Puntos**: Cada registro de peso corporal
- **Línea azul**: Tendencia general
- **Área**: Visualización del rango
- **Tooltip**: Toca un punto para ver fecha y peso exacto

#### Distribución Muscular (Pie Chart)
- **Colores**: Cada grupo muscular tiene un color
- **Porcentajes**: Proporción de volumen por grupo
- **Leyenda**: A la derecha del gráfico
- **Uso**: Identificar desequilibrios en tu entrenamiento

---

## 💡 Consejos de Uso

### Para Maximizar Datos
1. **Registra sensaciones** después de cada sesión (solo toma 10 segundos)
2. **Añade peso corporal** al menos una vez por semana (lunes recomendado)
3. **Toma medidas** mensualmente para ver progreso físico
4. **Revisa analíticas** cada semana para ajustar tu plan

### Interpretación de Sensaciones
- **Energía baja + Fatiga alta** → Necesitas descanso
- **Motivación baja** → Prueba cambiar tu rutina
- **Todo alto** → ¡Estás en tu mejor momento!

### Uso del Historial
- Busca sesiones antiguas para comparar volumen
- Identifica patrones (ej: qué días rindes mejor)
- Limpia sesiones erróneas sin miedo

---

## 🐛 Resolución de Problemas

### Las notificaciones no aparecen
1. Verifica permisos de notificaciones en ajustes del sistema
2. En Android 12+: Permite notificaciones exactas
3. Toca el botón 🔔 para reprogramar

### No veo la sección de sensaciones
Solo aparece en sesiones **nuevas** (completadas después de la actualización).  
Sesiones antiguas no tendrán esta opción.

### Los gráficos están vacíos
Asegúrate de:
- Tener al menos 2-3 sesiones registradas
- Haber añadido registros de peso/medidas
- El periodo seleccionado incluye datos

### La eliminación no funciona
Si una sesión no se elimina:
1. Verifica tu conexión a internet
2. Intenta cerrar y reabrir la app
3. La sesión debe tener un ID válido

---

## 📱 Compatibilidad

✅ Android 8.0+ (API 26+)  
✅ iOS 13.0+  
✅ Modo oscuro totalmente compatible  
✅ Tablets y móviles

---

## 🆘 Soporte

Si encuentras algún problema:
1. Cierra y reabre la app
2. Verifica tu conexión a Firebase
3. Revisa que tienes la última versión

**Nota**: Todos los datos están en Firestore y son persistentes incluso si desinstalas la app.
