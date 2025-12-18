import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:goldfinch_crm/models/driver.dart';

class DriverService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  const DriverService(this._firestore, this._auth);

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<List<Driver>> list() async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .orderBy('name')
          .get();

      final items = snapshot.docs
          .map((doc) => Driver.fromJson({...doc.data(), 'id': doc.id}))
          .whereType<Driver>()
          .toList();
      
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    } catch (e) {
      debugPrint('DriverService.list error: $e');
      return [];
    }
  }

  Future<Driver?> upsert(Driver driver) async {
    try {
      final now = DateTime.now();
      final next = driver.copyWith(
        ownerId: _currentUserId,
        updatedAt: now,
        createdAt: driver.createdAt == DateTime.fromMillisecondsSinceEpoch(0) ? now : driver.createdAt,
      );

      final docRef = _firestore.collection('drivers').doc(next.id);
      await docRef.set(next.toJson(), SetOptions(merge: true));
      return next;
    } catch (e) {
      debugPrint('DriverService.upsert error: $e');
      return null;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firestore.collection('drivers').doc(id).delete();
    } catch (e) {
      debugPrint('DriverService.delete error: $e');
    }
  }
}
