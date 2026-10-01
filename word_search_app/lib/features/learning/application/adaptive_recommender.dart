/// Targeted Practice Recommender and Review Puzzle Generator.
/// Pure Dart — zero Flutter UI dependencies.
/// Ported from learning/adaptive_recommender.py.
library;

import 'dart:math';

import '../../../core/engine/grid_engine.dart';
import '../../../core/models/models.dart';

/// Generates targeted review vocabulary lists composed of words the user found difficult.
class AdaptiveRecommender {
  const AdaptiveRecommender._();

  /// Selects candidate review words prioritizing [MasteryLevel.needsPractice],
  /// then [MasteryLevel.learning], and lastly [MasteryLevel.mastered].
  /// Returns a list of maps formatted with `'word'`, `'clue'`, and `'reading'`.
  static List<Map<String, String?>> getReviewWords({
    required PlayerProfile profile,
    String language = 'en',
    int targetCount = 10,
    Random? random,
  }) {
    final rng = random ?? Random();

    final allWords = profile.vocabularyDeck.values
        .where((w) => w.language.toLowerCase() == language.toLowerCase())
        .toList();

    final needsPractice = allWords
        .where((w) => w.masteryLevel == MasteryLevel.needsPractice)
        .toList()
      ..shuffle(rng);
    final learning = allWords
        .where((w) => w.masteryLevel == MasteryLevel.learning)
        .toList()
      ..shuffle(rng);
    final mastered = allWords
        .where((w) => w.masteryLevel == MasteryLevel.mastered)
        .toList()
      ..shuffle(rng);

    final selected = <WordMasteryRecord>[];

    // 1. Fill with difficult words first
    selected.addAll(needsPractice.take(targetCount));

    // 2. Fill remainder with learning words
    if (selected.length < targetCount) {
      final remainder = targetCount - selected.length;
      selected.addAll(learning.take(remainder));
    }

    // 3. If still not enough, add random mastered words for reinforcement
    if (selected.length < targetCount) {
      final remainder = targetCount - selected.length;
      selected.addAll(mastered.take(remainder));
    }

    return selected
        .map((record) => {
              'word': record.word,
              'clue': record.clue ?? 'Review word: ${record.word}',
              'reading': record.reading,
            })
        .toList();
  }

  /// Directly generates a review [Puzzle] using the player's weak vocabulary.
  static Puzzle? generateReviewPuzzle({
    required PlayerProfile profile,
    String language = 'en',
    int targetCount = 10,
    Difficulty difficulty = Difficulty.medium,
    ScriptType? scriptType,
    Random? random,
  }) {
    final reviewWords = getReviewWords(
      profile: profile,
      language: language,
      targetCount: targetCount,
      random: random,
    );

    if (reviewWords.isEmpty) return null;

    return GridEngine.generatePuzzle(
      wordsData: reviewWords,
      title: 'Targeted Review ($language)',
      theme: 'Spaced Repetition Review',
      language: language,
      difficulty: difficulty,
      scriptType: scriptType,
    );
  }
}
