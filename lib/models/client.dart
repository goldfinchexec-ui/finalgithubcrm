import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class Client {
  final String id;
  final String name;
  final String email;
  final String address;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Client({required this.id, required this.name, required this.email, required this.address, required this.ownerId, required this.createdAt, required this.updatedAt});

  Client copyWith({String? id, String? name, String? email, String? address, String? ownerId, DateTime? createdAt, DateTime? updatedAt}) =>
      Client(id: id ?? this.id, name: name ?? this.name, email: email ?? this.email, address: address ?? this.address, ownerId: ownerId ?? this.ownerId, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'address': address, 'owner_id': ownerId, 'created_at': Timestamp.fromDate(createdAt), 'updated_at': Timestamp.fromDate(updatedAt)};

  static Client? fromJson(dynamic json) {
    try {
      if (json is! Map) return null;
      final map = json.cast<String, dynamic>();
      return Client(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        address: map['address']?.toString() ?? '',
        ownerId: map['owner_id']?.toString() ?? '',
        createdAt: (map['created_at'] is Timestamp) ? (map['created_at'] as Timestamp).toDate() : DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: (map['updated_at'] is Timestamp) ? (map['updated_at'] as Timestamp).toDate() : DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (e) {
      debugPrint('Client.fromJson error: $e');
      return null;
    }
  }
}
