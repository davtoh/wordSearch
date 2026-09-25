// test/features/word_search/game_provider_test.dart
// Comprehensive tests for GameNotifier, drag selections, line interpolation, timers, and win states.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/engine/grid_engine.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/word_search/application/game_provider.dart';

void main() {
  late ProviderContainer container;
  late Puzzle testPuzzle;

  setUp(() {
    container = ProviderContainer();

    // Create a predictable puzzle with fixed words
    testPuzzle = GridEngine.generatePuzzle(
      wordsData: const [
        {'word': 'CAT', 'clue': 'A feline friend'},
        {'word': 'DOG', 'clue': 'A canine companion'},
        {'word': 'FISH', 'clue': 'Swims in water'},
      ],
      title: 'Pets Puzzle',
      difficulty: Difficulty.easy,
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('GameNotifier Initialization', () {
    test('builds initial state with default puzzle and casual mode', () {
      final state = container.read(gameProvider);
      expect(state.status, GameStatus.playing);
      expect(state.mode, GameMode.casual);
      expect(state.foundWords, isEmpty);
      expect(state.foundCoordsMap, isEmpty);
      expect(state.puzzle.words.isNotEmpty, isTrue);
    });

    test('initGame initializes specified puzzle and mode without auto-timer in tests', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, mode: GameMode.timedAttack, autoStartTimer: false);

      final state = container.read(gameProvider);
      expect(state.puzzle.metadata.title, 'Pets Puzzle');
      expect(state.mode, GameMode.timedAttack);
      expect(state.status, GameStatus.playing);
      expect(state.timeRemaining, testPuzzle.assistConfig.timeLimitSeconds.toDouble());
    });
  });

  group('Line Interpolation & Drag Geometry', () {
    test('interpolates horizontal line from left to right', () {
      final state = container.read(gameProvider);
      final line = state.interpolateLine((2, 1), (2, 4));
      expect(line, [(2, 1), (2, 2), (2, 3), (2, 4)]);
    });

    test('interpolates horizontal line from right to left (reverse)', () {
      final state = container.read(gameProvider);
      final line = state.interpolateLine((2, 4), (2, 1));
      expect(line, [(2, 4), (2, 3), (2, 2), (2, 1)]);
    });

    test('interpolates vertical line downwards', () {
      final state = container.read(gameProvider);
      final line = state.interpolateLine((0, 3), (3, 3));
      expect(line, [(0, 3), (1, 3), (2, 3), (3, 3)]);
    });

    test('interpolates true diagonal line', () {
      final state = container.read(gameProvider);
      final line = state.interpolateLine((1, 1), (4, 4));
      expect(line, [(1, 1), (2, 2), (3, 3), (4, 4)]);
    });

    test('single cell tap returns single coordinate', () {
      final state = container.read(gameProvider);
      final line = state.interpolateLine((2, 2), (2, 2));
      expect(line, [(2, 2)]);
    });

    test('rejects non-straight angles (e.g. knight move)', () {
      final state = container.read(gameProvider);
      final line = state.interpolateLine((0, 0), (1, 2));
      expect(line, isEmpty);
    });

    test('rejects out of bounds coordinates', () {
      final state = container.read(gameProvider);
      final line = state.interpolateLine((-1, 0), (2, 0));
      expect(line, isEmpty);

      final line2 = state.interpolateLine((0, 0), (99, 99));
      expect(line2, isEmpty);
    });
  });

  group('Drag Selection & Word Matching', () {
    test('confirmSelection matches word in forward direction', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, autoStartTimer: false);

      final catWord = testPuzzle.words.firstWhere((w) => w.word == 'CAT');
      final start = catWord.coords.first;
      final end = catWord.coords.last;

      notifier.startSelection(start);
      notifier.updateSelection(end);

      final matched = notifier.confirmSelection();
      expect(matched, isTrue);

      final state = container.read(gameProvider);
      expect(state.foundWords.any((w) => w.word == 'CAT'), isTrue);
      expect(state.selectedCoords, isEmpty);

      for (final coord in catWord.coords) {
        expect(state.isCoordFound(coord), isTrue);
      }
    });

    test('confirmSelection matches word in reverse direction', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, autoStartTimer: false);

      final dogWord = testPuzzle.words.firstWhere((w) => w.word == 'DOG');
      final start = dogWord.coords.last; // reverse start
      final end = dogWord.coords.first;

      notifier.startSelection(start);
      notifier.updateSelection(end);

      final matched = notifier.confirmSelection();
      expect(matched, isTrue);

      final state = container.read(gameProvider);
      expect(state.foundWords.any((w) => w.word == 'DOG'), isTrue);
    });

    test('confirmSelection rejects incorrect selection', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, autoStartTimer: false);

      notifier.startSelection((0, 0));
      notifier.updateSelection((0, 1));

      // Assuming (0, 0) to (0, 1) is not CAT, DOG, or FISH (length 2 vs min length 3)
      final matched = notifier.confirmSelection();
      expect(matched, isFalse);

      final state = container.read(gameProvider);
      expect(state.selectedCoords, isEmpty);
    });

    test('checkSelection validates start and end coordinates directly', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, autoStartTimer: false);

      final fishWord = testPuzzle.words.firstWhere((w) => w.word == 'FISH');
      final (ok, entry, coords) = notifier.checkSelection(
        fishWord.coords.first,
        fishWord.coords.last,
      );

      expect(ok, isTrue);
      expect(entry?.word, 'FISH');
      expect(coords, fishWord.coords);
    });

    test('winning condition transitions state to won', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, autoStartTimer: false);

      for (final word in testPuzzle.words) {
        notifier.startSelection(word.coords.first);
        notifier.updateSelection(word.coords.last);
        notifier.confirmSelection();
      }

      final state = container.read(gameProvider);
      expect(state.status, GameStatus.won);
      expect(state.isComplete, isTrue);
      expect(state.progress, 1.0);
    });
  });

  group('Timers & Countdown Logic', () {
    test('tick increments totalElapsedSeconds in casual mode', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, mode: GameMode.casual, autoStartTimer: false);

      notifier.tick(1.5);
      final state = container.read(gameProvider);
      expect(state.totalElapsedSeconds, 1.5);
    });

    test('tick decrements timeRemaining in timedAttack mode', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, mode: GameMode.timedAttack, autoStartTimer: false);

      final initialRemaining = container.read(gameProvider).timeRemaining;
      notifier.tick(2.0);

      final state = container.read(gameProvider);
      expect(state.timeRemaining, initialRemaining - 2.0);
      expect(state.totalElapsedSeconds, 2.0);
      expect(state.status, GameStatus.playing);
    });

    test('timer expiration triggers GameStatus.timeOut', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, mode: GameMode.timedAttack, autoStartTimer: false);

      // Tick past the time limit
      notifier.tick(300.0);

      final state = container.read(gameProvider);
      expect(state.status, GameStatus.timeOut);
      expect(state.timeRemaining, 0.0);
    });

    test('finding a word in timedAttack awards bonus time', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, mode: GameMode.timedAttack, autoStartTimer: false);

      notifier.tick(10.0);
      final remainingBefore = container.read(gameProvider).timeRemaining;

      final catWord = testPuzzle.words.firstWhere((w) => w.word == 'CAT');
      notifier.startSelection(catWord.coords.first);
      notifier.updateSelection(catWord.coords.last);
      notifier.confirmSelection();

      final state = container.read(gameProvider);
      expect(state.timeRemaining, remainingBefore + state.bonusPerWord);
    });
  });

  group('Session Controls (Pause, Give Up, Reset)', () {
    test('togglePause switches between playing and paused', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, autoStartTimer: false);

      final paused = notifier.togglePause();
      expect(paused, isTrue);
      expect(container.read(gameProvider).status, GameStatus.paused);

      final resumed = notifier.togglePause();
      expect(resumed, isFalse);
      expect(container.read(gameProvider).status, GameStatus.playing);
    });

    test('giveUp sets givenUp status and reveals all coordinates', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, autoStartTimer: false);

      notifier.giveUp();

      final state = container.read(gameProvider);
      expect(state.status, GameStatus.givenUp);
      expect(state.revealedAllOnGiveUp, isTrue);

      for (final w in testPuzzle.words) {
        for (final coord in w.coords) {
          expect(state.foundCoordsMap.containsKey(coord), isTrue);
        }
      }
    });

    test('resetGame resets all found words and timer', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.initGame(testPuzzle, autoStartTimer: false);

      final catWord = testPuzzle.words.firstWhere((w) => w.word == 'CAT');
      notifier.startSelection(catWord.coords.first);
      notifier.updateSelection(catWord.coords.last);
      notifier.confirmSelection();

      notifier.resetGame(autoStartTimer: false);

      final state = container.read(gameProvider);
      expect(state.foundWords, isEmpty);
      expect(state.foundCoordsMap, isEmpty);
      expect(state.totalElapsedSeconds, 0.0);
      expect(state.status, GameStatus.playing);
    });
  });
}
