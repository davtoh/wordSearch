/// Riverpod Game State Notifier and Providers.
/// Manages active puzzle lifecycle, timer loops, drag selections, and assists.
/// Ported from core/game_state.py and assists/registry.py.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/grid_engine.dart';
import '../../../../core/models/models.dart';
import '../domain/game_state.dart';
import 'assists_service.dart';

// ─────────────────────────────────────────────────────────
// Default Demo Puzzle Helper
// ─────────────────────────────────────────────────────────

Puzzle _createDefaultPuzzle() {
  return GridEngine.generatePuzzle(
    wordsData: const [
      {'word': 'FLUTTER', 'clue': 'Multi-platform UI toolkit'},
      {'word': 'DART', 'clue': 'Modern client-optimized language'},
      {'word': 'PUZZLE', 'clue': 'A fun word search grid'},
      {'word': 'RIVERPOD', 'clue': 'Reactive caching & state management'},
      {'word': 'SEARCH', 'clue': 'To look for hidden words'},
    ],
    title: 'Flutter Word Search',
    theme: 'Technology',
    difficulty: Difficulty.easy,
  );
}

// ─────────────────────────────────────────────────────────
// GameNotifier
// ─────────────────────────────────────────────────────────

/// Riverpod [Notifier] orchestrating game sessions, drag selections, timers, and assists.
class GameNotifier extends Notifier<GameState> {
  GameNotifier({AssistsService? assistsService})
      : assistsService = assistsService ?? AssistsService();

  final AssistsService assistsService;
  Timer? _timer;
  (int, int)? _selectionStart;

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    final defaultPuzzle = _createDefaultPuzzle();
    return GameState.initial(defaultPuzzle, mode: GameMode.casual);
  }

  // ─── Lifecycle & Setup ───────────────────────────────────

  /// Initializes a new game session with [puzzle] and [mode].
  void initGame(
    Puzzle puzzle, {
    GameMode mode = GameMode.casual,
    bool autoStartTimer = true,
  }) {
    _timer?.cancel();
    _selectionStart = null;
    assistsService.stallDetector.reset();

    state = GameState.initial(puzzle, mode: mode);

    if (autoStartTimer) {
      startTimer();
    }
  }

  /// Resets the current puzzle back to its unplayed state.
  void resetGame({bool autoStartTimer = true}) {
    final cleanWords = state.puzzle.words.map((w) {
      return w.copyWith(found: false, hintTierUsed: HintTier.none);
    }).toList();

    final cleanPuzzle = state.puzzle.copyWith(words: cleanWords);
    initGame(cleanPuzzle, mode: state.mode, autoStartTimer: autoStartTimer);
  }

  // ─── Timers & Tick Loop ───────────────────────────────────

  /// Starts the active gameplay timer (runs every 250ms).
  void startTimer({Duration interval = const Duration(milliseconds: 250)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      tick(interval.inMilliseconds / 1000.0);
    });
  }

  /// Pauses the active gameplay timer.
  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Steps the game clock by [deltaSeconds].
  void tick(double deltaSeconds) {
    if (state.status != GameStatus.playing) return;

    final newElapsed = state.totalElapsedSeconds + deltaSeconds;

    if (state.mode == GameMode.timedAttack) {
      final newRemaining = state.timeRemaining - deltaSeconds;
      if (newRemaining <= 0) {
        pauseTimer();
        state = state.copyWith(
          timeRemaining: 0.0,
          totalElapsedSeconds: newElapsed,
          status: GameStatus.timeOut,
        );
        return;
      }

      state = state.copyWith(
        timeRemaining: newRemaining,
        totalElapsedSeconds: newElapsed,
      );
    } else {
      state = state.copyWith(totalElapsedSeconds: newElapsed);
    }

    // Check stall detection
    final stallMessage = assistsService.checkStall(state, deltaSeconds);
    if (stallMessage != null && state.stallAlert != stallMessage) {
      state = state.copyWith(stallAlert: stallMessage);
    }
  }

  // ─── Drag Selection Logic ────────────────────────────────

  /// Starts drag selection at [coord].
  void startSelection((int, int) coord) {
    if (state.status != GameStatus.playing) return;

    _selectionStart = coord;
    state = state.copyWith(
      selectedCoords: [coord],
      clearStallAlert: true,
    );
  }

  /// Updates drag selection straight line from the initial tap to [currentCoord].
  void updateSelection((int, int) currentCoord) {
    if (state.status != GameStatus.playing) return;

    _selectionStart ??= currentCoord;
    final line = state.interpolateLine(_selectionStart!, currentCoord);
    if (line.isNotEmpty) {
      state = state.copyWith(selectedCoords: line);
    }
  }

  /// Confirms the active selection line.
  ///
  /// Returns `true` if an unfound word was matched (forward or reverse).
  bool confirmSelection() {
    if (state.status != GameStatus.playing || state.selectedCoords.isEmpty) {
      _selectionStart = null;
      state = state.copyWith(selectedCoords: const []);
      return false;
    }

    final coords = List<(int, int)>.from(state.selectedCoords);
    _selectionStart = null;

    final matched = _matchWord(coords);
    if (matched != null) {
      _markWordFound(matched, coords);
      state = state.copyWith(selectedCoords: const []);
      return true;
    }

    state = state.copyWith(selectedCoords: const []);
    return false;
  }

  /// Cancels any active drag selection.
  void cancelSelection() {
    _selectionStart = null;
    state = state.copyWith(selectedCoords: const []);
  }

  /// Direct start-to-end line validator matching Python `GameState.check_selection`.
  (bool, WordEntry?, List<(int, int)>) checkSelection(
    (int, int) startCoord,
    (int, int) endCoord,
  ) {
    if (state.status != GameStatus.playing) {
      return (false, null, const []);
    }

    final coords = state.interpolateLine(startCoord, endCoord);
    if (coords.isEmpty) {
      return (false, null, const []);
    }

    final matched = _matchWord(coords);
    if (matched != null) {
      _markWordFound(matched, coords);
      return (true, matched, coords);
    }

    return (false, null, coords);
  }

  // ─── Private Selection Matching ──────────────────────────

  WordEntry? _matchWord(List<(int, int)> coords) {
    if (coords.isEmpty) return null;

    // Read selected letters from grid
    final selectedLetters = [
      for (final (r, c) in coords) state.puzzle.grid[r][c],
    ].join();
    final reversedLetters = selectedLetters.split('').reversed.join();

    final reversedCoords = coords.reversed.toList();

    for (final wordEntry in state.puzzle.words) {
      if (wordEntry.found) continue;

      // 1. Exact coordinate match (forward or reverse)
      final bool coordsMatch = _coordsEqual(coords, wordEntry.coords) ||
          _coordsEqual(reversedCoords, wordEntry.coords);

      if (coordsMatch) return wordEntry;

      // 2. Letter match with identical coordinate length
      final bool lettersMatch = selectedLetters == wordEntry.word ||
          reversedLetters == wordEntry.word;

      if (lettersMatch && coords.length == wordEntry.coords.length) {
        return wordEntry;
      }
    }

    return null;
  }

  bool _coordsEqual(List<(int, int)> a, List<(int, int)> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _markWordFound(WordEntry target, List<(int, int)> coords) {
    final updatedWord = target.copyWith(found: true);

    final updatedWords = state.puzzle.words.map((w) {
      return w.word == target.word ? updatedWord : w;
    }).toList();

    final newFoundWords = [...state.foundWords, updatedWord];

    final newFoundMap = Map<(int, int), String>.from(state.foundCoordsMap);
    for (final coord in target.coords) {
      newFoundMap[coord] = target.word;
    }

    // Time bonus in Timed Attack mode
    final double newRemaining = state.mode == GameMode.timedAttack
        ? state.timeRemaining + state.bonusPerWord
        : state.timeRemaining;

    // Clear active hints if they matched this word
    final clearHint = state.activeHintWord?.word == target.word;
    final newHintCoords = clearHint
        ? const <(int, int)>{}
        : state.activeHintCoords;

    assistsService.notifyWordFound();

    final updatedPuzzle = state.puzzle.copyWith(words: updatedWords);
    final bool isWon = updatedWords.every((w) => w.found);

    if (isWon) {
      pauseTimer();
    }

    state = state.copyWith(
      puzzle: updatedPuzzle,
      foundWords: newFoundWords,
      foundCoordsMap: newFoundMap,
      timeRemaining: newRemaining,
      activeHintCoords: newHintCoords,
      clearActiveHintWord: clearHint,
      lastFoundWord: updatedWord,
      status: isWon ? GameStatus.won : state.status,
      clearStallAlert: true,
    );
  }

  // ─── Assists API ──────────────────────────────────────────

  /// Requests the next progressive hint tier.
  ProgressiveHintResult? requestHint({String? targetWord}) {
    if (state.status != GameStatus.playing) return null;

    final hintResult =
        assistsService.requestHint(state, targetWord: targetWord);
    if (hintResult == null) return null;

    final updatedWords = state.puzzle.words.map((w) {
      return w.word == hintResult.wordEntry.word ? hintResult.wordEntry : w;
    }).toList();

    final updatedPuzzle = state.puzzle.copyWith(words: updatedWords);

    state = state.copyWith(
      puzzle: updatedPuzzle,
      activeHintCoords: Set.from(hintResult.highlightCoords),
      activeHintWord: hintResult.wordEntry,
    );

    return hintResult;
  }

  /// Calculates Hot/Cold proximity radar feedback for [coord].
  ProximityFeedback? checkProximity((int, int) coord) {
    if (state.status != GameStatus.playing) return null;

    final feedback = assistsService.checkProximity(state, coord);
    if (feedback != null) {
      state = state.copyWith(proximityFeedback: feedback);
    }
    return feedback;
  }

  /// Adds emergency overtime in Timed Attack mode (+30s default).
  void applyEmergencyTimeBoost({double boostSeconds = 30.0}) {
    if (state.mode != GameMode.timedAttack) return;

    final boosted =
        assistsService.emergencyTimeBoost(state, boostSeconds: boostSeconds);
    state = state.copyWith(timeRemaining: boosted);
  }

  // ─── Session Controls ─────────────────────────────────────

  /// Toggles between [GameStatus.playing] and [GameStatus.paused].
  bool togglePause() {
    if (state.status == GameStatus.playing) {
      pauseTimer();
      state = state.copyWith(status: GameStatus.paused);
      return true;
    } else if (state.status == GameStatus.paused) {
      startTimer();
      state = state.copyWith(status: GameStatus.playing);
      return false;
    }
    return false;
  }

  /// Surrenders the game and reveals all remaining unfound words.
  void giveUp() {
    if (state.status == GameStatus.won || state.status == GameStatus.givenUp) {
      return;
    }

    pauseTimer();

    final allCoordsMap = Map<(int, int), String>.from(state.foundCoordsMap);
    for (final w in state.puzzle.words) {
      for (final coord in w.coords) {
        allCoordsMap.putIfAbsent(coord, () => w.word);
      }
    }

    state = state.copyWith(
      status: GameStatus.givenUp,
      revealedAllOnGiveUp: true,
      foundCoordsMap: allCoordsMap,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Riverpod Providers
// ─────────────────────────────────────────────────────────

/// Primary game state provider.
final gameProvider =
    NotifierProvider<GameNotifier, GameState>(GameNotifier.new);

/// Current session status provider.
final gameStatusProvider =
    Provider<GameStatus>((ref) => ref.watch(gameProvider).status);

/// List of found words provider.
final foundWordsProvider =
    Provider<List<WordEntry>>((ref) => ref.watch(gameProvider).foundWords);

/// Countdown seconds remaining provider (for Timed Attack).
final timeRemainingProvider =
    Provider<double>((ref) => ref.watch(gameProvider).timeRemaining);

/// Active hint coordinates provider.
final activeHintCoordsProvider = Provider<Set<(int, int)>>(
    (ref) => ref.watch(gameProvider).activeHintCoords);

