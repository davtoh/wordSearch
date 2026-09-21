/// GridEngine — core algorithm for placing words and generating multilingual
/// word search boards.
/// Pure Dart — zero Flutter UI dependencies.
/// Ported from core/grid_engine.py.
library;

import 'dart:math';

import '../constants/scripts.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────────────────
// Top-level helpers
// ─────────────────────────────────────────────────────────

/// Returns the allowed placement [Direction]s for a given [difficulty].
List<Direction> getAllowedDirections(Difficulty difficulty) =>
    switch (difficulty) {
      Difficulty.easy => [Direction.horizontalLr, Direction.verticalTb],
      Difficulty.medium => [
          Direction.horizontalLr,
          Direction.verticalTb,
          Direction.diagonalTlBr,
          Direction.diagonalBlTr,
        ],
      _ => Direction.values, // hard, expert, dynamic → all 8
    };

/// Calculates the optimal square grid size `(rows, cols)` given [words],
/// [difficulty], a [targetDensity] fill ratio, and an optional [customSize].
(int, int) calculateOptimalDimensions(
  List<String> words,
  Difficulty difficulty, {
  double targetDensity = 0.65,
  (int, int)? customSize,
}) {
  if (customSize != null) return customSize;
  if (words.isEmpty) return (10, 10);

  final maxLen = words.map((w) => w.length).reduce(max);
  final totalChars = words.fold(0, (s, w) => s + w.length);

  // Minimum dimension must fit the longest word with at least 2 buffer cells.
  final minDim = max(maxLen + 2, 8);

  final clampedDensity = targetDensity.clamp(0.20, 0.90);
  final estimatedArea = totalChars / clampedDensity;
  int side = max(minDim, sqrt(estimatedArea).ceil());

  if (difficulty == Difficulty.easy) {
    side = max(side, maxLen + 3);
  } else if (difficulty == Difficulty.expert) {
    side = max(minDim, sqrt(totalChars / 0.85).ceil());
  }

  // Clamp between 8×8 and 30×30 for mobile/desktop usability.
  side = side.clamp(8, 30);
  return (side, side);
}

// ─────────────────────────────────────────────────────────
// GridEngine class
// ─────────────────────────────────────────────────────────

/// Core algorithm for placing words and generating multilingual word search boards.
class GridEngine {
  GridEngine._();

  static final _rng = Random();

  // ── Public API ─────────────────────────────────────────

  /// Generates a complete [Puzzle] with placed words and script-aware fillers.
  ///
  /// [wordsData] is a list of maps with at least a `'word'` key.
  /// Optional keys: `'clue'`, `'reading'`.
  static Puzzle generatePuzzle({
    required List<Map<String, String?>> wordsData,
    String title = 'Word Search',
    String theme = 'General',
    String language = 'en',
    Difficulty difficulty = Difficulty.easy,
    (int, int)? customDimensions,
    ScriptType? scriptType,
    AssistConfig? assistConfig,
    int maxRetries = 50,
  }) {
    final rawWords =
        wordsData.map((m) => m['word'] ?? '').where((w) => w.isNotEmpty).toList();

    final detectedScript = scriptType ?? detectScript(rawWords);

    // Normalise and deduplicate entries.
    final normalized = <WordEntry>[];
    final seen = <String>{};
    for (final item in wordsData) {
      final raw = (item['word'] ?? '').trim();
      if (raw.isEmpty) continue;
      final norm = normalizeWordForPuzzle(raw, detectedScript);
      if (norm.length >= 2 && seen.add(norm)) {
        normalized.add(WordEntry(
          word: norm,
          clue: item['clue'],
          reading: item['reading'],
        ));
      }
    }

    if (normalized.isEmpty) {
      throw ArgumentError('No valid words provided for puzzle generation.');
    }

    final cfg = assistConfig ?? const AssistConfig();
    final (rows, cols) = calculateOptimalDimensions(
      normalized.map((e) => e.word).toList(),
      difficulty,
      targetDensity: cfg.densityTarget,
      customSize: customDimensions,
    );
    final allowedDirs = getAllowedDirections(difficulty);

    int r = rows, c = cols;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final (grid, placed) =
          _tryPlaceAll(normalized, r, c, allowedDirs, detectedScript);

      if (placed.length == normalized.length) {
        _fillEmptyCells(grid, detectedScript);
        return Puzzle(
          metadata: PuzzleMetadata(
            title: title,
            theme: theme,
            language: language,
            scriptType: detectedScript,
            difficulty: difficulty,
          ),
          rows: r,
          cols: c,
          grid: grid,
          words: placed,
          allowedDirections: allowedDirs,
          assistConfig: cfg,
        );
      }

      // After halfway, give the grid a little more room.
      if (attempt > maxRetries ~/ 2) {
        r++;
        c++;
      }
    }

    // Fallback: return a partial puzzle with as many words as fit.
    final (grid, placed) =
        _tryPlaceAll(normalized, r, c, allowedDirs, detectedScript);
    _fillEmptyCells(grid, detectedScript);
    return Puzzle(
      metadata: PuzzleMetadata(
        title: title,
        theme: theme,
        language: language,
        scriptType: detectedScript,
        difficulty: difficulty,
      ),
      rows: r,
      cols: c,
      grid: grid,
      words: placed,
      allowedDirections: allowedDirs,
      assistConfig: cfg,
    );
  }

  /// Dynamic Mode: re-randomises up to 30 % of non-word filler cells in [puzzle].
  ///
  /// Returns a new [Puzzle] with the updated grid (the original is unmodified).
  static Puzzle shiftDistractorCells(Puzzle puzzle) {
    final protected = <(int, int)>{};
    for (final w in puzzle.words) {
      for (final coord in w.coords) {
        protected.add(coord);
      }
    }

    final pool = getCharacterPool(puzzle.metadata.scriptType);
    // Deep-copy the grid so the original Puzzle stays immutable.
    final newGrid = [
      for (final row in puzzle.grid) [...row],
    ];

    for (int r = 0; r < puzzle.rows; r++) {
      for (int c = 0; c < puzzle.cols; c++) {
        if (!protected.contains((r, c)) && _rng.nextDouble() < 0.30) {
          newGrid[r][c] = pool[_rng.nextInt(pool.length)];
        }
      }
    }

    return puzzle.copyWith(grid: newGrid);
  }

  // ── Private placement helpers ──────────────────────────

  static (List<List<String>>, List<WordEntry>) _tryPlaceAll(
    List<WordEntry> entries,
    int rows,
    int cols,
    List<Direction> allowedDirs,
    ScriptType script,
  ) {
    final grid = List.generate(rows, (_) => List.filled(cols, ''));
    final placed = <WordEntry>[];

    // Sort longest-first so shorter words fill in the gaps.
    final sorted = [...entries]
      ..sort((a, b) => b.word.length.compareTo(a.word.length));

    for (final entry in sorted) {
      final (ok, coords, dir) =
          _placeWord(grid, entry.word, rows, cols, allowedDirs);
      if (ok) {
        placed.add(entry.copyWith(coords: coords, direction: dir));
      }
    }

    return (grid, placed);
  }

  /// Attempts to place [word] in [grid], returning `(success, coords, direction)`.
  static (bool, List<(int, int)>, Direction?) _placeWord(
    List<List<String>> grid,
    String word,
    int rows,
    int cols,
    List<Direction> allowedDirs,
  ) {
    final chars = word.split('');
    final wLen = chars.length;

    // Shuffle all candidate starting positions.
    final candidates = [
      for (int r = 0; r < rows; r++)
        for (int c = 0; c < cols; c++) (r, c),
    ]..shuffle(_rng);

    for (final (startR, startC) in candidates) {
      final shuffledDirs = [...allowedDirs]..shuffle(_rng);

      for (final dir in shuffledDirs) {
        final (dr, dc) = dir.delta;
        final endR = startR + (wLen - 1) * dr;
        final endC = startC + (wLen - 1) * dc;

        // Boundary check.
        if (endR < 0 || endR >= rows || endC < 0 || endC >= cols) continue;

        // Conflict check — empty cell or matching letter both are OK.
        bool canPlace = true;
        final coords = <(int, int)>[];

        for (int i = 0; i < wLen; i++) {
          final cr = startR + i * dr;
          final cc = startC + i * dc;
          final cell = grid[cr][cc];
          if (cell != '' && cell != chars[i]) {
            canPlace = false;
            break;
          }
          coords.add((cr, cc));
        }

        if (canPlace) {
          // Commit characters to grid.
          for (int i = 0; i < wLen; i++) {
            final (cr, cc) = coords[i];
            grid[cr][cc] = chars[i];
          }
          return (true, coords, dir);
        }
      }
    }

    return (false, const [], null);
  }

  static void _fillEmptyCells(List<List<String>> grid, ScriptType script) {
    final pool = getCharacterPool(script);
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        if (grid[r][c].isEmpty) {
          grid[r][c] = pool[_rng.nextInt(pool.length)];
        }
      }
    }
  }
}

