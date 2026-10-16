import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'features/settings/application/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock mobile phones to Portrait orientation by default (settings can override).
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

/// Root application widget.
///
/// Watches [themeNotifierProvider] so that theme changes made in
/// [SettingsScreen] are immediately reflected across the whole app.
/// The [fontScaleProvider] is applied via a [MediaQuery] wrapper that
/// overrides [TextScaler] for the entire widget tree.
class WordSearchApp extends ConsumerWidget {
  const WordSearchApp({super.key, this.router});

  final RouterConfig<Object>? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeNotifierProvider);
    final notifier = ref.read(themeNotifierProvider.notifier);

    return MediaQuery(
      // Apply the user's font-scale multiplier globally.
      data: MediaQueryData(
        textScaler: TextScaler.linear(settings.fontScaleFactor),
      ),
      child: MaterialApp.router(
        title: 'Word Search App',
        debugShowCheckedModeBanner: false,
        // ── Themes ────────────────────────────────────────────
        theme: notifier.lightTheme,
        darkTheme: notifier.darkTheme,
        themeMode: settings.themeMode,
        // ── Router ────────────────────────────────────────────
        routerConfig: router ?? appRouter,
      ),
    );
  }
}
