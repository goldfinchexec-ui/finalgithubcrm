import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:goldfinch_crm/models/client.dart';

class ClientService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  const ClientService(this._firestore, this._auth);

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<List<Client>> list() async {
    try {
      final snapshot = await _firestore
          .collection('clients')
          .orderBy('name')
          .get();

      final items = snapshot.docs
          .map((doc) => Client.fromJson({...doc.data(), 'id': doc.id}))
          .whereType<Client>()
          .toList();
      
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    } catch (e) {
      debugPrint('ClientService.list error: $e');
      return [];
    }
  }

  Future<Client?> upsert(Client client) async {
    try {
      final now = DateTime.now();
      final next = client.copyWith(
        ownerId: _currentUserId,
        updatedAt: now,
        createdAt: client.createdAt == DateTime.fromMillisecondsSinceEpoch(0) ? now : client.createdAt,
      );

      final docRef = _firestore.collection('clients').doc(next.id);
      await docRef.set(next.toJson(), SetOptions(merge: true));
      return next;
    } catch (e) {
      debugPrint('ClientService.upsert error: $e');
      return null;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firestore.collection('clients').doc(id).delete();
    } catch (e) {
      debugPrint('ClientService.delete error: $e');
    }
  }
}
