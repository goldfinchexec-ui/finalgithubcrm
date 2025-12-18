import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

enum TransactionCategory { driverPayout, clientInvoice, generalExpense, generalIncome }

enum TransactionStatus { paid, pending, received, outstanding }

enum TransactionFrequency { oneTime, weekly, monthly }

@immutable
class LedgerTransaction {
  final String id;
  final TransactionType type;
  final TransactionCategory category;
  final String title;
  final String? relatedDriverId;
  final String? relatedClientId;
  final TransactionStatus status;
  final int amountPence;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> attachments;
  final TransactionFrequency? frequency;
  final String createdByUserId;
  final String? createdByUserName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? invoiceNumber;
  final String? note;

  const LedgerTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.relatedDriverId,
    required this.relatedClientId,
    required this.status,
    required this.amountPence,
    required this.startDate,
    required this.endDate,
    required this.attachments,
    required this.frequency,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.invoiceNumber,
    this.note,
    this.createdByUserName,
  });

  bool get hasRange => endDate != null;

  LedgerTransaction copyWith({
    String? id,
    TransactionType? type,
    TransactionCategory? category,
    String? title,
    String? relatedDriverId,
    String? relatedClientId,
    TransactionStatus? status,
    int? amountPence,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? attachments,
    TransactionFrequency? frequency,
    String? createdByUserId,
    String? createdByUserName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? invoiceNumber,
    String? note,
  }) =>
      LedgerTransaction(
        id: id ?? this.id,
        type: type ?? this.type,
        category: category ?? this.category,
        title: title ?? this.title,
        relatedDriverId: relatedDriverId ?? this.relatedDriverId,
        relatedClientId: relatedClientId ?? this.relatedClientId,
        status: status ?? this.status,
        amountPence: amountPence ?? this.amountPence,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        attachments: attachments ?? this.attachments,
        frequency: frequency ?? this.frequency,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        createdByUserName: createdByUserName ?? this.createdByUserName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'category': category.name,
        'title': title,
        'related_driver_id': relatedDriverId,
        'related_client_id': relatedClientId,
        'status': status.name,
        'amount_pence': amountPence,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'attachments': attachments,
        'frequency': frequency?.name,
        'created_by_user_id': createdByUserId,
        'created_by_user_name': createdByUserName,
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': Timestamp.fromDate(updatedAt),
        'invoice_number': invoiceNumber,
        'note': note,
      };

  static LedgerTransaction? fromJson(dynamic json) {
    try {
      if (json is! Map) return null;
      final map = json.cast<String, dynamic>();
      final attachmentsRaw = map['attachments'];
      final List<String> attachments = attachmentsRaw is List ? attachmentsRaw.map((e) => e.toString()).toList() : <String>[];
      final typeName = map['type']?.toString() ?? '';
      final categoryName = map['category']?.toString() ?? '';
      final statusName = map['status']?.toString() ?? '';
      final freqName = map['frequency']?.toString();
      return LedgerTransaction(
        id: map['id']?.toString() ?? '',
        type: TransactionType.values.firstWhere((e) => e.name == typeName, orElse: () => TransactionType.expense),
        category: TransactionCategory.values.firstWhere((e) => e.name == categoryName, orElse: () => TransactionCategory.generalExpense),
        title: map['title']?.toString() ?? '',
        relatedDriverId: map['related_driver_id']?.toString(),
        relatedClientId: map['related_client_id']?.toString(),
        status: TransactionStatus.values.firstWhere((e) => e.name == statusName, orElse: () => TransactionStatus.pending),
        amountPence: (map['amount_pence'] is int) ? map['amount_pence'] as int : int.tryParse(map['amount_pence']?.toString() ?? '') ?? 0,
        startDate: (map['start_date'] is Timestamp) ? (map['start_date'] as Timestamp).toDate() : DateTime.tryParse(map['start_date']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        endDate: (map['end_date'] == null) ? null : (map['end_date'] is Timestamp) ? (map['end_date'] as Timestamp).toDate() : DateTime.tryParse(map['end_date']?.toString() ?? ''),
        attachments: attachments,
        frequency: (freqName == null) ? null : TransactionFrequency.values.firstWhere((e) => e.name == freqName, orElse: () => TransactionFrequency.oneTime),
        createdByUserId: map['created_by_user_id']?.toString() ?? '',
        createdByUserName: map['created_by_user_name']?.toString(),
        createdAt: (map['created_at'] is Timestamp) ? (map['created_at'] as Timestamp).toDate() : DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: (map['updated_at'] is Timestamp) ? (map['updated_at'] as Timestamp).toDate() : DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        invoiceNumber: map['invoice_number']?.toString(),
        note: map['note']?.toString(),
      );
    } catch (e) {
      debugPrint('LedgerTransaction.fromJson error: $e');
      return null;
    }
  }
}
