import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoPlan { planificado, usado, saltado }

class PlanOutfit {
  final String id;
  final DateTime fecha;
  final String? parteDelDia; // mañana, tarde, noche (opcional)
  final String outfitId;
  final EstadoPlan estado;
  final String nota;

  PlanOutfit({
    required this.id,
    required this.fecha,
    this.parteDelDia,
    required this.outfitId,
    required this.estado,
    required this.nota,
  });

  factory PlanOutfit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlanOutfit(
      id: doc.id,
      fecha: (data['fecha'] as Timestamp).toDate(),
      parteDelDia: data['parteDelDia'],
      outfitId: data['outfitId'] ?? '',
      estado: EstadoPlan.values.firstWhere(
        (e) => e.toString() == 'EstadoPlan.${data['estado']}',
        orElse: () => EstadoPlan.planificado,
      ),
      nota: data['nota'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // 🔒 guarda como Timestamp siempre (robusto en móvil)
      'fecha': Timestamp.fromDate(fecha),
      'parteDelDia': parteDelDia,
      'outfitId': outfitId,
      'estado': estado.name,
      'nota': nota,
    };
  }
}
