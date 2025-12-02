import 'package:flutter/material.dart';
import '../models/food_models.dart';
import '../services/food_firestore_service.dart';
import 'recipe_edit_screen.dart';

class RecipesListScreen extends StatelessWidget {
  final FoodFirestoreService svc;
  const RecipesListScreen({super.key, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [
          IconButton(
            tooltip: 'Nueva receta',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RecipeEditScreen(svc: svc)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Recipe>>(
        stream: svc.streamRecipes(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('Crea tu primera receta'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (_, i) {
              final r = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(r.name),
                  subtitle: Text(
                    'Raciones: ${r.servings}${r.kcal != null ? ' • ${r.kcal!.toStringAsFixed(0)} kcal totales' : ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RecipeEditScreen(svc: svc, initial: r)),
                        );
                      }
                      if (v == 'dup') {
                        await svc.createRecipe(Recipe(
                          id: '',
                          name: '${r.name} (copia)',
                          description: r.description,
                          tags: r.tags,
                          servings: r.servings,
                          ingredients: r.ingredients,
                          steps: r.steps,
                          kcal: r.kcal,
                          protein: r.protein,
                          carbs: r.carbs,
                          fat: r.fat,
                          fiber: r.fiber,
                          sodium: r.sodium,
                        ));
                      }
                      if (v == 'del') {
                        final ok = await _confirm(
                          context,
                          'Eliminar receta',
                          '¿Eliminar "${r.name}"?',
                        );
                        if (ok) await svc.deleteRecipe(r.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'dup', child: Text('Duplicar')),
                      PopupMenuItem(value: 'del', child: Text('Eliminar')),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: list.length,
          );
        },
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    return ok == true;
  }
}
