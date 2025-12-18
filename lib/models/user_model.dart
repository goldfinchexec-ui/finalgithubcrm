import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class AppUser {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({required this.id, required this.name, required this.email, required this.createdAt, required this.updatedAt});

  AppUser copyWith({String? id, String? name, String? email, DateTime? createdAt, DateTime? updatedAt}) => AppUser(id: id ?? this.id, name: name ?? this.name, email: email ?? this.email, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'created_at': Timestamp.fromDate(createdAt), 'updated_at': Timestamp.fromDate(updatedAt)};

  static AppUser? fromJson(dynamic json) {
    try {
      if (json is! Map) return null;
      final map = json.cast<String, dynamic>();
      return AppUser(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        createdAt: (map['created_at'] is Timestamp) ? (map['created_at'] as Timestamp).toDate() : DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: (map['updated_at'] is Timestamp) ? (map['updated_at'] as Timestamp).toDate() : DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (e) {
      debugPrint('AppUser.fromJson error: $e');
      return null;
    }
  }
}
