/// UI-Agnostic Game State Model and Selection Validator.
/// Pure Dart — zero Flutter UI dependencies.
/// Ported from core/game_state.py.
library;

import 'dart:math';
import 'package:equatable/equatable.dart';

import '../../../../core/models/models.dart';
import '../application/assists_service.dart';

/// Represents the complete, immutable state of an active puzzle session.
class GameState extends Equatable {
  const GameState({
    required this.puzzle,
    this.mode = GameMode.casual,
    this.status = GameStatus.playing,
    this.foundWords = const [],
    this.foundCoordsMap = const {},
    this.timeLimit = 240,
    this.timeRemaining = 240.0,
    this.bonusPerWord = 15,
    this.totalElapsedSeconds = 0.0,
    this.activeHintCoords = const {},
    this.activeHintWord,
    this.revealedAllOnGiveUp = false,
    this.selectedCoords = const [],
    this.lastFoundWord,
    this.stallAlert,
    this.proximityFeedback,
  });

  /// The active puzzle grid and word entries.
  final Puzzle puzzle;

  /// Game mode: casual or timedAttack.
  final GameMode mode;

  /// Current session status (playing, paused, won, timeOut, givenUp).
  final GameStatus status;

  /// Words successfully discovered by the player.
  final List<WordEntry> foundWords;

  /// Map of `(row, col)` coordinate to the word string found there.
  final Map<(int, int), String> foundCoordsMap;

  /// Time limit in seconds (for Timed Attack).
  final int timeLimit;

  /// Current seconds remaining (in Timed Attack).
  final double timeRemaining;

  /// Bonus seconds awarded per found word.
  final int bonusPerWord;

  /// Total active elapsed time in seconds.
  final double totalElapsedSeconds;

  /// Highlighted coordinates currently shown for hint assists.
  final Set<(int, int)> activeHintCoords;

  /// The word targeted by the active hint.
  final WordEntry? activeHintWord;

  /// Whether the player surrendered and revealed all remaining words.
  final bool revealedAllOnGiveUp;

  /// Active drag selection coordinates in progress.
  final List<(int, int)> selectedCoords;

  /// Most recently discovered word.
  final WordEntry? lastFoundWord;

  /// Stall / inactivity alert message if triggered.
  final String? stallAlert;

  /// Current proximity feedback from radar assist.
  final ProximityFeedback? proximityFeedback;

  // ─── Factory Initializer ─────────────────────────────────

  /// Creates a new initial [GameState] for [puzzle] and [mode].
  factory GameState.initial(Puzzle puzzle, {GameMode mode = GameMode.casual}) {
    final timeLimit = puzzle.assistConfig.timeLimitSeconds;
    return GameState(
      puzzle: puzzle,
      mode: mode,
      status: GameStatus.playing,
      timeLimit: timeLimit,
      timeRemaining: timeLimit.toDouble(),
      bonusPerWord: puzzle.assistConfig.bonusTimePerWord,
    );
  }

  // ─── Selection & Line Geometry ────────────────────────────

  /// Calculates a straight-line list of grid cells between [start] and [end].
  ///
  /// Supports horizontal, vertical, and true 45-degree diagonals.
  /// Returns empty list if out of bounds or not along an allowed 8-way direction.
  List<(int, int)> interpolateLine((int, int) start, (int, int) end) {
    final (r0, c0) = start;
    final (r1, c1) = end;

    // Bounds checking
    if (r0 < 0 || r0 >= puzzle.rows || c0 < 0 || c0 >= puzzle.cols) {
      return const [];
    }
    if (r1 < 0 || r1 >= puzzle.rows || c1 < 0 || c1 >= puzzle.cols) {
      return const [];
    }

    final dr = r1 - r0;
    final dc = c1 - c0;

    // Single cell tap
    if (dr == 0 && dc == 0) {
      return [(r0, c0)];
    }

    final absDr = dr.abs();
    final absDc = dc.abs();

    // Must be horizontal, vertical, or 45-degree diagonal
    if (dr != 0 && dc != 0 && absDr != absDc) {
      return const [];
    }

    final stepR = dr == 0 ? 0 : (dr > 0 ? 1 : -1);
    final stepC = dc == 0 ? 0 : (dc > 0 ? 1 : -1);
    final steps = max(absDr, absDc);

    return [
      for (int i = 0; i <= steps; i++) (r0 + i * stepR, c0 + i * stepC),
    ];
  }

  /// Calculates Euclidean distance from [coord] to the start of the nearest unfound word.
  double? getNearestUnfoundWordDistance((int, int) coord) {
    final (r, c) = coord;
    final unfound = puzzle.words.where((w) => !w.found && w.startCoord != null);
    if (unfound.isEmpty) return null;

    double minDist = double.infinity;
    for (final w in unfound) {
      final (sr, sc) = w.startCoord!;
      final dist = sqrt(pow(r - sr, 2) + pow(c - sc, 2));
      if (dist < minDist) {
        minDist = dist;
      }
    }
    return minDist;
  }

  // ─── Queries & Helpers ────────────────────────────────────

  /// Whether all words have been found.
  bool get isComplete =>
      puzzle.words.isNotEmpty && foundWords.length >= puzzle.words.length;

  /// Progress ratio from 0.0 to 1.0.
  double get progress =>
      puzzle.words.isEmpty ? 0.0 : foundWords.length / puzzle.words.length;

  /// True if the coordinate has already been solved.
  bool isCoordFound((int, int) coord) => foundCoordsMap.containsKey(coord);

  /// True if the coordinate is actively highlighted by a hint.
  bool isCoordHinted((int, int) coord) => activeHintCoords.contains(coord);

  /// True if the coordinate is in the current active selection line.
  bool isCoordSelected((int, int) coord) => selectedCoords.contains(coord);

  // ─── copyWith ─────────────────────────────────────────────

  GameState copyWith({
    Puzzle? puzzle,
    GameMode? mode,
    GameStatus? status,
    List<WordEntry>? foundWords,
    Map<(int, int), String>? foundCoordsMap,
    int? timeLimit,
    double? timeRemaining,
    int? bonusPerWord,
    double? totalElapsedSeconds,
    Set<(int, int)>? activeHintCoords,
    WordEntry? activeHintWord,
    bool clearActiveHintWord = false,
    bool? revealedAllOnGiveUp,
    List<(int, int)>? selectedCoords,
    WordEntry? lastFoundWord,
    bool clearLastFoundWord = false,
    String? stallAlert,
    bool clearStallAlert = false,
    ProximityFeedback? proximityFeedback,
    bool clearProximityFeedback = false,
  }) {
    return GameState(
      puzzle: puzzle ?? this.puzzle,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      foundWords: foundWords ?? this.foundWords,
      foundCoordsMap: foundCoordsMap ?? this.foundCoordsMap,
      timeLimit: timeLimit ?? this.timeLimit,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      bonusPerWord: bonusPerWord ?? this.bonusPerWord,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      activeHintCoords: activeHintCoords ?? this.activeHintCoords,
      activeHintWord: clearActiveHintWord
          ? null
          : (activeHintWord ?? this.activeHintWord),
      revealedAllOnGiveUp: revealedAllOnGiveUp ?? this.revealedAllOnGiveUp,
      selectedCoords: selectedCoords ?? this.selectedCoords,
      lastFoundWord: clearLastFoundWord
          ? null
          : (lastFoundWord ?? this.lastFoundWord),
      stallAlert: clearStallAlert ? null : (stallAlert ?? this.stallAlert),
      proximityFeedback: clearProximityFeedback
          ? null
          : (proximityFeedback ?? this.proximityFeedback),
    );
  }

  @override
  List<Object?> get props => [
        puzzle,
        mode,
        status,
        foundWords,
        foundCoordsMap,
        timeLimit,
        timeRemaining,
        bonusPerWord,
        totalElapsedSeconds,
        activeHintCoords,
        activeHintWord,
        revealedAllOnGiveUp,
        selectedCoords,
        lastFoundWord,
        stallAlert,
        proximityFeedback,
      ];
}

