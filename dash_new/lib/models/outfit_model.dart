import 'package:cloud_firestore/cloud_firestore.dart';

class Outfit {
  final String id;
  final String nombre;
  final String notas;
  final bool favorito;
  final Map<String, String?> slots; // {top: prendaId, bottom: prendaId, shoes: prendaId...}
  final Map<String, String>? portada; // {thumbUrl, mediumUrl}
  final int vecesUsado;
  final DateTime? ultimaVezUsado;

  Outfit({
    required this.id,
    required this.nombre,
    required this.notas,
    required this.favorito,
    required this.slots,
    this.portada,
    required this.vecesUsado,
    this.ultimaVezUsado,
  });

  factory Outfit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Outfit(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      notas: data['notas'] ?? '',
      favorito: data['favorito'] ?? false,
      // valores null permitidos
      slots: Map<String, String?>.from(data['slots'] ?? {}),
      portada: data['portada'] != null ? Map<String, String>.from(data['portada']) : null,
      vecesUsado: (data['vecesUsado'] as num?)?.toInt() ?? 0,
      ultimaVezUsado: data['ultimaVezUsado'] != null
          ? (data['ultimaVezUsado'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'notas': notas,
      'favorito': favorito,
      'slots': slots,
      'portada': portada,
      'vecesUsado': vecesUsado,
      // 🔒 Timestamp explícito
      if (ultimaVezUsado != null)
        'ultimaVezUsado': Timestamp.fromDate(ultimaVezUsado!),
    };
  }
}
