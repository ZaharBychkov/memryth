import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/quote.dart';
import 'models/tag.dart';
import 'screens/quotes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(TagAdapter());
  Hive.registerAdapter(QuoteAdapter());

  await Hive.openBox<Tag>('tags');
  await Hive.openBox<Quote>('quotes');

  runApp(const MemrythApp());
}

class MemrythApp extends StatelessWidget {
  const MemrythApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мемритм',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6FA5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDF7F2),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2C2C2C)),
          bodyMedium: TextStyle(color: Color(0xFF2C2C2C)),
          titleLarge: TextStyle(color: Color(0xFF2C2C2C)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF5F0E6),
          foregroundColor: Color(0xFF2C2C2C),
          elevation: 0,
        ),
      ),
      home: const QuotesScreen(),
    );
  }
}
