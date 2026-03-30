import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioProvider(),
      child: const NoorAlQuranApp(),
    ),
  );
}

class NoorAlQuranApp extends StatelessWidget {
  const NoorAlQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'Noor Al-Quran',
          debugShowCheckedModeBanner: false,
          themeMode: provider.isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF10B981),
            brightness: Brightness.light,
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF059669),
            brightness: Brightness.dark,
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
