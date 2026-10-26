import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_search_app/core/engine/grid_engine.dart';
import 'package:word_search_app/core/storage/app_storage.dart';
import 'package:word_search_app/features/navigation/presentation/main_menu_screen.dart';
import 'package:word_search_app/features/packs/presentation/pack_library_screen.dart';
import 'package:word_search_app/features/word_search/application/game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStorage unit tests', () {
    late SharedPreferences prefs;
    late AppStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = AppStorage(initialPrefs: prefs);
    });

    test('persists and loads custom API key', () async {
      expect(await storage.loadCustomApiKey(), isNull);

      await storage.saveCustomApiKey('AIzaSyCustomKeyTest123');
      expect(await storage.loadCustomApiKey(), 'AIzaSyCustomKeyTest123');

      await storage.saveCustomApiKey(null);
      expect(await storage.loadCustomApiKey(), isNull);
    });

    test('persists and loads selected Gemini model', () async {
      expect(await storage.loadSelectedModel(), isNull);

      await storage.saveSelectedModel('gemini-3.8-flash');
      expect(await storage.loadSelectedModel(), 'gemini-3.8-flash');
    });

    test('persists and loads active game session', () async {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: [
          {'word': 'PLANET', 'clue': 'Celestial body'},
          {'word': 'ORBIT', 'clue': 'Path'},
        ],
        title: 'Space Test',
      );

      final container = ProviderContainer(
        overrides: [
          appStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(puzzle);

      // Verify game was persisted
      final loaded = await storage.loadActiveGame();
      expect(loaded, isNotNull);
      expect(loaded!.puzzle.title, 'Space Test');
      expect(loaded.puzzle.words.length, 2);
    });

    test('clears active game when puzzle is completed', () async {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: [
          {'word': 'SUN', 'clue': 'Star'},
        ],
        title: 'Sun Puzzle',
      );

      final container = ProviderContainer(
        overrides: [
          appStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(puzzle, autoStartTimer: false);

      // Mark the single word found to complete
      final sunWord = container.read(gameProvider).puzzle.words.first;
      notifier.checkSelection(sunWord.coords.first, sunWord.coords.last);

      // Allow async persistence to finish
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Game is completed; active session should be cleared
      final loaded = await storage.loadActiveGame();
      expect(loaded, isNull);
    });

    test('puzzleToPackJson formats standard pack JSON schema', () {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: [
          {'word': 'GALAXY', 'clue': 'System of stars'},
        ],
        title: 'Cosmos',
      );

      final packJson = storage.puzzleToPackJson(puzzle);
      expect(packJson['title'], 'Cosmos');
      expect(packJson['puzzles'], isList);
      expect((packJson['puzzles'] as List).length, 1);
    });
  });

  group('MainMenuScreen Resume Game Card widget tests', () {
    testWidgets('displays resume game card when active game has progress',
        (tester) async {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: [
          {'word': 'COMET', 'clue': 'Icy body'},
          {'word': 'MOON', 'clue': 'Satellite'},
        ],
        title: 'Active Space Mission',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initialize game and mark one word found (without running background timer)
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(puzzle, autoStartTimer: false);
      final cometWord = container.read(gameProvider).puzzle.words.first;
      notifier.checkSelection(cometWord.coords.first, cometWord.coords.last);

      String? navigatedRoute;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MainMenuScreen(
              onNavigate: (route) => navigatedRoute = route,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('resume_game_card')), findsOneWidget);
      expect(find.text('Active Space Mission'), findsOneWidget);
      expect(find.text('1 / 2 words'), findsOneWidget);
      expect(find.byKey(const Key('resume_game_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('resume_game_button')));
      await tester.pumpAndSettle();

      expect(navigatedRoute, '/game');
    });
  });

  group('PackLibraryScreen Export Dialog enhancements', () {
    testWidgets('export dialog offers Copy, Save to Library, and Save to Device',
        (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('app_storage_export_test_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          try {
            tempDir.deleteSync(recursive: true);
          } catch (_) {}
        }
      });
      final testStorage = AppStorage(customPuzzlesDirectory: tempDir);

      final container = ProviderContainer(
        overrides: [
          appStorageProvider.overrideWithValue(testStorage),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PackLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Export Active Puzzle
      await tester.tap(find.byKey(const Key('export_active_puzzle_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('copy_json_button')), findsOneWidget);
      expect(find.byKey(const Key('save_internal_button')), findsOneWidget);
      expect(find.byKey(const Key('save_device_button')), findsOneWidget);

      // Tap Save to App Library
      await tester.tap(find.byKey(const Key('save_internal_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Saved to app folder! Puzzle is now in your Pack Library.'),
          findsOneWidget);
    });
  });
}
