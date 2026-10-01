import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/ai/application/gemini_service.dart';

void main() {
  group('GeminiService Tests', () {
    test('unconfigured service falls back to offline default words', () async {
      final service = GeminiService(apiKey: null);
      expect(service.isConfigured, isFalse);

      final words = await service.generateWords(topic: 'Space', count: 5);
      expect(words.length, 5);
      expect(words.first['word'], isNotEmpty);
      expect(words.first['clue'], isNotEmpty);
    });

    test('offline fallback limits count properly', () {
      final fallback3 = GeminiService.offlineFallback('Tech', count: 3);
      expect(fallback3.length, 3);

      final fallbackAll = GeminiService.offlineFallback('Tech', count: 50);
      expect(fallbackAll.length, 8); // max available offline defaults
    });

    test('generates words successfully from mocked JSON response', () async {
      final mockJson = jsonEncode([
        {'word': 'PLANET', 'clue': 'A celestial body orbiting a star.'},
        {'word': 'ASTEROID', 'clue': 'A minor planet of the inner Solar System.'},
        {'word': 'COMET', 'clue': 'An icy celestial body.'},
      ]);

      final service = GeminiService(
        apiKey: 'test-api-key',
        rawJsonGenerator: (instruction, prompt) async {
          expect(instruction, contains('lexicographer'));
          expect(prompt, contains('Astronomy'));
          return mockJson;
        },
      );

      expect(service.isConfigured, isTrue);

      final words = await service.generateWords(
        topic: 'Astronomy',
        count: 3,
        difficulty: Difficulty.medium,
      );

      expect(words.length, 3);
      expect(words[0]['word'], 'PLANET');
      expect(words[0]['clue'], 'A celestial body orbiting a star.');
      expect(words[1]['word'], 'ASTEROID');
      expect(words[2]['word'], 'COMET');
    });

    test('cleans markdown codeblocks from AI output', () async {
      const wrappedJson = '''```json
[
  {"word": "QUANTUM", "clue": "Discrete packet of energy.", "reading": null},
  {"word": "PHOTON", "clue": "Particle representing a quantum of light.", "reading": null}
]
```''';

      final service = GeminiService(
        apiKey: 'test-key',
        rawJsonGenerator: (_, _) async => wrappedJson,
      );

      final words = await service.generateWords(topic: 'Physics', count: 2);
      expect(words.length, 2);
      expect(words[0]['word'], 'QUANTUM');
      expect(words[1]['word'], 'PHOTON');
    });

    test('gracefully falls back on malformed JSON or exception', () async {
      final service = GeminiService(
        apiKey: 'test-key',
        rawJsonGenerator: (_, _) async {
          throw Exception('Network connection timed out');
        },
      );

      final words = await service.generateWords(topic: 'Biology', count: 4);
      expect(words.length, 4);
      expect(words.first['word'], 'SEARCH');
    });

    test('generatePuzzle creates a valid complete Puzzle object', () async {
      final mockJson = jsonEncode([
        {'word': 'ALPHA', 'clue': 'First letter.'},
        {'word': 'BETA', 'clue': 'Second letter.'},
        {'word': 'GAMMA', 'clue': 'Third letter.'},
      ]);

      final service = GeminiService(
        apiKey: 'test-key',
        rawJsonGenerator: (_, _) async => mockJson,
      );

      final puzzle = await service.generatePuzzle(
        topic: 'Greek Alphabet',
        count: 3,
        difficulty: Difficulty.easy,
      );

      expect(puzzle.metadata.title, 'Greek Alphabet');
      expect(puzzle.metadata.theme, 'Greek Alphabet');
      expect(puzzle.words.length, 3);
      expect(puzzle.rows, greaterThanOrEqualTo(8));
      expect(puzzle.cols, greaterThanOrEqualTo(8));
      expect(puzzle.grid.length, puzzle.rows);
      expect(puzzle.grid[0].length, puzzle.cols);
    });

    test('Riverpod geminiServiceProvider provides service instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(geminiServiceProvider);
      expect(service, isNotNull);
      expect(service, isA<GeminiService>());
    });
  });
}
