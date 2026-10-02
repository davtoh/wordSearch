import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock mobile phones to Portrait orientation, while allowing flexible orientations on tablets & desktop
  final isMobilePhone = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  if (isMobilePhone) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(
    const ProviderScope(
      child: WordSearchApp(),
    ),
  );
}

class WordSearchApp extends StatelessWidget {
  const WordSearchApp({super.key, this.router});

  final RouterConfig<Object>? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Word Search App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router ?? appRouter,
    );
  }
}
