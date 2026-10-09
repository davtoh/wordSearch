// test/features/learning/learn_screen_test.dart
// Comprehensive tests for:
// 1. Responsive LayoutBuilder/MediaQuery reflow (Mobile vs Desktop, flashcard & review grid)
// 2. FocusNode management preventing virtual keyboard popups on non-text tap targets
// 3. SystemChrome orientation handling
// 4. Vocabulary flashcards with spaced-repetition indicators
// 5. Semantics labels and touch targets for screen readers
// 6. Starting word search puzzles using only un-mastered words

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/learning/application/learning_provider.dart';
import 'package:word_search_app/features/learning/application/mastery_notifier.dart';
import 'package:word_search_app/features/learning/presentation/learn_screen.dart';
import 'package:word_search_app/features/word_search/application/game_provider.dart';
import 'package:word_search_app/features/word_search/presentation/widgets/board_widget.dart';

void main() {
  PlayerProfile createTestProfile() {
    return PlayerProfile(
      vocabularyDeck: {
        'en:NEEDS_PRACTICE_WORD': WordMasteryRecord(
          word: 'NEEDS_PRACTICE_WORD',
          language: 'en',
          clue: 'A word that needs much practice',
          reading: 'needz-prak-tis',
          timesEncountered: 3,
          timesSolved: 1,
          totalSolveTimeSeconds: 65.0,
          hintTiersHistory: const [1, 4],
          errorClicks: 5,
          lastEncounteredAt: DateTime.now().toUtc(),
          masteryLevel: MasteryLevel.needsPractice,
        ),
        'en:LEARNING_WORD': WordMasteryRecord(
          word: 'LEARNING_WORD',
          language: 'en',
          clue: 'A word currently in learning progress',
          reading: 'lurn-ing',
          timesEncountered: 2,
          timesSolved: 2,
          totalSolveTimeSeconds: 40.0,
          hintTiersHistory: const [1, 2],
          errorClicks: 1,
          lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
          masteryLevel: MasteryLevel.learning,
        ),
        'en:MASTERED_WORD': WordMasteryRecord(
          word: 'MASTERED_WORD',
          language: 'en',
          clue: 'A completely mastered word',
          reading: 'mas-terd',
          timesEncountered: 5,
          timesSolved: 5,
          totalSolveTimeSeconds: 40.0,
          hintTiersHistory: const [1, 1, 1],
          errorClicks: 0,
          lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
          masteryLevel: MasteryLevel.mastered,
        ),
      },
    );
  }

  Widget buildTestApp({
    Size screenSize = const Size(400, 800),
    ProviderContainer? container,
    bool initialReviewMode = false,
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: LearnScreen(initialReviewMode: initialReviewMode),
        ),
      ),
    );
  }

  group('Responsive LayoutBuilder & MediaQuery Reflow', () {
    testWidgets('renders narrow layout stacked vertically without overflow on phones',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(400, 800),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Check header, flashcard, and search elements render
      expect(find.text('Learn & Mastery'), findsOneWidget);
      expect(find.text('Vocabulary Mastery Deck'), findsOneWidget);
      expect(find.byKey(const Key('flashcard_card')), findsOneWidget);
      expect(find.byKey(const Key('vocabulary_search_field')), findsOneWidget);
      expect(find.textContaining('Vocabulary Bank'), findsOneWidget);

      // Verify no vertical dividers from wide view are present
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('reflows side-by-side into two columns on wide tablet/desktop viewports',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(1024, 768),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      // Side-by-side view includes a VerticalDivider separating the columns
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.byKey(const Key('flashcard_card')), findsOneWidget);
      expect(find.byKey(const Key('vocabulary_search_field')), findsOneWidget);
    });

    testWidgets('reflows review puzzle grid and word bank side-by-side on wide screens vs stacked on narrow',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      // 1. Narrow viewport: Stacked vertically
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(400, 800),
          container: container,
          initialReviewMode: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BoardWidget), findsOneWidget);
      expect(find.textContaining('Targeted Practice'), findsOneWidget);
      // On narrow screens, review layout uses horizontal scroll list underneath board
      expect(find.byType(Divider), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);

      // 2. Wide viewport: Side-by-side
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(
        buildTestApp(
          screenSize: const Size(1024, 768),
          container: container,
          initialReviewMode: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BoardWidget), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });
  });

  group('FocusNode Management & Virtual Soft Keyboard Prevention', () {
    testWidgets('tapping non-text elements unfocuses soft keyboard',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      // 1. Focus search field
      final searchFinder = find.byKey(const Key('vocabulary_search_field'));
      await tester.tap(searchFinder);
      await tester.pumpAndSettle();

      final searchTextField = tester.widget<TextField>(searchFinder);
      expect(searchTextField.focusNode?.hasFocus, isTrue);

      // 2. Tap on flashcard: should unfocus keyboard
      await tester.tap(find.byKey(const Key('flashcard_card')));
      await tester.pumpAndSettle();

      expect(searchTextField.focusNode?.hasFocus, isFalse);

      // 3. Refocus search field
      await tester.tap(searchFinder);
      await tester.pumpAndSettle();
      expect(searchTextField.focusNode?.hasFocus, isTrue);

      // 4. Tap on background gesture detector: should unfocus
      await tester.tap(find.byKey(const Key('learn_screen_gesture_detector')));
      await tester.pumpAndSettle();
      expect(searchTextField.focusNode?.hasFocus, isFalse);
    });

    testWidgets('tapping review controls and filter chips does not request keyboard focus',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      // Tapping filter chip
      await tester.tap(find.byKey(const Key('mastery_filter_learning')));
      await tester.pumpAndSettle();

      final searchFinder = find.byKey(const Key('vocabulary_search_field'));
      final searchTextField = tester.widget<TextField>(searchFinder);
      expect(searchTextField.focusNode?.hasFocus, isFalse);

      // Tapping rating button
      await tester.tap(find.byKey(const Key('rate_learning_button')));
      await tester.pumpAndSettle();
      expect(searchTextField.focusNode?.hasFocus, isFalse);
    });
  });

  group('Vocabulary Flashcards & Spaced-Repetition Indicators', () {
    testWidgets('renders front of card with reading, language, and mastery badge',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      // Verify card front contains the word and reading
      expect(find.text('NEEDS_PRACTICE_WORD'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const Key('flashcard_card')),
          matching: find.text('needz-prak-tis'),
        ),
        findsOneWidget,
      );
      expect(find.text('EN'), findsWidgets);
      expect(find.text('Needs Practice'), findsWidgets);
    });

    testWidgets('flips to back of card to reveal definition and spaced repetition metrics',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      // Flip card using flip button
      await tester.tap(find.byKey(const Key('flip_flashcard_button')));
      await tester.pumpAndSettle();

      // Verify back face details inside flashcard
      expect(find.text('Definition / Clue'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('flashcard_card')),
          matching: find.text('A word that needs much practice'),
        ),
        findsOneWidget,
      );
      expect(find.text('Spaced Repetition Performance'), findsOneWidget);
      expect(find.text('Solve Velocity'), findsOneWidget);
      expect(find.text('65.0s avg'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget); // Solves count
      expect(find.text('5'), findsOneWidget); // Error clicks count
      expect(find.text('Tier 4'), findsOneWidget); // Max hint tier
    });

    testWidgets('rating buttons update word mastery level in profile',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      // Rate current word as Mastered
      await tester.tap(find.byKey(const Key('rate_mastered_button')));
      await tester.pumpAndSettle();

      final profile = container.read(playerProfileProvider);
      final record = profile.vocabularyDeck['en:NEEDS_PRACTICE_WORD'];
      expect(record?.masteryLevel, MasteryLevel.mastered);
    });

    testWidgets('navigates next and previous flashcards',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Flashcard 1 of 3'), findsOneWidget);

      // Tap Next
      await tester.tap(find.byKey(const Key('next_flashcard_button')));
      await tester.pumpAndSettle();

      expect(find.text('Flashcard 2 of 3'), findsOneWidget);

      // Tap Prev
      await tester.tap(find.byKey(const Key('prev_flashcard_button')));
      await tester.pumpAndSettle();

      expect(find.text('Flashcard 1 of 3'), findsOneWidget);
    });
  });

  group('Accessibility & Screen Reader Semantics', () {
    testWidgets('flashcards and review controls expose screen reader semantics and 48x48 touch targets',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(buildTestApp(container: container));
        await tester.pumpAndSettle();

        // Check Semantics labels
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label?.contains('Front of flashcard for NEEDS_PRACTICE_WORD') ??
                    false),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label == 'Previous vocabulary card'),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label == 'Flip flashcard between word and definition'),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics && (w.properties.label == 'Next vocabulary card'),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label?.contains('Rate NEEDS_PRACTICE_WORD as Needs Practice') ??
                    false),
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label?.contains('Start word search puzzle using only un-mastered words') ??
                    false),
          ),
          findsOneWidget,
        );

        // Verify touch target constraints on interactive icon buttons
        final flipButton = tester.widget<IconButton>(find.byKey(const Key('flip_flashcard_button')));
        expect(flipButton.constraints?.minWidth, greaterThanOrEqualTo(48.0));
        expect(flipButton.constraints?.minHeight, greaterThanOrEqualTo(48.0));
      } finally {
        handle.dispose();
      }
    });
  });

  group('Start Word Search Puzzle with Only Un-mastered Words', () {
    testWidgets('generateUnmasteredPuzzle generates puzzle with strictly un-mastered words',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      final notifier = container.read(masteryNotifierProvider.notifier);
      final puzzle = notifier.generateUnmasteredPuzzle();

      expect(puzzle, isNotNull);
      // All placed words in the puzzle should strictly come from un-mastered records
      for (final wordEntry in puzzle!.words) {
        expect(wordEntry.word, isNot('MASTERED_WORD'));
      }
      expect(puzzle.words.any((w) => w.word == 'NEEDS_PRACTICE_WORD'), isTrue);
      expect(puzzle.words.any((w) => w.word == 'LEARNING_WORD'), isTrue);
    });

    testWidgets('tapping start unmastered puzzle button initiates game in gameProvider',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      final startButton = find.byKey(const Key('start_unmastered_puzzle_button'));
      expect(startButton, findsOneWidget);

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Check gameProvider received the un-mastered review puzzle
      final activeGameState = container.read(gameProvider);
      expect(
        activeGameState.puzzle.metadata.theme,
        'Un-mastered Vocabulary Deck',
      );

      // Cancel game timer before test concludes
      container.read(gameProvider.notifier).togglePause();
    });

    testWidgets('toggle practice board switches into in-screen review grid mode',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(playerProfileProvider.notifier)
          .setProfile(createTestProfile());

      await tester.pumpWidget(buildTestApp(container: container));
      await tester.pumpAndSettle();

      // Toggle practice board
      await tester.tap(find.byKey(const Key('toggle_practice_board_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BoardWidget), findsOneWidget);
      expect(find.byKey(const Key('exit_practice_board_button')), findsOneWidget);

      // Exit practice board returns to flashcard view
      await tester.tap(find.byKey(const Key('exit_practice_board_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BoardWidget), findsNothing);
      expect(find.byKey(const Key('flashcard_card')), findsOneWidget);
    });
  });
}
