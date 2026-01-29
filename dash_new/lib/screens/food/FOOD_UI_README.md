# Food Module UI - Rediseño Premium

## 📋 Resumen del Cambio

Se ha refactorizado completamente el módulo Food con un diseño premium tipo SaaS, implementado desde cero con una paleta pastel profesional y componentes reutilizables.

## 🎨 Paleta de Colores Pastel

### Colores Principales
- **Beige Soft**: `#D7CDC2` - Tonos neutros cálidos
- **Taupe**: `#B5A89B` - Elegante y sofisticado
- **Teal Soft**: `#80AAA6` - Acento principal fresco
- **Teal Light**: `#A0BFBD` - Acento secundario suave
- **Background Light**: `#D2E2E0` - Fondo claro
- **Background Very Light**: `#E5EDEF` - Gris muy claro

### Dark Mode
- Fondos oscuros neutros (#1A1D1E, #242729, #2D3133)
- Acentos pastel suavizados para mantener elegancia
- Transiciones automáticas según el tema del sistema

## 📁 Archivos Creados

### 1. **lib/theme/food_theme.dart**
Sistema de diseño completo para el módulo Food:
- Paleta de colores pastel (light + dark)
- Gradientes suaves predefinidos
- Sistema de espaciado consistente (4/8/12/16/20/24/30/40)
- Bordes redondeados profesionales (12/16/20/24)
- Sombras sutiles con variantes hover
- Tipografía escalable y semántica
- Funciones helper para obtener colores según tema

### 2. **lib/screens/food/widgets/food_components.dart**
Componentes básicos reutilizables:

#### `FoodMetricCard`
- Card de métrica estilo SaaS con hover
- Icono con fondo coloreado
- Valor principal grande + subtitle
- Navegación al tap
- Responsive y con animaciones suaves

#### `FoodSectionHeader`
- Título de sección con icono opcional
- Subtítulo descriptivo
- Botón de acción opcional
- Consistente en todo el módulo

#### `FoodRecipeCard`
- Card horizontal de receta
- Imagen/placeholder con gradiente
- Tags coloridos (High protein, Low carb, Vegan)
- Macros (kcal, proteína)
- Hover effect profesional

#### `FoodMealSlot`
- Slot de comida para plan semanal
- Estado vacío: "+ Añadir"
- Estado lleno: nombre receta + kcal + editar
- Gradiente de fondo cuando tiene contenido

#### `FoodEmptyState`
- Estado vacío elegante centrado
- Icono grande circular con gradiente
- Título + subtítulo
- Botón de acción opcional

### 3. **lib/screens/food/widgets/food_sections.dart**
Componentes complejos y secciones:

#### `FoodTopBar`
- Top bar del módulo con título y subtítulo
- Buscador central
- Botones de acción: "Nueva receta", "Plan semanal", "Filtros"
- Layout responsive (desktop horizontal, mobile vertical)

#### `FoodWeeklyPlanCard`
- Card del plan semanal
- Desktop: grid 7 días × 3 comidas con scroll horizontal
- Mobile: selector de día + lista de comidas
- Botones: Generar plan, Exportar lista, Ver calendario
- Slots interactivos

#### `FoodShoppingListCard`
- Card de lista de compra
- Campo para añadir items rápido
- Items agrupados por categoría
- Checkboxes funcionales
- Botones: Marcar todo, Limpiar
- Estado vacío integrado

### 4. **lib/screens/food/dashboard/food_home_screen_v2.dart**
Pantalla principal completamente refactorizada:

#### Estructura
1. **FoodTopBar** fijo arriba
2. **Scroll principal** con CustomScrollView:
   - **Métricas** (4 cards): Calorías, Proteína, Recetas, Lista compra
   - **Plan Semanal** (card grande interactivo)
   - **Sección inferior** (desktop: 2 columnas, mobile: apilado):
     - Recetas recientes (6 cards)
     - Lista de compra (card lateral)

#### Responsive
- **Desktop** (≥1200px): 4 métricas, layout 2 columnas
- **Tablet** (600-1199px): 2 métricas por fila, layout 2 columnas
- **Mobile** (<600px): 1 métrica por fila, columnas apiladas

#### Integración con Firestore
- Streams preservados del código original
- `streamDay()` para métricas diarias
- `streamRecipes()` para recetas
- `streamShoppingLists()` para lista de compra
- Placeholders cuando no hay datos

## 🚀 Características Premium

### Micro-interacciones
- Hover effects en desktop (cambio de sombra, borde)
- InkWell con splash suave
- AnimatedContainer para transiciones
- Estados disabled/loading elegantes

### Accesibilidad
- Tooltips en botones
- Contraste adecuado en light/dark
- Tamaños táctiles mínimos (44×44)
- Semántica correcta

### Performance
- `const` constructors donde es posible
- Widgets optimizados con keys
- Streams eficientes
- Lazy loading de imágenes

## 📐 Sistema de Espaciado

Consistente en todo el módulo:
- `spacing4`: 4px - micro
- `spacing8`: 8px - xs
- `spacing12`: 12px - sm
- `spacing16`: 16px - md
- `spacing20`: 20px - lg
- `spacing24`: 24px - xl
- `spacing30`: 30px - 2xl
- `spacing40`: 40px - 3xl

## 🎯 TODOs Pendientes

Los siguientes TODOs están marcados en el código para futuras implementaciones:

1. **Búsqueda**: Implementar funcionalidad de búsqueda en FoodTopBar
2. **Filtros**: Modal/sheet de filtros avanzados
3. **Generación automática**: IA para generar plan semanal
4. **Detalle de receta**: Pantalla completa de receta al hacer tap
5. **Añadir items**: CRUD de lista de compra desde el card
6. **Cálculo de macros**: Sumar kcal/proteína reales desde ingredientes de receta
7. **Tags dinámicos**: Sistema de tags configurables por usuario
8. **Exportar**: Exportar plan semanal a PDF o imagen

## 🔧 Uso

### Importar el tema
```dart
import 'package:mi_dashboard_personal/theme/food_theme.dart';
```

### Usar componentes
```dart
import 'package:mi_dashboard_personal/screens/food/widgets/food_components.dart';
import 'package:mi_dashboard_personal/screens/food/widgets/food_sections.dart';

// Ejemplo: Metric Card
FoodMetricCard(
  icon: Icons.local_fire_department,
  label: 'Calorías hoy',
  value: '1,850 kcal',
  subtitle: 'de 2,000 objetivo',
  accentColor: FoodTheme.tealSoft,
  onTap: () => Navigator.push(...),
)
```

### Navegación
La pantalla principal maneja toda la navegación a:
- Diary (Diario de comidas)
- Recipes (Lista de recetas)
- Planner (Planificador semanal)
- Shopping (Listas de compra)

## 🎨 Diseño Inspirado En

- Dribbble dashboards modernos
- Linear.app (microinteracciones)
- Notion (tipografía y espaciado)
- Stripe Dashboard (métricas cards)
- Figma (paleta pastel profesional)

## ✅ Compatibilidad

- ✅ Flutter 3.x
- ✅ Material 3
- ✅ Web (responsive)
- ✅ Desktop (Windows/macOS/Linux)
- ✅ Mobile (iOS/Android)
- ✅ Light + Dark mode
- ✅ Sin dependencias externas adicionales

## 📝 Notas Técnicas

- **No rompe lógica existente**: toda la lógica de Firestore se mantiene
- **Componentización máxima**: cada widget es reutilizable
- **Performance**: optimizado con const y keys
- **Mantenible**: código limpio y comentado
- **Escalable**: fácil añadir nuevas secciones

---

**Creado**: Enero 2026  
**Versión**: 2.0 Premium
