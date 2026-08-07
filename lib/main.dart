import 'package:accountify/core/database/database.dart';
import 'package:accountify/core/providers/database_provider.dart';
import 'package:accountify/core/theme/theme_mode.dart';
import 'package:accountify/core/theme/theme_provider.dart';
import 'package:accountify/features/lock/app_lock_gate.dart';
import 'package:accountify/routes/go_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await db.init();

  final banksList = await db.select(db.banks).get();
  print('Loaded ${banksList.length} banks');
  for (var bank in banksList) {
    print('  - ${bank.name} (${bank.shortName})');
  }

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Map our AppThemeMode to Flutter's ThemeMode
    final ThemeMode flutterThemeMode;
    switch (themeMode) {
      case AppThemeMode.light:
        flutterThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        flutterThemeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
      default:
        final brightness = WidgetsBinding.instance.window.platformBrightness;
        flutterThemeMode = brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light;
    }

    return MaterialApp.router(
      title: 'Accountify',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: flutterThemeMode,
      routerConfig: router,
      // Overlay the app-lock gate above every route so a locked app is never
      // accessible regardless of the current navigation state.
      builder: (context, child) =>
          AppLockGate(child: child ?? const SizedBox()),
      // showPerformanceOverlay: true,
    );
  }
}
