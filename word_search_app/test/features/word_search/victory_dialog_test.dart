// test/features/word_search/victory_dialog_test.dart
// Unit and Widget tests for VictoryDialog and post-game modal sheet integration.
// Verifies elapsed time, words found count, hint stats, quick actions,
// automated GameState.isCompleted trigger in GameScreen, and accessibility.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/learning/application/learning_provider.dart';
import 'package:word_search_app/features/word_search/application/game_provider.dart';
import 'package:word_search_app/features/word_search/domain/game_state.dart';
import 'package:word_search_app/features/word_search/presentation/game_screen.dart';
import 'package:word_search_app/features/word_search/presentation/widgets/victory_dialog.dart';

void main() {
  // Helper to build a completed mock puzzle
  Puzzle createCompletedPuzzle({
    int hintWordsCount = 0,
    int totalWords = 3,
  }) {
    final words = <WordEntry>[];
    for (int i = 0; i < totalWords; i++) {
      final hintTier =
          i < hintWordsCount ? HintTier.tier2WordName : HintTier.none;
      words.add(
        WordEntry(
          word: 'WORD$i',
          clue: 'Clue for WORD$i',
          coords: [(i, 0), (i, 1), (i, 2), (i, 3), (i, 4)],
          found: true,
          hintTierUsed: hintTier,
        ),
      );
    }

    return Puzzle(
      metadata: PuzzleMetadata(
        id: 'test_puzzle',
        title: 'Vocabulary Challenge',
        theme: 'Education',
        difficulty: Difficulty.medium,
      ),
      rows: 10,
      cols: 10,
      grid: List.generate(10, (_) => List.generate(10, (_) => 'A')),
      words: words,
    );
  }

  // Helper to build a completed GameState
  GameState createCompletedGameState({
    double elapsedSeconds = 85.0,
    int hintWordsCount = 0,
    int totalWords = 3,
  }) {
    final puzzle = createCompletedPuzzle(
      hintWordsCount: hintWordsCount,
      totalWords: totalWords,
    );

    return GameState(
      puzzle: puzzle,
      foundWords: puzzle.words,
      foundCoordsMap: {
        for (final w in puzzle.words)
          for (final c in w.coords) c: w.word,
      },
      status: GameStatus.won,
      totalElapsedSeconds: elapsedSeconds,
    );
  }

  Widget createTestWidget({
    required Widget child,
    ProviderContainer? container,
    Size screenSize = const Size(400, 800),
    double fontScale = 1.0,
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize,
            textScaler: TextScaler.linear(fontScale),
          ),
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  group('VictoryDialog Widget UI & Stats Presentation', () {
    testWidgets('renders celebration header, title, and puzzle metadata',
        (WidgetTester tester) async {
      final gameState = createCompletedGameState(elapsedSeconds: 75.0);

      await tester.pumpWidget(
        createTestWidget(
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      // Check modal sheet container
      expect(find.byKey(const Key('victory_modal_sheet')), findsOneWidget);

      // Check celebration icon and text
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      expect(find.text('Puzzle Completed!'), findsOneWidget);
      expect(find.textContaining('Vocabulary Challenge • Medium'), findsOneWidget);
    });

    testWidgets('displays accurate elapsed time, words found count, and zero hints',
        (WidgetTester tester) async {
      // 85 seconds = 01:25
      final gameState = createCompletedGameState(
        elapsedSeconds: 85.0,
        hintWordsCount: 0,
        totalWords: 4,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      // Time elapsed stat
      expect(find.byKey(const Key('victory_time_elapsed_stat')), findsOneWidget);
      expect(find.text('01:25'), findsOneWidget);
      expect(find.text('Time Elapsed'), findsOneWidget);

      // Words found count stat
      expect(find.byKey(const Key('victory_words_found_stat')), findsOneWidget);
      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.text('Words Found'), findsOneWidget);

      // Hint usage stat with 0 hints
      expect(find.byKey(const Key('victory_hints_used_stat')), findsOneWidget);
      expect(find.text('0 (None)'), findsOneWidget);
      expect(find.text('Hint Usage'), findsOneWidget);
    });

    testWidgets('displays accurate hint usage stats when hints were used',
        (WidgetTester tester) async {
      final gameState = createCompletedGameState(
        elapsedSeconds: 150.0,
        hintWordsCount: 2,
        totalWords: 5,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 used'), findsOneWidget);
      expect(find.text('5 / 5'), findsOneWidget);
      expect(find.text('02:30'), findsOneWidget);
    });

    testWidgets('renders discovered word chips in wrap layout',
        (WidgetTester tester) async {
      final gameState = createCompletedGameState(totalWords: 3);

      await tester.pumpWidget(
        createTestWidget(
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discovered Words (3)'), findsOneWidget);
      expect(find.text('WORD0'), findsOneWidget);
      expect(find.text('WORD1'), findsOneWidget);
      expect(find.text('WORD2'), findsOneWidget);
    });
  });

  group('Victory Quick Actions', () {
    testWidgets('Play Again action invokes custom callback',
        (WidgetTester tester) async {
      bool playAgainCalled = false;
      final gameState = createCompletedGameState();

      await tester.pumpWidget(
        createTestWidget(
          child: VictoryDialog(
            gameState: gameState,
            onPlayAgain: () {
              playAgainCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final playAgainBtn = find.byKey(const Key('victory_play_again_button'));
      expect(playAgainBtn, findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);

      await tester.tap(playAgainBtn);
      await tester.pumpAndSettle();

      expect(playAgainCalled, isTrue);
    });

    testWidgets('Play Again default action resets game state in gameProvider',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final gameState = createCompletedGameState();
      container.read(gameProvider.notifier).initGame(
            gameState.puzzle,
            autoStartTimer: false,
          );

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      final playAgainBtn = find.byKey(const Key('victory_play_again_button'));
      await tester.tap(playAgainBtn);
      await tester.pumpAndSettle();

      final state = container.read(gameProvider);
      expect(state.status, GameStatus.playing);
      expect(state.foundWords, isEmpty);

      // Cancel timer started by resetGame so fake_async doesn't complain of pending timer
      container.read(gameProvider.notifier).pauseTimer();
    });

    testWidgets('Return to Main Menu action invokes custom callback',
        (WidgetTester tester) async {
      bool menuCalled = false;
      final gameState = createCompletedGameState();

      await tester.pumpWidget(
        createTestWidget(
          child: VictoryDialog(
            gameState: gameState,
            onReturnToMainMenu: () {
              menuCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final menuBtn = find.byKey(const Key('victory_main_menu_button'));
      expect(menuBtn, findsOneWidget);
      expect(find.text('Return to Main Menu'), findsOneWidget);

      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      expect(menuCalled, isTrue);
    });

    testWidgets(
        'Add Words to Learn Deck populates player vocabulary deck and shows feedback',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final gameState = createCompletedGameState(totalWords: 3);

      await tester.pumpWidget(
        createTestWidget(
          container: container,
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      final addBtn = find.byKey(const Key('victory_add_to_learn_deck_button'));
      expect(addBtn, findsOneWidget);
      expect(find.text('Add Words to Learn Deck'), findsOneWidget);

      // Initially vocabulary deck in profile is empty
      final initialProfile = container.read(playerProfileProvider);
      expect(initialProfile.vocabularyDeck.isEmpty, isTrue);

      // Tap to add words
      await tester.tap(addBtn);
      await tester.pump();

      // Verify button updates state to added
      expect(find.text('Added to Learn Deck'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Verify SnackBar appears
      expect(find.text('Words added to Learn Deck!'), findsOneWidget);

      // Verify vocabulary deck was populated in playerProfileProvider
      final updatedProfile = container.read(playerProfileProvider);
      expect(updatedProfile.vocabularyDeck.length, 3);
      expect(updatedProfile.vocabularyDeck.containsKey('en:WORD0'), isTrue);
      expect(updatedProfile.vocabularyDeck.containsKey('en:WORD1'), isTrue);
      expect(updatedProfile.vocabularyDeck.containsKey('en:WORD2'), isTrue);
    });
  });

  group('Modal Bottom Sheet & GameScreen Integration', () {
    testWidgets('showVictoryModalSheet presents bottom sheet dialog over context',
        (WidgetTester tester) async {
      final gameState = createCompletedGameState();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    key: const Key('open_sheet_button'),
                    onPressed: () {
                      showVictoryModalSheet(
                        context: context,
                        gameState: gameState,
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap open button
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Verify VictoryDialog inside bottom sheet
      expect(find.byType(VictoryDialog), findsOneWidget);
      expect(find.byKey(const Key('victory_modal_sheet')), findsOneWidget);
      expect(find.text('Puzzle Completed!'), findsOneWidget);
    });

    testWidgets('GameScreen automatically triggers Victory Modal on GameState.isCompleted',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Start with uncompleted puzzle
      final puzzle = Puzzle(
        metadata: PuzzleMetadata(
          id: 'p1',
          title: 'Demo Puzzle',
          theme: 'General',
          difficulty: Difficulty.easy,
        ),
        rows: 5,
        cols: 5,
        grid: List.generate(5, (_) => List.generate(5, (_) => 'A')),
        words: const [
          WordEntry(
            word: 'TEST',
            coords: [(0, 0), (0, 1), (0, 2), (0, 3)],
            found: false,
          ),
        ],
      );

      container.read(gameProvider.notifier).initGame(
            puzzle,
            autoStartTimer: false,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sheet should not be visible while playing
      expect(find.byType(VictoryDialog), findsNothing);

      // Now complete the puzzle by checking the selection of the only word
      container.read(gameProvider.notifier).checkSelection((0, 0), (0, 3));
      await tester.pumpAndSettle();

      // Modal Sheet should now be displayed automatically!
      expect(find.byType(VictoryDialog), findsOneWidget);
      expect(find.text('Puzzle Completed!'), findsOneWidget);
      expect(find.byKey(const Key('victory_play_again_button')), findsOneWidget);
    });

    testWidgets('Tapping HUD Completed text re-opens Victory Modal',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final puzzle = Puzzle(
        metadata: PuzzleMetadata(
          id: 'p2',
          title: 'Quick Puzzle',
          theme: 'General',
          difficulty: Difficulty.easy,
        ),
        rows: 5,
        cols: 5,
        grid: List.generate(5, (_) => List.generate(5, (_) => 'A')),
        words: const [
          WordEntry(
            word: 'TEST',
            coords: [(0, 0), (0, 1), (0, 2), (0, 3)],
            found: false,
          ),
        ],
      );

      container.read(gameProvider.notifier).initGame(
            puzzle,
            autoStartTimer: false,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Complete the word so it becomes won
      container.read(gameProvider.notifier).checkSelection((0, 0), (0, 3));
      await tester.pumpAndSettle();

      // Modal bottom sheet appears
      expect(find.byType(VictoryDialog), findsOneWidget);

      // Dismiss the modal sheet
      Navigator.of(tester.element(find.byType(VictoryDialog))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(VictoryDialog), findsNothing);

      // Tapping HUD completed button re-opens it
      final hudCompletedFinder =
          find.byKey(const Key('hud_victory_completed_button'));
      expect(hudCompletedFinder, findsOneWidget);

      await tester.tap(hudCompletedFinder);
      await tester.pumpAndSettle();

      expect(find.byType(VictoryDialog), findsOneWidget);
      expect(find.text('Puzzle Completed!'), findsOneWidget);
    });
  });

  group('Accessibility & Responsive Text Scaling', () {
    testWidgets('action buttons satisfy 48x48 dp minimum touch target',
        (WidgetTester tester) async {
      final gameState = createCompletedGameState();

      await tester.pumpWidget(
        createTestWidget(
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      final playAgainSize = tester.getSize(find.byKey(const Key('victory_play_again_button')));
      final deckSize = tester.getSize(find.byKey(const Key('victory_add_to_learn_deck_button')));
      final menuSize = tester.getSize(find.byKey(const Key('victory_main_menu_button')));

      expect(playAgainSize.height, greaterThanOrEqualTo(48.0));
      expect(playAgainSize.width, greaterThanOrEqualTo(48.0));

      expect(deckSize.height, greaterThanOrEqualTo(48.0));
      expect(deckSize.width, greaterThanOrEqualTo(48.0));

      expect(menuSize.height, greaterThanOrEqualTo(48.0));
      expect(menuSize.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('exposes screen reader semantics for victory summary and stats',
        (WidgetTester tester) async {
      final gameState = createCompletedGameState(
        elapsedSeconds: 90.0,
        hintWordsCount: 1,
        totalWords: 3,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp(r'Victory dialog\. Puzzle completed in 01:30 with 3 of 3 words found and 1 hints used\.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('adapts gracefully to 200% font scale without layout overflow',
        (WidgetTester tester) async {
      final gameState = createCompletedGameState(totalWords: 4);

      await tester.pumpWidget(
        createTestWidget(
          fontScale: 2.0, // 200% text scale
          child: VictoryDialog(gameState: gameState),
        ),
      );
      await tester.pumpAndSettle();

      // No assertion failure / RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('victory_modal_sheet')), findsOneWidget);
      expect(find.text('Puzzle Completed!'), findsOneWidget);
    });
  });
}
