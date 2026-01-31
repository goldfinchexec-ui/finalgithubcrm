import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ToastType { info, success, error, warning }

class ToastMessage {
  final String id;
  final String title;
  final String description;
  final ToastType type;
  final Duration duration;

  const ToastMessage({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.duration = const Duration(seconds: 4),
  });
}

class ToastNotifier extends StateNotifier<List<ToastMessage>> {
  ToastNotifier() : super([]);

  void show({
    required String title,
    String description = '',
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final message = ToastMessage(id: id, title: title, description: description, type: type, duration: duration);
    
    state = [...state, message];
    
    // Auto-dismiss
    Future.delayed(duration, () {
      dismiss(id);
    });
  }

  void dismiss(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final toastProvider = StateNotifierProvider<ToastNotifier, List<ToastMessage>>((ref) {
  return ToastNotifier();
});
