/// WordEntry — a single word within a puzzle, including placement metadata.
/// Pure Dart — zero Flutter UI dependencies.
library;

import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Represents a single word in the puzzle with its grid placement and metadata.
class WordEntry extends Equatable {
  const WordEntry({
    required this.word,
    this.clue,
    this.reading,
    this.coords = const [],
    this.direction,
    this.found = false,
    this.hintTierUsed = HintTier.none,
  });

  /// The normalised word string as it appears in the grid.
  final String word;

  /// Optional clue / definition shown to the player.
  final String? clue;

  /// Optional phonetic reading (e.g. Hiragana reading for Kanji words).
  final String? reading;

  /// Ordered list of (row, col) coordinates occupied by this word in the grid.
  final List<(int, int)> coords;

  /// Direction this word is placed in.
  final Direction? direction;

  /// Whether the player has already found this word.
  final bool found;

  /// The highest hint tier the player has consumed for this word.
  final HintTier hintTierUsed;

  // ─── Derived helpers ───────────────────────────────────

  /// First cell coordinate, or null if not yet placed.
  (int, int)? get startCoord => coords.isNotEmpty ? coords.first : null;

  /// Last cell coordinate, or null if not yet placed.
  (int, int)? get endCoord => coords.isNotEmpty ? coords.last : null;

  /// Character count of the word.
  int get length => word.length;

  // ─── copyWith ─────────────────────────────────────────

  WordEntry copyWith({
    String? word,
    String? clue,
    String? reading,
    List<(int, int)>? coords,
    Direction? direction,
    bool? found,
    HintTier? hintTierUsed,
  }) =>
      WordEntry(
        word: word ?? this.word,
        clue: clue ?? this.clue,
        reading: reading ?? this.reading,
        coords: coords ?? this.coords,
        direction: direction ?? this.direction,
        found: found ?? this.found,
        hintTierUsed: hintTierUsed ?? this.hintTierUsed,
      );

  // ─── JSON helpers ─────────────────────────────────────

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        word: json['word'] as String,
        clue: json['clue'] as String?,
        reading: json['reading'] as String?,
        coords: (json['coords'] as List<dynamic>? ?? [])
            .map((c) => (c[0] as int, c[1] as int))
            .toList(),
        direction: json['direction'] != null
            ? Direction.fromValue(json['direction'] as String)
            : null,
        found: json['found'] as bool? ?? false,
        hintTierUsed: HintTier.fromLevel(json['hint_tier_used'] as int? ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        if (clue != null) 'clue': clue,
        if (reading != null) 'reading': reading,
        'coords': coords.map((c) => [c.$1, c.$2]).toList(),
        if (direction != null) 'direction': direction!.value,
        'found': found,
        'hint_tier_used': hintTierUsed.level,
      };

  @override
  List<Object?> get props => [
        word,
        clue,
        reading,
        coords,
        direction,
        found,
        hintTierUsed,
      ];

  @override
  String toString() => 'WordEntry(word: $word, found: $found, '
      'direction: ${direction?.name}, coords: ${coords.length} cells)';
}

