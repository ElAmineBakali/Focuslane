# 🚀 CÓMO PROBAR EL NUEVO DISEÑO FOOD

## Paso 1: Verificar que todo compile

```bash
flutter pub get
flutter analyze
```

Deberías ver **0 errores** en los siguientes archivos:
- `lib/theme/food_theme.dart`
- `lib/screens/food/dashboard/food_home_screen_v2.dart`
- `lib/screens/food/dashboard/widgets/food_components.dart`
- `lib/screens/food/dashboard/widgets/food_sections.dart`

## Paso 2: Ejecutar la app

### Desktop (recomendado para ver el diseño completo)
```bash
flutter run -d windows
# o
flutter run -d macos
# o
flutter run -d linux
```

### Web
```bash
flutter run -d chrome
```

### Mobile
```bash
flutter run -d android
# o
flutter run -d ios
```

## Paso 3: Navegar al módulo Food

Desde el home/modules screen de Focuslane, toca/haz clic en el módulo "Food".

Deberías ver:
1. **Top Bar** con título "Food", búsqueda y botones
2. **4 Metric Cards** (Calorías, Proteína, Recetas, Lista compra)
3. **Plan Semanal** con días de la semana
4. **Recetas Recientes** a la izquierda
5. **Lista de Compra** a la derecha

## Paso 4: Probar responsive

### Desktop (≥1200px)
- 4 métricas en una fila
- Plan semanal con 7 columnas (scroll horizontal)
- Layout de 2 columnas abajo

### Tablet (600-1199px)
- 2 métricas por fila
- Plan semanal con scroll
- Layout de 2 columnas abajo

### Mobile (<600px)
- 1 métrica por fila
- Selector de día + lista de comidas
- Columnas apiladas (recetas arriba, lista compra abajo)

Redimensiona la ventana para ver las transiciones.

## Paso 5: Probar interacciones

### Hover (desktop)
- Pasa el mouse sobre cualquier métrica → debería cambiar sombra y borde
- Pasa sobre recipe cards → hover effect

### Taps
- Toca una métrica → navega a la pantalla correspondiente
- Toca "Nueva receta" → va a lista de recetas
- Toca "Plan semanal" → va al planificador
- Toca un meal slot vacío → muestra "+ Añadir"
- Toca un meal slot con receta → muestra info y editar

### Búsqueda
- Toca el campo de búsqueda → placeholder visible
- (Funcionalidad pendiente de implementar)

## Paso 6: Probar light/dark mode

Cambia el tema de Focuslane a dark mode:
- Los colores pastel se suavizan automáticamente
- Fondos oscuros neutros
- Bordes y sombras ajustados
- Texto claro con opacidad

## Paso 7: Ver el showcase de componentes (opcional)

Para ver todos los componentes en un solo lugar:

1. Importa el showcase en tu navegación:
```dart
import 'package:mi_dashboard_personal/screens/food/dashboard/widgets/food_components_showcase.dart';
```

2. Navega a él:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const FoodComponentsShowcase(),
  ),
);
```

Verás:
- Todos los componentes aislados
- Paleta de colores
- Ejemplos interactivos

## 📊 Checklist de Verificación

- [ ] Compila sin errores
- [ ] Top bar visible y responsive
- [ ] 4 métricas se muestran correctamente
- [ ] Plan semanal renderiza (vacío o con placeholders)
- [ ] Recetas se cargan desde Firestore (o muestra empty state)
- [ ] Lista de compra muestra items (placeholders si no hay datos)
- [ ] Navegación funciona (Diary, Recipes, Planner, Shopping)
- [ ] Responsive desktop/tablet/mobile
- [ ] Light mode se ve bien
- [ ] Dark mode se ve bien
- [ ] Hover effects funcionan (desktop)
- [ ] Sin overflow amarillo/negro
- [ ] Scroll suave

## 🐛 Troubleshooting

### Error: "No se encuentra FoodTheme"
**Solución**: Verifica que `lib/theme/food_theme.dart` existe

### Error: "No se encuentra food_components"
**Solución**: Verifica la estructura:
```
lib/screens/food/dashboard/widgets/
  ├── food_components.dart
  └── food_sections.dart
```

### Los colores no se ven pastel
**Solución**: Verifica que estás usando `FoodTheme.getPrimaryAccent(context)` y no colores del theme global

### El responsive no funciona
**Solución**: Redimensiona la ventana (no solo zoom). Los breakpoints son:
- Mobile: < 600px
- Tablet: 600-1199px
- Desktop: ≥ 1200px

### No hay datos en recetas/lista compra
**Es normal**: Si tu Firestore está vacío, verás el "Empty State" elegante. Añade datos para ver los componentes llenos.

## 🎨 Personalización Rápida

### Cambiar colores
Edita `lib/theme/food_theme.dart`, líneas 7-13:
```dart
static const Color tealSoft = Color(0xFF80AAA6);  // Cambia aquí
static const Color tealLight = Color(0xFFA0BFBD); // Y aquí
```

### Cambiar espaciado
Edita `lib/theme/food_theme.dart`, líneas 66-73

### Cambiar bordes
Edita `lib/theme/food_theme.dart`, líneas 75-79

## 📸 Screenshots Recomendados

Para documentación/portfolio, toma screenshots de:
1. Desktop full screen (1920×1080) - light mode
2. Desktop full screen - dark mode
3. Tablet landscape (1024×768)
4. Mobile portrait (375×812)
5. Hover effect en métrica card
6. Plan semanal con datos
7. Empty state de recetas

## 🎉 ¡Listo!

Si todo funciona correctamente, deberías tener un módulo Food con aspecto premium, profesional y listo para escalar.

**Próximo paso**: Implementa los TODOs marcados según tu prioridad.
