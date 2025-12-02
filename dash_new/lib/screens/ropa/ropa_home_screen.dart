import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/prenda_firestore_service.dart';
import '../../models/prenda_model.dart';
import 'prenda_form_screen.dart';
import '../../widgets/prenda_card.dart';
import 'package:mi_dashboard_personal/utils/app_links.dart';

class RopaHomeScreen extends StatelessWidget {
  const RopaHomeScreen({super.key});

  void _accionesPrenda(
    BuildContext context,
    Prenda p,
    PrendaFirestoreService svc,
    String uid,
  ) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Ver / Editar'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrendaFormScreen(initial: p),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Eliminar'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Eliminar prenda'),
                            content: Text('¿Eliminar "${p.nombre}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                    );
                    if (ok == true) {
                      await svc.deletePrenda(uid, p.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prenda eliminada')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final prendaService = PrendaFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Ropa"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.link_rounded),
            onSelected: (v) {
              if (v == 'Zalando') AppLinks.openZalando();
              if (v == 'Shein') AppLinks.openShein();
              if (v == 'Amazon') AppLinks.openAmazon();
              if (v == 'AliExpress') AppLinks.openAliExpress();
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'Zalando', child: Text('Zalando')),
                  PopupMenuItem(value: 'Shein', child: Text('Shein')),
                  PopupMenuItem(value: 'Amazon', child: Text('Amazon')),
                  PopupMenuItem(value: 'AliExpress', child: Text('AliExpress')),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: "Planificador",
            onPressed: () => Navigator.pushNamed(context, "/planificadorRopa"),
          ),
          IconButton(
            icon: const Icon(Icons.style),
            tooltip: "Outfits",
            onPressed: () => Navigator.pushNamed(context, "/outfits"),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, "/prendaForm"),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Prenda>>(
        stream: prendaService.prendasStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final prendas = snapshot.data!;
          if (prendas.isEmpty) {
            return const Center(child: Text("Aún no tienes prendas añadidas"));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 240,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: prendas.length,
            itemBuilder: (context, index) {
              final prenda = prendas[index];
              return InkWell(
                onTap:
                    () => _accionesPrenda(context, prenda, prendaService, uid),
                onLongPress:
                    () => _accionesPrenda(context, prenda, prendaService, uid),
                child: PrendaCard(prenda: prenda),
              );
            },
          );
        },
      ),
    );
  }
}
