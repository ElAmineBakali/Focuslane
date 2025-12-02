import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/outfit_firestore_service.dart';
import '../../models/outfit_model.dart';

class OutfitListScreen extends StatelessWidget {
  const OutfitListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = OutfitFirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Mis Outfits")),
      body: StreamBuilder<List<Outfit>>(
        stream: service.outfitsStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final outfits = snapshot.data!;
          if (outfits.isEmpty) {
            return const Center(child: Text("No tienes outfits aún"));
          }
          return ListView.separated(
            itemCount: outfits.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final o = outfits[i];
              return ListTile(
                leading: const Icon(Icons.style),
                title: Text(o.nombre),
                subtitle: Text(o.notas.isEmpty ? '—' : o.notas),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      "/outfitDetalle",
                      arguments: o,
                    ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, "/outfitBuilder"),
        child: const Icon(Icons.add),
      ),
    );
  }
}
