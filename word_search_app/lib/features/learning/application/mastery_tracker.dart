/// Vocabulary Mastery and Spaced Learning Classifier.
/// Pure Dart — zero Flutter UI dependencies.
/// Ported from learning/mastery_tracker.py.
library;

import '../../../core/models/models.dart';

/// Classifies vocabulary familiarity based on solve velocity, error rate,
/// and hint dependency.
class MasteryTracker {
  const MasteryTracker._();

  /// Updates or creates a vocabulary mastery record in the player's profile,
  /// returning the updated [PlayerProfile] and [WordMasteryRecord].
  static (PlayerProfile, WordMasteryRecord) updateWordProgress({
    required PlayerProfile profile,
    required WordEntry wordEntry,
    required double solveTimeSeconds,
    int errorClicks = 0,
    String language = 'en',
    DateTime? now,
    double needsPracticeThreshold = 45.0,
  }) {
    final key = '$language:${wordEntry.word.toUpperCase()}';
    final existing = profile.vocabularyDeck[key];

    final base = existing ??
        WordMasteryRecord(
          word: wordEntry.word,
          language: language,
          clue: wordEntry.clue,
          reading: wordEntry.reading,
        );

    final updatedSolved =
        wordEntry.found ? base.timesSolved + 1 : base.timesSolved;
    final updatedSolveTime = wordEntry.found
        ? base.totalSolveTimeSeconds + solveTimeSeconds
        : base.totalSolveTimeSeconds;
    final updatedHints = [
      ...base.hintTiersHistory,
      wordEntry.hintTierUsed.level,
    ];
    final updatedErrorClicks = base.errorClicks + errorClicks;
    final timestamp = now ?? DateTime.now().toUtc();

    // Intermediate record to compute mastery level
    final candidate = base.copyWith(
      timesEncountered: base.timesEncountered + 1,
      timesSolved: updatedSolved,
      totalSolveTimeSeconds: updatedSolveTime,
      hintTiersHistory: updatedHints,
      errorClicks: updatedErrorClicks,
      lastEncounteredAt: timestamp,
    );

    final evaluatedLevel = evaluateMasteryLevel(
      candidate,
      needsPracticeThreshold: needsPracticeThreshold,
    );
    final finalized = candidate.copyWith(masteryLevel: evaluatedLevel);

    final newDeck = Map<String, WordMasteryRecord>.from(profile.vocabularyDeck);
    newDeck[key] = finalized;

    final updatedProfile = profile.copyWith(vocabularyDeck: newDeck);
    return (updatedProfile, finalized);
  }

  /// Determines if a word is [MasteryLevel.mastered], [MasteryLevel.learning],
  /// or [MasteryLevel.needsPractice].
  static MasteryLevel evaluateMasteryLevel(
    WordMasteryRecord record, {
    double needsPracticeThreshold = 45.0,
  }) {
    if (record.timesSolved == 0) {
      return MasteryLevel.needsPractice;
    }

    final avgTime = record.averageSolveTime;
    final maxHint = record.hintTiersHistory.isNotEmpty
        ? record.hintTiersHistory.reduce((a, b) => a > b ? a : b)
        : 0;

    // Needs practice: slow (>45s) or required heavy hints (Tier 4+) or high errors (>=3/encounter)
    final errorRatio = record.timesEncountered > 0
        ? record.errorClicks / record.timesEncountered
        : 0.0;

    if (avgTime > needsPracticeThreshold ||
        maxHint >= HintTier.tier4Orientation.level ||
        errorRatio >= 3.0) {
      return MasteryLevel.needsPractice;
    }

    // Mastered: solved at least twice, very fast (<=15s), minimal hints (Tier 2 or less)
    if (record.timesSolved >= 2 &&
        avgTime <= 15.0 &&
        maxHint <= HintTier.tier2WordName.level) {
      return MasteryLevel.mastered;
    }

    return MasteryLevel.learning;
  }
}
