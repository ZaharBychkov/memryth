import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/demo_seed.dart';
import 'models/quote.dart';
import 'models/tag.dart';
import 'screens/quotes_screen.dart';
import 'settings/app_settings.dart';
import 'settings/app_settings_controller.dart';
import 'settings/app_settings_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TagAdapter());
  Hive.registerAdapter(QuoteAdapter());

  await Hive.openBox<Tag>('tags');
  await Hive.openBox<Quote>('quotes');
  await Hive.openBox('settings');
  await DemoSeed.ensureSeeded();

  final settingsController = await AppSettingsController.create();
  runApp(MemrythApp(settingsController: settingsController));
}

class MemrythApp extends StatelessWidget {
  const MemrythApp({super.key, required this.settingsController});

  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: settingsController,
      child: AnimatedBuilder(
        animation: settingsController,
        builder: (context, _) {
          final settings = settingsController.settings;
          return MaterialApp(
            title: 'Memryth',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: settings.themeMode == AppThemeMode.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            themeAnimationDuration: Duration.zero,
            scrollBehavior: const _MemrythScrollBehavior(),
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(settings.uiTextSize.scale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const QuotesScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const seed = Color(0xFF4A6FA5);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        surface: const Color(0xFFFDF7F2),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFDF7F2),
      canvasColor: const Color(0xFFFDF7F2),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFD8CEC5),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF2C2C2C)),
        bodyMedium: TextStyle(color: Color(0xFF2C2C2C)),
        titleLarge: TextStyle(color: Color(0xFF2C2C2C)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFFF5F0E6),
        foregroundColor: Color(0xFF2C2C2C),
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFFF7F1EA)),
    );
  }

  ThemeData _buildDarkTheme() {
    const accent = Color(0xFF9DB3D8);
    const background = Color(0xFF171A1F);
    const surface = Color(0xFF1E2229);
    const appBar = Color(0xFF1A1E24);
    const text = Color(0xFFEAE4DB);
    const muted = Color(0xFFB8AEA2);

    return ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        onSurface: text,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: const Color(0xFF373D46),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        titleLarge: TextStyle(color: text),
      ),
      hintColor: muted,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: appBar,
        foregroundColor: text,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1D2127)),
    );
  }
}

class _MemrythScrollBehavior extends MaterialScrollBehavior {
  const _MemrythScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
