import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/prenda_firestore_service.dart';
import '../../services/outfit_firestore_service.dart';
import '../../models/prenda_model.dart';
import '../../models/outfit_model.dart';

class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  final _nombreCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  final Map<String, String?> _slotsSeleccionados = {
    'head': null,
    'top': null,
    'outer': null,
    'bottom': null,
    'shoes': null,
    'accessories': null,
  };

  final _categorias = {
    'head': "Cabeza",
    'top': "Parte superior",
    'outer': "Capa exterior",
    'bottom': "Parte inferior",
    'shoes': "Calzado",
    'accessories': "Accesorios",
  };

  Widget _miniPrenda(Prenda p, bool seleccionada) {
    final url =
        p.imagenes['thumb'] ?? p.imagenes['medium'] ?? p.imagenes['full'];
    return Container(
      width: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color:
              seleccionada
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child:
            (url == null || url.isEmpty)
                ? Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.photo_outlined),
                )
                : Image.network(url, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final prendaService = PrendaFirestoreService();
    final outfitService = OutfitFirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Outfit")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: "Nombre del outfit"),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _notasCtrl,
            decoration: const InputDecoration(labelText: "Notas"),
          ),
          const SizedBox(height: 20),

          // Una única suscripción al stream y luego filtro por categoría
          StreamBuilder<List<Prenda>>(
            stream: prendaService.prendasStream(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final todas = snapshot.data ?? const <Prenda>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    _categorias.entries.map((entry) {
                      final cat = entry.key;
                      final prendas =
                          todas
                              .where(
                                (p) =>
                                    p.categoriaId == cat &&
                                    p.estado != EstadoPrenda.sucia,
                              )
                              .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 140,
                            child:
                                prendas.isEmpty
                                    ? const Center(
                                      child: Text("No hay prendas disponibles"),
                                    )
                                    : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: prendas.length,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(width: 10),
                                      itemBuilder: (context, i) {
                                        final prenda = prendas[i];
                                        final seleccionada =
                                            _slotsSeleccionados[cat] ==
                                            prenda.id;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _slotsSeleccionados[cat] =
                                                  prenda.id;
                                            });
                                          },
                                          child: _miniPrenda(
                                            prenda,
                                            seleccionada,
                                          ),
                                        );
                                      },
                                    ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
              );
            },
          ),

          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Guardar Outfit"),
            onPressed: () async {
              final slotsClean = <String, String>{};
              _slotsSeleccionados.forEach((k, v) {
                if (v != null && v.isNotEmpty) slotsClean[k] = v;
              });

              if (slotsClean.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecciona al menos una prenda'),
                  ),
                );
                return;
              }

              final outfit = Outfit(
                id: "",
                nombre:
                    _nombreCtrl.text.trim().isEmpty
                        ? 'Outfit'
                        : _nombreCtrl.text.trim(),
                notas: _notasCtrl.text.trim(),
                favorito: false,
                slots: slotsClean,
                portada: null,
                vecesUsado: 0,
                ultimaVezUsado: null,
              );
              await outfitService.addOutfit(uid, outfit);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
