import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/models/models.dart';
import 'package:word_search_app/features/packs/data/pack_repository.dart';

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

      final hardPuzzle = pack.getPuzzle(0, difficulty: Difficulty.hard);
      expect(hardPuzzle.metadata.difficulty, Difficulty.hard);
    });

    test('throws RangeError for invalid puzzle index', () {
      final pack = PuzzlePack.fromJson(samplePackJson);

      expect(() => pack.getPuzzle(-1), throwsRangeError);
      expect(() => pack.getPuzzle(5), throwsRangeError);
    });
  });

  group('Built-in Script Pools Tests (core/scripts.py Port)', () {
    test('returns all 5 built-in script pools with correct metadata', () {
      final repo = PackRepository();
      final pools = repo.getBuiltInScriptPools();

      expect(pools.length, equals(5));

      final scriptTypes = pools.map((p) => p.scriptType).toList();
      expect(scriptTypes, containsAll([
        ScriptType.latinAccented,
        ScriptType.hiragana,
        ScriptType.katakana,
        ScriptType.kanji,
        ScriptType.cyrillic,
      ]));

      // Spanish accents verification
      final spanish = pools.firstWhere((p) => p.scriptType == ScriptType.latinAccented);
      expect(spanish.name, 'Spanish Accents');
      expect(spanish.poolChars, containsAll(['Ñ', 'Á', 'É', 'Í', 'Ó', 'Ú', 'Ü']));
      expect(spanish.sampleWords, contains('CORAZÓN'));

      // Hiragana verification
      final hiragana = pools.firstWhere((p) => p.scriptType == ScriptType.hiragana);
      expect(hiragana.name, 'Hiragana');
      expect(hiragana.poolChars, containsAll(['あ', 'い', 'う', 'え', 'お']));
      expect(hiragana.sampleWords, contains('おはよう'));

      // Katakana verification
      final katakana = pools.firstWhere((p) => p.scriptType == ScriptType.katakana);
      expect(katakana.name, 'Katakana');
      expect(katakana.poolChars, containsAll(['ア', 'イ', 'ウ', 'エ', 'オ']));
      expect(katakana.sampleWords, contains('コーヒー'));

      // Kanji verification
      final kanji = pools.firstWhere((p) => p.scriptType == ScriptType.kanji);
      expect(kanji.name, 'Kanji');
      expect(kanji.poolChars, containsAll(['日', '月', '年', '大', '中', '小']));
      expect(kanji.sampleWords, contains('日本語'));

      // Cyrillic verification
      final cyrillic = pools.firstWhere((p) => p.scriptType == ScriptType.cyrillic);
      expect(cyrillic.name, 'Cyrillic');
      expect(cyrillic.poolChars, containsAll(['А', 'Б', 'В', 'Г', 'Д']));
      expect(cyrillic.sampleWords, contains('МОСКВА'));
    });

    test('generates valid sample Puzzle from ScriptPoolInfo', () {
      final repo = PackRepository();
      final pools = repo.getBuiltInScriptPools();

      for (final pool in pools) {
        final puzzle = pool.generateSamplePuzzle(difficulty: Difficulty.easy);
        expect(puzzle.grid.isNotEmpty, isTrue);
        expect(puzzle.words.isNotEmpty, isTrue);
        expect(puzzle.metadata.scriptType, equals(pool.scriptType));
      }
    });
  });

  group('PackRepository Import & Export Tests', () {
    test('loads built-in packs on demand', () {
      final repo = PackRepository();
      expect(repo.getAllPacks(), isEmpty);

      repo.loadBuiltInPacks();
      final packs = repo.getAllPacks();
      expect(packs.length, greaterThanOrEqualTo(5));

      final sciencePack = repo.getPackById('english_science');
      expect(sciencePack, isNotNull);
      expect(sciencePack!.title, 'Cosmos & Computing');
      expect(sciencePack.puzzleCount, 2);

      final spanishPack = repo.getPackById('spanish_accents');
      expect(spanishPack, isNotNull);
      expect(spanishPack!.scriptType, ScriptType.latinAccented);

      final jaPack = repo.getPackById('japanese_basics');
      expect(jaPack, isNotNull);
      expect(jaPack!.language, 'ja');
      expect(jaPack.scriptType, ScriptType.hiragana);
    });

    test('loads external pack from JSON string and supports dynamic registration', () {
      final repo = PackRepository();
      const customJson = '''
      {
        "id": "custom_colors",
        "title": "Vibrant Colors",
        "description": "Colors of the rainbow",
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

      final pack = repo.loadPackFromJson(customJson, filePath: 'custom_colors.json');
      expect(pack.id, 'custom_colors');
      expect(pack.title, 'Vibrant Colors');
      expect(pack.filePath, 'custom_colors.json');
      expect(repo.getPackById('custom_colors'), equals(pack));

      final removed = repo.removePack('custom_colors');
      expect(removed, isTrue);
      expect(repo.getPackById('custom_colors'), isNull);
    });

    test('throws FormatException on malformed pack JSON', () {
      final repo = PackRepository();
      expect(() => repo.loadPackFromJson('not a json'), throwsA(isA<FormatException>()));
      expect(() => repo.loadPackFromJson('["array", "instead"]'), throwsA(isA<FormatException>()));
    });

    test('exports puzzle and pack to standard JSON schemas', () {
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
      expect(decodedPuzzle['metadata']['title'], equals(puzzle.metadata.title));
      expect(decodedPuzzle['words'], isNotEmpty);
      expect(decodedPuzzle['grid'], isNotEmpty);
    });

    test('packRepositoryProvider and packListProvider provide reactive state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(packRepositoryProvider);
      expect(repo.getAllPacks(), isNotEmpty);

      final initialPacks = container.read(packListProvider);
      expect(initialPacks, isNotEmpty);

      // Test importing via Notifier
      const newPackJson = '''
      {
        "id": "dynamic_pack",
        "title": "Dynamic Pack",
        "puzzles": []
      }
      ''';
      container.read(packListProvider.notifier).importFromJson(newPackJson);
      final updatedPacks = container.read(packListProvider);
      expect(updatedPacks.any((p) => p.id == 'dynamic_pack'), isTrue);

      // Test removing via Notifier
      container.read(packListProvider.notifier).removePack('dynamic_pack');
      final finalPacks = container.read(packListProvider);
      expect(finalPacks.any((p) => p.id == 'dynamic_pack'), isFalse);
    });
  });
}
