import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/prenda_model.dart';

class PrendaFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _storage = Supabase.instance.client.storage;
  static const String _bucketName = 'notes-media';

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('wardrobe_items');

  Stream<List<Prenda>> prendasStream(String uid) => _col(uid)
      .orderBy('nombre', descending: false)
      .snapshots()
      .map((s) => s.docs.map(Prenda.fromFirestore).toList());

  Future<Prenda?> getPrenda(String uid, String id) async {
    final doc = await _col(uid).doc(id).get();
    if (!doc.exists) return null;
    return Prenda.fromFirestore(doc);
  }

  Stream<Prenda?> prendaStream(String uid, String id) => _col(
    uid,
  ).doc(id).snapshots().map((d) => d.exists ? Prenda.fromFirestore(d) : null);

  Future<void> addPrenda(String uid, Prenda prenda) async {
    await _col(uid).doc(prenda.id).set(prenda.toFirestore());
  }

  Future<void> updatePrenda(String uid, Prenda prenda) async {
    await _col(uid).doc(prenda.id).update(prenda.toFirestore());
  }

  Future<void> deletePrenda(String uid, String prendaId) async {
    await _col(uid).doc(prendaId).delete();
  }

  Future<Map<String, String>> uploadImagenPrenda({
    required String uid,
    required String prendaId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$uid/wardrobe/$prendaId/$ts.jpg';
    await _storage
        .from(_bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    final url = _storage.from(_bucketName).getPublicUrl(path);
    return {'thumb': url, 'medium': url, 'full': url};
  }

  Stream<List<Prenda>> prendasByCategoria(String uid, String categoriaId) =>
      _col(uid)
          .where('categoriaId', isEqualTo: categoriaId)
          .snapshots()
          .map((s) => s.docs.map(Prenda.fromFirestore).toList());

  Stream<List<Prenda>> prendasByEstado(String uid, EstadoPrenda estado) =>
      _col(uid)
          .where('estado', isEqualTo: estado.name)
          .snapshots()
          .map((s) => s.docs.map(Prenda.fromFirestore).toList());

  Stream<List<Prenda>> prendasFavoritas(String uid) => _col(uid)
      .where('favorita', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(Prenda.fromFirestore).toList());

  Future<void> toggleFavorita(String uid, String prendaId, bool valor) async {
    await _col(uid).doc(prendaId).update({'favorita': valor});
  }

  Future<void> toggleArchivada(String uid, String prendaId, bool valor) async {
    await _col(uid).doc(prendaId).update({'archivada': valor});
  }

  Future<void> updateEstado(
    String uid,
    String prendaId,
    EstadoPrenda estado,
  ) async {
    await _col(uid).doc(prendaId).update({'estado': estado.name});
  }

  Future<void> incrementarUso(String uid, String prendaId) async {
    await _db.runTransaction((tx) async {
      final ref = _col(uid).doc(prendaId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final veces = (data['vecesUsada'] as num?)?.toInt() ?? 0;
      tx.update(ref, {
        'vecesUsada': veces + 1,
        'ultimaVezUsada': DateTime.now(),
        'estado': EstadoPrenda.usada.name,
      });
    });
  }

  Future<void> marcarLavada(String uid, String prendaId) =>
      updateEstado(uid, prendaId, EstadoPrenda.lavada);
  Future<void> marcarSucia(String uid, String prendaId) =>
      updateEstado(uid, prendaId, EstadoPrenda.sucia);
  Future<void> marcarLavandose(String uid, String prendaId) =>
      updateEstado(uid, prendaId, EstadoPrenda.lavandose);
}
