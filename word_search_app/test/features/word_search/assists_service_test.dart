// test/features/word_search/assists_service_test.dart
// Comprehensive tests for the 6-tier progressive hint provider,
// proximity hot/cold radar, auto stall detector, and time bonus providers.

import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/engine/grid_engine.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/word_search/application/assists_service.dart';
import 'package:word_search_app/features/word_search/domain/game_state.dart';

void main() {
  late Puzzle testPuzzle;
  late GameState gameState;
  late AssistsService assistsService;

  setUp(() {
    testPuzzle = GridEngine.generatePuzzle(
      wordsData: const [
        {
          'word': 'CAT',
          'clue': 'A small domesticated carnivorous mammal',
          'reading': 'neko',
        },
        {
          'word': 'DOG',
          'clue': 'Man\'s best friend',
          'reading': 'inu',
        },
      ],
      title: 'Animals',
      difficulty: Difficulty.easy,
    );

    gameState = GameState.initial(testPuzzle);
    assistsService = AssistsService();
  });

  group('Progressive 6-Tier Hints', () {
    test('tier 1 returns clue definition', () {
      final hint1 = assistsService.requestHint(gameState, targetWord: 'CAT');
      expect(hint1, isNotNull);
      expect(hint1!.tier, HintTier.tier1Clue);
      expect(hint1.message, contains('A small domesticated carnivorous mammal'));
      expect(hint1.highlightCoords, isEmpty);
    });

    test('tier 2 reveals word name and reading', () {
      // Advance to tier 1
      final hint1 = assistsService.requestHint(gameState, targetWord: 'CAT')!;
      final state1 = gameState.copyWith(
        puzzle: gameState.puzzle.copyWith(
          words: [hint1.wordEntry, gameState.puzzle.words[1]],
        ),
      );

      final hint2 = assistsService.requestHint(state1, targetWord: 'CAT');
      expect(hint2, isNotNull);
      expect(hint2!.tier, HintTier.tier2WordName);
      expect(hint2.message, contains("Word: 'CAT' (3 letters)"));
      expect(hint2.message, contains('[Reading: neko]'));
    });

    test('tier 3 reveals first character and length', () {
      final w = gameState.puzzle.words[0].copyWith(hintTierUsed: HintTier.tier2WordName);
      final s = gameState.copyWith(puzzle: gameState.puzzle.copyWith(words: [w, gameState.puzzle.words[1]]));

      final hint3 = assistsService.requestHint(s, targetWord: 'CAT');
      expect(hint3!.tier, HintTier.tier3FirstLetter);
      expect(hint3.message, contains("Starts with 'C' (3 letters)"));
    });

    test('tier 4 reveals orientation direction', () {
      final w = gameState.puzzle.words[0].copyWith(hintTierUsed: HintTier.tier3FirstLetter);
      final s = gameState.copyWith(puzzle: gameState.puzzle.copyWith(words: [w, gameState.puzzle.words[1]]));

      final hint4 = assistsService.requestHint(s, targetWord: 'CAT');
      expect(hint4!.tier, HintTier.tier4Orientation);
      expect(hint4.message, contains('is placed'));
    });

    test('tier 5 reveals start coordinate and provides highlight', () {
      final w = gameState.puzzle.words[0].copyWith(hintTierUsed: HintTier.tier4Orientation);
      final s = gameState.copyWith(puzzle: gameState.puzzle.copyWith(words: [w, gameState.puzzle.words[1]]));

      final hint5 = assistsService.requestHint(s, targetWord: 'CAT');
      expect(hint5!.tier, HintTier.tier5StartCoordinate);
      expect(hint5.highlightCoords.length, 1);
      expect(hint5.highlightCoords.first, w.startCoord);
      expect(hint5.message, contains('starts at Row'));
    });

    test('tier 6 reveals full word glow path', () {
      final w = gameState.puzzle.words[0].copyWith(hintTierUsed: HintTier.tier5StartCoordinate);
      final s = gameState.copyWith(puzzle: gameState.puzzle.copyWith(words: [w, gameState.puzzle.words[1]]));

      final hint6 = assistsService.requestHint(s, targetWord: 'CAT');
      expect(hint6!.tier, HintTier.tier6FullGlow);
      expect(hint6.highlightCoords, w.coords);
      expect(hint6.message, contains('Revealing full path'));
    });

    test('returns null when all words are already found', () {
      final allFoundPuzzle = testPuzzle.copyWith(
        words: testPuzzle.words.map((w) => w.copyWith(found: true)).toList(),
      );
      final s = gameState.copyWith(puzzle: allFoundPuzzle);

      final hint = assistsService.requestHint(s);
      expect(hint, isNull);
    });
  });

  group('Proximity Radar Assist', () {
    test('returns BURNING when tapping directly on start coordinate', () {
      final catStart = testPuzzle.words[0].startCoord!;
      final feedback = assistsService.checkProximity(gameState, catStart);

      expect(feedback, isNotNull);
      expect(feedback!.status, 'BURNING');
      expect(feedback.distance, 0.0);
      expect(feedback.message, contains('Burning Hot'));
    });

    test('returns HOT or WARM when close to a start coordinate', () {
      final (r, c) = testPuzzle.words[0].startCoord!;
      // Offset by 1 row
      final targetRow = (r + 1 < testPuzzle.rows) ? r + 1 : r - 1;
      final feedback = assistsService.checkProximity(gameState, (targetRow, c));

      expect(feedback, isNotNull);
      expect(['BURNING', 'HOT', 'WARM'].contains(feedback!.status), isTrue);
    });

    test('returns COLD when far away', () {
      // Find maximum distance coordinate
      final (r, c) = testPuzzle.words[0].startCoord!;
      final farR = (r + 6) % testPuzzle.rows;
      final farC = (c + 6) % testPuzzle.cols;

      final feedback = assistsService.checkProximity(gameState, (farR, farC));
      expect(feedback, isNotNull);
      expect(feedback!.distance, greaterThan(0.0));
    });

    test('returns null when proximity assist is disabled in config', () {
      final disabledPuzzle = testPuzzle.copyWith(
        assistConfig: testPuzzle.assistConfig.copyWith(proximityEnabled: false),
      );
      final s = gameState.copyWith(puzzle: disabledPuzzle);

      final feedback = assistsService.checkProximity(s, (0, 0));
      expect(feedback, isNull);
    });
  });

  group('Auto Stall Detector', () {
    test('triggers alert when idle exceeds stall threshold', () {
      final detector = AutoStallDetector(stallThresholdSeconds: 10.0);
      final service = AssistsService(stallDetector: detector);

      final alertBefore = service.checkStall(gameState, 5.0);
      expect(alertBefore, isNull);

      final alertAfter = service.checkStall(gameState, 6.0); // total 11.0 >= 10.0
      expect(alertAfter, isNotNull);
      expect(alertAfter, contains('Need a hint?'));
    });

    test('notifyWordFound resets the stall clock', () {
      final detector = AutoStallDetector(stallThresholdSeconds: 10.0);
      final service = AssistsService(stallDetector: detector);

      service.checkStall(gameState, 8.0);
      service.notifyWordFound();

      // Another 5 seconds should not trigger (5 < 10)
      final alert = service.checkStall(gameState, 5.0);
      expect(alert, isNull);
    });
  });

  group('Time Bonus Provider', () {
    test('emergencyTimeBoost adds boost seconds in timedAttack mode', () {
      final timedState = gameState.copyWith(
        mode: GameMode.timedAttack,
        timeRemaining: 50.0,
      );

      final boosted = assistsService.emergencyTimeBoost(timedState, boostSeconds: 30.0);
      expect(boosted, 80.0);
    });

    test('emergencyTimeBoost does not modify time in casual mode', () {
      final casualState = gameState.copyWith(
        mode: GameMode.casual,
        timeRemaining: 100.0,
      );

      final boosted = assistsService.emergencyTimeBoost(casualState, boostSeconds: 30.0);
      expect(boosted, 100.0);
    });
  });
}

