# PLAN COMPLETO DE RECONSTRUCCIÓN DEL MÓDULO DE FINANZAS

## ESTADO ACTUAL  
El módulo tiene estructura visual básica pero **CERO funcionalidad real**:
- ❌ No filtra por mes actual (muestra todas las transacciones mezcladas)
- ❌ No hay alertas de presupuestos excedidos
- ❌ No hay notificaciones de suscripciones próximas  
- ❌ No hay plantillas de transacciones
- ❌ No hay filtros avanzados (fecha, categoría, cuenta, búsqueda)
- ❌ No hay gráficos de evolución
- ❌ Deudas sin ledger calculado
- ❌ Depósitos sin balance acumulado
- ❌ Patrimonio sin fotos ni evolución de valor
- ❌ Gastos variables sin estado mensual
- ❌ Sin PIN/Biometría funcional
- ❌ Sin exportación CSV
- ❌ Presupuestos sin progreso real-time de transacciones

## IMPLEMENTACIÓN REQUERIDA

### 1. FINANCE HOME (Dashboard KPI Real)
**Archivo**: `finance_home_screen_v2.dart`
**Implementar**:
```dart
// KPIs del MES ACTUAL (no de todos los tiempos)
- Balance mensual (ingresos - gastos este mes)
- Ingresos del mes
- Gastos del mes  
- Tendencia vs mes anterior (+ iconos ↑↓)
- Mini gráfico de cashflow (ultimos 7 días)

// Alertas prioritarias
- Presupuestos excedidos (rojo, mostrar %)
- Suscripciones próximas (< 3 días)
- Gastos fijos pendientes del mes

// Accesos rápidos mejorados
- Nueva transacción (formulario completo)
- Ver todas las transacciones (con filtros)
- Gestionar presupuestos
- Analytics completo
```

### 2. TRANSACTIONS (Filtros + Plantillas)
**Archivos**: `transactions_screen_v2.dart`, `transaction_form_screen_v2.dart`
**Implementar**:
```dart
// Lista con filtros avanzados
- Rango de fechas (DateRangePicker)
- Tipo (income/expense/transfer) - Chips
- Categoría + Subcategoría (Autocomplete)
- Cuenta (Dropdown)
- Buscar por título/notas
- Tags (multi-select chips)

// Plantillas frecuentes
- Mostrar top 5 transacciones más repetidas
- "Repetir transacción" - botón en cada item
- Guardar como plantilla (icono ★)
- Sección "Plantillas guardadas"

// Formulario completo
- Todos los campos: título, monto, tipo, fecha
- Categoría + Subcategoría (autocomplete de historial)
- Cuenta (dropdown)
- Tags (chips editables)
- Divisa original + FX Rate (campos opcionales)
- Recurrencia (none/weekly/monthly/custom)
- Notas largas (maxLines: 5)
- Validaciones fuertes (monto > 0, título requerido)
```

### 3. BUDGETS (Progreso Real-Time)
**Archivo**: `budgets_screen_v2.dart`
**Implementar**:
```dart
// Progreso en tiempo real
Stream<double> calculateSpent(Budget budget) {
  // Query transacciones donde:
  // - date >= budget.startDate && date <= budget.endDate
  // - category == budget.category (si aplica)
  // - type == expense
  // Sumar amounts
}

// Visual de presupuestos
- Card por presupuesto con:
  * Nombre + categoría
  * Monto presupuestado vs gastado
  * Barra de progreso (color verde/amarillo/rojo)
  * Porcentaje (ej: "85% usado")
  * Días restantes del periodo
  
// Alertas configurables  
- Umbral de alerta (ej: 80%, 90%, 100%)
- Notificación local cuando se supera
- Indicador visual (⚠️ badge rojo)

// Múltiples periodos
- Semanal, Mensual, Custom (start-end dates)
- Selector en formulario
- Cálculo automático de fechas
```

### 4. SUBSCRIPTIONS (Notificaciones Reales)
**Archivo**: `subscriptions_screen_v2.dart`
**Implementar**:
```dart
// Programar notificaciones
void scheduleSubscriptionReminder(Subscription sub) async {
  final notifId = sub.id.hashCode;
  final daysArray = [1, 3, 7]; // configurable
  for (final days in daysArray) {
    final notifDate = sub.nextDueDate.subtract(Duration(days: days));
    await NotificationService.I.scheduleOnce(
      id: notifId + days,
      title: 'Pago próximo: ${sub.name}',
      body: 'En $days días (${sub.amount}€)',
      whenLocal: notifDate,
    );
  }
}

// Histórico de pagos
- Tabla con fecha, monto, método de pago
- Botón "Ver histórico" por suscripción
- Stream de transacciones vinculadas (relatedTxId)

// Auto-marcar (opcional, configurable)
- Toggle "Auto-crear transacción"
- Si activo: en la fecha de vencimiento, crear tx automático
- Notificación: "Se registró pago de Netflix (12.99€)"

// Próximos pagos destacados
- Sección en Finance Home
- Card con los 3 próximos pagos
- Indicador de días restantes (badge)
```

### 5. VARIABLE EXPENSES (Estado Mensual)
**Archivo**: Crear `variable_expenses_screen_v2.dart`
**Implementar**:
```dart
// Vista por mes
- Selector de mes/año (DatePicker)
- Lista de gastos variables con estado:
  * Verde ✓: Pagado (existe tx vinculada)
  * Amarillo ⏱: Pendiente
  * Gris: N/A este mes

// Crear transacción vinculada
- Botón "Pagar ahora" en cada item pendiente
- Abre formulario pre-rellenado con:
  * Título = expense.description
  * Monto = expense.estimatedAmount
  * Categoría = expense.category
  * Link relatedTxId
- Al guardar, marca como pagado

// Marcar automático
- Al cargar lista, buscar transacciones del mes
- Si existe tx con mismo título/categoría/monto similar:
  * Auto-vincular (update relatedTxId)
  * Marcar como pagado

// Progreso mensual
- Total estimado vs real gastado
- Barra de progreso
- Diferencia en €
```

### 6. DEBTS (Ledger Completo)
**Archivo**: `debts_screen_v2.dart`
**Implementar**:
```dart
// Ledger por persona
class DebtLedger {
  final String personId;
  final List<DebtEntry> entries; // ordenadas por fecha
  double get balance => entries.fold(0, (sum, e) => 
    sum + (e.type == 'lend' ? e.amount : -e.amount)
  );
}

// Card por persona
- Nombre + foto (opcional)
- Saldo total (positivo = me deben, negativo = debo)
- Botón "Ver ledger"

// Vista de ledger individual
- Tabla cronológica:
  * Fecha | Concepto | Monto | Balance acumulado
  * Color: verde (me deben), rojo (debo)
- Botón "+ Nuevo movimiento"
- Botón "Saldar deuda" (crea entry de balance)

// Vincular transacciones
- Campo opcional "Transaction ID" en DebtEntry
- Si se rellena, mostrar link a tx
- Desde transacciones, opción "Vincular a deuda"

// Gráfica de evolución
- LineChart con balance en el tiempo
- Eje X: fechas, Eje Y: saldo
```

### 7. DEPOSITS (Balance Histórico)
**Archivo**: Crear `deposits_screen_v2.dart`
**Implementar**:
```dart
// Vista por cuenta
- Lista de cuentas (DepositAccount)
- Balance actual visible en card

// Movimientos con balance acumulado
Stream<List<DepositMovementWithBalance>> getMovementsWithBalance(
  String accountId
) {
  // Query movements ordenados por fecha ASC
  // Calcular balance acumulado:
  double running = initialBalance;
  for (movement in movements) {
    running += movement.type == 'deposit' 
      ? movement.amount 
      : -movement.amount;
    movement.runningBalance = running;
  }
}

// Tabla de movimientos
- Fecha | Concepto | Tipo | Monto | Balance
- Iconos: ↑ (deposit), ↓ (withdrawal)
- Color por tipo

// Vincular transacciones
- Campo txRef en DepositMovement
- Al crear movimiento, buscar tx pendientes
- Opción de vincular (rellenar txRef)

// Gráfico de evolución
- LineChart del balance en el tiempo
- Filtrar por rango de fechas
```

### 8. ASSETS (Fotos + Evolución)
**Archivo**: `assets_screen_v2.dart`
**Implementar**:
```dart
// Migrar a colección privada
Colección: /users/{userId}/assets
- Permisos: solo el usuario puede leer/escribir

// Modelo expandido
class Asset {
  String id;
  String name;
  String category; // 'vehicle', 'property', 'investment', 'other'
  double purchasePrice;
  DateTime purchaseDate;
  String? photoUrl; // URL de Cloud Storage
  String? location; // dirección o coordenadas
  List<ValueSnapshot> valueHistory; // evolución del valor
  String? notes;
}

class ValueSnapshot {
  DateTime date;
  double value;
  String? notes; // ej: "Tasación profesional"
}

// Vista Grid
- GridView con cards
- Mostrar foto (o icono por categoría)
- Nombre + valor actual
- Indicador de cambio (% desde compra)

// Formulario
- Campos: nombre, categoría (dropdown), precio, fecha
- Botón "Añadir foto" (image_picker + Firebase Storage)
- Campo opcional: ubicación (TextField)
- Notas (maxLines: 3)

// Gráfico de patrimonio total
- Sumar valores de todos los assets
- LineChart con evolución temporal
- Mostrar valor total actual destacado
```

### 9. ANALYTICS (Comparativas + Gráficos)
**Archivo**: `finance_analytics_screen_v2.dart`
**Implementar**:
```dart
// Comparativa mensual
- Ingresos mes actual vs anterior (% cambio)
- Gastos mes actual vs anterior
- Balance mes actual vs anterior
- Indicadores visuales: ↑↓ con colores

// Gráfico de ingresos/gastos
- BarChart por mes (últimos 6 meses)
- Dos barras por mes: ingresos (verde), gastos (rojo)
- Balance (línea amarilla)

// Top 5 categorías
- PieChart de categorías de gastos
- % del total por categoría
- Mostrar monto y %

// Cashflow
- LineChart de balance acumulado
- Eje X: fechas (últimos 30 días)
- Eje Y: balance

// Ahorro acumulado
- Calcular: sum(ingresos) - sum(gastos) desde inicio
- Mostrar con KPI card grande
- Tendencia (gráfico mini)
```

### 10. SETTINGS (PIN/Bio + CSV)
**Archivo**: `finance_settings_screen_v2.dart`
**Implementar**:
```dart
// Biometría funcional
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

- Toggle "Requerir autenticación"
- Si activo: al abrir Finance module, pedir bio/PIN
- Usar LocalAuthentication.authenticate()
- Mensaje: "Autenticación requerida para Finanzas"

// PIN personalizado
- Botón "Configurar PIN"
- Modal con 4-digit PIN input
- Guardar hash en FlutterSecureStorage
- Opción "Cambiar PIN" / "Eliminar PIN"

// Recordatorios configurables
- Toggle "Recordatorios de suscripciones"
- Slider "Días de anticipación" (1-7)
- Toggle "Alertas de presupuestos"
- Slider "Umbral de alerta" (50%-100%)

// Exportación CSV
- Botón "Exportar transacciones"
- DateRangePicker para seleccionar rango
- Generar CSV con columnas:
  Fecha, Tipo, Título, Monto, Categoría, Cuenta, Notas
- Guardar en Downloads o compartir

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

Future<void> exportTransactionsCSV(
  List<FinanceTransaction> txs
) async {
  List<List<dynamic>> rows = [
    ['Fecha', 'Tipo', 'Título', 'Monto', 'Categoría', 'Notas']
  ];
  for (final tx in txs) {
    rows.add([
      tx.date.toString(),
      tx.type.name,
      tx.title,
      tx.amount,
      tx.category ?? '',
      tx.notes ?? '',
    ]);
  }
  String csv = const ListToCsvConverter().convert(rows);
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/transacciones_${DateTime.now().millisecondsSinceEpoch}.csv');
  await file.writeAsString(csv);
  // Mostrar snackbar con path
}
```

## ORDEN DE IMPLEMENTACIÓN

### FASE 1: CORE FUNCIONAL (Ahora)
1. ✅ Finance UI Theme (hecho)
2. 🔄 Modelos completos (validar)
3. ⚠️ Transaction Service con filtros avanzados
4. ⚠️ Budget Service con cálculo real-time
5. ⚠️ Subscription Service con notificaciones

### FASE 2: SCREENS CRÍTICAS
6. Finance Home con KPIs del mes actual
7. Transactions con filtros y plantillas
8. Budgets con progreso real
9. Subscriptions con recordatorios
10. Analytics con gráficos

### FASE 3: FEATURES AVANZADAS  
11. Variable Expenses (nueva funcionalidad)
12. Debts con ledger
13. Deposits con balance histórico
14. Assets con fotos
15. Settings con PIN/Bio + CSV

## ESTIMACIÓN
- **Tiempo total**: 40-60 horas de desarrollo
- **Complejidad**: Alta (múltiples integraciones, lógica de negocio compleja)
- **Prioridad**: CRÍTICA - el módulo actual es inutilizable

## NOTAS
- Cada pantalla debe usar FinanceUI para consistencia
- Todos los streams deben manejar errores
- Todos los formularios necesitan validación
- Todas las notificaciones requieren permisos del usuario
- Todos los gráficos usar fl_chart (ya instalado)
- Testing manual extensivo requerido

---

**ESTE ES UN TRABAJO MASIVO. El usuario tiene razón: el módulo actual solo tiene estructura visual sin funcionalidad real.**
