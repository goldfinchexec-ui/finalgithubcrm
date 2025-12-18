import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:goldfinch_crm/models/client.dart';
import 'package:goldfinch_crm/models/driver.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/models/user_model.dart';
import 'package:goldfinch_crm/services/attachment_service.dart';
import 'package:goldfinch_crm/services/client_service.dart';
import 'package:goldfinch_crm/services/driver_service.dart';
import 'package:goldfinch_crm/services/local_json_store.dart';
import 'package:goldfinch_crm/services/transaction_service.dart';
import 'package:goldfinch_crm/services/user_service.dart';
import 'package:goldfinch_crm/services/auth_service.dart';

final localJsonStoreProvider = Provider<LocalJsonStore>((ref) => const LocalJsonStore());

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.read(firebaseAuthProvider)));

final userServiceProvider = Provider<UserService>((ref) => UserService(ref.read(localJsonStoreProvider)));
final driverServiceProvider = Provider<DriverService>((ref) => DriverService(ref.read(firestoreProvider), ref.read(firebaseAuthProvider)));
final clientServiceProvider = Provider<ClientService>((ref) => ClientService(ref.read(firestoreProvider), ref.read(firebaseAuthProvider)));
final transactionServiceProvider = Provider<TransactionService>((ref) => TransactionService(ref.read(firestoreProvider), ref.read(firebaseAuthProvider)));
final attachmentServiceProvider = Provider<AttachmentService>((ref) => const AttachmentService());

// Auth state stream (null when signed out)
final authStateProvider = StreamProvider<User?>((ref) => ref.read(authServiceProvider).authStateChanges());

final isAuthenticatedProvider = Provider<bool>((ref) => ref.watch(authStateProvider).asData?.value != null);

final currentUserProvider = FutureProvider<AppUser>((ref) async => ref.read(userServiceProvider).ensureCurrentUser());

class DriversNotifier extends AsyncNotifier<List<Driver>> {
  @override
  Future<List<Driver>> build() => ref.read(driverServiceProvider).list();

  Future<void> upsert(Driver driver) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(driverServiceProvider).upsert(driver);
      return ref.read(driverServiceProvider).list();
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(driverServiceProvider).delete(id);
      return ref.read(driverServiceProvider).list();
    });
  }
}

final driversProvider = AsyncNotifierProvider<DriversNotifier, List<Driver>>(DriversNotifier.new);

class ClientsNotifier extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() => ref.read(clientServiceProvider).list();

  Future<void> upsert(Client client) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clientServiceProvider).upsert(client);
      return ref.read(clientServiceProvider).list();
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clientServiceProvider).delete(id);
      return ref.read(clientServiceProvider).list();
    });
  }
}

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, List<Client>>(ClientsNotifier.new);

class TransactionsNotifier extends AsyncNotifier<List<LedgerTransaction>> {
  @override
  Future<List<LedgerTransaction>> build() => ref.read(transactionServiceProvider).list();

  Future<void> upsert(LedgerTransaction tx) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionServiceProvider).upsert(tx);
      return ref.read(transactionServiceProvider).list();
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionServiceProvider).delete(id);
      return ref.read(transactionServiceProvider).list();
    });
  }
}

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<LedgerTransaction>>(TransactionsNotifier.new);

class ShellUiState {
  final bool sidebarCollapsed;
  const ShellUiState({required this.sidebarCollapsed});

  ShellUiState copyWith({bool? sidebarCollapsed}) => ShellUiState(sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed);
}

class ShellUiNotifier extends Notifier<ShellUiState> {
  static const _key = 'gf_sidebar_collapsed';

  @override
  ShellUiState build() {
    _load();
    return const ShellUiState(sidebarCollapsed: false);
  }

  Future<void> _load() async {
    final store = ref.read(localJsonStoreProvider);
    final v = await store.readBool(_key);
    if (v != null) state = state.copyWith(sidebarCollapsed: v);
  }

  Future<void> toggleSidebar() async {
    final store = ref.read(localJsonStoreProvider);
    final next = !state.sidebarCollapsed;
    state = state.copyWith(sidebarCollapsed: next);
    await store.writeBool(_key, next);
  }
}

final shellUiProvider = NotifierProvider<ShellUiNotifier, ShellUiState>(ShellUiNotifier.new);
