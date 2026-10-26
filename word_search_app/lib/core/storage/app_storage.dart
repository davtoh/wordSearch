import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/packs/data/pack_repository.dart';
import '../../features/word_search/domain/game_state.dart';
import '../models/models.dart';

/// Central storage management service for persisting settings, API keys,
/// active game sessions, and saved/recent AI puzzle packs to internal folders.
class AppStorage {
  AppStorage({
    SharedPreferences? initialPrefs,
    this.customPuzzlesDirectory,
  }) : _prefs = initialPrefs;

  SharedPreferences? _prefs;
  final Directory? customPuzzlesDirectory;

  static const String _keyApiKey = 'gemini_custom_api_key';
  static const String _keySelectedModel = 'gemini_selected_model';
  static const String _keyActivePuzzleJson = 'active_game_puzzle_json';
  static const String _keyActiveFoundWords = 'active_game_found_words';
  static const String _keyActiveElapsed = 'active_game_elapsed_seconds';
  static const String _keyActiveGameMode = 'active_game_mode';

  /// Ensures SharedPreferences instance is ready.
  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  // ─── API Key & Model Persistence ─────────────────────────

  /// Loads custom Gemini API key from persistent storage.
  Future<String?> loadCustomApiKey() async {
    final prefs = await _getPrefs();
    if (prefs == null) return null;
    final key = prefs.getString(_keyApiKey)?.trim();
    if (key != null && key.isNotEmpty) return key;
    return null;
  }

  /// Saves or clears custom Gemini API key in persistent storage.
  Future<void> saveCustomApiKey(String? key) async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    if (key == null || key.trim().isEmpty) {
      await prefs.remove(_keyApiKey);
    } else {
      await prefs.setString(_keyApiKey, key.trim());
    }
  }

  /// Loads selected Gemini model from persistent storage.
  Future<String?> loadSelectedModel() async {
    final prefs = await _getPrefs();
    if (prefs == null) return null;
    final model = prefs.getString(_keySelectedModel)?.trim();
    if (model != null && model.isNotEmpty) return model;
    return null;
  }

  /// Saves selected Gemini model to persistent storage.
  Future<void> saveSelectedModel(String model) async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    await prefs.setString(_keySelectedModel, model.trim());
  }

  // ─── Internal App Folder Persistence ─────────────────────

  /// Returns the internal app directory dedicated to storing puzzle packs.
  Future<Directory?> getSavedPuzzlesDirectory() async {
    final customDir = customPuzzlesDirectory;
    if (customDir != null) {
      if (!customDir.existsSync()) {
        customDir.createSync(recursive: true);
      }
      return customDir;
    }
    if (kIsWeb) return null;
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDocs.path}/saved_puzzles');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    } catch (_) {
      return null;
    }
  }

  /// Converts a [Puzzle] into a [PuzzlePack] schema map.
  Map<String, dynamic> puzzleToPackJson(Puzzle puzzle, {String? customTitle}) {
    final title = customTitle ?? puzzle.title;
    return {
      'id': 'pack_${puzzle.metadata.id}',
      'title': title,
      'description': 'AI generated word search puzzle',
      'language': puzzle.metadata.language,
      'script_type': puzzle.metadata.scriptType.value,
      'puzzles': [
        {
          'title': title,
          'theme': puzzle.metadata.theme,
          'difficulty': puzzle.difficulty.value,
          'words': puzzle.words
              .map((w) => {
                    'word': w.word,
                    'clue': w.clue,
                    'reading': w.reading,
                  })
              .toList(),
        }
      ],
    };
  }

  /// Saves a [Puzzle] or [PuzzlePack] directly to the app's internal folder.
  Future<String?> savePuzzleToInternalFolder(
    Puzzle puzzle, {
    String? customTitle,
  }) async {
    final dir = await getSavedPuzzlesDirectory();
    if (dir == null) return null;

    final packJson = puzzleToPackJson(puzzle, customTitle: customTitle);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(packJson);

    // Sanitize filename
    final safeTitle = puzzle.title
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .toLowerCase();
    final fileName = 'ai_${safeTitle}_${puzzle.metadata.id}.json';
    final file = File('${dir.path}/$fileName');
    file.writeAsStringSync(jsonStr);
    return file.path;
  }

  /// Saves raw JSON pack content to the internal app folder.
  Future<String?> savePackJsonToInternalFolder({
    required String fileName,
    required String jsonContent,
  }) async {
    final dir = await getSavedPuzzlesDirectory();
    if (dir == null) return null;

    final safeName = fileName.endsWith('.json') ? fileName : '$fileName.json';
    final file = File('${dir.path}/$safeName');
    file.writeAsStringSync(jsonContent);
    return file.path;
  }

  /// Loads all saved puzzle packs from the internal app folder.
  Future<List<PuzzlePack>> loadAllInternalPacks() async {
    final dir = await getSavedPuzzlesDirectory();
    if (dir == null) return [];

    final packs = <PuzzlePack>[];
    try {
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = entity.readAsStringSync();
            final dynamic decoded = jsonDecode(content);
            if (decoded is Map<String, dynamic>) {
              // Could be a pack schema or a raw puzzle schema
              if (decoded.containsKey('puzzles')) {
                packs.add(PuzzlePack.fromJson(decoded, filePath: entity.path));
              } else if (decoded.containsKey('metadata') &&
                  decoded.containsKey('grid')) {
                final puzzle = Puzzle.fromJson(decoded);
                final packJson = puzzleToPackJson(puzzle);
                packs.add(PuzzlePack.fromJson(packJson, filePath: entity.path));
              }
            }
          } catch (_) {
            // Ignore corrupted individual files
          }
        }
      }
    } catch (_) {
      // Filesystem listing failed
    }

    return packs;
  }

  // ─── Export to Device File (User-Chosen Location) ────────

  /// Exports [jsonContent] using [FilePicker.saveFile] to allow the user
  /// to choose any location on their phone (Downloads, Documents, Drive, etc.).
  Future<String?> exportJsonToDevice({
    required String defaultFileName,
    required String jsonContent,
    String? dialogTitle,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonContent));
    final safeFileName = defaultFileName.endsWith('.json')
        ? defaultFileName
        : '$defaultFileName.json';

    try {
      final chosenUri = await FilePicker.saveFile(
        dialogTitle: dialogTitle ?? 'Save Puzzle JSON File',
        fileName: safeFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (chosenUri != null) {
        String? resolvedPath;
        try {
          resolvedPath = chosenUri.toFilePath();
        } catch (_) {
          resolvedPath = chosenUri.path;
        }

        if (resolvedPath.isNotEmpty && !kIsWeb) {
          try {
            final file = File(resolvedPath);
            if (!await file.exists() || await file.length() == 0) {
              await file.writeAsString(jsonContent);
            }
          } catch (_) {}
        }
        return resolvedPath.isNotEmpty ? resolvedPath : chosenUri.toString();
      }
      return null;
    } catch (_) {
      // If native saveFile fails, fallback to saving in internal folder
      return await savePackJsonToInternalFolder(
        fileName: safeFileName,
        jsonContent: jsonContent,
      );
    }
  }

  // ─── Active Game Session Persistence ─────────────────────

  /// Saves the current active [GameState] to persistent storage so it can be resumed.
  Future<void> saveActiveGame(GameState state) async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    if (state.status == GameStatus.won ||
        state.status == GameStatus.givenUp ||
        state.puzzle.isComplete) {
      await clearActiveGame();
      return;
    }

    try {
      final puzzleJson = jsonEncode(state.puzzle.toJson());
      final foundList = state.foundWords.map((w) => w.word).toList();

      await prefs.setString(_keyActivePuzzleJson, puzzleJson);
      await prefs.setStringList(_keyActiveFoundWords, foundList);
      await prefs.setDouble(_keyActiveElapsed, state.totalElapsedSeconds);
      await prefs.setString(_keyActiveGameMode, state.mode.name);
    } catch (_) {
      // Serialization failure safety
    }
  }

  /// Loads saved active game session if one exists.
  Future<GameState?> loadActiveGame() async {
    final prefs = await _getPrefs();
    if (prefs == null) return null;
    final puzzleStr = prefs.getString(_keyActivePuzzleJson);
    if (puzzleStr == null || puzzleStr.isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(puzzleStr);
      if (decoded is! Map<String, dynamic>) return null;

      final rawPuzzle = Puzzle.fromJson(decoded);
      final foundWordsList = prefs.getStringList(_keyActiveFoundWords) ?? [];
      final elapsed = prefs.getDouble(_keyActiveElapsed) ?? 0.0;
      final modeName = prefs.getString(_keyActiveGameMode) ?? 'casual';
      final mode = GameMode.values.firstWhere(
        (m) => m.name == modeName,
        orElse: () => GameMode.casual,
      );

      // Re-mark found words
      final updatedWords = rawPuzzle.words.map((w) {
        if (foundWordsList.contains(w.word)) {
          return w.copyWith(found: true);
        }
        return w;
      }).toList();

      final updatedPuzzle = rawPuzzle.copyWith(words: updatedWords);
      if (updatedPuzzle.isComplete) {
        await clearActiveGame();
        return null;
      }

      final foundCoordsMap = <(int, int), String>{};
      final foundWordEntries = <WordEntry>[];
      for (final w in updatedWords) {
        if (w.found) {
          foundWordEntries.add(w);
          for (final coord in w.coords) {
            foundCoordsMap[coord] = w.word;
          }
        }
      }

      return GameState(
        puzzle: updatedPuzzle,
        mode: mode,
        status: GameStatus.playing,
        foundWords: foundWordEntries,
        foundCoordsMap: foundCoordsMap,
        totalElapsedSeconds: elapsed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clears active game from persistent storage.
  Future<void> clearActiveGame() async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    await prefs.remove(_keyActivePuzzleJson);
    await prefs.remove(_keyActiveFoundWords);
    await prefs.remove(_keyActiveElapsed);
    await prefs.remove(_keyActiveGameMode);
  }
}

/// Global provider for [AppStorage].
final appStorageProvider = Provider<AppStorage>((ref) {
  return AppStorage();
});
