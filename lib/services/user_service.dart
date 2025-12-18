import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:goldfinch_crm/models/user_model.dart';
import 'package:goldfinch_crm/services/local_json_store.dart';

class UserService {
  static const _key = 'gf_users';
  static const _currentKey = 'gf_current_user_id';

  final LocalJsonStore _store;
  const UserService(this._store);

  Future<AppUser> ensureCurrentUser() async {
    final users = await listUsers();
    if (users.isNotEmpty) return users.first;

    final now = DateTime.now();
    final user = AppUser(id: const Uuid().v4(), name: 'Goldfinch Staff', email: 'staff@goldfinch.local', createdAt: now, updatedAt: now);
    await saveUsers([user]);
    return user;
  }

  Future<List<AppUser>> listUsers() async {
    final raw = await _store.readList(_key);
    final users = raw.map(AppUser.fromJson).whereType<AppUser>().toList();
    if (users.isEmpty && raw.isNotEmpty) {
      debugPrint('UserService.listUsers: all entries invalid, sanitized');
      await saveUsers([]);
    }
    return users;
  }

  Future<void> saveUsers(List<AppUser> users) async => _store.writeList(_key, users.map((e) => e.toJson()).toList());
}
