/// Riverpod State Management for Player Profile and Vocabulary Mastery Deck.
library;

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import 'mastery_tracker.dart';
import 'vocabulary_deck.dart';

/// State notifier managing the persistent [PlayerProfile].
class PlayerProfileNotifier extends Notifier<PlayerProfile> {
  @override
  PlayerProfile build() {
    return const PlayerProfile();
  }

  /// Sets the entire profile (e.g. after loading from disk or cloud).
  void setProfile(PlayerProfile profile) {
    state = profile;
  }

  /// Records the solve metrics for a single word in the vocabulary deck.
  WordMasteryRecord recordWordSolve({
    required WordEntry wordEntry,
    required double solveTimeSeconds,
    int errorClicks = 0,
    String language = 'en',
  }) {
    final (updatedProfile, record) = MasteryTracker.updateWordProgress(
      profile: state,
      wordEntry: wordEntry,
      solveTimeSeconds: solveTimeSeconds,
      errorClicks: errorClicks,
      language: language,
    );

    state = updatedProfile;
    return record;
  }

  /// Adds a list of words to the player's vocabulary deck.
  List<WordMasteryRecord> addWordsToLearnDeck({
    required List<WordEntry> words,
    double solveTimeSeconds = 0.0,
    String language = 'en',
  }) {
    final records = <WordMasteryRecord>[];
    for (final word in words) {
      final rec = recordWordSolve(
        wordEntry: word,
        solveTimeSeconds: words.isNotEmpty && solveTimeSeconds > 0
            ? solveTimeSeconds / words.length
            : 10.0,
        language: language,
      );
      records.add(rec);
    }
    return records;
  }

  /// Records completion metrics for a finished game session.
  void recordGameFinished({
    required bool won,
    required int wordsFound,
    required double playTimeSeconds,
    String? timedAttackKey,
    int? timedAttackScore,
  }) {
    final totalGames = state.totalGamesPlayed + 1;
    final totalWon = won ? state.totalGamesWon + 1 : state.totalGamesWon;
    final totalWords = state.totalWordsFound + wordsFound;
    final totalPlayTime = state.totalPlayTimeSeconds + playTimeSeconds;

    // Calculate velocity (seconds per word found)
    final sessionSpw =
        wordsFound > 0 ? playTimeSeconds / wordsFound : 0.0;
    final bestSpw = state.bestVelocitySpw == 0.0
        ? sessionSpw
        : (sessionSpw > 0.0 ? min(state.bestVelocitySpw, sessionSpw) : state.bestVelocitySpw);

    final highScores =
        Map<String, int>.from(state.timedAttackHighScores);
    if (timedAttackKey != null && timedAttackScore != null) {
      final prevBest = highScores[timedAttackKey] ?? 0;
      if (timedAttackScore > prevBest) {
        highScores[timedAttackKey] = timedAttackScore;
      }
    }

    state = state.copyWith(
      totalGamesPlayed: totalGames,
      totalGamesWon: totalWon,
      totalWordsFound: totalWords,
      totalPlayTimeSeconds: totalPlayTime,
      bestVelocitySpw: bestSpw,
      timedAttackHighScores: highScores,
    );
  }

  /// Resets the player's profile to default state.
  void resetProfile() {
    state = const PlayerProfile();
  }
}

/// Provider for the active player profile.
final playerProfileProvider =
    NotifierProvider<PlayerProfileNotifier, PlayerProfile>(
  PlayerProfileNotifier.new,
);

/// Provider for vocabulary deck summary metrics.
final vocabularySummaryProvider = Provider<VocabularyDeckSummary>((ref) {
  final profile = ref.watch(playerProfileProvider);
  return VocabularyDeckManager.getSummaryStats(profile: profile);
});
