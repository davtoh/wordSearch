/// Puzzle Pack data models and repository for loading, exporting, and managing
/// offline, built-in, and user-imported puzzle packs.
/// Pure Dart / Riverpod compatible — zero Flutter UI dependencies.
/// Ported from storage/pack_loader.py, storage/pack_exporter.py, and core/scripts.py.
library;

import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/scripts.dart';
import '../../../core/engine/grid_engine.dart';
import '../../../core/models/models.dart';
import '../../../core/storage/app_storage.dart';

// ─────────────────────────────────────────────────────────
// ScriptPoolInfo Model
// ─────────────────────────────────────────────────────────

/// Metadata and character inventory for a built-in multilingual script pool.
class ScriptPoolInfo extends Equatable {
  const ScriptPoolInfo({
    required this.scriptType,
    required this.name,
    required this.nativeName,
    required this.description,
    required this.poolChars,
    required this.sampleWords,
  });

  final ScriptType scriptType;
  final String name;
  final String nativeName;
  final String description;
  final List<String> poolChars;
  final List<String> sampleWords;

  int get characterCount => poolChars.length;
  String get previewGlyphs => poolChars.take(12).join(' ');

  /// Generates a playable sample puzzle populated using this script's vocabulary and fillers.
  Puzzle generateSamplePuzzle({Difficulty difficulty = Difficulty.easy}) {
    final wordsData = sampleWords.map((w) => {'word': w}).toList();
    return GridEngine.generatePuzzle(
      wordsData: wordsData,
      title: '$name Word Search',
      theme: name,
      language: switch (scriptType) {
        ScriptType.latinAccented => 'es',
        ScriptType.hiragana || ScriptType.katakana || ScriptType.kanji => 'ja',
        ScriptType.cyrillic => 'ru',
        _ => 'en',
      },
      difficulty: difficulty,
      scriptType: scriptType,
    );
  }

  @override
  List<Object?> get props => [
        scriptType,
        name,
        nativeName,
        description,
        poolChars,
        sampleWords,
      ];
}

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
    final rawPuzzles = json['puzzles'] as List<dynamic>?;
    final List<Map<String, dynamic>> puzzles;
    if (rawPuzzles != null) {
      puzzles = rawPuzzles.whereType<Map<String, dynamic>>().toList();
    } else if (json.containsKey('words')) {
      final meta = json['metadata'] as Map<String, dynamic>?;
      puzzles = [
        {
          'title': meta?['title'] ?? json['title'] ?? 'Puzzle',
          'theme': meta?['theme'] ?? 'General',
          'difficulty': meta?['difficulty'] ?? 'easy',
          'words': json['words'],
        }
      ];
    } else {
      puzzles = [];
    }

    final meta = json['metadata'] as Map<String, dynamic>?;
    final id = json['id'] as String? ?? (meta?['id'] as String?) ?? 'pack_unknown';
    final title = json['title'] as String? ?? (meta?['title'] as String?) ?? 'Untitled Pack';
    final language = json['language'] as String? ?? (meta?['language'] as String?) ?? 'en';
    final scriptTypeStr = json['script_type'] as String? ?? (meta?['script_type'] as String?) ?? 'latin';

    return PuzzlePack(
      id: id,
      title: title,
      description: json['description'] as String? ?? '',
      language: language,
      scriptType: ScriptType.fromValue(scriptTypeStr),
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

/// Discovers, loads, imports, exports, and manages offline puzzle packages and script pools.
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

  /// Exports a [PuzzlePack] to a formatted JSON string according to standard schema.
  String exportPackToJson(PuzzlePack pack, {bool pretty = true}) {
    return pack.toJsonString(pretty: pretty);
  }

  /// Exports a [Puzzle] to a standard JSON schema string.
  String exportPuzzleToJson(Puzzle puzzle, {bool pretty = true}) {
    final map = puzzle.toJson();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }

  /// Returns metadata and pools for all built-in scripts ported from core/scripts.py.
  List<ScriptPoolInfo> getBuiltInScriptPools() {
    return [
      ScriptPoolInfo(
        scriptType: ScriptType.latinAccented,
        name: 'Spanish Accents',
        nativeName: 'Español con tildes',
        description: 'Vibrant Latin script with accented vowels (Á, É, Í, Ó, Ú, Ü) and Ñ.',
        poolChars: spanishChars,
        sampleWords: const [
          'CORAZÓN',
          'MÚSICA',
          'ÁRBOL',
          'CAFÉ',
          'MAÑANA',
          'PINGÜINO',
          'RATÓN',
          'DIFÍCIL',
        ],
      ),
      ScriptPoolInfo(
        scriptType: ScriptType.hiragana,
        name: 'Hiragana',
        nativeName: 'ひらがな',
        description: 'Phonetic Japanese syllabary with smooth, cursive strokes.',
        poolChars: hiraganaChars,
        sampleWords: const [
          'おはよう',
          'ありがとう',
          'さようなら',
          'こんにちは',
          'ねこ',
          'さくら',
        ],
      ),
      ScriptPoolInfo(
        scriptType: ScriptType.katakana,
        name: 'Katakana',
        nativeName: 'カタカナ',
        description: 'Angular Japanese syllabary used for loanwords, emphasis, and names.',
        poolChars: katakanaChars,
        sampleWords: const [
          'コーヒー',
          'カメラ',
          'パソコン',
          'テレビ',
          'ラーメン',
          'ホテル',
        ],
      ),
      ScriptPoolInfo(
        scriptType: ScriptType.kanji,
        name: 'Kanji',
        nativeName: '漢字',
        description: 'Adopted logographic Chinese characters used in modern Japanese writing.',
        poolChars: commonKanjiChars,
        sampleWords: const [
          '日本語',
          '学校',
          '先生',
          '電話',
          '時間',
          '友達',
        ],
      ),
      ScriptPoolInfo(
        scriptType: ScriptType.cyrillic,
        name: 'Cyrillic',
        nativeName: 'Кириллица',
        description: 'Alphabet used across Slavic languages in Eastern Europe and Northern Asia.',
        poolChars: cyrillicChars,
        sampleWords: const [
          'МОСКВА',
          'КОСМОС',
          'СПУТНИК',
          'ПРИВЕТ',
          'ДРУГ',
          'ГОРОД',
        ],
      ),
    ];
  }

  /// Populates the repository with default offline packs including script collections.
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

    registerPack(const PuzzlePack(
      id: 'spanish_accents',
      title: 'Spanish Accents (Español con Tildes)',
      description: 'Master accented vowels and Ñ in everyday Spanish words.',
      language: 'es',
      scriptType: ScriptType.latinAccented,
      puzzlesData: [
        {
          'id': 'spanish_common',
          'title': 'Accented Words (Palabras con Tilde)',
          'theme': 'Vocabulary',
          'difficulty': 'easy',
          'words': [
            {'word': 'CORAZÓN', 'clue': 'Heart'},
            {'word': 'MÚSICA', 'clue': 'Music'},
            {'word': 'ÁRBOL', 'clue': 'Tree'},
            {'word': 'CAFÉ', 'clue': 'Coffee'},
            {'word': 'MAÑANA', 'clue': 'Tomorrow / Morning'},
            {'word': 'PINGÜINO', 'clue': 'Penguin'},
            {'word': 'RATÓN', 'clue': 'Mouse'},
          ],
        },
      ],
    ));

    registerPack(const PuzzlePack(
      id: 'japanese_katakana_pack',
      title: 'Japanese Katakana (カタカナ外来語)',
      description: 'Common Japanese loanwords written in Katakana script.',
      language: 'ja',
      scriptType: ScriptType.katakana,
      puzzlesData: [
        {
          'id': 'katakana_gadgets',
          'title': 'Modern Tech & Items',
          'theme': 'Everyday Items',
          'difficulty': 'easy',
          'words': [
            {'word': 'コーヒー', 'clue': 'Coffee'},
            {'word': 'カメラ', 'clue': 'Camera'},
            {'word': 'パソコン', 'clue': 'Personal Computer'},
            {'word': 'テレビ', 'clue': 'Television'},
            {'word': 'ラーメン', 'clue': 'Ramen noodles'},
          ],
        },
      ],
    ));

    registerPack(const PuzzlePack(
      id: 'cyrillic_pack',
      title: 'Cyrillic Explorer (Кириллица)',
      description: 'Classic Russian and Slavic terms in the Cyrillic alphabet.',
      language: 'ru',
      scriptType: ScriptType.cyrillic,
      puzzlesData: [
        {
          'id': 'cyrillic_cities',
          'title': 'Cosmos & Culture',
          'theme': 'Culture',
          'difficulty': 'easy',
          'words': [
            {'word': 'МОСКВА', 'clue': 'Moscow'},
            {'word': 'КОСМОС', 'clue': 'Outer space'},
            {'word': 'СПУТНИК', 'clue': 'Satellite / Companion'},
            {'word': 'ПРИВЕТ', 'clue': 'Hello / Hi'},
            {'word': 'ДРУГ', 'clue': 'Friend'},
            {'word': 'ГОРОД', 'clue': 'City / Town'},
          ],
        },
      ],
    ));
  }
}

// ─────────────────────────────────────────────────────────
// Riverpod Providers
// ─────────────────────────────────────────────────────────

/// Provider for the singleton [PackRepository] initialized with built-in packs.
final packRepositoryProvider = Provider<PackRepository>((ref) {
  final repo = PackRepository();
  repo.loadBuiltInPacks();
  return repo;
});

/// Reactive notifier maintaining the current list of available puzzle packs.
class PackListNotifier extends Notifier<List<PuzzlePack>> {
  @override
  List<PuzzlePack> build() {
    final repo = ref.watch(packRepositoryProvider);
    _loadInternalSavedPacks();
    return repo.getAllPacks();
  }

  Future<void> _loadInternalSavedPacks() async {
    try {
      final storage = ref.read(appStorageProvider);
      final internalPacks = await storage.loadAllInternalPacks();
      if (internalPacks.isNotEmpty) {
        final repo = ref.read(packRepositoryProvider);
        for (final p in internalPacks) {
          repo.registerPack(p);
        }
        state = repo.getAllPacks();
      }
    } catch (_) {}
  }

  /// Registers an in-memory or generated pack and updates reactive state.
  void registerPack(PuzzlePack pack) {
    final repo = ref.read(packRepositoryProvider);
    repo.registerPack(pack);
    state = repo.getAllPacks();
  }

  /// Imports a new pack from a JSON string and updates the reactive state.
  PuzzlePack importFromJson(String jsonString, {String? filePath}) {
    final repo = ref.read(packRepositoryProvider);
    final pack = repo.loadPackFromJson(jsonString, filePath: filePath);
    state = repo.getAllPacks();
    return pack;
  }

  /// Removes a pack by its id and updates the reactive state.
  bool removePack(String id) {
    final repo = ref.read(packRepositoryProvider);
    final removed = repo.removePack(id);
    if (removed) {
      state = repo.getAllPacks();
    }
    return removed;
  }

  /// Refreshes the list from the repository.
  void refresh() {
    final repo = ref.read(packRepositoryProvider);
    state = repo.getAllPacks();
  }
}

/// Reactive provider exposing the live list of registered puzzle packs.
final packListProvider =
    NotifierProvider<PackListNotifier, List<PuzzlePack>>(PackListNotifier.new);
