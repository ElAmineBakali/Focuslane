import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:focuslane/design/ui/focuslane_ui.dart';
import 'package:focuslane/navigation/app_route_observer.dart';
import 'package:focuslane/navigation/app_routes.dart';
import 'package:focuslane/screens/food/models/food_models.dart';
import 'package:focuslane/screens/food/screens/food_diary_screen.dart';
import 'package:focuslane/screens/food/screens/recipe_detail_screen.dart';
import 'package:focuslane/screens/food/screens/recipes_list_screen.dart';
import 'package:focuslane/screens/food/screens/shopping_lists_screen.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/food/services/food_photo_ai_service.dart';

class FoodDashboardScreen extends StatefulWidget {
  const FoodDashboardScreen({
    super.key,
    required this.svc,
    this.embedded = false,
    this.onOpenSection,
  });

  final FoodFirestoreService svc;
  final bool embedded;
  final ValueChanged<int>? onOpenSection;

  @override
  State<FoodDashboardScreen> createState() => _FoodDashboardScreenState();
}

class _FoodDashboardScreenState extends State<FoodDashboardScreen>
    with RouteAware {
  final FoodPhotoAiService _photoAiService = FoodPhotoAiService();

  String _dayId(DateTime date) => date.toIso8601String().substring(0, 10);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final todayId = _dayId(DateTime.now());
    final content = StreamBuilder<Map<String, double?>>(
      stream: widget.svc.streamGlobalTargets(),
      builder: (context, targetsSnap) {
        return StreamBuilder<DailyIntakeDoc>(
          stream: widget.svc.streamDay(todayId),
          builder: (context, daySnap) {
            return StreamBuilder<List<Recipe>>(
              stream: widget.svc.streamRecipes(),
              builder: (context, recipeSnap) {
                return StreamBuilder<List<ShoppingList>>(
                  stream: widget.svc.streamShoppingLists(),
                  builder: (context, shoppingSnap) {
                    final day =
                        daySnap.data ??
                        DailyIntakeDoc(
                          id: todayId,
                          entries: const [],
                          waterMl: 0,
                          totals: const {
                            'kcal': 0,
                            'protein': 0,
                            'carbs': 0,
                            'fat': 0,
                          },
                          targets: const {},
                        );
                    final targets =
                        targetsSnap.data ?? const <String, double?>{};
                    final recipes = recipeSnap.data ?? const <Recipe>[];
                    final lists = shoppingSnap.data ?? const <ShoppingList>[];
                    return _FoodDashboardContent(
                      dayId: todayId,
                      day: day,
                      targets: targets,
                      recipes: recipes,
                      shoppingLists: lists,
                      onOpenDiary:
                          () => _openSectionOrPush(
                            context,
                            sectionIndex: 1,
                            builder: (_) => FoodDiaryScreen(svc: widget.svc),
                          ),
                      onOpenRecipes:
                          () => _openSectionOrPush(
                            context,
                            sectionIndex: 3,
                            builder: (_) => RecipesListScreen(svc: widget.svc),
                          ),
                      onOpenShopping:
                          () => _openSectionOrPush(
                            context,
                            sectionIndex: 5,
                            builder:
                                (_) => ShoppingListsScreen(svc: widget.svc),
                          ),
                      onAddWater:
                          (ml) => widget.svc.incrementWater(todayId, ml),
                      onStartPhotoAi: _startPhotoAiFlow,
                      svc: widget.svc,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    if (widget.embedded) return content;

    return AppShell(
      title: 'Alimentación',
      subtitle: 'Calorías, macros, hidratación y análisis con IA.',
      activeRoute: AppRoutes.foodDashboard,
      actions: [
        FocusIconButton(
          icon: Icons.add_a_photo_outlined,
          tooltip: 'Analizar comida por foto',
          onPressed: _startPhotoAiFlow,
        ),
        const SizedBox(width: 10),
      ],
      child: content,
    );
  }

  void _openSectionOrPush(
    BuildContext context, {
    required int sectionIndex,
    required WidgetBuilder builder,
  }) {
    final handler = widget.onOpenSection;
    if (handler != null) {
      handler(sectionIndex);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  Future<void> _startPhotoAiFlow() async {
    final file = await _pickImageForPhotoAi();
    if (file == null || !mounted) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    var analyzingShown = false;
    var analysisCanceled = false;

    try {
      void cancelAnalysis() {
        analysisCanceled = true;
        if (analyzingShown && mounted && rootNavigator.canPop()) {
          rootNavigator.pop();
          analyzingShown = false;
        }
        if (kDebugMode) debugPrint('[FoodPhotoAI] análisis cancelado');
      }

      analyzingShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PhotoAiAnalyzingDialog(onCancel: cancelAnalysis),
      );

      final result = await _photoAiService.estimateFromImage(file);
      if (analysisCanceled) return;

      if (analyzingShown && mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
        analyzingShown = false;
      }

      if (!mounted) return;
      await _showPhotoAiPreview(_dayId(DateTime.now()), result);
    } catch (error) {
      if (analyzingShown && mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
      if (analysisCanceled || !mounted) return;

      final message =
          error is FoodPhotoAiException
              ? error.message
              : 'No se pudo analizar la foto. Revisa la conexión e inténtalo de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<XFile?> _pickImageForPhotoAi() async {
    final picker = ImagePicker();
    try {
      if (kIsWeb) return picker.pickImage(source: ImageSource.gallery);

      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder:
            (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Cámara'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Galería'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
      );

      if (source == null) return null;
      return picker.pickImage(source: source);
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el selector de imágenes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  Future<void> _showPhotoAiPreview(
    String dayId,
    CaloriesAiResult result,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final macros = result.macros;
            Future<void> confirm() async {
              if (saving) return;
              setSheetState(() => saving = true);
              try {
                await _savePhotoAiEntry(dayId: dayId, result: result);
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Entrada añadida por foto.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (_) {
                if (!sheetContext.mounted) return;
                setSheetState(() => saving = false);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo guardar la entrada.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }

            return _PhotoAiPreviewSheet(
              result: result,
              protein: macros.protein,
              carbs: macros.carbs,
              fat: macros.fat,
              saving: saving,
              onCancel: () => Navigator.pop(sheetContext),
              onConfirm: confirm,
            );
          },
        );
      },
    );
  }

  Future<void> _savePhotoAiEntry({
    required String dayId,
    required CaloriesAiResult result,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final entry = IntakeEntry(
      id: '',
      type: FavoriteType.photoAi,
      refId: 'ai:${DateTime.now().millisecondsSinceEpoch}',
      qty: 1,
      unit: UnitKind.unit,
      nameSnapshot:
          result.items.isNotEmpty
              ? result.items.first.name
              : 'Comida estimada por foto',
      macrosSnapshot: {
        'kcal': result.calories,
        'protein': result.macros.protein,
        'carbs': result.macros.carbs,
        'fat': result.macros.fat,
        'fiber': 0,
        'sodium': 0,
      },
      meal: MealSlot.lunch,
      aiMeta: {
        'source': 'openai',
        'model': result.model,
        'confidence': result.confidence,
        'classifiedAt': nowIso,
        'mimeType': result.mimeType,
        'bytesLength': result.bytesLength,
        'items':
            result.items
                .map(
                  (item) => {
                    'name': item.name,
                    'portion': item.portion,
                    'calories': item.calories,
                  },
                )
                .toList(),
        if (result.inputHash != null && result.inputHash!.trim().isNotEmpty)
          'inputHash': result.inputHash,
      },
    );

    await widget.svc.addPhotoAiEntry(dayId: dayId, entry: entry);
  }
}

class _FoodDashboardContent extends StatelessWidget {
  const _FoodDashboardContent({
    required this.dayId,
    required this.day,
    required this.targets,
    required this.recipes,
    required this.shoppingLists,
    required this.onOpenDiary,
    required this.onOpenRecipes,
    required this.onOpenShopping,
    required this.onAddWater,
    required this.onStartPhotoAi,
    required this.svc,
  });

  final String dayId;
  final DailyIntakeDoc day;
  final Map<String, double?> targets;
  final List<Recipe> recipes;
  final List<ShoppingList> shoppingLists;
  final VoidCallback onOpenDiary;
  final VoidCallback onOpenRecipes;
  final VoidCallback onOpenShopping;
  final ValueChanged<int> onAddWater;
  final VoidCallback onStartPhotoAi;
  final FoodFirestoreService svc;

  @override
  Widget build(BuildContext context) {
    final activeList =
        shoppingLists.isEmpty
            ? null
            : shoppingLists.firstWhere(
              (list) => list.isDefault,
              orElse: () => shoppingLists.first,
            );

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FoodAlerts(svc: svc),
            _CalorieHero(
              day: day,
              targetKcal: targets['kcal'],
              onOpenDiary: onOpenDiary,
            ),
            const SizedBox(height: 16),
            ResponsiveGrid(
              minItemWidth: 220,
              spacing: 16,
              children: [
                _MacroCard(
                  title: 'Proteína',
                  value: day.totals['protein'] ?? 0,
                  target: targets['protein'],
                  unit: 'g',
                  icon: Icons.fitness_center_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _MacroCard(
                  title: 'Carbohidratos',
                  value: day.totals['carbs'] ?? 0,
                  target: targets['carbs'],
                  unit: 'g',
                  icon: Icons.grain_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _MacroCard(
                  title: 'Grasas',
                  value: day.totals['fat'] ?? 0,
                  target: targets['fat'],
                  unit: 'g',
                  icon: Icons.water_drop_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final hydration = _HydrationCard(
                  waterMl: day.waterMl,
                  targetMl: targets['water'],
                  onAddWater: onAddWater,
                );
                final ai = _AiAnalysisCard(onStartPhotoAi: onStartPhotoAi);
                final diary = _DailyMealsCard(
                  entries: day.entries,
                  onOpenDiary: onOpenDiary,
                );

                if (!wide) {
                  return Column(
                    children: [
                      hydration,
                      const SizedBox(height: 16),
                      ai,
                      const SizedBox(height: 16),
                      diary,
                    ],
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: hydration),
                      const SizedBox(width: 16),
                      Expanded(child: ai),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: diary),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 940;
                final recipeCard = _RecentRecipesCard(
                  recipes: recipes,
                  svc: svc,
                  onOpenRecipes: onOpenRecipes,
                );
                final shoppingCard = _ShoppingPreviewCard(
                  list: activeList,
                  onOpenShopping: onOpenShopping,
                  onToggleItem: (index, checked) {
                    if (activeList == null) return;
                    svc.toggleCheckedByIndex(activeList.id, index, checked);
                  },
                );

                if (!wide) {
                  return Column(
                    children: [
                      recipeCard,
                      const SizedBox(height: 16),
                      shoppingCard,
                    ],
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: recipeCard),
                      const SizedBox(width: 16),
                      Expanded(child: shoppingCard),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodAlerts extends StatelessWidget {
  const _FoodAlerts({required this.svc});

  final FoodFirestoreService svc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: svc.streamAlerts(),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? const {};
        final proteinLow = alerts['foodProteinLowAfterWorkout'] == true;
        final extremeDeficit = alerts['foodExtremeDeficitWorkout'] == true;
        if (!proteinLow && !extremeDeficit) return const SizedBox.shrink();

        final cards = <Widget>[];
        if (proteinLow) {
          final target =
              (alerts['targetProteinToday'] as num?)?.toDouble() ?? 0;
          final current = (alerts['proteinToday'] as num?)?.toDouble() ?? 0;
          final gap = (target - current).clamp(0, 9999);
          cards.add(
            _InlineAlert(
              icon: Icons.warning_amber_rounded,
              title: 'Proteína baja tras entreno',
              message:
                  'Faltan ${gap.toStringAsFixed(0)} g para el objetivo de hoy.',
            ),
          );
        }
        if (extremeDeficit) {
          final deficit = (alerts['kcalDeltaToday'] as num?)?.toDouble() ?? 0;
          cards.add(
            _InlineAlert(
              icon: Icons.local_fire_department_rounded,
              title: 'Déficit extremo con entreno fuerte',
              message:
                  'Balance energético actual ${deficit.toStringAsFixed(0)} kcal.',
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(children: cards),
        );
      },
    );
  }
}

class _CalorieHero extends StatelessWidget {
  const _CalorieHero({
    required this.day,
    required this.targetKcal,
    required this.onOpenDiary,
  });

  final DailyIntakeDoc day;
  final double? targetKcal;
  final VoidCallback onOpenDiary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kcal = day.totals['kcal'] ?? 0;
    final progress =
        targetKcal == null || targetKcal == 0
            ? 0.0
            : (kcal / targetKcal!).clamp(0.0, 1.0);

    return FocusCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FocusBadge(
                label: DateFormat('d MMM', 'es_ES').format(DateTime.now()),
                color: scheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Calorías de hoy',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                targetKcal == null
                    ? 'Configura un objetivo diario para medir tu progreso.'
                    : '${kcal.toStringAsFixed(0)} de ${targetKcal!.toStringAsFixed(0)} kcal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${day.entries.length} entradas registradas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              FocusPrimaryButton(
                label: 'Abrir diario',
                icon: Icons.restaurant_menu_rounded,
                fullWidth: compact,
                onPressed: onOpenDiary,
              ),
            ],
          );
          final ring = FocusProgressRing(
            value: progress,
            size: compact ? 148 : 180,
            strokeWidth: 13,
            label: kcal.toStringAsFixed(0),
            subtitle: 'kcal',
            color: scheme.primary,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 18), Center(child: ring)],
            );
          }

          return Row(
            children: [Expanded(child: copy), const SizedBox(width: 24), ring],
          );
        },
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.title,
    required this.value,
    required this.target,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String title;
  final double value;
  final double? target;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress =
        target == null || target == 0 ? 0.0 : (value / target!).clamp(0.0, 1.0);
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${value.toStringAsFixed(0)} $unit',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            target == null
                ? 'Sin objetivo'
                : 'Objetivo ${target!.toStringAsFixed(0)} $unit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FocusProgressBar(value: progress, color: color, height: 7),
        ],
      ),
    );
  }
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard({
    required this.waterMl,
    required this.targetMl,
    required this.onAddWater,
  });

  final int waterMl;
  final double? targetMl;
  final ValueChanged<int> onAddWater;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress =
        targetMl == null || targetMl == 0
            ? 0.0
            : (waterMl / targetMl!).clamp(0.0, 1.0);

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FocusSectionHeader(
            title: 'Hidratación',
            subtitle: 'Agua registrada hoy',
            icon: Icons.water_drop_rounded,
          ),
          const SizedBox(height: 16),
          Center(
            child: FocusProgressRing(
              value: progress,
              size: 128,
              strokeWidth: 10,
              label: '${(waterMl / 1000).toStringAsFixed(1)} L',
              subtitle: targetMl == null ? 'sin objetivo' : 'agua',
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FocusSecondaryButton(
                label: '+250 ml',
                icon: Icons.add_rounded,
                onPressed: () => onAddWater(250),
              ),
              FocusSecondaryButton(
                label: '+500 ml',
                icon: Icons.add_rounded,
                onPressed: () => onAddWater(500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiAnalysisCard extends StatelessWidget {
  const _AiAnalysisCard({required this.onStartPhotoAi});

  final VoidCallback onStartPhotoAi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Análisis con IA',
            subtitle: 'Estima calorías y macros desde una foto',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  color: scheme.primary,
                  size: 34,
                ),
                const SizedBox(height: 10),
                Text(
                  'Analiza un plato y confirma la entrada antes de guardarla.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FocusPrimaryButton(
            label: 'Analizar imagen',
            icon: Icons.add_a_photo_outlined,
            fullWidth: true,
            onPressed: onStartPhotoAi,
          ),
        ],
      ),
    );
  }
}

class _DailyMealsCard extends StatelessWidget {
  const _DailyMealsCard({required this.entries, required this.onOpenDiary});

  final List<IntakeEntry> entries;
  final VoidCallback onOpenDiary;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByMeal(entries);
    final sections = [
      (MealSlot.breakfast, 'Desayuno', Icons.wb_sunny_rounded),
      (MealSlot.lunch, 'Comida', Icons.lunch_dining_rounded),
      (MealSlot.dinner, 'Cena', Icons.dinner_dining_rounded),
      (MealSlot.snack, 'Aperitivos', Icons.cookie_rounded),
      (MealSlot.merienda, 'Merienda', Icons.local_cafe_rounded),
    ];

    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Registro diario',
            subtitle: 'Comidas de hoy',
            icon: Icons.restaurant_menu_rounded,
            trailing: TextButton(
              onPressed: onOpenDiary,
              child: const Text('Abrir'),
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            FocusEmptyState(
              icon: Icons.restaurant_outlined,
              message: 'Sin comidas registradas',
              subtitle: 'Abre el diario para registrar la primera comida.',
              actionLabel: 'Registrar comida',
              onAction: onOpenDiary,
            )
          else
            Column(
              children: [
                for (final section in sections)
                  _MealPreviewRow(
                    label: section.$2,
                    icon: section.$3,
                    entries: grouped[section.$1] ?? const [],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Map<MealSlot, List<IntakeEntry>> _groupByMeal(List<IntakeEntry> entries) {
    final grouped = <MealSlot, List<IntakeEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.meal, () => []).add(entry);
    }
    return grouped;
  }
}

class _MealPreviewRow extends StatelessWidget {
  const _MealPreviewRow({
    required this.label,
    required this.icon,
    required this.entries,
  });

  final String label;
  final IconData icon;
  final List<IntakeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kcal = entries.fold<double>(
      0,
      (sum, entry) => sum + (entry.macrosSnapshot['kcal'] ?? 0),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            entries.isEmpty
                ? 'Sin entradas'
                : '${entries.length} - ${kcal.toStringAsFixed(0)} kcal',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRecipesCard extends StatelessWidget {
  const _RecentRecipesCard({
    required this.recipes,
    required this.svc,
    required this.onOpenRecipes,
  });

  final List<Recipe> recipes;
  final FoodFirestoreService svc;
  final VoidCallback onOpenRecipes;

  @override
  Widget build(BuildContext context) {
    final recent = recipes.take(5).toList(growable: false);
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Recetas recientes',
            subtitle: 'Biblioteca nutricional',
            icon: Icons.menu_book_rounded,
            trailing: TextButton(
              onPressed: onOpenRecipes,
              child: const Text('Ver todas'),
            ),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            FocusEmptyState(
              icon: Icons.menu_book_outlined,
              message: 'Sin recetas guardadas',
              subtitle: 'Crea recetas para reutilizarlas en el diario.',
              actionLabel: 'Abrir recetas',
              onAction: onOpenRecipes,
            )
          else
            Column(
              children: [
                for (final recipe in recent)
                  _RecipePreviewTile(recipe: recipe, svc: svc),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecipePreviewTile extends StatelessWidget {
  const _RecipePreviewTile({required this.recipe, required this.svc});

  final Recipe recipe;
  final FoodFirestoreService svc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kcal = recipe.kcal;
    final protein = recipe.protein;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: recipe, svc: svc),
              ),
            ),
        child: Row(
          children: [
            Icon(Icons.restaurant_rounded, color: scheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${recipe.servings} raciones',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (kcal != null)
              FocusBadge(
                label:
                    protein == null
                        ? '${kcal.toStringAsFixed(0)} kcal'
                        : '${kcal.toStringAsFixed(0)} kcal - ${protein.toStringAsFixed(0)} g P',
                color: scheme.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingPreviewCard extends StatelessWidget {
  const _ShoppingPreviewCard({
    required this.list,
    required this.onOpenShopping,
    required this.onToggleItem,
  });

  final ShoppingList? list;
  final VoidCallback onOpenShopping;
  final void Function(int index, bool checked) onToggleItem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = list?.items ?? const <ShoppingListItem>[];
    final pending = items.where((item) => !item.checked).toList();
    return FocusCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionHeader(
            title: 'Lista de compra',
            subtitle: list?.name ?? 'Sin lista activa',
            icon: Icons.shopping_cart_rounded,
            trailing: TextButton(
              onPressed: onOpenShopping,
              child: const Text('Abrir'),
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            FocusEmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'Sin productos pendientes',
              subtitle: 'Abre las listas para preparar tu compra.',
              actionLabel: 'Abrir listas',
              onAction: onOpenShopping,
            )
          else
            Column(
              children: [
                for (final item in pending.take(6))
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.checked,
                          onChanged: (value) {
                            if (value == null) return;
                            onToggleItem(items.indexOf(item), value);
                          },
                        ),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1)} ${item.unit.name}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                if (pending.length > 6)
                  Text(
                    '+ ${pending.length - 6} productos más',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoAiAnalyzingDialog extends StatelessWidget {
  const _PhotoAiAnalyzingDialog({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analizando con IA',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Estimando calorías y macros de la imagen.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [TextButton(onPressed: onCancel, child: const Text('Cancelar'))],
    );
  }
}

class _PhotoAiPreviewSheet extends StatelessWidget {
  const _PhotoAiPreviewSheet({
    required this.result,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.saving,
    required this.onCancel,
    required this.onConfirm,
  });

  final CaloriesAiResult result;
  final double protein;
  final double carbs;
  final double fat;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Añadir por foto',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              FocusCard(
                child: Row(
                  children: [
                    FocusProgressRing(
                      value: result.confidence.clamp(0.0, 1.0),
                      size: 118,
                      strokeWidth: 10,
                      label: result.calories.toStringAsFixed(0),
                      subtitle: 'kcal',
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimación detectada',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Modelo ${result.model} - confianza ${(result.confidence * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FocusBadge(
                                label:
                                    'Proteína ${protein.toStringAsFixed(0)} g',
                                color: scheme.primary,
                              ),
                              FocusBadge(
                                label:
                                    'Carbohidratos ${carbs.toStringAsFixed(0)} g',
                                color: scheme.secondary,
                              ),
                              FocusBadge(
                                label: 'Grasas ${fat.toStringAsFixed(0)} g',
                                color: scheme.tertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (result.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                FocusCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FocusSectionHeader(
                        title: 'Items estimados',
                        subtitle: 'Revisa antes de guardar',
                        icon: Icons.restaurant_menu_rounded,
                      ),
                      const SizedBox(height: 12),
                      for (final item in result.items)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      item.portion,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.calories.toStringAsFixed(0)} kcal',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FocusSecondaryButton(
                      label: 'Cancelar',
                      fullWidth: true,
                      onPressed: saving ? null : onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FocusPrimaryButton(
                      label: saving ? 'Guardando' : 'Confirmar',
                      icon: Icons.check_rounded,
                      fullWidth: true,
                      isLoading: saving,
                      onPressed: saving ? null : onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
