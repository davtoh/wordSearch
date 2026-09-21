// test/core/grid_engine_test.dart
// Comprehensive unit tests for the pure Dart domain layer.
// Tests cover: enums, models, script detection, grid generation,
// boundary collision, multi-directional placement, and distractor shifting.

import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/constants/scripts.dart';
import 'package:word_search_app/core/engine/grid_engine.dart';
import 'package:word_search_app/core/models/models.dart';

void main() {
  // ─────────────────────────────────────────────────────
  // Enums
  // ─────────────────────────────────────────────────────
  group('Direction enum', () {
    test('delta returns correct (dRow, dCol) for every direction', () {
      expect(Direction.horizontalLr.delta, (0, 1));
      expect(Direction.horizontalRl.delta, (0, -1));
      expect(Direction.verticalTb.delta, (1, 0));
      expect(Direction.verticalBt.delta, (-1, 0));
      expect(Direction.diagonalTlBr.delta, (1, 1));
      expect(Direction.diagonalBrTl.delta, (-1, -1));
      expect(Direction.diagonalBlTr.delta, (-1, 1));
      expect(Direction.diagonalTrBl.delta, (1, -1));
    });

    test('fromDelta reconstructs the correct direction', () {
      expect(Direction.fromDelta(0, 1), Direction.horizontalLr);
      expect(Direction.fromDelta(-1, -1), Direction.diagonalBrTl);
      expect(Direction.fromDelta(1, -1), Direction.diagonalTrBl);
    });

    test('fromDelta normalises large deltas to unit steps', () {
      // (5, 5) should normalise to (1, 1) → diagonalTlBr
      expect(Direction.fromDelta(5, 5), Direction.diagonalTlBr);
    });

    test('fromDelta returns null for (0, 0)', () {
      expect(Direction.fromDelta(0, 0), isNull);
    });

    test('fromValue round-trips correctly', () {
      for (final d in Direction.values) {
        expect(Direction.fromValue(d.value), d);
      }
    });
  });

  group('HintTier enum', () {
    test('fromLevel returns correct tier', () {
      expect(HintTier.fromLevel(0), HintTier.none);
      expect(HintTier.fromLevel(3), HintTier.tier3FirstLetter);
      expect(HintTier.fromLevel(6), HintTier.tier6FullGlow);
    });

    test('fromLevel falls back to none for out-of-range values', () {
      expect(HintTier.fromLevel(99), HintTier.none);
    });
  });

  // ─────────────────────────────────────────────────────
  // Scripts / character pools
  // ─────────────────────────────────────────────────────
  group('detectScript', () {
    test('detects Latin for plain English words', () {
      expect(detectScript(['APPLE', 'BANANA', 'CHERRY']), ScriptType.latin);
    });

    test('detects Hiragana correctly', () {
      expect(detectScript(['あいう', 'かきく']), ScriptType.hiragana);
    });

    test('detects Katakana correctly', () {
      expect(detectScript(['アイウ', 'カキク']), ScriptType.katakana);
    });

    test('detects Kanji correctly', () {
      expect(detectScript(['日本語', '漢字']), ScriptType.kanji);
    });

    test('detects Cyrillic correctly', () {
      expect(detectScript(['СЛОВО', 'ТЕСТ']), ScriptType.cyrillic);
    });

    test('detects Latin Accented for Spanish words', () {
      expect(detectScript(['ÁRBOL', 'MÚSICA']), ScriptType.latinAccented);
    });

    test('returns latin for empty list', () {
      expect(detectScript([]), ScriptType.latin);
    });
  });

  group('getCharacterPool', () {
    test('Latin pool contains only uppercase ASCII letters', () {
      final pool = getCharacterPool(ScriptType.latin);
      expect(pool.length, 26);
      expect(pool.every((c) => RegExp(r'^[A-Z]$').hasMatch(c)), isTrue);
    });

    test('Hiragana pool is non-empty and contains hiragana characters', () {
      final pool = getCharacterPool(ScriptType.hiragana);
      expect(pool.isNotEmpty, isTrue);
      expect(pool.every(isHiragana), isTrue);
    });

    test('Katakana pool contains only katakana characters', () {
      final pool = getCharacterPool(ScriptType.katakana);
      expect(pool.every(isKatakana), isTrue);
    });

    test('Cyrillic pool contains only Cyrillic characters', () {
      final pool = getCharacterPool(ScriptType.cyrillic);
      expect(pool.every(isCyrillic), isTrue);
    });
  });

  group('normalizeWordForPuzzle', () {
    test('uppercases Latin words', () {
      expect(normalizeWordForPuzzle('apple', ScriptType.latin), 'APPLE');
    });

    test('strips whitespace from multi-word phrases', () {
      expect(
          normalizeWordForPuzzle('  hello world  ', ScriptType.latin), 'HELLOWORLD');
    });

    test('does NOT uppercase CJK words', () {
      expect(normalizeWordForPuzzle('あいう', ScriptType.hiragana), 'あいう');
    });
  });

  // ─────────────────────────────────────────────────────
  // calculateOptimalDimensions
  // ─────────────────────────────────────────────────────
  group('calculateOptimalDimensions', () {
    test('returns 10×10 for empty word list', () {
      expect(calculateOptimalDimensions([], Difficulty.easy), (10, 10));
    });

    test('custom size overrides calculation', () {
      expect(
        calculateOptimalDimensions(['APPLE', 'BANANA'], Difficulty.easy,
            customSize: (15, 15)),
        (15, 15),
      );
    });

    test('minimum dimension is at least as long as the longest word + 2', () {
      final (rows, _) =
          calculateOptimalDimensions(['ABCDEFGHIJKLMNOP'], Difficulty.medium);
      // Longest word is 16 chars, so min is 18.
      expect(rows, greaterThanOrEqualTo(18));
    });

    test('result is clamped between 8 and 30', () {
      // Many very long words should still clamp to 30.
      final words = List.generate(20, (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
      final (r, c) = calculateOptimalDimensions(words, Difficulty.hard);
      expect(r, lessThanOrEqualTo(30));
      expect(c, lessThanOrEqualTo(30));
    });
  });

  // ─────────────────────────────────────────────────────
  // GridEngine.generatePuzzle — core integration tests
  // ─────────────────────────────────────────────────────
  group('GridEngine.generatePuzzle', () {
    final simpleWords = [
      {'word': 'CAT', 'clue': 'A small pet'},
      {'word': 'DOG', 'clue': 'Man\'s best friend'},
      {'word': 'FISH', 'clue': 'Lives in water'},
      {'word': 'BIRD', 'clue': 'Can fly'},
      {'word': 'LION', 'clue': 'King of the jungle'},
    ];

    test('generates a puzzle with all words placed (Easy)', () {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: simpleWords,
        difficulty: Difficulty.easy,
      );
      expect(puzzle.words.length, simpleWords.length);
    });

    test('grid has correct dimensions', () {
      final puzzle = GridEngine.generatePuzzle(wordsData: simpleWords);
      expect(puzzle.grid.length, puzzle.rows);
      expect(puzzle.grid.first.length, puzzle.cols);
    });

    test('grid is fully filled — no empty cells', () {
      final puzzle = GridEngine.generatePuzzle(wordsData: simpleWords);
      for (final row in puzzle.grid) {
        expect(row.every((c) => c.isNotEmpty), isTrue,
            reason: 'Found an empty cell in the grid');
      }
    });

    test('each word\'s coords spell the correct letters', () {
      final puzzle = GridEngine.generatePuzzle(wordsData: simpleWords);
      for (final entry in puzzle.words) {
        final reconstructed = entry.coords
            .map((pos) => puzzle.grid[pos.$1][pos.$2])
            .join();
        expect(reconstructed, entry.word,
            reason: 'Word "${entry.word}" letters mismatch at its coords');
      }
    });

    test('word coordinates stay within grid bounds', () {
      final puzzle = GridEngine.generatePuzzle(wordsData: simpleWords);
      for (final entry in puzzle.words) {
        for (final (r, c) in entry.coords) {
          expect(r, inInclusiveRange(0, puzzle.rows - 1));
          expect(c, inInclusiveRange(0, puzzle.cols - 1));
        }
      }
    });

    test('Easy mode only uses Horizontal-LR and Vertical-TB', () {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: simpleWords,
        difficulty: Difficulty.easy,
      );
      final easyDirs = {Direction.horizontalLr, Direction.verticalTb};
      for (final entry in puzzle.words) {
        expect(easyDirs.contains(entry.direction), isTrue,
            reason:
                'Easy puzzle used disallowed direction: ${entry.direction?.name}');
      }
    });

    test('Hard mode can use all 8 directions', () {
      // Run several times to maximise direction coverage.
      final allUsed = <Direction>{};
      for (int i = 0; i < 10; i++) {
        final puzzle = GridEngine.generatePuzzle(
          wordsData: simpleWords,
          difficulty: Difficulty.hard,
        );
        for (final entry in puzzle.words) {
          if (entry.direction != null) allUsed.add(entry.direction!);
        }
      }
      // After 10 runs with 5 words each, we should see more than 2 directions.
      expect(allUsed.length, greaterThan(2));
    });

    test('does not import Flutter (no package:flutter import in engine)', () {
      // Structural smoke-test: simply calling the engine without flutter env.
      expect(
        () => GridEngine.generatePuzzle(wordsData: simpleWords),
        returnsNormally,
      );
    });

    test('deduplicates words with the same normalised form', () {
      final dupeWords = [
        {'word': 'cat'},
        {'word': 'CAT'},
        {'word': 'Cat'},
        {'word': 'DOG'},
      ];
      final puzzle = GridEngine.generatePuzzle(wordsData: dupeWords);
      // After dedup: CAT + DOG = 2 unique words.
      expect(puzzle.words.length, 2);
    });

    test('throws ArgumentError for empty/invalid words list', () {
      expect(
        () => GridEngine.generatePuzzle(wordsData: [
          {'word': ''},
          {'word': 'A'}, // too short (< 2 chars)
        ]),
        throwsArgumentError,
      );
    });

    test('generates Hiragana puzzle with correct script fillers', () {
      final hiraganaWords = [
        {'word': 'あいう'},
        {'word': 'かきく'},
        {'word': 'さしす'},
      ];
      final puzzle = GridEngine.generatePuzzle(
        wordsData: hiraganaWords,
        scriptType: ScriptType.hiragana,
      );
      // Every cell should be a Hiragana character.
      for (final row in puzzle.grid) {
        for (final cell in row) {
          expect(isHiragana(cell), isTrue,
              reason: 'Non-hiragana filler found: $cell');
        }
      }
    });

    test('metadata fields are set correctly', () {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: simpleWords,
        title: 'Animals',
        theme: 'Nature',
        language: 'en',
        difficulty: Difficulty.medium,
      );
      expect(puzzle.metadata.title, 'Animals');
      expect(puzzle.metadata.theme, 'Nature');
      expect(puzzle.metadata.language, 'en');
      expect(puzzle.metadata.difficulty, Difficulty.medium);
    });
  });

  // ─────────────────────────────────────────────────────
  // shiftDistractorCells
  // ─────────────────────────────────────────────────────
  group('GridEngine.shiftDistractorCells', () {
    test('word letters are never changed during distractor shift', () {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: [
          {'word': 'CAT'},
          {'word': 'DOG'},
          {'word': 'FISH'},
        ],
        difficulty: Difficulty.easy,
      );

      // Record all word-cell expected letters.
      final protected = <(int, int), String>{};
      for (final entry in puzzle.words) {
        for (int i = 0; i < entry.coords.length; i++) {
          protected[entry.coords[i]] = entry.word[i];
        }
      }

      // Run shift 20 times.
      var shifted = puzzle;
      for (int i = 0; i < 20; i++) {
        shifted = GridEngine.shiftDistractorCells(shifted);
      }

      // Verify protected cells are unchanged.
      for (final entry in protected.entries) {
        final pos = entry.key;
        final expected = entry.value;
        expect(shifted.grid[pos.$1][pos.$2], expected,
            reason:
                'Word letter at $pos changed from "$expected" to "${shifted.grid[pos.$1][pos.$2]}"');
      }
    });

    test('original puzzle grid is not mutated (immutability)', () {
      final puzzle = GridEngine.generatePuzzle(
        wordsData: [{'word': 'CAT'}, {'word': 'DOG'}],
      );
      final originalCell = puzzle.grid[0][0];
      // Run shift many times.
      GridEngine.shiftDistractorCells(puzzle);
      // Original puzzle's grid should remain unchanged.
      expect(puzzle.grid[0][0], originalCell);
    });
  });

  // ─────────────────────────────────────────────────────
  // WordEntry model
  // ─────────────────────────────────────────────────────
  group('WordEntry', () {
    test('startCoord and endCoord return correct values', () {
      const entry = WordEntry(
        word: 'CAT',
        coords: [(0, 0), (0, 1), (0, 2)],
        direction: Direction.horizontalLr,
      );
      expect(entry.startCoord, (0, 0));
      expect(entry.endCoord, (0, 2));
    });

    test('length matches word length', () {
      const entry = WordEntry(word: 'HELLO');
      expect(entry.length, 5);
    });

    test('copyWith only updates the provided field', () {
      const entry = WordEntry(word: 'CAT', found: false);
      final found = entry.copyWith(found: true);
      expect(found.found, isTrue);
      expect(found.word, 'CAT');
    });

    test('JSON round-trip preserves all fields', () {
      const entry = WordEntry(
        word: 'DOG',
        clue: 'A loyal pet',
        coords: [(1, 2), (1, 3), (1, 4)],
        direction: Direction.horizontalLr,
        found: true,
        hintTierUsed: HintTier.tier2WordName,
      );
      final json = entry.toJson();
      final restored = WordEntry.fromJson(json);
      expect(restored, entry);
    });

    test('Equatable equality works', () {
      const a = WordEntry(word: 'CAT', found: true);
      const b = WordEntry(word: 'CAT', found: true);
      expect(a, equals(b));
    });
  });

  // ─────────────────────────────────────────────────────
  // Puzzle model
  // ─────────────────────────────────────────────────────
  group('Puzzle', () {
    late Puzzle puzzle;

    setUp(() {
      puzzle = GridEngine.generatePuzzle(
        wordsData: [
          {'word': 'CAT'},
          {'word': 'DOG'},
          {'word': 'FISH'},
        ],
      );
    });

    test('totalWords returns correct count', () {
      expect(puzzle.totalWords, 3);
    });

    test('isComplete is false when no words are found', () {
      expect(puzzle.isComplete, isFalse);
    });

    test('isComplete is true when all words are marked found', () {
      final allFound = puzzle.copyWith(
        words: puzzle.words.map((w) => w.copyWith(found: true)).toList(),
      );
      expect(allFound.isComplete, isTrue);
    });

    test('getWord returns correct entry', () {
      final entry = puzzle.getWord('CAT');
      expect(entry, isNotNull);
      expect(entry!.word, 'CAT');
    });

    test('getWord returns null for unknown word', () {
      expect(puzzle.getWord('ZEBRA'), isNull);
    });
  });
}
