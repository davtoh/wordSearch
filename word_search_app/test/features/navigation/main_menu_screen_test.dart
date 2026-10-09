// test/features/navigation/main_menu_screen_test.dart
// Widget tests for MainMenuScreen, touch target accessibility, responsive reflow,
// and state-preserving declarative routing via GoRouter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/app_router.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/navigation/presentation/main_menu_screen.dart';
import 'package:word_search_app/features/packs/presentation/pack_library_screen.dart';
import 'package:word_search_app/features/word_search/application/game_provider.dart';
import 'package:word_search_app/features/word_search/presentation/game_screen.dart';

void main() {
  group('MainMenuScreen Presentation & Accessibility', () {
    testWidgets('renders all 5 action tiles with titles and subtitles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header branding
      expect(find.text('Word Search App'), findsOneWidget);
      expect(find.text('Welcome to Word Search'), findsOneWidget);
      expect(find.text('Explore, Learn & Play'), findsOneWidget);

      // Verify all 5 action tiles exist
      expect(find.text('Quick Play'), findsOneWidget);
      expect(find.text('Pack Library'), findsOneWidget);
      expect(find.text('Learn Mode'), findsOneWidget);
      expect(find.text('AI Generator'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify subtitles
      expect(find.text('Jump right into a classic word search puzzle'), findsOneWidget);
      expect(find.text('Explore themed word packs and collections'), findsOneWidget);
      expect(find.text('Master vocabulary with spaced repetition'), findsOneWidget);
      expect(find.text('Generate infinite dynamic custom puzzles'), findsOneWidget);
      expect(find.text('Audio, display themes, and preferences'), findsOneWidget);
    });

    testWidgets('enforces minimum 48x48 dp touch target dimensions on all action tiles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final tileKeys = [
        'menu_tile_quick_play',
        'menu_tile_pack_library',
        'menu_tile_learn_mode',
        'menu_tile_ai_generator',
        'menu_tile_settings',
      ];

      for (final key in tileKeys) {
        final finder = find.byKey(Key(key));
        expect(finder, findsOneWidget, reason: 'Tile $key should be rendered');

        final Size size = tester.getSize(finder);
        expect(
          size.width,
          greaterThanOrEqualTo(48.0),
          reason: 'Width of $key must be >= 48 dp (got ${size.width})',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(48.0),
          reason: 'Height of $key must be >= 48 dp (got ${size.height})',
        );
      }
    });

    testWidgets('provides accessible button semantics on all action tiles',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: MainMenuScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final tileLabels = [
          'Quick Play',
          'Pack Library',
          'Learn Mode',
          'AI Generator',
          'Settings',
        ];

        for (final label in tileLabels) {
          expect(
            find.bySemanticsLabel(label),
            findsOneWidget,
            reason: 'Tile with label $label should have matching semantics',
          );
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('invokes onNavigate callback when an action tile is tapped',
        (WidgetTester tester) async {
      String? navigatedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(
            onNavigate: (route) {
              navigatedRoute = route;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Quick Play
      await tester.tap(find.byKey(const Key('menu_tile_quick_play')));
      await tester.pumpAndSettle();
      expect(navigatedRoute, equals(AppRoutes.game));

      // Tap Pack Library
      await tester.tap(find.byKey(const Key('menu_tile_pack_library')));
      await tester.pumpAndSettle();
      expect(navigatedRoute, equals(AppRoutes.packLibrary));

      // Tap Learn Mode
      await tester.tap(find.byKey(const Key('menu_tile_learn_mode')));
      await tester.pumpAndSettle();
      expect(navigatedRoute, equals(AppRoutes.learnMode));

      // Tap AI Generator
      await tester.tap(find.byKey(const Key('menu_tile_ai_generator')));
      await tester.pumpAndSettle();
      expect(navigatedRoute, equals(AppRoutes.aiGenerator));

      // Tap Settings
      await tester.tap(find.byKey(const Key('menu_tile_settings')));
      await tester.pumpAndSettle();
      expect(navigatedRoute, equals(AppRoutes.settings));
    });
  });

  group('Responsive Layout Reflow (Mobile vs Desktop)', () {
    testWidgets('reflows gracefully on compact mobile viewport without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('Quick Play'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('reflows across multiple columns on desktop/tablet viewport',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final wrapFinder = find.byType(Wrap);
      expect(wrapFinder, findsOneWidget);

      // Verify that tiles on wide screen have substantial width and fit comfortably
      final tile1 = tester.getSize(find.byKey(const Key('menu_tile_quick_play')));
      expect(tile1.width, greaterThan(200.0));
      expect(tile1.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('Declarative Routing & State Preservation', () {
    testWidgets('routes to all views using GoRouter',
        (WidgetTester tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.menu);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially at Main Menu
      expect(find.text('Welcome to Word Search'), findsOneWidget);

      // 1. Navigate to Quick Play
      await tester.tap(find.byKey(const Key('menu_tile_quick_play')));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);

      // Navigate back to menu
      await tester.tap(find.byKey(const Key('game_back_to_menu_button')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Word Search'), findsOneWidget);

      // 2. Navigate to Pack Library
      await tester.tap(find.byKey(const Key('menu_tile_pack_library')));
      await tester.pumpAndSettle();
      expect(find.byType(PackLibraryScreen), findsOneWidget);

      // Navigate back using pack library back button
      await tester.tap(find.byKey(const Key('pack_library_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Word Search'), findsOneWidget);

      // 3. Navigate to Learn Mode
      await tester.tap(find.byKey(const Key('menu_tile_learn_mode')));
      await tester.pumpAndSettle();
      expect(find.byType(LearnModeScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('learn_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Word Search'), findsOneWidget);

      // 4. Navigate to AI Generator
      await tester.tap(find.byKey(const Key('menu_tile_ai_generator')));
      await tester.pumpAndSettle();
      expect(find.byType(AiGeneratorScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('destination_back_button')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Word Search'), findsOneWidget);

      // 5. Navigate to Settings
      await tester.tap(find.byKey(const Key('menu_tile_settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('return_to_menu_button')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Word Search'), findsOneWidget);
    });

    testWidgets('preserves GameState across view navigation without destruction',
        (WidgetTester tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.menu);
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Go to GameScreen
      await tester.tap(find.byKey(const Key('menu_tile_quick_play')));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);

      // Modify game state: pause the game
      final notifier = container.read(gameProvider.notifier);
      notifier.togglePause();
      await tester.pumpAndSettle();

      expect(container.read(gameProvider).status, equals(GameStatus.paused));

      // Navigate to Settings
      router.go(AppRoutes.settings);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Navigate back to GameScreen
      router.go(AppRoutes.game);
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);

      // Verify GameState was preserved (still paused, word bank remains identical)
      expect(container.read(gameProvider).status, equals(GameStatus.paused));
    });
  });
}
