import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalJsonStore {
  const LocalJsonStore();

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> result = [];
      bool hadBad = false;

      for (final item in decoded) {
        if (item is Map) {
          result.add(item.cast<String, dynamic>());
        } else {
          hadBad = true;
          debugPrint('LocalJsonStore.readList: skipping corrupt item for key=$key');
        }
      }

      if (hadBad) {
        await writeList(key, result);
      }
      return result;
    } catch (e) {
      debugPrint('LocalJsonStore.readList decode error for key=$key: $e');
      await prefs.remove(key);
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  Future<bool> hasKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  Future<void> writeBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool?> readBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }
}
