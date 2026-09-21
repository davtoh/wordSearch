/// Player profile and vocabulary mastery tracking models.
/// Pure Dart — zero Flutter UI dependencies.
library;

import 'package:equatable/equatable.dart';

import 'enums.dart';

// ─────────────────────────────────────────────────────────
// WordMasteryRecord
// ─────────────────────────────────────────────────────────

/// Tracks a player's mastery metrics for a single vocabulary word.
class WordMasteryRecord extends Equatable {
  WordMasteryRecord({
    required this.word,
    this.language = 'en',
    this.clue,
    this.reading,
    this.timesEncountered = 0,
    this.timesSolved = 0,
    this.totalSolveTimeSeconds = 0.0,
    this.hintTiersHistory = const [],
    this.errorClicks = 0,
    DateTime? lastEncounteredAt,
    this.masteryLevel = MasteryLevel.unseen,
  }) : lastEncounteredAt = lastEncounteredAt ?? DateTime.now().toUtc();

  final String word;
  final String language;
  final String? clue;
  final String? reading;
  final int timesEncountered;
  final int timesSolved;
  final double totalSolveTimeSeconds;

  /// List of hint tier levels used across all encounters.
  final List<int> hintTiersHistory;
  final int errorClicks;
  final DateTime lastEncounteredAt;
  final MasteryLevel masteryLevel;

  /// Average seconds-per-word solve time (0 if never solved).
  double get averageSolveTime =>
      totalSolveTimeSeconds / (timesSolved > 0 ? timesSolved : 1);

  WordMasteryRecord copyWith({
    String? word,
    String? language,
    String? clue,
    String? reading,
    int? timesEncountered,
    int? timesSolved,
    double? totalSolveTimeSeconds,
    List<int>? hintTiersHistory,
    int? errorClicks,
    DateTime? lastEncounteredAt,
    MasteryLevel? masteryLevel,
  }) =>
      WordMasteryRecord(
        word: word ?? this.word,
        language: language ?? this.language,
        clue: clue ?? this.clue,
        reading: reading ?? this.reading,
        timesEncountered: timesEncountered ?? this.timesEncountered,
        timesSolved: timesSolved ?? this.timesSolved,
        totalSolveTimeSeconds:
            totalSolveTimeSeconds ?? this.totalSolveTimeSeconds,
        hintTiersHistory: hintTiersHistory ?? this.hintTiersHistory,
        errorClicks: errorClicks ?? this.errorClicks,
        lastEncounteredAt: lastEncounteredAt ?? this.lastEncounteredAt,
        masteryLevel: masteryLevel ?? this.masteryLevel,
      );

  factory WordMasteryRecord.fromJson(Map<String, dynamic> json) =>
      WordMasteryRecord(
        word: json['word'] as String,
        language: json['language'] as String? ?? 'en',
        clue: json['clue'] as String?,
        reading: json['reading'] as String?,
        timesEncountered: json['times_encountered'] as int? ?? 0,
        timesSolved: json['times_solved'] as int? ?? 0,
        totalSolveTimeSeconds:
            (json['total_solve_time_seconds'] as num?)?.toDouble() ?? 0.0,
        hintTiersHistory:
            (json['hint_tiers_history'] as List<dynamic>?)?.cast<int>() ??
                const [],
        errorClicks: json['error_clicks'] as int? ?? 0,
        lastEncounteredAt: json['last_encountered_at'] != null
            ? DateTime.parse(json['last_encountered_at'] as String)
            : null,
        masteryLevel: MasteryLevel.fromValue(
            json['mastery_level'] as String? ?? 'unseen'),
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'language': language,
        if (clue != null) 'clue': clue,
        if (reading != null) 'reading': reading,
        'times_encountered': timesEncountered,
        'times_solved': timesSolved,
        'total_solve_time_seconds': totalSolveTimeSeconds,
        'hint_tiers_history': hintTiersHistory,
        'error_clicks': errorClicks,
        'last_encountered_at': lastEncounteredAt.toIso8601String(),
        'mastery_level': masteryLevel.value,
      };

  @override
  List<Object?> get props => [
        word, language, clue, reading, timesEncountered, timesSolved,
        totalSolveTimeSeconds, hintTiersHistory, errorClicks,
        lastEncounteredAt, masteryLevel,
      ];
}

// ─────────────────────────────────────────────────────────
// PlayerProfile
// ─────────────────────────────────────────────────────────

/// Persistent player profile with cumulative statistics and vocabulary deck.
class PlayerProfile extends Equatable {
  const PlayerProfile({
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalWordsFound = 0,
    this.totalPlayTimeSeconds = 0.0,
    this.bestVelocitySpw = 0.0,
    this.overallAccuracy = 100.0,
    this.timedAttackHighScores = const {},
    this.vocabularyDeck = const {},
  });

  final int totalGamesPlayed;
  final int totalGamesWon;
  final int totalWordsFound;

  /// Cumulative play time in seconds.
  final double totalPlayTimeSeconds;

  /// Best seconds-per-word velocity (lower is faster).
  final double bestVelocitySpw;

  /// Overall accuracy percentage (0–100).
  final double overallAccuracy;

  /// Map of difficulty/mode key → highest score achieved.
  final Map<String, int> timedAttackHighScores;

  /// Map of word string → [WordMasteryRecord].
  final Map<String, WordMasteryRecord> vocabularyDeck;

  PlayerProfile copyWith({
    int? totalGamesPlayed,
    int? totalGamesWon,
    int? totalWordsFound,
    double? totalPlayTimeSeconds,
    double? bestVelocitySpw,
    double? overallAccuracy,
    Map<String, int>? timedAttackHighScores,
    Map<String, WordMasteryRecord>? vocabularyDeck,
  }) =>
      PlayerProfile(
        totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
        totalGamesWon: totalGamesWon ?? this.totalGamesWon,
        totalWordsFound: totalWordsFound ?? this.totalWordsFound,
        totalPlayTimeSeconds: totalPlayTimeSeconds ?? this.totalPlayTimeSeconds,
        bestVelocitySpw: bestVelocitySpw ?? this.bestVelocitySpw,
        overallAccuracy: overallAccuracy ?? this.overallAccuracy,
        timedAttackHighScores:
            timedAttackHighScores ?? this.timedAttackHighScores,
        vocabularyDeck: vocabularyDeck ?? this.vocabularyDeck,
      );

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        totalGamesPlayed: json['total_games_played'] as int? ?? 0,
        totalGamesWon: json['total_games_won'] as int? ?? 0,
        totalWordsFound: json['total_words_found'] as int? ?? 0,
        totalPlayTimeSeconds:
            (json['total_play_time_seconds'] as num?)?.toDouble() ?? 0.0,
        bestVelocitySpw:
            (json['best_velocity_spw'] as num?)?.toDouble() ?? 0.0,
        overallAccuracy:
            (json['overall_accuracy'] as num?)?.toDouble() ?? 100.0,
        timedAttackHighScores:
            (json['timed_attack_high_scores'] as Map<String, dynamic>?)
                    ?.cast<String, int>() ??
                const {},
        vocabularyDeck: (json['vocabulary_deck'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(
                    k,
                    WordMasteryRecord.fromJson(
                        v as Map<String, dynamic>))) ??
            const {},
      );

  Map<String, dynamic> toJson() => {
        'total_games_played': totalGamesPlayed,
        'total_games_won': totalGamesWon,
        'total_words_found': totalWordsFound,
        'total_play_time_seconds': totalPlayTimeSeconds,
        'best_velocity_spw': bestVelocitySpw,
        'overall_accuracy': overallAccuracy,
        'timed_attack_high_scores': timedAttackHighScores,
        'vocabulary_deck':
            vocabularyDeck.map((k, v) => MapEntry(k, v.toJson())),
      };

  @override
  List<Object?> get props => [
        totalGamesPlayed, totalGamesWon, totalWordsFound,
        totalPlayTimeSeconds, bestVelocitySpw, overallAccuracy,
        timedAttackHighScores, vocabularyDeck,
      ];
}

