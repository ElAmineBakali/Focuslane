import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/outfit_model.dart';

class OutfitFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('wardrobe_outfits');

  Stream<List<Outfit>> outfitsStream(String uid) {
    return _col(uid).snapshots().map(
      (s) => s.docs.map((d) => Outfit.fromFirestore(d)).toList(),
    );
  }

  Future<void> addOutfit(String uid, Outfit outfit) async {
    final doc = _col(uid).doc();
    await doc.set({...outfit.toFirestore()});
  }

  Future<void> updateOutfit(String uid, Outfit outfit) async {
    await _col(uid).doc(outfit.id).update(outfit.toFirestore());
  }

  Future<void> deleteOutfit(String uid, String outfitId) async {
    await _col(uid).doc(outfitId).delete();
  }
}
