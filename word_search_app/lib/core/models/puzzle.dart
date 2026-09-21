/// Puzzle — self-contained, serialisable word search puzzle object.
/// Pure Dart — zero Flutter UI dependencies.
library;

import 'package:equatable/equatable.dart';

import 'assist_config.dart';
import 'enums.dart';
import 'puzzle_metadata.dart';
import 'word_entry.dart';

/// A complete, self-contained word search puzzle with grid and word placements.
class Puzzle extends Equatable {
  const Puzzle({
    required this.metadata,
    required this.rows,
    required this.cols,
    required this.grid,
    required this.words,
    this.allowedDirections = const [],
    this.assistConfig = const AssistConfig(),
  });

  final PuzzleMetadata metadata;

  /// Number of rows in the grid.
  final int rows;

  /// Number of columns in the grid.
  final int cols;

  /// 2-D grid of characters: `grid[row][col]`.
  final List<List<String>> grid;

  /// All words placed in the puzzle.
  final List<WordEntry> words;

  /// Directions permitted for word placement in this puzzle.
  final List<Direction> allowedDirections;

  /// Assist and difficulty settings for this puzzle session.
  final AssistConfig assistConfig;

  // ─── Derived helpers ───────────────────────────────────

  /// Total number of words in the puzzle.
  int get totalWords => words.length;

  /// Number of words already found by the player.
  int get foundWordsCount => words.where((w) => w.found).length;

  /// True when every word has been found.
  bool get isComplete => totalWords > 0 && foundWordsCount == totalWords;

  /// Returns the [WordEntry] matching [wordStr], or null if not found.
  WordEntry? getWord(String wordStr) {
    for (final w in words) {
      if (w.word == wordStr) return w;
    }
    return null;
  }

  // ─── copyWith ─────────────────────────────────────────

  Puzzle copyWith({
    PuzzleMetadata? metadata,
    int? rows,
    int? cols,
    List<List<String>>? grid,
    List<WordEntry>? words,
    List<Direction>? allowedDirections,
    AssistConfig? assistConfig,
  }) =>
      Puzzle(
        metadata: metadata ?? this.metadata,
        rows: rows ?? this.rows,
        cols: cols ?? this.cols,
        grid: grid ?? this.grid,
        words: words ?? this.words,
        allowedDirections: allowedDirections ?? this.allowedDirections,
        assistConfig: assistConfig ?? this.assistConfig,
      );

  // ─── JSON helpers ─────────────────────────────────────

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        metadata: PuzzleMetadata.fromJson(
            json['metadata'] as Map<String, dynamic>),
        rows: json['rows'] as int,
        cols: json['cols'] as int,
        grid: (json['grid'] as List<dynamic>)
            .map((row) => (row as List<dynamic>).cast<String>())
            .toList(),
        words: (json['words'] as List<dynamic>)
            .map((w) => WordEntry.fromJson(w as Map<String, dynamic>))
            .toList(),
        allowedDirections: (json['allowed_directions'] as List<dynamic>? ?? [])
            .map((v) => Direction.fromValue(v as String))
            .toList(),
        assistConfig: json['assist_config'] != null
            ? AssistConfig.fromJson(
                json['assist_config'] as Map<String, dynamic>)
            : const AssistConfig(),
      );

  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'rows': rows,
        'cols': cols,
        'grid': grid,
        'words': words.map((w) => w.toJson()).toList(),
        'allowed_directions': allowedDirections.map((d) => d.value).toList(),
        'assist_config': assistConfig.toJson(),
      };

  @override
  List<Object?> get props => [
        metadata, rows, cols, grid, words, allowedDirections, assistConfig,
      ];

  @override
  String toString() =>
      'Puzzle(id: ${metadata.id}, ${rows}x$cols, '
      'words: $totalWords, found: $foundWordsCount)';
}

