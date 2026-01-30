import 'package:flutter/material.dart';
import '../services/food_firestore_service.dart';

class FoodSettingsScreen extends StatefulWidget {
  final FoodFirestoreService svc;

  const FoodSettingsScreen({super.key, required this.svc});

  @override
  State<FoodSettingsScreen> createState() => _FoodSettingsScreenState();
}

class _FoodSettingsScreenState extends State<FoodSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Objetivos Nutricionales'),
              subtitle: const Text('Configura tus metas diarias'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Preferencias'),
              subtitle: const Text('Unidades y formato'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Exportar Datos'),
              subtitle: const Text('Descarga tus datos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
