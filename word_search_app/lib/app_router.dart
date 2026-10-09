import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/learning/presentation/learn_screen.dart';
import 'features/navigation/presentation/main_menu_screen.dart';
import 'features/packs/presentation/pack_library_screen.dart';
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

/// Helper screen widget for placeholder or feature view destinations.
class _DestinationShellScreen extends StatelessWidget {
  const _DestinationShellScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('destination_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Menu',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.menu);
            }
          },
        ),
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                key: const Key('return_to_menu_button'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => context.go(AppRoutes.menu),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Main Menu'),
              ),
            ],
          ),
        ),
      ),
    );
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

/// AI Generator Screen destination
class AiGeneratorScreen extends StatelessWidget {
  const AiGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DestinationShellScreen(
      title: 'AI Generator',
      icon: Icons.auto_awesome_rounded,
      description: 'Generate dynamic puzzle topics tailored to any subject.',
    );
  }
}

/// Settings Screen destination
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DestinationShellScreen(
      title: 'Settings',
      icon: Icons.settings_rounded,
      description: 'Configure game preferences, sound effects, and display themes.',
    );
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
                builder: (context, state) => const AiGeneratorScreen(),
              ),
            ],
          ),
          // Branch 5: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
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
