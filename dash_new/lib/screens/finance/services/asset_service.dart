import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mi_dashboard_personal/screens/finance/models/asset_model.dart';
import 'dart:io';

class AssetService {
  static final AssetService I = AssetService._();
  AssetService._();

  final _col = FirebaseFirestore.instance.collection('finance_assets');

  String get _uid => fb_auth.FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Asset>> watchAll() {
    return _col
        .where('userId', isEqualTo: _uid)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(Asset.fromDoc).toList());
  }

  Future<void> upsert(Asset a) async {
    final data = a.toMap();
    if (a.id.isEmpty) {
      await _col.add(data..['userId'] = _uid);
    } else {
      await _col.doc(a.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> create(Asset a) async {
    final data = a.toMap();
    await _col.add(data..['userId'] = _uid);
  }

  Future<void> update(Asset a) async {
    await _col.doc(a.id).set(a.toMap(), SetOptions(merge: true));
  }

  Future<String?> uploadPhoto(File file) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('finance/assets/$_uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> addValueSnapshot(String assetId, AssetValueSnapshot snap) async {
    final doc = await _col.doc(assetId).get();
    final asset = Asset.fromDoc(doc);
    final updated = List<AssetValueSnapshot>.from(asset.valueHistory)
      ..add(snap);
    await _col.doc(assetId).update({
      'valueHistory': updated.map((e) => e.toMap()).toList(),
      'currentValue': snap.value,
    });
  }
}

