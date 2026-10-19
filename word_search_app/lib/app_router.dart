import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/ai_generator/presentation/ai_generator_screen.dart';
import 'features/learning/presentation/learn_screen.dart';
import 'features/navigation/presentation/main_menu_screen.dart';
import 'features/packs/presentation/pack_library_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/word_search/presentation/game_screen.dart';

/// Route constants for declarative routing across the app.
class AppRoutes {
  static const String menu = '/';
  static const String game = '/game';
  static const String packLibrary = '/pack-library';
  static const String learnMode = '/learn-mode';
  static const String aiGenerator = '/ai-generator';
  static const String settings = '/settings';
}

/// Navigation Shell wrapping the routes in a [StatefulShellRoute.indexedStack].
/// This ensures parallel branches keep their state alive without destruction when switching views.
class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return navigationShell;
  }
}



/// Learn Mode Screen destination
class LearnModeScreen extends StatelessWidget {
  const LearnModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LearnScreen();
  }
}

/// AI Generator Screen destination – delegates to the real feature screen.
class AiGeneratorShellScreen extends StatelessWidget {
  const AiGeneratorShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiGeneratorScreen();
  }
}

/// Settings Screen destination – delegates to the real feature screen.
class SettingsShellScreen extends StatelessWidget {
  const SettingsShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}

/// Factory function to create a configured [GoRouter] instance.
/// Uses [StatefulShellRoute.indexedStack] to maintain view state across tab navigation.
GoRouter createAppRouter({
  String initialLocation = AppRoutes.menu,
  List<NavigatorObserver>? observers,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    observers: observers,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Main Menu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.menu,
                name: 'menu',
                builder: (context, state) => const MainMenuScreen(),
              ),
            ],
          ),
          // Branch 1: Quick Play (Game Screen)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.game,
                name: 'game',
                builder: (context, state) => const GameScreen(),
              ),
            ],
          ),
          // Branch 2: Pack Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.packLibrary,
                name: 'pack_library',
                builder: (context, state) => const PackLibraryScreen(),
              ),
            ],
          ),
          // Branch 3: Learn Mode
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.learnMode,
                name: 'learn_mode',
                builder: (context, state) => const LearnModeScreen(),
              ),
            ],
          ),
          // Branch 4: AI Generator
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.aiGenerator,
                name: 'ai_generator',
                builder: (context, state) => const AiGeneratorShellScreen(),
              ),
            ],
          ),
          // Branch 5: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsShellScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Global router instance for the application.
final GoRouter appRouter = createAppRouter();
