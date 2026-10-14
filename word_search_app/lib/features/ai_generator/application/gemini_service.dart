/// AI Generator feature – application layer.
/// Re-exports the shared [GeminiService] and adds the
/// [AiGeneratorNotifier] / [AiGeneratorState] Riverpod glue.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../ai/application/gemini_service.dart';
import '../../word_search/application/game_provider.dart';

export '../../ai/application/gemini_service.dart';

// ─────────────────────────────────────────────────────────
// AiGeneratorStatus
// ─────────────────────────────────────────────────────────

/// Represents the lifecycle of a single AI generation request.
enum AiGeneratorStatus {
  /// No request has been made yet (idle).
  idle,

  /// Waiting for the Gemini API to respond.
  loading,

  /// Words have been generated and are ready for review / editing.
  success,

  /// The API call failed or the quota was reached.
  error,
}

// ─────────────────────────────────────────────────────────
// AiGeneratorState
// ─────────────────────────────────────────────────────────

/// Immutable state for the AI Topic Generator view.
class AiGeneratorState extends Equatable {
  const AiGeneratorState({
    this.status = AiGeneratorStatus.idle,
    this.topic = '',
    this.language = 'en',
    this.wordCount = 10,
    this.difficulty = Difficulty.easy,
    this.scriptType = ScriptType.latin,
    this.candidateWords = const [],
    this.errorMessage,
  });

  /// Current lifecycle status.
  final AiGeneratorStatus status;

  /// Topic / prompt the user typed.
  final String topic;

  /// ISO-639-1 language code (e.g. 'en', 'ja', 'ru').
  final String language;

  /// How many words to request from Gemini.
  final int wordCount;

  /// Difficulty preset passed to the puzzle engine.
  final Difficulty difficulty;

  /// Writing system for the target language.
  final ScriptType scriptType;

  /// AI-returned (and user-editable) candidate word list.
  /// Each entry contains 'word', 'clue', and optionally 'reading'.
  final List<Map<String, String?>> candidateWords;

  /// Human-readable error description when [status] == [AiGeneratorStatus.error].
  final String? errorMessage;

  // ── Derived helpers ──

  bool get isIdle => status == AiGeneratorStatus.idle;
  bool get isLoading => status == AiGeneratorStatus.loading;
  bool get isSuccess => status == AiGeneratorStatus.success;
  bool get isError => status == AiGeneratorStatus.error;

  /// True when there is at least one candidate word to display.
  bool get hasWords => candidateWords.isNotEmpty;

  AiGeneratorState copyWith({
    AiGeneratorStatus? status,
    String? topic,
    String? language,
    int? wordCount,
    Difficulty? difficulty,
    ScriptType? scriptType,
    List<Map<String, String?>>? candidateWords,
    String? errorMessage,
  }) {
    return AiGeneratorState(
      status: status ?? this.status,
      topic: topic ?? this.topic,
      language: language ?? this.language,
      wordCount: wordCount ?? this.wordCount,
      difficulty: difficulty ?? this.difficulty,
      scriptType: scriptType ?? this.scriptType,
      candidateWords: candidateWords ?? this.candidateWords,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        topic,
        language,
        wordCount,
        difficulty,
        scriptType,
        candidateWords,
        errorMessage,
      ];
}

// ─────────────────────────────────────────────────────────
// AiGeneratorNotifier
// ─────────────────────────────────────────────────────────

/// Riverpod [Notifier] that drives the AI Generator feature.
///
/// Responsibilities:
/// * Holds the prompt [topic] and generation options typed by the user.
/// * Calls [GeminiService.generateWords] and surfaces loading / error states.
/// * Exposes the returned word list so the screen can render editable chips.
/// * Allows the user to add / remove / rename individual candidate words before
///   launching [GameScreen] via [gameProvider].
class AiGeneratorNotifier extends Notifier<AiGeneratorState> {
  @override
  AiGeneratorState build() => const AiGeneratorState();

  // ── Input helpers ────────────────────────────────────────

  /// Updates the [topic] typed by the user.
  void setTopic(String topic) {
    state = state.copyWith(topic: topic.trim());
  }

  /// Updates the target [language].
  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  /// Updates the number of words to request.
  void setWordCount(int count) {
    state = state.copyWith(wordCount: count.clamp(3, 30));
  }

  /// Updates the puzzle [difficulty].
  void setDifficulty(Difficulty difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }

  /// Updates the [scriptType] used for the target language.
  void setScriptType(ScriptType scriptType) {
    state = state.copyWith(scriptType: scriptType);
  }

  // ── Candidate word mutations ─────────────────────────────

  /// Adds [word] (with optional [clue]) to [candidateWords].
  void addCandidateWord({required String word, String? clue}) {
    final trimmed = word.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    if (state.candidateWords.any((w) => w['word'] == trimmed)) return;
    final updated = List<Map<String, String?>>.from(state.candidateWords)
      ..add({'word': trimmed, 'clue': clue ?? 'User-added word', 'reading': null});
    state = state.copyWith(candidateWords: updated);
  }

  /// Removes the candidate at [index].
  void removeCandidateAt(int index) {
    if (index < 0 || index >= state.candidateWords.length) return;
    final updated = List<Map<String, String?>>.from(state.candidateWords)
      ..removeAt(index);
    state = state.copyWith(candidateWords: updated);
  }

  /// Replaces the word label at [index] with [newWord].
  void renameCandidateAt(int index, String newWord) {
    final trimmed = newWord.trim().toUpperCase();
    if (trimmed.isEmpty || index < 0 || index >= state.candidateWords.length) return;
    final updated = List<Map<String, String?>>.from(state.candidateWords);
    updated[index] = Map<String, String?>.from(updated[index])
      ..['word'] = trimmed;
    state = state.copyWith(candidateWords: updated);
  }

  /// Clears all candidate words and resets to [AiGeneratorStatus.idle].
  void clearCandidates() {
    state = state.copyWith(
      status: AiGeneratorStatus.idle,
      candidateWords: [],
      errorMessage: null,
    );
  }

  // ── AI Generation ────────────────────────────────────────

  /// Calls the Gemini API for [state.topic] and populates [candidateWords].
  /// Surfaces loading + error states so the UI can react appropriately.
  /// Uses [GeminiService.generateWordsOrThrow] so quota / network failures are
  /// propagated as [AiGeneratorStatus.error] rather than silently falling back.
  Future<void> generateWords() async {
    final topic = state.topic;
    if (topic.isEmpty) return;

    state = state.copyWith(
      status: AiGeneratorStatus.loading,
      errorMessage: null,
    );

    try {
      final service = ref.read(geminiServiceProvider);
      final words = await service.generateWordsOrThrow(
        topic: topic,
        language: state.language,
        count: state.wordCount,
        difficulty: state.difficulty,
        scriptType: state.scriptType,
      );

      if (words.isEmpty) {
        // Service returned empty list — surface as a soft error.
        state = state.copyWith(
          status: AiGeneratorStatus.error,
          errorMessage:
              'No words were generated for "$topic". Try a different topic.',
          candidateWords: [],
        );
        return;
      }

      state = state.copyWith(
        status: AiGeneratorStatus.success,
        candidateWords: words,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: AiGeneratorStatus.error,
        errorMessage: 'Failed to generate words: ${e.toString()}',
        candidateWords: [],
      );
    }
  }

  // ── Game launch ──────────────────────────────────────────

  /// Builds a puzzle from the current [candidateWords] and hands it off to
  /// [gameProvider], then navigates to [GameScreen] via GoRouter.
  ///
  /// Requires at least 3 candidate words to form a valid puzzle.
  Future<void> launchGame({
    required void Function(String route) navigateTo,
  }) async {
    if (state.candidateWords.length < 3) return;

    final puzzle = await ref.read(geminiServiceProvider).generatePuzzle(
          topic: state.topic.isNotEmpty ? state.topic : 'AI Generated',
          language: state.language,
          count: state.wordCount,
          difficulty: state.difficulty,
          scriptType: state.scriptType,
        );

    ref.read(gameProvider.notifier).initGame(puzzle);
    navigateTo('/game');
  }
}

/// Global provider for the AI Generator state.
final aiGeneratorProvider =
    NotifierProvider<AiGeneratorNotifier, AiGeneratorState>(
  AiGeneratorNotifier.new,
);
