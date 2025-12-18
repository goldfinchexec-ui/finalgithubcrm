import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Ensure web implementation of Firebase Storage is linked on web builds.
// This import is harmless on mobile/desktop and can prevent channel errors on web.
// ignore: unused_import
import 'package:firebase_storage_web/firebase_storage_web.dart';
import 'theme.dart';
import 'nav.dart';
import 'ui/app_scroll_behavior.dart';

/// Main entry point for the application
///
/// This sets up:
/// - Provider state management (ThemeProvider, CounterProvider)
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() async {
  // Ensure binding is ready for async initialization
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[boot] Widgets binding initialized');

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[boot] Firebase initialized');
  } catch (e, st) {
    debugPrint('[boot][error] Firebase initialization failed: $e');
    debugPrint(st.toString());
  }

  // Initialize locale data for dates/numbers used across the UI
  // This fixes: LocaleDataException (call initializeDateFormatting(<locale>))
  Intl.defaultLocale = 'en_GB';
  try {
    await initializeDateFormatting('en_GB');
    debugPrint('[boot] Locale initialized: en_GB');
  } catch (e, st) {
    debugPrint('[boot][warn] initializeDateFormatting failed: $e');
    debugPrint(st.toString());
  }

  // Global error handlers so startup issues are visible in the Debug Console
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: \\n${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };

  // Initialize the app with Riverpod ProviderScope
  debugPrint('[boot] Entering runApp');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[boot] MyApp.build()');
    // MultiProvider wraps the app to provide state to all widgets
    // As you extend the app, use MultiProvider to wrap the app
    // and provide state to all widgets
    // Example:
    // return MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (_) => ExampleProvider()),
    //   ],
    //   child: MaterialApp.router(
    //     title: 'Dreamflow Starter',
    //     debugShowCheckedModeBanner: false,
    //     routerConfig: AppRouter.router,
    //   ),
    // );
    return MaterialApp.router(
      title: 'Goldfinch CRM',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,

      // Smooth, platform-consistent scrolling on web/desktop
      scrollBehavior: const AppScrollBehavior(),

      // Use context.go() or context.push() to navigate to the routes.
      routerConfig: AppRouter.router,
    );
  }
}
