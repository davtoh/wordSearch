/// Puzzle Pack data models and repository for loading, exporting, and managing
/// offline and user-created puzzle packs.
/// Pure Dart / Riverpod compatible — zero Flutter UI dependencies.
/// Ported from storage/pack_loader.py and storage/pack_exporter.py.
library;

import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/grid_engine.dart';
import '../../../core/models/models.dart';

/// Provider for the [PackRepository] pre-populated with built-in puzzle packs.
final packRepositoryProvider = Provider<PackRepository>((ref) {
  final repo = PackRepository();
  repo.loadBuiltInPacks();
  return repo;
});

// ─────────────────────────────────────────────────────────
// PuzzlePack Model
// ─────────────────────────────────────────────────────────

/// Represents a collection of thematic word search puzzles.
class PuzzlePack extends Equatable {
  const PuzzlePack({
    required this.id,
    required this.title,
    this.description = '',
    this.language = 'en',
    this.scriptType = ScriptType.latin,
    this.puzzlesData = const [],
    this.filePath,
  });

  final String id;
  final String title;
  final String description;
  final String language;
  final ScriptType scriptType;
  final List<Map<String, dynamic>> puzzlesData;
  final String? filePath;

  /// Number of puzzles contained in this package.
  int get puzzleCount => puzzlesData.length;

  /// Instantiates and generates a [Puzzle] object from the specified index in the pack.
  Puzzle getPuzzle(int index, {Difficulty? difficulty}) {
    if (index < 0 || index >= puzzlesData.length) {
      throw RangeError(
        "Puzzle index $index out of range (0..${puzzlesData.length - 1}) in pack '$title'",
      );
    }

    final pInfo = puzzlesData[index];
    final diff = difficulty ??
        (pInfo['difficulty'] != null
            ? Difficulty.fromValue(pInfo['difficulty'].toString())
            : Difficulty.easy);

    final rawWords = pInfo['words'] as List<dynamic>? ?? [];
    final wordsData = rawWords.map((item) {
      if (item is Map) {
        return {
          'word': item['word']?.toString(),
          'clue': item['clue']?.toString(),
          'reading': item['reading']?.toString(),
        };
      }
      return {'word': item.toString(), 'clue': null, 'reading': null};
    }).toList();

    return GridEngine.generatePuzzle(
      wordsData: wordsData,
      title: pInfo['title']?.toString() ?? title,
      theme: pInfo['theme']?.toString() ?? title,
      language: language,
      difficulty: diff,
      scriptType: scriptType,
    );
  }

  PuzzlePack copyWith({
    String? id,
    String? title,
    String? description,
    String? language,
    ScriptType? scriptType,
    List<Map<String, dynamic>>? puzzlesData,
    String? filePath,
  }) =>
      PuzzlePack(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        language: language ?? this.language,
        scriptType: scriptType ?? this.scriptType,
        puzzlesData: puzzlesData ?? this.puzzlesData,
        filePath: filePath ?? this.filePath,
      );

  factory PuzzlePack.fromJson(Map<String, dynamic> json, {String? filePath}) {
    final rawPuzzles = json['puzzles'] as List<dynamic>? ?? [];
    final puzzles = rawPuzzles
        .whereType<Map<String, dynamic>>()
        .toList();

    return PuzzlePack(
      id: json['id'] as String? ?? 'pack_unknown',
      title: json['title'] as String? ?? 'Untitled Pack',
      description: json['description'] as String? ?? '',
      language: json['language'] as String? ?? 'en',
      scriptType: ScriptType.fromValue(json['script_type'] as String? ?? 'latin'),
      puzzlesData: puzzles,
      filePath: filePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'language': language,
        'script_type': scriptType.value,
        'puzzles': puzzlesData,
      };

  String toJsonString({bool pretty = true}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toJson());
    }
    return jsonEncode(toJson());
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        language,
        scriptType,
        puzzlesData,
        filePath,
      ];
}

// ─────────────────────────────────────────────────────────
// PackRepository
// ─────────────────────────────────────────────────────────

/// Discovers, loads, imports, exports, and manages offline puzzle packages.
class PackRepository {
  final Map<String, PuzzlePack> _packs = {};

  /// Returns all registered packs sorted alphabetically by title.
  List<PuzzlePack> getAllPacks() {
    final list = _packs.values.toList();
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  /// Finds a pack by its unique [id], or null if not registered.
  PuzzlePack? getPackById(String id) => _packs[id];

  /// Registers a pack into the repository.
  void registerPack(PuzzlePack pack) {
    _packs[pack.id] = pack;
  }

  /// Removes a pack by its [id]. Returns true if removed.
  bool removePack(String id) {
    return _packs.remove(id) != null;
  }

  /// Clears all loaded packs.
  void clear() {
    _packs.clear();
  }

  /// Loads and registers a pack from a JSON string.
  PuzzlePack loadPackFromJson(String jsonString, {String? filePath}) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid pack JSON: expected root object.');
    }
    final pack = PuzzlePack.fromJson(decoded, filePath: filePath);
    registerPack(pack);
    return pack;
  }

  /// Exports a [PuzzlePack] to a formatted JSON string.
  String exportPackToJson(PuzzlePack pack, {bool pretty = true}) {
    return pack.toJsonString(pretty: pretty);
  }

  /// Exports a completed [Puzzle] to a standalone JSON string.
  String exportPuzzleToJson(Puzzle puzzle, {bool pretty = true}) {
    final map = puzzle.toJson();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }

  /// Populates the repository with default offline packs (Science, Computing, Japanese, etc.).
  void loadBuiltInPacks() {
    registerPack(const PuzzlePack(
      id: 'english_science',
      title: 'Cosmos & Computing',
      description: 'Explore astronomical wonders and computer science fundamentals.',
      language: 'en',
      scriptType: ScriptType.latin,
      puzzlesData: [
        {
          'id': 'space_exploration',
          'title': 'Space & Astronomy',
          'theme': 'Space',
          'difficulty': 'easy',
          'words': [
            {'word': 'GALAXY', 'clue': 'A massive gravitational system of stars, remnants, and dark matter.'},
            {'word': 'NEBULA', 'clue': 'An interstellar cloud of dust and ionized gases.'},
            {'word': 'PULSAR', 'clue': 'A highly magnetized rotating neutron star.'},
            {'word': 'ORBIT', 'clue': 'The gravitationally curved trajectory of an object.'},
            {'word': 'COMET', 'clue': 'An icy celestial body releasing gases near the Sun.'},
            {'word': 'ECLIPSE', 'clue': 'One celestial body passing into the shadow of another.'},
            {'word': 'QUASAR', 'clue': 'An extremely luminous active galactic nucleus.'},
            {'word': 'GRAVITY', 'clue': 'A fundamental attractive interaction between masses.'},
            {'word': 'COSMOS', 'clue': 'The universe regarded as a complex, orderly system.'},
          ],
        },
        {
          'id': 'computer_science',
          'title': 'Computer Science Core',
          'theme': 'Computer Science',
          'difficulty': 'medium',
          'words': [
            {'word': 'ALGORITHM', 'clue': 'A finite sequence of instructions to solve a problem.'},
            {'word': 'COMPILER', 'clue': 'A program that translates source code into machine code.'},
            {'word': 'RECURSION', 'clue': 'Solving a problem where solution depends on smaller instances.'},
            {'word': 'DATABASE', 'clue': 'An organized collection of electronic data.'},
            {'word': 'VARIABLE', 'clue': 'A storage location paired with an associated symbolic name.'},
            {'word': 'FUNCTION', 'clue': 'A packaged unit of code that performs a specific task.'},
            {'word': 'POINTER', 'clue': 'An object that stores the memory address of another value.'},
            {'word': 'NETWORK', 'clue': 'A set of interconnected digital nodes.'},
            {'word': 'BOOLEAN', 'clue': 'A binary data type (True or False).'},
          ],
        },
      ],
    ));

    registerPack(const PuzzlePack(
      id: 'japanese_basics',
      title: 'Japanese Fundamentals (日本語の基本)',
      description: 'Introductory Hiragana vocabulary for daily Japanese conversation.',
      language: 'ja',
      scriptType: ScriptType.hiragana,
      puzzlesData: [
        {
          'id': 'daily_greetings',
          'title': 'Daily Greetings (あいさつ)',
          'theme': 'Greetings',
          'difficulty': 'easy',
          'words': [
            {'word': 'おはよう', 'clue': 'Good morning (informal)', 'reading': 'ohayou'},
            {'word': 'こんにちは', 'clue': 'Hello / Good afternoon', 'reading': 'konnichiwa'},
            {'word': 'ありがとう', 'clue': 'Thank you', 'reading': 'arigatou'},
            {'word': 'さようなら', 'clue': 'Goodbye', 'reading': 'sayounara'},
            {'word': 'こんばんは', 'clue': 'Good evening', 'reading': 'konbanwa'},
            {'word': 'すみません', 'clue': 'Excuse me / Sorry', 'reading': 'sumimasen'},
          ],
        },
      ],
    ));
  }
}
