import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoPrenda { lavada, usada, sucia, lavandose }

class Prenda {
  final String id;
  final String nombre;
  final String categoriaId;
  final String descripcion;
  final EstadoPrenda estado;
  final List<String> colores;
  final List<String> temporadas;
  final List<String> ocasiones;
  final String? marca;
  final double? precio;
  final Map<String, String> imagenes;    final int vecesUsada;
  final DateTime? ultimaVezUsada;
  final bool archivada;
  final bool favorita;
  final List<String> etiquetas;

  Prenda({
    required this.id,
    required this.nombre,
    required this.categoriaId,
    required this.descripcion,
    required this.estado,
    required this.colores,
    required this.temporadas,
    required this.ocasiones,
    this.marca,
    this.precio,
    required this.imagenes,
    required this.vecesUsada,
    this.ultimaVezUsada,
    required this.archivada,
    required this.favorita,
    required this.etiquetas,
  });

  factory Prenda.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prenda(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      categoriaId: data['categoriaId'] ?? '',
      descripcion: data['descripcion'] ?? '',
      estado: EstadoPrenda.values.firstWhere(
        (e) => e.toString() == 'EstadoPrenda.${data['estado']}',
        orElse: () => EstadoPrenda.lavada,
      ),
      colores: List<String>.from(data['colores'] ?? []),
      temporadas: List<String>.from(data['temporadas'] ?? []),
      ocasiones: List<String>.from(data['ocasiones'] ?? []),
      marca: data['marca'],
      precio:
          (data['precio'] != null) ? (data['precio'] as num).toDouble() : null,
      imagenes: Map<String, String>.from(data['imagenes'] ?? {}),
      vecesUsada: (data['vecesUsada'] as num?)?.toInt() ?? 0,
      ultimaVezUsada:
          (data['ultimaVezUsada'] is Timestamp)
              ? (data['ultimaVezUsada'] as Timestamp).toDate()
              : null,
      archivada: data['archivada'] == true,
      favorita: data['favorita'] == true,
      etiquetas: List<String>.from(data['etiquetas'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'categoriaId': categoriaId,
      'descripcion': descripcion,
      'estado': estado.name,
      'colores': colores,
      'temporadas': temporadas,
      'ocasiones': ocasiones,
      'marca': marca,
      'precio': precio,
      'imagenes': imagenes,
      'vecesUsada': vecesUsada,
      'ultimaVezUsada':
          ultimaVezUsada != null ? Timestamp.fromDate(ultimaVezUsada!) : null,
      'archivada': archivada,
      'favorita': favorita,
      'etiquetas': etiquetas,
    };
  }
}
