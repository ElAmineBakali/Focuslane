import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/prenda_firestore_service.dart';
import '../../models/prenda_model.dart';
import '../../models/outfit_model.dart';

class OutfitDetailScreen extends StatelessWidget {
  final Outfit outfit;
  const OutfitDetailScreen({super.key, required this.outfit});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final svc = PrendaFirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(outfit.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Prenda>>(
          stream: svc.prendasStream(uid),
          builder: (_, s) {
            final prendas = s.data ?? const <Prenda>[];
            final byId = {for (final p in prendas) p.id: p};

            Widget tile(String slot, String label) {
              final id = outfit.slots[slot];
              final p = (id != null) ? byId[id] : null;
              final url = p?.imagenes['thumb'] ??
                  p?.imagenes['medium'] ??
                  p?.imagenes['full'];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (url == null || url.isEmpty)
                      ? const SizedBox(
                          width: 48, height: 48,
                          child: ColoredBox(color: Color(0x11000000)),
                        )
                      : Image.network(url, width: 48, height: 48, fit: BoxFit.cover),
                ),
                title: Text(label),
                subtitle: Text(p?.nombre ?? '—'),
              );
            }

            return ListView(
              children: [
                if (outfit.notas.isNotEmpty) ...[
                  Text("Notas: ${outfit.notas}"),
                  const SizedBox(height: 8),
                ],
                tile('head', 'Cabeza'),
                tile('top', 'Parte superior'),
                tile('outer', 'Capa exterior'),
                tile('bottom', 'Parte inferior'),
                tile('shoes', 'Calzado'),
                tile('accessories', 'Accesorios'),
                const Divider(),
                Text("Veces usado: ${outfit.vecesUsado}"),
                Text("Última vez: ${outfit.ultimaVezUsado ?? 'Nunca'}"),
              ],
            );
          },
        ),
      ),
    );
  }
}
