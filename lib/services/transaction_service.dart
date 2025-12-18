import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:goldfinch_crm/models/ledger_transaction.dart';

class TransactionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  const TransactionService(this._firestore, this._auth);

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<List<LedgerTransaction>> list() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .orderBy('start_date', descending: true)
          .limit(1000)
          .get();

      final items = snapshot.docs
          .map((doc) => LedgerTransaction.fromJson({...doc.data(), 'id': doc.id}))
          .whereType<LedgerTransaction>()
          .toList();
      
      items.sort((a, b) => b.startDate.compareTo(a.startDate));
      return items;
    } catch (e) {
      debugPrint('TransactionService.list error: $e');
      return [];
    }
  }

  Future<LedgerTransaction?> upsert(LedgerTransaction tx) async {
    try {
      final now = DateTime.now();
      final authUser = _auth.currentUser;
      final createdName = (() {
        final dn = authUser?.displayName?.trim();
        if (dn != null && dn.isNotEmpty) return dn;
        final email = authUser?.email ?? '';
        if (email.contains('@')) return email.split('@').first;
        return 'Staff';
      })();
      final next = tx.copyWith(
        createdByUserId: _currentUserId,
        createdByUserName: tx.createdByUserName ?? createdName,
        updatedAt: now,
        createdAt: tx.createdAt == DateTime.fromMillisecondsSinceEpoch(0) ? now : tx.createdAt,
      );

      final docRef = _firestore.collection('transactions').doc(next.id);
      await docRef.set(next.toJson(), SetOptions(merge: true));
      return next;
    } catch (e) {
      debugPrint('TransactionService.upsert error: $e');
      return null;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firestore.collection('transactions').doc(id).delete();
    } catch (e) {
      debugPrint('TransactionService.delete error: $e');
    }
  }

  Future<List<LedgerTransaction>> forMonth(DateTime month) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('TransactionService.forMonth: no authenticated user');
      return [];
    }

    try {
      final key = DateFormat('yyyy-MM').format(month);
      final items = await list();
      return items.where((t) => DateFormat('yyyy-MM').format(t.startDate) == key).toList();
    } catch (e) {
      debugPrint('TransactionService.forMonth error: $e');
      return [];
    }
  }

  Future<List<LedgerTransaction>> forRange(DateTime start, DateTime end) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('TransactionService.forRange: no authenticated user');
      return [];
    }

    try {
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
      
      final items = await list();
      return items.where((t) {
        final txStart = t.startDate;
        final txEnd = t.endDate ?? t.startDate;
        return !(txEnd.isBefore(startDay) || txStart.isAfter(endDay));
      }).toList();
    } catch (e) {
      debugPrint('TransactionService.forRange error: $e');
      return [];
    }
  }

  Future<List<LedgerTransaction>> receiptVault() async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('type', isEqualTo: TransactionType.expense.name)
          .orderBy('start_date', descending: true)
          .limit(500)
          .get();

      final items = snapshot.docs
          .map((doc) => LedgerTransaction.fromJson({...doc.data(), 'id': doc.id}))
          .whereType<LedgerTransaction>()
          .where((t) => t.attachments.isNotEmpty)
          .toList();
      
      return items;
    } catch (e) {
      debugPrint('TransactionService.receiptVault error: $e');
      return [];
    }
  }
}
