import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/learning/application/adaptive_recommender.dart';
import 'package:word_search_app/features/learning/application/learning_provider.dart';
import 'package:word_search_app/features/learning/application/mastery_tracker.dart';
import 'package:word_search_app/features/learning/application/vocabulary_deck.dart';

void main() {
  group('MasteryTracker Classification Tests', () {
    test('classifies 0 solves as needsPractice', () {
      final record = WordMasteryRecord(
        word: 'GALAXY',
        timesEncountered: 1,
        timesSolved: 0,
      );

      final level = MasteryTracker.evaluateMasteryLevel(record);
      expect(level, MasteryLevel.needsPractice);
    });

    test('classifies fast solve with minimal hints as mastered', () {
      final record = WordMasteryRecord(
        word: 'PLANET',
        timesEncountered: 2,
        timesSolved: 2,
        totalSolveTimeSeconds: 20.0, // avg 10.0s (<=15s)
        hintTiersHistory: const [1, 2], // max tier 2
        errorClicks: 1,
      );

      final level = MasteryTracker.evaluateMasteryLevel(record);
      expect(level, MasteryLevel.mastered);
    });

    test('classifies slow solve (>45s) as needsPractice', () {
      final record = WordMasteryRecord(
        word: 'SUPERNOVA',
        timesEncountered: 2,
        timesSolved: 2,
        totalSolveTimeSeconds: 100.0, // avg 50.0s (>45s)
        hintTiersHistory: const [1, 1],
      );

      final level = MasteryTracker.evaluateMasteryLevel(record);
      expect(level, MasteryLevel.needsPractice);
    });

    test('classifies heavy hint dependency (Tier 4+) as needsPractice', () {
      final record = WordMasteryRecord(
        word: 'PULSAR',
        timesEncountered: 2,
        timesSolved: 2,
        totalSolveTimeSeconds: 20.0,
        hintTiersHistory: const [1, 4], // Tier 4 used
      );

      final level = MasteryTracker.evaluateMasteryLevel(record);
      expect(level, MasteryLevel.needsPractice);
    });

    test('classifies high error click ratio (>=3.0) as needsPractice', () {
      final record = WordMasteryRecord(
        word: 'QUASAR',
        timesEncountered: 2,
        timesSolved: 2,
        totalSolveTimeSeconds: 20.0,
        hintTiersHistory: const [1, 1],
        errorClicks: 7, // 7 / 2 = 3.5 >= 3.0
      );

      final level = MasteryTracker.evaluateMasteryLevel(record);
      expect(level, MasteryLevel.needsPractice);
    });

    test('classifies moderate performance as learning', () {
      final record = WordMasteryRecord(
        word: 'ASTEROID',
        timesEncountered: 1,
        timesSolved: 1,
        totalSolveTimeSeconds: 25.0, // avg 25s
        hintTiersHistory: const [2],
        errorClicks: 1,
      );

      final level = MasteryTracker.evaluateMasteryLevel(record);
      expect(level, MasteryLevel.learning);
    });

    test('updateWordProgress updates profile and history accurately', () {
      const initialProfile = PlayerProfile();
      const entry = WordEntry(
        word: 'COMET',
        clue: 'An icy celestial body.',
        found: true,
        hintTierUsed: HintTier.tier1Clue,
      );

      final (profile1, record1) = MasteryTracker.updateWordProgress(
        profile: initialProfile,
        wordEntry: entry,
        solveTimeSeconds: 12.0,
        errorClicks: 1,
        language: 'en',
      );

      expect(profile1.vocabularyDeck.length, 1);
      expect(record1.word, 'COMET');
      expect(record1.timesEncountered, 1);
      expect(record1.timesSolved, 1);
      expect(record1.totalSolveTimeSeconds, 12.0);
      expect(record1.hintTiersHistory, [1]);
      expect(record1.masteryLevel, MasteryLevel.learning); // solved once so far

      // Second solve - fast with Tier 2 hint -> should become mastered
      final entry2 = entry.copyWith(hintTierUsed: HintTier.tier2WordName);
      final (profile2, record2) = MasteryTracker.updateWordProgress(
        profile: profile1,
        wordEntry: entry2,
        solveTimeSeconds: 8.0,
        errorClicks: 0,
        language: 'en',
      );

      expect(record2.timesSolved, 2);
      expect(record2.totalSolveTimeSeconds, 20.0); // 12 + 8
      expect(record2.averageSolveTime, 10.0);
      expect(record2.hintTiersHistory, [1, 2]);
      expect(record2.masteryLevel, MasteryLevel.mastered);
      expect(profile2.vocabularyDeck['en:COMET']?.masteryLevel,
          MasteryLevel.mastered);
    });
  });

  group('VocabularyDeckManager Filtering & Stats Tests', () {
    late PlayerProfile testProfile;

    setUp(() {
      final now = DateTime.now().toUtc();
      testProfile = PlayerProfile(
        vocabularyDeck: {
          'en:ORBIT': WordMasteryRecord(
            word: 'ORBIT',
            language: 'en',
            clue: 'Curved trajectory around a body.',
            timesEncountered: 3,
            timesSolved: 3,
            totalSolveTimeSeconds: 30.0,
            masteryLevel: MasteryLevel.mastered,
            lastEncounteredAt: now.subtract(const Duration(minutes: 5)),
          ),
          'en:GRAVITY': WordMasteryRecord(
            word: 'GRAVITY',
            language: 'en',
            clue: 'Attractive force between masses.',
            timesEncountered: 2,
            timesSolved: 1,
            totalSolveTimeSeconds: 70.0,
            masteryLevel: MasteryLevel.needsPractice,
            lastEncounteredAt: now.subtract(const Duration(minutes: 2)),
          ),
          'en:ECLIPSE': WordMasteryRecord(
            word: 'ECLIPSE',
            language: 'en',
            clue: 'Celestial shadow phenomenon.',
            timesEncountered: 1,
            timesSolved: 1,
            totalSolveTimeSeconds: 22.0,
            masteryLevel: MasteryLevel.learning,
            lastEncounteredAt: now,
          ),
          'ja:NEBULA': WordMasteryRecord(
            word: 'せいうん',
            language: 'ja',
            clue: 'Interstellar gas cloud.',
            reading: 'seiun',
            timesEncountered: 1,
            timesSolved: 1,
            totalSolveTimeSeconds: 15.0,
            masteryLevel: MasteryLevel.learning,
            lastEncounteredAt: now.subtract(const Duration(hours: 1)),
          ),
        },
      );
    });

    test('filters by language', () {
      final enWords = VocabularyDeckManager.filterWords(
        profile: testProfile,
        language: 'en',
      );
      expect(enWords.length, 3);
      expect(enWords.every((w) => w.language == 'en'), isTrue);

      final jaWords = VocabularyDeckManager.filterWords(
        profile: testProfile,
        language: 'ja',
      );
      expect(jaWords.length, 1);
      expect(jaWords.first.word, 'せいうん');
    });

    test('filters by mastery level', () {
      final mastered = VocabularyDeckManager.filterWords(
        profile: testProfile,
        masteryLevel: MasteryLevel.mastered,
      );
      expect(mastered.length, 1);
      expect(mastered.first.word, 'ORBIT');

      final needsPractice = VocabularyDeckManager.filterWords(
        profile: testProfile,
        masteryLevel: MasteryLevel.needsPractice,
      );
      expect(needsPractice.length, 1);
      expect(needsPractice.first.word, 'GRAVITY');
    });

    test('filters by search query across word, clue, and reading', () {
      final queryByClue = VocabularyDeckManager.filterWords(
        profile: testProfile,
        searchQuery: 'shadow',
      );
      expect(queryByClue.length, 1);
      expect(queryByClue.first.word, 'ECLIPSE');

      final queryByReading = VocabularyDeckManager.filterWords(
        profile: testProfile,
        searchQuery: 'seiun',
      );
      expect(queryByReading.length, 1);
      expect(queryByReading.first.word, 'せいうん');
    });

    test('orders filtered results by most recently encountered first', () {
      final all = VocabularyDeckManager.filterWords(
        profile: testProfile,
        language: 'en',
      );
      // ECLIPSE was encountered at now, GRAVITY at -2m, ORBIT at -5m
      expect(all[0].word, 'ECLIPSE');
      expect(all[1].word, 'GRAVITY');
      expect(all[2].word, 'ORBIT');
    });

    test('computes summary statistics accurately', () {
      final summaryEn = VocabularyDeckManager.getSummaryStats(
        profile: testProfile,
        language: 'en',
      );
      expect(summaryEn.totalWords, 3);
      expect(summaryEn.mastered, 1);
      expect(summaryEn.learning, 1);
      expect(summaryEn.needsPractice, 1);
      expect(summaryEn.masteryRate, 33.3); // 1 / 3 = 33.3%

      final summaryAll = VocabularyDeckManager.getSummaryStats(
        profile: testProfile,
      );
      expect(summaryAll.totalWords, 4);
      expect(summaryAll.mastered, 1);
      expect(summaryAll.learning, 2);
      expect(summaryAll.needsPractice, 1);
      expect(summaryAll.masteryRate, 25.0); // 1 / 4 = 25.0%
    });
  });

  group('AdaptiveRecommender Tests', () {
    late PlayerProfile profile;

    setUp(() {
      profile = PlayerProfile(
        vocabularyDeck: {
          'en:HARD1': WordMasteryRecord(
            word: 'HARD1',
            language: 'en',
            masteryLevel: MasteryLevel.needsPractice,
          ),
          'en:HARD2': WordMasteryRecord(
            word: 'HARD2',
            language: 'en',
            masteryLevel: MasteryLevel.needsPractice,
          ),
          'en:LEARN1': WordMasteryRecord(
            word: 'LEARN1',
            language: 'en',
            masteryLevel: MasteryLevel.learning,
          ),
          'en:LEARN2': WordMasteryRecord(
            word: 'LEARN2',
            language: 'en',
            masteryLevel: MasteryLevel.learning,
          ),
          'en:MASTER1': WordMasteryRecord(
            word: 'MASTER1',
            language: 'en',
            masteryLevel: MasteryLevel.mastered,
          ),
        },
      );
    });

    test('prioritizes needsPractice then learning', () {
      final words = AdaptiveRecommender.getReviewWords(
        profile: profile,
        language: 'en',
        targetCount: 3,
        random: Random(42),
      );

      expect(words.length, 3);
      final wordStrings = words.map((w) => w['word']).toList();
      // Should contain both HARD words
      expect(wordStrings.where((w) => w!.startsWith('HARD')).length, 2);
      // And 1 LEARN word
      expect(wordStrings.where((w) => w!.startsWith('LEARN')).length, 1);
    });

    test('generates review puzzle from difficult vocabulary', () {
      final puzzle = AdaptiveRecommender.generateReviewPuzzle(
        profile: profile,
        language: 'en',
        targetCount: 4,
        difficulty: Difficulty.easy,
        random: Random(42),
      );

      expect(puzzle, isNotNull);
      expect(puzzle!.metadata.title, contains('Targeted Review'));
      expect(puzzle.words.length, 4);
      expect(puzzle.grid.isNotEmpty, isTrue);
    });
  });

  group('Riverpod PlayerProfileNotifier Tests', () {
    test('records word solve and updates deck in provider state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playerProfileProvider.notifier);
      const entry = WordEntry(
        word: 'PULSAR',
        clue: 'Rotating neutron star.',
        found: true,
        hintTierUsed: HintTier.none,
      );

      final record = notifier.recordWordSolve(
        wordEntry: entry,
        solveTimeSeconds: 11.5,
      );

      expect(record.word, 'PULSAR');
      final updatedProfile = container.read(playerProfileProvider);
      expect(updatedProfile.vocabularyDeck['en:PULSAR'], isNotNull);

      // Check summary provider
      final summary = container.read(vocabularySummaryProvider);
      expect(summary.totalWords, 1);
      expect(summary.learning, 1);
    });

    test('records game completion metrics and high score tracking', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playerProfileProvider.notifier);
      notifier.recordGameFinished(
        won: true,
        wordsFound: 5,
        playTimeSeconds: 50.0,
        timedAttackKey: 'easy_60s',
        timedAttackScore: 450,
      );

      var profile = container.read(playerProfileProvider);
      expect(profile.totalGamesPlayed, 1);
      expect(profile.totalGamesWon, 1);
      expect(profile.totalWordsFound, 5);
      expect(profile.totalPlayTimeSeconds, 50.0);
      expect(profile.bestVelocitySpw, 10.0); // 50s / 5 words
      expect(profile.timedAttackHighScores['easy_60s'], 450);

      // Higher score replaces previous best
      notifier.recordGameFinished(
        won: true,
        wordsFound: 6,
        playTimeSeconds: 48.0,
        timedAttackKey: 'easy_60s',
        timedAttackScore: 600,
      );

      profile = container.read(playerProfileProvider);
      expect(profile.totalGamesPlayed, 2);
      expect(profile.bestVelocitySpw, 8.0); // 48s / 6 = 8.0 < 10.0
      expect(profile.timedAttackHighScores['easy_60s'], 600);

      // Reset restores defaults
      notifier.resetProfile();
      profile = container.read(playerProfileProvider);
      expect(profile.totalGamesPlayed, 0);
      expect(profile.timedAttackHighScores, isEmpty);
    });
  });
}
