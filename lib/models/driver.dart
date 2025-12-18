import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class Driver {
  final String id;
  final String name;
  final String code;
  final String email;
  final String vehicleReg;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Driver({required this.id, required this.name, required this.code, required this.email, required this.vehicleReg, required this.ownerId, required this.createdAt, required this.updatedAt});

  Driver copyWith({String? id, String? name, String? code, String? email, String? vehicleReg, String? ownerId, DateTime? createdAt, DateTime? updatedAt}) =>
      Driver(id: id ?? this.id, name: name ?? this.name, code: code ?? this.code, email: email ?? this.email, vehicleReg: vehicleReg ?? this.vehicleReg, ownerId: ownerId ?? this.ownerId, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'email': email,
        'vehicle_reg': vehicleReg,
        'owner_id': ownerId,
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': Timestamp.fromDate(updatedAt),
      };

  static Driver? fromJson(dynamic json) {
    try {
      if (json is! Map) return null;
      final map = json.cast<String, dynamic>();
      return Driver(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        code: map['code']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        vehicleReg: map['vehicle_reg']?.toString() ?? '',
        ownerId: map['owner_id']?.toString() ?? '',
        createdAt: (map['created_at'] is Timestamp) ? (map['created_at'] as Timestamp).toDate() : DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: (map['updated_at'] is Timestamp) ? (map['updated_at'] as Timestamp).toDate() : DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (e) {
      debugPrint('Driver.fromJson error: $e');
      return null;
    }
  }
}
