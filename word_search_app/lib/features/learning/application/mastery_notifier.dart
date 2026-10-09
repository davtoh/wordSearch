/// Riverpod State Management for Vocabulary Flashcard Review and Mastery Tracking.
/// Connects mastery_tracker.dart, vocabulary_deck.dart, and adaptive_recommender.dart.
library;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/engine/grid_engine.dart';
import '../../../core/models/models.dart';
import '../../word_search/application/game_provider.dart';
import '../../word_search/domain/game_state.dart';
import 'learning_provider.dart';
import 'vocabulary_deck.dart';

/// Filtering options for the vocabulary deck.
enum MasteryFilter {
  all,
  needsPractice,
  learning,
  mastered;

  String get label => switch (this) {
        MasteryFilter.all => 'All',
        MasteryFilter.needsPractice => 'Needs Practice',
        MasteryFilter.learning => 'Learning',
        MasteryFilter.mastered => 'Mastered',
      };

  MasteryLevel? toMasteryLevel() => switch (this) {
        MasteryFilter.all => null,
        MasteryFilter.needsPractice => MasteryLevel.needsPractice,
        MasteryFilter.learning => MasteryLevel.learning,
        MasteryFilter.mastered => MasteryLevel.mastered,
      };
}

/// State for the Vocabulary Mastery & Flashcard View.
class MasteryState extends Equatable {
  const MasteryState({
    this.selectedFilter = MasteryFilter.all,
    this.searchQuery = '',
    this.selectedLanguage,
    this.currentCardIndex = 0,
    this.isCardFlipped = false,
    this.activeReviewPuzzle,
    this.reviewGameState,
    this.isReviewMode = false,
  });

  final MasteryFilter selectedFilter;
  final String searchQuery;
  final String? selectedLanguage;
  final int currentCardIndex;
  final bool isCardFlipped;
  final Puzzle? activeReviewPuzzle;
  final GameState? reviewGameState;
  final bool isReviewMode;

  MasteryState copyWith({
    MasteryFilter? selectedFilter,
    String? searchQuery,
    String? Function()? selectedLanguage,
    int? currentCardIndex,
    bool? isCardFlipped,
    Puzzle? Function()? activeReviewPuzzle,
    GameState? Function()? reviewGameState,
    bool? isReviewMode,
  }) {
    return MasteryState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedLanguage: selectedLanguage != null
          ? selectedLanguage()
          : this.selectedLanguage,
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
      isCardFlipped: isCardFlipped ?? this.isCardFlipped,
      activeReviewPuzzle: activeReviewPuzzle != null
          ? activeReviewPuzzle()
          : this.activeReviewPuzzle,
      reviewGameState: reviewGameState != null
          ? reviewGameState()
          : this.reviewGameState,
      isReviewMode: isReviewMode ?? this.isReviewMode,
    );
  }

  @override
  List<Object?> get props => [
        selectedFilter,
        searchQuery,
        selectedLanguage,
        currentCardIndex,
        isCardFlipped,
        activeReviewPuzzle,
        reviewGameState,
        isReviewMode,
      ];
}

/// Starter vocabulary deck to populate when player profile deck is empty.
final List<WordMasteryRecord> _starterDeck = [
  WordMasteryRecord(
    word: 'PHOTOSYNTHESIS',
    language: 'en',
    clue: 'Process plants use to synthesize food from sunlight and CO2',
    reading: 'foh-toh-sin-thuh-sis',
    timesEncountered: 3,
    timesSolved: 1,
    totalSolveTimeSeconds: 58.0,
    hintTiersHistory: const [1, 3, 5],
    errorClicks: 4,
    lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
    masteryLevel: MasteryLevel.needsPractice,
  ),
  WordMasteryRecord(
    word: 'MITOCHONDRIA',
    language: 'en',
    clue: 'Powerhouse organelle generating cellular energy (ATP)',
    reading: 'my-tuh-kon-dree-uh',
    timesEncountered: 2,
    timesSolved: 2,
    totalSolveTimeSeconds: 44.0,
    hintTiersHistory: const [1, 2],
    errorClicks: 2,
    lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(minutes: 25)),
    masteryLevel: MasteryLevel.learning,
  ),
  WordMasteryRecord(
    word: 'GRAVITY',
    language: 'en',
    clue: 'Universal attractive force between masses',
    reading: 'grav-i-tee',
    timesEncountered: 4,
    timesSolved: 4,
    totalSolveTimeSeconds: 32.0,
    hintTiersHistory: const [1, 1, 2, 1],
    errorClicks: 0,
    lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    masteryLevel: MasteryLevel.mastered,
  ),
  WordMasteryRecord(
    word: 'ALGORITHM',
    language: 'en',
    clue: 'Step-by-step procedure for solving a computational problem',
    reading: 'al-guh-rith-um',
    timesEncountered: 3,
    timesSolved: 1,
    totalSolveTimeSeconds: 62.0,
    hintTiersHistory: const [2, 4],
    errorClicks: 5,
    lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
    masteryLevel: MasteryLevel.needsPractice,
  ),
  WordMasteryRecord(
    word: 'COMPILER',
    language: 'en',
    clue: 'Transforms source code into executable machine instructions',
    reading: 'kuhm-py-ler',
    timesEncountered: 2,
    timesSolved: 2,
    totalSolveTimeSeconds: 38.0,
    hintTiersHistory: const [1, 2],
    errorClicks: 1,
    lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
    masteryLevel: MasteryLevel.learning,
  ),
  WordMasteryRecord(
    word: 'RECURSION',
    language: 'en',
    clue: 'Method where a function calls itself to solve smaller subproblems',
    reading: 'ri-kur-zhun',
    timesEncountered: 3,
    timesSolved: 3,
    totalSolveTimeSeconds: 24.0,
    hintTiersHistory: const [1, 1, 1],
    errorClicks: 0,
    lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(hours: 4)),
    masteryLevel: MasteryLevel.mastered,
  ),
  WordMasteryRecord(
    word: 'QUANTUM',
    language: 'en',
    clue: 'Discrete packet of energy or subatomic particle state',
    reading: 'kwon-tuhm',
    timesEncountered: 2,
    timesSolved: 1,
    totalSolveTimeSeconds: 50.0,
    hintTiersHistory: const [2, 4],
    errorClicks: 3,
    lastEncounteredAt: DateTime.now().toUtc().subtract(const Duration(hours: 5)),
    masteryLevel: MasteryLevel.needsPractice,
  ),
];

/// Riverpod Notifier for the Vocabulary Mastery & Flashcard View.
class MasteryNotifier extends Notifier<MasteryState> {
  @override
  MasteryState build() {
    return const MasteryState();
  }

  /// Sets the active mastery level filter (All, Needs Practice, Learning, Mastered).
  void setFilter(MasteryFilter filter) {
    state = state.copyWith(
      selectedFilter: filter,
      currentCardIndex: 0,
      isCardFlipped: false,
    );
  }

  /// Updates the search query filter.
  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      currentCardIndex: 0,
      isCardFlipped: false,
    );
  }

  /// Selects or clears the active language filter.
  void setLanguage(String? language) {
    state = state.copyWith(
      selectedLanguage: () => language,
      currentCardIndex: 0,
      isCardFlipped: false,
    );
  }

  /// Toggles front/back display of the current flashcard.
  void flipCard() {
    state = state.copyWith(isCardFlipped: !state.isCardFlipped);
  }

  /// Sets the card flip state explicitly.
  void setCardFlipped(bool flipped) {
    state = state.copyWith(isCardFlipped: flipped);
  }

  /// Advances to the next flashcard in the filtered deck.
  void nextCard(int totalCards) {
    if (totalCards <= 0) return;
    final nextIndex = (state.currentCardIndex + 1) % totalCards;
    state = state.copyWith(
      currentCardIndex: nextIndex,
      isCardFlipped: false,
    );
  }

  /// Rewinds to the previous flashcard in the filtered deck.
  void previousCard(int totalCards) {
    if (totalCards <= 0) return;
    final prevIndex =
        (state.currentCardIndex - 1 + totalCards) % totalCards;
    state = state.copyWith(
      currentCardIndex: prevIndex,
      isCardFlipped: false,
    );
  }

  /// Jumps directly to a card index.
  void jumpToCard(int index) {
    state = state.copyWith(
      currentCardIndex: index,
      isCardFlipped: false,
    );
  }

  /// Toggles in-screen review practice mode.
  void toggleReviewMode() {
    state = state.copyWith(isReviewMode: !state.isReviewMode);
  }

  /// Seeds default vocabulary records if player's profile vocabulary deck is empty.
  void seedDefaultDeckIfEmpty() {
    final profile = ref.read(playerProfileProvider);
    if (profile.vocabularyDeck.isEmpty) {
      final deckMap = <String, WordMasteryRecord>{};
      for (final rec in _starterDeck) {
        deckMap['${rec.language}:${rec.word.toUpperCase()}'] = rec;
      }
      ref
          .read(playerProfileProvider.notifier)
          .setProfile(profile.copyWith(vocabularyDeck: deckMap));
    }
  }

  /// Manually updates or adjusts a word's mastery level in the player's profile.
  void updateWordMastery({
    required String word,
    required String language,
    required MasteryLevel newLevel,
  }) {
    final profile = ref.read(playerProfileProvider);
    final key = '$language:${word.toUpperCase()}';
    final existing = profile.vocabularyDeck[key];

    if (existing != null) {
      final updated = existing.copyWith(
        masteryLevel: newLevel,
        lastEncounteredAt: DateTime.now().toUtc(),
      );
      final newDeck = Map<String, WordMasteryRecord>.from(profile.vocabularyDeck);
      newDeck[key] = updated;
      ref
          .read(playerProfileProvider.notifier)
          .setProfile(profile.copyWith(vocabularyDeck: newDeck));
    } else {
      final created = WordMasteryRecord(
        word: word,
        language: language,
        masteryLevel: newLevel,
        lastEncounteredAt: DateTime.now().toUtc(),
      );
      final newDeck = Map<String, WordMasteryRecord>.from(profile.vocabularyDeck);
      newDeck[key] = created;
      ref
          .read(playerProfileProvider.notifier)
          .setProfile(profile.copyWith(vocabularyDeck: newDeck));
    }
  }

  /// Generates a word search puzzle using ONLY un-mastered words
  /// (i.e. [MasteryLevel.needsPractice], [MasteryLevel.learning], or [MasteryLevel.unseen]).
  /// Returns null if no un-mastered words exist in the player's deck.
  Puzzle? generateUnmasteredPuzzle({
    String? language,
    int targetCount = 10,
    Difficulty difficulty = Difficulty.medium,
    ScriptType? scriptType,
  }) {
    final profile = ref.read(playerProfileProvider);

    // Filter strictly for words that are NOT mastered
    var unmastered = profile.vocabularyDeck.values
        .where((w) => w.masteryLevel != MasteryLevel.mastered)
        .toList();

    if (language != null && language.trim().isNotEmpty) {
      unmastered = unmastered
          .where((w) => w.language.toLowerCase() == language.toLowerCase())
          .toList();
    }

    if (unmastered.isEmpty) {
      return null;
    }

    // Sort to prioritize needsPractice first, then learning
    unmastered.sort((a, b) {
      if (a.masteryLevel == MasteryLevel.needsPractice &&
          b.masteryLevel != MasteryLevel.needsPractice) {
        return -1;
      }
      if (b.masteryLevel == MasteryLevel.needsPractice &&
          a.masteryLevel != MasteryLevel.needsPractice) {
        return 1;
      }
      return b.lastEncounteredAt.compareTo(a.lastEncounteredAt);
    });

    final selected = unmastered.take(targetCount).toList();
    final wordsData = selected
        .map((record) => {
              'word': record.word,
              'clue': record.clue ?? 'Review: ${record.word}',
              'reading': record.reading,
            })
        .toList();

    final puzzle = GridEngine.generatePuzzle(
      wordsData: wordsData,
      title: 'Vocabulary Review (${selected.length} Un-mastered Words)',
      theme: 'Un-mastered Vocabulary Deck',
      language: language ?? 'en',
      difficulty: difficulty,
      scriptType: scriptType,
    );

    state = state.copyWith(
      activeReviewPuzzle: () => puzzle,
      reviewGameState: () => GameState.initial(puzzle),
      isReviewMode: true,
    );

    return puzzle;
  }

  /// Starts an un-mastered word search game session, loads it into [gameProvider],
  /// and declaratively routes to the Game Screen via [GoRouter].
  Puzzle? startUnmasteredGameAndNavigate({
    required BuildContext context,
    String? language,
    int targetCount = 10,
    Difficulty difficulty = Difficulty.medium,
  }) {
    final puzzle = generateUnmasteredPuzzle(
      language: language,
      targetCount: targetCount,
      difficulty: difficulty,
    );

    if (puzzle != null) {
      ref.read(gameProvider.notifier).initGame(puzzle);
      try {
        context.go(AppRoutes.game);
      } catch (_) {
        // Fallback for tests or standard navigator contexts
      }
    }

    return puzzle;
  }

  /// Clears active review puzzle practice.
  void exitReviewPractice() {
    state = state.copyWith(
      activeReviewPuzzle: () => null,
      reviewGameState: () => null,
      isReviewMode: false,
    );
  }
}

/// Provider for the [MasteryNotifier] state.
final masteryNotifierProvider =
    NotifierProvider<MasteryNotifier, MasteryState>(MasteryNotifier.new);

/// Provider exposing the filtered list of vocabulary records based on
/// search query, active mastery level filter, and language.
final filteredVocabularyProvider = Provider<List<WordMasteryRecord>>((ref) {
  final profile = ref.watch(playerProfileProvider);
  final masteryState = ref.watch(masteryNotifierProvider);

  return VocabularyDeckManager.filterWords(
    profile: profile,
    language: masteryState.selectedLanguage,
    masteryLevel: masteryState.selectedFilter.toMasteryLevel(),
    searchQuery: masteryState.searchQuery,
  );
});

/// Provider returning only the un-mastered words in the player's deck.
final unmasteredWordsProvider = Provider<List<WordMasteryRecord>>((ref) {
  final profile = ref.watch(playerProfileProvider);
  return profile.vocabularyDeck.values
      .where((w) => w.masteryLevel != MasteryLevel.mastered)
      .toList();
});
