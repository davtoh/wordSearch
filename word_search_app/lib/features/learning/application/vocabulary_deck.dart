/// Searchable and Filterable Vocabulary Deck.
/// Pure Dart — zero Flutter UI dependencies.
/// Ported from learning/vocabulary_deck.py.
library;

import 'package:equatable/equatable.dart';

import '../../../core/models/models.dart';

/// Summary statistical metrics for the player's vocabulary deck.
class VocabularyDeckSummary extends Equatable {
  const VocabularyDeckSummary({
    required this.totalWords,
    required this.mastered,
    required this.learning,
    required this.needsPractice,
    required this.masteryRate,
  });

  final int totalWords;
  final int mastered;
  final int learning;
  final int needsPractice;

  /// Percentage of total words mastered (0.0 – 100.0).
  final double masteryRate;

  @override
  List<Object?> get props => [
        totalWords,
        mastered,
        learning,
        needsPractice,
        masteryRate,
      ];
}

/// Provides querying and filtering over the player's saved vocabulary records.
class VocabularyDeckManager {
  const VocabularyDeckManager._();

  /// Filters player vocabulary records by language, mastery level, and text query.
  /// Results are sorted by most recently encountered descending.
  static List<WordMasteryRecord> filterWords({
    required PlayerProfile profile,
    String? language,
    MasteryLevel? masteryLevel,
    String? searchQuery,
  }) {
    var results = profile.vocabularyDeck.values.toList();

    if (language != null && language.trim().isNotEmpty) {
      results = results
          .where((r) => r.language.toLowerCase() == language.toLowerCase())
          .toList();
    }

    if (masteryLevel != null) {
      results = results.where((r) => r.masteryLevel == masteryLevel).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      results = results.where((r) {
        final matchesWord = r.word.toLowerCase().contains(q);
        final matchesClue =
            r.clue != null && r.clue!.toLowerCase().contains(q);
        final matchesReading =
            r.reading != null && r.reading!.toLowerCase().contains(q);
        return matchesWord || matchesClue || matchesReading;
      }).toList();
    }

    // Sort by most recently encountered descending
    results.sort((a, b) => b.lastEncounteredAt.compareTo(a.lastEncounteredAt));
    return results;
  }

  /// Calculates aggregate mastery statistics for a given profile and optional language.
  static VocabularyDeckSummary getSummaryStats({
    required PlayerProfile profile,
    String? language,
  }) {
    var words = profile.vocabularyDeck.values.toList();
    if (language != null && language.trim().isNotEmpty) {
      words = words
          .where((w) => w.language.toLowerCase() == language.toLowerCase())
          .toList();
    }

    final total = words.length;
    final mastered =
        words.where((w) => w.masteryLevel == MasteryLevel.mastered).length;
    final learning =
        words.where((w) => w.masteryLevel == MasteryLevel.learning).length;
    final needsPractice =
        words.where((w) => w.masteryLevel == MasteryLevel.needsPractice).length;

    final rate = total > 0 ? (mastered / total) * 100.0 : 0.0;
    final roundedRate = double.parse(rate.toStringAsFixed(1));

    return VocabularyDeckSummary(
      totalWords: total,
      mastered: mastered,
      learning: learning,
      needsPractice: needsPractice,
      masteryRate: roundedRate,
    );
  }
}
