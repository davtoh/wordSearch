import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/word_search/data/pack_repository.dart';

void main() {
  group('PuzzlePack Model Tests', () {
    final samplePackJson = {
      'id': 'animals_pack',
      'title': 'Animal Kingdom',
      'description': 'Puzzles about wildlife.',
      'language': 'en',
      'script_type': 'latin',
      'puzzles': [
        {
          'id': 'mammals',
          'title': 'Mammals',
          'theme': 'Mammals',
          'difficulty': 'easy',
          'words': [
            {'word': 'TIGER', 'clue': 'Large striped feline.'},
            {'word': 'ELEPHANT', 'clue': 'Largest land mammal.'},
            {'word': 'DOLPHIN', 'clue': 'Highly intelligent marine mammal.'},
          ],
        },
        {
          'id': 'birds',
          'title': 'Birds',
          'theme': 'Birds',
          'difficulty': 'medium',
          'words': [
            {'word': 'EAGLE', 'clue': 'Large bird of prey.'},
            {'word': 'FALCON', 'clue': 'Fast flying predator.'},
            {'word': 'PARROT', 'clue': 'Colorful tropical bird.'},
          ],
        },
      ],
    };

    test('parses from JSON and serializes back correctly', () {
      final pack = PuzzlePack.fromJson(samplePackJson);

      expect(pack.id, 'animals_pack');
      expect(pack.title, 'Animal Kingdom');
      expect(pack.description, 'Puzzles about wildlife.');
      expect(pack.language, 'en');
      expect(pack.scriptType, ScriptType.latin);
      expect(pack.puzzleCount, 2);

      final exportedMap = pack.toJson();
      expect(exportedMap['id'], 'animals_pack');
      expect(exportedMap['title'], 'Animal Kingdom');
      expect(exportedMap['puzzles'].length, 2);

      final jsonStr = pack.toJsonString();
      expect(jsonStr, contains('Animal Kingdom'));
    });

    test('generates valid Puzzle from puzzle index', () {
      final pack = PuzzlePack.fromJson(samplePackJson);

      final puzzle = pack.getPuzzle(0);
      expect(puzzle.metadata.title, 'Mammals');
      expect(puzzle.metadata.difficulty, Difficulty.easy);
      expect(puzzle.words.length, 3);
      expect(puzzle.grid.isNotEmpty, isTrue);

      final mediumPuzzle = pack.getPuzzle(0, difficulty: Difficulty.hard);
      expect(mediumPuzzle.metadata.difficulty, Difficulty.hard);
    });

    test('throws RangeError for invalid puzzle index', () {
      final pack = PuzzlePack.fromJson(samplePackJson);

      expect(() => pack.getPuzzle(-1), throwsRangeError);
      expect(() => pack.getPuzzle(5), throwsRangeError);
    });
  });

  group('PackRepository Tests', () {
    test('loads built-in packs on demand', () {
      final repo = PackRepository();
      expect(repo.getAllPacks(), isEmpty);

      repo.loadBuiltInPacks();
      final packs = repo.getAllPacks();
      expect(packs.length, greaterThanOrEqualTo(2));

      final sciencePack = repo.getPackById('english_science');
      expect(sciencePack, isNotNull);
      expect(sciencePack!.title, 'Cosmos & Computing');
      expect(sciencePack.puzzleCount, 2);

      final jaPack = repo.getPackById('japanese_basics');
      expect(jaPack, isNotNull);
      expect(jaPack!.language, 'ja');
      expect(jaPack.scriptType, ScriptType.hiragana);
    });

    test('loads pack from JSON string and supports dynamic registration', () {
      final repo = PackRepository();
      const customJson = '''
      {
        "id": "custom_colors",
        "title": "Vibrant Colors",
        "language": "en",
        "script_type": "latin",
        "puzzles": [
          {
            "id": "primary",
            "title": "Primary Colors",
            "words": [
              {"word": "RED"},
              {"word": "BLUE"},
              {"word": "YELLOW"}
            ]
          }
        ]
      }
      ''';

      final pack = repo.loadPackFromJson(customJson);
      expect(pack.id, 'custom_colors');
      expect(repo.getPackById('custom_colors'), equals(pack));

      final removed = repo.removePack('custom_colors');
      expect(removed, isTrue);
      expect(repo.getPackById('custom_colors'), isNull);
    });

    test('exports puzzle and pack to JSON strings', () {
      final repo = PackRepository();
      repo.loadBuiltInPacks();

      final pack = repo.getPackById('english_science')!;
      final packJson = repo.exportPackToJson(pack);
      expect(packJson, contains('Cosmos & Computing'));

      final puzzle = pack.getPuzzle(0);
      final puzzleJson = repo.exportPuzzleToJson(puzzle);
      final decodedPuzzle = jsonDecode(puzzleJson) as Map<String, dynamic>;
      expect(decodedPuzzle['rows'], equals(puzzle.rows));
      expect(decodedPuzzle['cols'], equals(puzzle.cols));
    });

    test('packRepositoryProvider provides initialized repository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(packRepositoryProvider);
      expect(repo.getAllPacks(), isNotEmpty);
      expect(repo.getPackById('english_science'), isNotNull);
    });
  });
}
