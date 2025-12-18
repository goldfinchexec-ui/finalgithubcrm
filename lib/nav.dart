import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:goldfinch_crm/shell/app_shell_scaffold.dart';
import 'package:goldfinch_crm/pages/home_page.dart';
import 'package:goldfinch_crm/pages/dashboard_page.dart';
import 'package:goldfinch_crm/pages/bookings_page.dart';
import 'package:goldfinch_crm/pages/drivers_page.dart';
import 'package:goldfinch_crm/pages/driver_invoices_page.dart';
import 'package:goldfinch_crm/pages/clients_page.dart';
import 'package:goldfinch_crm/pages/client_invoices_page.dart';
import 'package:goldfinch_crm/pages/general_income_page.dart';
import 'package:goldfinch_crm/pages/general_expenses_page.dart';
import 'package:goldfinch_crm/pages/receipt_vault_page.dart';
import 'package:goldfinch_crm/pages/auth/login_page.dart';
import 'package:goldfinch_crm/pages/auth/signup_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// GoRouter configuration for app navigation
///
/// This uses go_router for declarative routing with ShellRoute:
/// - Type-safe navigation
/// - Deep linking support (web URLs, app links)
/// - Easy route parameters
/// - Navigation guards and redirects
/// - Single shell scaffold wrapping all pages
///
/// To add a new route:
/// 1. Add a route constant to AppRoutes below
/// 2. Add a GoRoute to the ShellRoute.routes list
/// 3. Navigate using context.go() or context.push()
/// 4. Use context.pop() to go back.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    // Rebuild redirects when auth state changes
    refreshListenable: _GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (context, state) {
      // Use FirebaseAuth directly for instant, zone-safe checks during redirects
      final isAuthed = FirebaseAuth.instance.currentUser != null;
      final loggingIn = state.uri.path == AppRoutes.login || state.uri.path == AppRoutes.signup;

      // If not authed, send to login except for auth pages
      if (!isAuthed && !loggingIn) {
        return AppRoutes.login;
      }
      // If authed and on auth pages, go to dashboard
      if (isAuthed && loggingIn) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => const NoTransitionPage(child: SignupPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.bookings,
            name: 'bookings',
            pageBuilder: (context, state) => const NoTransitionPage(child: BookingsPage()),
          ),
          GoRoute(
            path: AppRoutes.drivers,
            name: 'drivers',
            pageBuilder: (context, state) => const NoTransitionPage(child: DriversPage()),
          ),
          GoRoute(
            path: AppRoutes.driverInvoices,
            name: 'driver-invoices',
            pageBuilder: (context, state) => const NoTransitionPage(child: DriverInvoicesPage()),
          ),
          GoRoute(
            path: AppRoutes.clients,
            name: 'clients',
            pageBuilder: (context, state) => const NoTransitionPage(child: ClientsPage()),
          ),
          GoRoute(
            path: AppRoutes.clientInvoices,
            name: 'client-invoices',
            pageBuilder: (context, state) => const NoTransitionPage(child: ClientInvoicesPage()),
          ),
          GoRoute(
            path: AppRoutes.generalIncome,
            name: 'general-income',
            pageBuilder: (context, state) => const NoTransitionPage(child: GeneralIncomePage()),
          ),
          GoRoute(
            path: AppRoutes.generalExpenses,
            name: 'general-expenses',
            pageBuilder: (context, state) => const NoTransitionPage(child: GeneralExpensesPage()),
          ),
          GoRoute(
            path: AppRoutes.receiptVault,
            name: 'receipt-vault',
            pageBuilder: (context, state) => const NoTransitionPage(child: ReceiptVaultPage()),
          ),
        ],
      ),
    ],
  );
}

/// Route path constants
/// Use these instead of hard-coding route strings
class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String bookings = '/bookings';
  static const String drivers = '/drivers';
  static const String driverInvoices = '/driver-invoices';
  static const String clients = '/clients';
  static const String clientInvoices = '/client-invoices';
  static const String generalIncome = '/general-income';
  static const String generalExpenses = '/general-expenses';
  static const String receiptVault = '/receipt-vault';
}

/// Lightweight Listenable that triggers router refreshes on stream events
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
