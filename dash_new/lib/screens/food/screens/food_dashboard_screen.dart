import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focuslane/navigation/app_route_observer.dart';
import 'package:focuslane/screens/food/models/food_models.dart';
import 'package:focuslane/screens/food/services/food_firestore_service.dart';
import 'package:focuslane/screens/food/services/food_photo_ai_service.dart';
import 'food_dashboard_widgets.dart';
import 'package:focuslane/design/ui/shared/app_card.dart';
import 'food_diary_screen.dart';
import 'recipes_list_screen.dart';
import 'recipe_detail_screen.dart';
import 'shopping_lists_screen.dart';
import 'package:focuslane/screens/food/widgets/food_compact_widgets.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';
import 'package:focuslane/design/ui/components/focus_module_header.dart';
import 'package:focuslane/design/ui/components/responsive_kpi_grid.dart';

class FoodDashboardScreen extends StatefulWidget {
  final FoodFirestoreService svc;
  
  const FoodDashboardScreen({super.key, required this.svc});

  @override
  State<FoodDashboardScreen> createState() => _FoodDashboardScreenState();
}

class _FoodDashboardScreenState extends State<FoodDashboardScreen>
    with RouteAware {
  String _dayId(DateTime d) => d.toIso8601String().substring(0, 10);
  final FoodPhotoAiService _photoAiService = FoodPhotoAiService();
  
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: FoodCompactAppBar(
        title: 'Nutrición',
        subtitle: 'Planificación, recetas y seguimiento',
        leadingMode: FocusModuleLeadingMode.exitModule,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            tooltip: 'Añadir por foto',
            onPressed: _startPhotoAiFlow,
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Nueva receta',
            onPressed: () => _navigateToRecipes(context),
          ),
        ],
      ),
      body: ListView(
        padding: isDesktop
            ? const EdgeInsets.all(40)
            : FocuslaneUI.pagePaddingCompact,
        children: [
          _buildMetricsSection(context, todayId, isDesktop),
          const SizedBox(height: 10.0),
          isDesktop || isTablet
              ? _buildBottomSectionDesktop(context)
              : _buildBottomSectionMobile(context),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(
    BuildContext context,
    String todayId,
    bool isDesktop,
  ) {
    return StreamBuilder<Map<String, double?>>(
      stream: widget.svc.streamGlobalTargets(),
      builder: (context, targetsSnap) {
        debugPrint('[FoodDashboard][targets] snapshot state=${targetsSnap.connectionState} data=${targetsSnap.data}');
        final targetKcal = targetsSnap.data?['kcal'] ?? 2000;
        final targetProtein = targetsSnap.data?['protein'] ?? 150;
        debugPrint('[FoodDashboard][targets] targetKcal=$targetKcal targetProtein=$targetProtein');
        return StreamBuilder<DailyIntakeDoc>(
          stream: widget.svc.streamDay(todayId),
          builder: (context, daySnap) {
            debugPrint('[FoodDashboard][dayIntake] snapshot state=${daySnap.connectionState} dayId=$todayId hasData=${daySnap.hasData}');
            final day = daySnap.data ??
                DailyIntakeDoc(
                  id: todayId,
                  entries: const [],
                  waterMl: 0,
                  totals: const {
                    'kcal': 0.0,
                    'protein': 0.0,
                    'carbs': 0.0,
                    'fat': 0.0,
                  },
                  targets: const {},
                );

            final kcal = day.totals['kcal'] ?? 0.0;
            final protein = day.totals['protein'] ?? 0.0;
            debugPrint('[FoodDashboard][dayIntake] totals: kcal=$kcal protein=$protein carbs=${day.totals['carbs']} fat=${day.totals['fat']} waterMl=${day.waterMl} entries=${day.entries.length}');

            final alerts = _buildAlerts(context);

            return StreamBuilder<List<Recipe>>(
              stream: widget.svc.streamRecipes(),
              builder: (context, recipesSnap) {
                final recipesCount = recipesSnap.data?.length ?? 0;

                return StreamBuilder<List<ShoppingList>>(
                  stream: widget.svc.streamShoppingLists(),
                  builder: (context, shoppingSnap) {
                    final shoppingItems =
                        shoppingSnap.data?.expand((list) => list.items).length ?? 0;

                    return Column(
                      children: [
                        alerts,
                        ResponsiveKpiGrid(
                          children: [
                            FoodMetricCard(
                              icon: Icons.local_fire_department,
                              label: 'Calorías hoy',
                              value: '${kcal.toStringAsFixed(0)} kcal',
                              subtitle: 'de ${targetKcal.toStringAsFixed(0)} objetivo',
                              onTap: () => _navigateToDiary(context),
                            ),
                            FoodMetricCard(
                              icon: Icons.fitness_center,
                              label: 'Proteína hoy',
                              value: '${protein.toStringAsFixed(0)} g',
                              subtitle: 'de ${targetProtein.toStringAsFixed(0)}g objetivo',
                              onTap: () => _navigateToDiary(context),
                            ),
                            FoodMetricCard(
                              icon: Icons.restaurant_menu,
                              label: 'Recetas guardadas',
                              value: '$recipesCount',
                              subtitle: 'en tu biblioteca',
                              onTap: () => _navigateToRecipes(context),
                            ),
                            FoodMetricCard(
                              icon: Icons.shopping_cart,
                              label: 'Lista de compra',
                              value: '$shoppingItems productos',
                              subtitle: 'pendientes',
                              onTap: () => _navigateToShopping(context),
                            ),
                          ],
                          childAspectRatio: 1.9,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlerts(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.svc.streamAlerts(),
      builder: (context, alertSnap) {
        debugPrint('[FoodDashboard][alerts] snapshot state=${alertSnap.connectionState} data=${alertSnap.data}');
        final alerts = alertSnap.data ?? const {};
        final proteinLow = alerts['foodProteinLowAfterWorkout'] == true;
        final extremeDeficit = alerts['foodExtremeDeficitWorkout'] == true;
        debugPrint('[FoodDashboard][alerts] proteinLow=$proteinLow extremeDeficit=$extremeDeficit');
        if (!proteinLow && !extremeDeficit) {
          return const SizedBox.shrink();
        }

        final cards = <Widget>[];
        if (proteinLow) {
          final targetProtein = (alerts['targetProteinToday'] as num?)?.toDouble() ?? 0;
          final proteinToday = (alerts['proteinToday'] as num?)?.toDouble() ?? 0;
          final gap = (targetProtein - proteinToday).clamp(0, 9999);
          cards.add(
            _AlertCard(
              icon: Icons.warning_amber,
              title: 'Proteína baja tras entreno',
              message: 'Faltan ${gap.toStringAsFixed(0)} g para el objetivo de hoy.',
            ),
          );
        }
        if (extremeDeficit) {
          final deficit = (alerts['kcalDeltaToday'] as num?)?.toDouble() ?? 0;
          cards.add(
            _AlertCard(
              icon: Icons.local_fire_department,
              title: 'Déficit extremo con entreno fuerte',
              message: 'Balance energético actual ${deficit.toStringAsFixed(0)} kcal.',
            ),
          );
        }
        return Column(
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildBottomSectionDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildRecipesSection(context),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          flex: 1,
          child: _buildShoppingSection(context),
        ),
      ],
    );
  }

  Widget _buildBottomSectionMobile(BuildContext context) {
    return Column(
      children: [
        _buildRecipesSection(context),
        const SizedBox(height: 10.0),
        _buildShoppingSection(context),
      ],
    );
  }

  Widget _buildRecipesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return StreamBuilder<List<Recipe>>(
      stream: widget.svc.streamRecipes(),
      builder: (context, snapshot) {
        final recipes = snapshot.data ?? [];
        final recentRecipes = recipes.take(6).toList();

        return AppSurface(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FoodSectionHeader(
                title: 'Recetas recientes',
                subtitle: 'Favoritas y últimas',
                icon: Icons.restaurant,
                actionLabel: 'Ver todas',
                onActionPressed: () => _navigateToRecipes(context),
              ),
              const SizedBox(height: 6.0),
              if (recentRecipes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 28,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'No hay recetas guardadas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _navigateToRecipes(context),
                          child: const Text('Añadir primera receta'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentRecipes.map((recipe) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: FoodRecipeCard(
                      name: recipe.name,
                      tags: _getRecipeTags(recipe),
                      kcal: _calculateRecipeKcal(recipe) ?? 0,
                      protein: _calculateRecipeProtein(recipe) ?? 0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(
                            recipe: recipe,
                            svc: widget.svc,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShoppingSection(BuildContext context) {
    return StreamBuilder<List<ShoppingList>>(
      stream: widget.svc.streamShoppingLists(),
      builder: (context, snapshot) {
        final lists = snapshot.data ?? [];
        final activeLists = lists;
        ShoppingList? activeList;

        if (activeLists.isNotEmpty) {
          activeList =
              activeLists.firstWhere(
                (l) => l.isDefault,
                orElse: () => activeLists.first,
              );
        }

        return FoodShoppingListCard(
          listId: activeList?.id,
          items: activeList?.items ?? const [],
          onToggleItem: (index, checked) {
            if (activeList == null) return;
            widget.svc.toggleCheckedByIndex(activeList.id, index, checked);
          },
          onMarkAll: () {
            if (activeList == null) return;
            widget.svc.setAllChecked(activeList.id, true);
          },
          onClearCompleted: () {
            if (activeList == null) return;
            widget.svc.clearCompleted(activeList.id);
          },
          onNavigate: () => _navigateToShopping(context),
        );
      },
    );
  }

  List<String> _getRecipeTags(Recipe recipe) {
    final tags = <String>[];
    
    if (recipe.name.toLowerCase().contains('pollo') ||
        recipe.name.toLowerCase().contains('pavo')) {
      tags.add('Alto en proteína');
    }
    if (recipe.name.toLowerCase().contains('ensalada') ||
        recipe.name.toLowerCase().contains('vegetal')) {
      tags.add('Bajo en carbohidratos');
    }
    if (recipe.name.toLowerCase().contains('vegano') ||
        recipe.name.toLowerCase().contains('vegan')) {
      tags.add('Vegano');
    }
    
    if (tags.isEmpty) {
      tags.add('Casera');
    }
    
    return tags;
  }

  double? _calculateRecipeKcal(Recipe recipe) {
    return 450.0;
  }

  double? _calculateRecipeProtein(Recipe recipe) {
    return 32.0;
  }

  void _navigateToDiary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDiaryScreen(svc: widget.svc),
      ),
    );
  }

  void _navigateToRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipesListScreen(svc: widget.svc),
      ),
    );
  }

  void _navigateToShopping(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListsScreen(svc: widget.svc),
      ),
    );
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
        if (kDebugMode) {
          debugPrint('[FoodPhotoAI] analysis cancelled by user');
        }
      }

      analyzingShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PhotoAiAnalyzingDialog(onCancel: cancelAnalysis),
      );

      final result = await _photoAiService.estimateFromImage(file);

      if (analysisCanceled) {
        return;
      }

      if (analyzingShown && mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
        analyzingShown = false;
      }

      if (!mounted) return;
      final dayId = _dayId(DateTime.now());
      await _showPhotoAiPreview(dayId, result);
    } catch (error) {
      if (analyzingShown && mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }

      if (analysisCanceled) {
        return;
      }

      if (!mounted) return;
      final message = error is FoodPhotoAiException
          ? error.message
          : 'No se pudo analizar la foto. Revisa la conexión e inténtalo de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  Future<XFile?> _pickImageForPhotoAi() async {
    final picker = ImagePicker();
    try {
      if (kIsWeb) {
        return picker.pickImage(source: ImageSource.gallery);
      }

      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Cámara'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Galería'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return null;
      return picker.pickImage(source: source);
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el selector de imágenes.')),
      );
      return null;
    }
  }

  Future<void> _showPhotoAiPreview(
    String dayId,
    CaloriesAiResult result,
  ) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final kcal = result.calories;
            final macros = result.macros;

            Future<void> onConfirm() async {
              if (saving) return;
              setStateSheet(() => saving = true);
              try {
                await _savePhotoAiEntry(
                  dayId: dayId,
                  result: result,
                );
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Entrada añadida por foto.')),
                );
              } catch (_) {
                if (sheetContext.mounted) {
                  setStateSheet(() => saving = false);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se pudo guardar la entrada. Inténtalo de nuevo.',
                      ),
                    ),
                  );
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Añadir por foto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${kcal.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Modelo ${result.model} · confianza ${(result.confidence * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('P ${macros.protein.toStringAsFixed(0)} g')),
                          Chip(label: Text('C ${macros.carbs.toStringAsFixed(0)} g')),
                          Chip(label: Text('G ${macros.fat.toStringAsFixed(0)} g')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Macros · P ${macros.protein.toStringAsFixed(0)} g · C ${macros.carbs.toStringAsFixed(0)} g · G ${macros.fat.toStringAsFixed(0)} g',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (result.items.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Items estimados',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...result.items.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(item.name),
                            subtitle: Text(item.portion),
                            trailing: Text('${item.calories.toStringAsFixed(0)} kcal'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: saving ? null : onConfirm,
                              child: Text(saving ? 'Guardando…' : 'Confirmar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
      qty: 1.0,
      unit: UnitKind.unit,
      nameSnapshot: result.items.isNotEmpty
          ? result.items.first.name
          : 'Comida estimada por foto',
      macrosSnapshot: {
        'kcal': result.calories,
        'protein': result.macros.protein,
        'carbs': result.macros.carbs,
        'fat': result.macros.fat,
        'fiber': 0.0,
        'sodium': 0.0,
      },
      meal: MealSlot.lunch,
      aiMeta: {
        'source': 'openai',
        'model': result.model,
        'confidence': result.confidence,
        'classifiedAt': nowIso,
        'mimeType': result.mimeType,
        'bytesLength': result.bytesLength,
        'items': result.items
            .map((item) => {
                  'name': item.name,
                  'portion': item.portion,
                  'calories': item.calories,
                })
            .toList(),
        if (result.inputHash != null && result.inputHash!.trim().isNotEmpty)
          'inputHash': result.inputHash,
      },
    );

    await widget.svc.addPhotoAiEntry(dayId: dayId, entry: entry);
    if (kDebugMode) {
      debugPrint('[FoodPhotoAI] saved entry dayId=$dayId');
    }
  }
}

class _PhotoAiAnalyzingDialog extends StatelessWidget {
  const _PhotoAiAnalyzingDialog({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Analizando…')),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer.withValues(alpha: .2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




