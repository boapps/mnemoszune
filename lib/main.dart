import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnemoszune/screens/home_screen.dart';
import 'package:mnemoszune/providers/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: MnemoszuneApp()));
}

class MnemoszuneApp extends ConsumerWidget {
  const MnemoszuneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Mnemoszune',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: settings.darkMode ? Brightness.dark : Brightness.light,
        ),
        fontFamily: settings.fontFamily,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: settings.fontSize),
          bodyMedium: TextStyle(fontSize: settings.fontSize - 2),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
