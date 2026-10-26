/// AI-Powered Topic and Puzzle Generator using Google Gemini.
/// Pure Dart / Riverpod integration with fallback offline generation.
/// Ported from ai/topic_generator.py and ai/gemini_client.py.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/engine/grid_engine.dart';
import '../../../core/models/models.dart';
import '../../../core/storage/app_storage.dart';

/// Exception thrown when Gemini API key is missing or not configured.
class GeminiConfigException implements Exception {
  const GeminiConfigException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Available Gemini models for word search vocabulary generation.
class GeminiModelOption {
  const GeminiModelOption({
    required this.id,
    required this.name,
    required this.description,
    this.isRecommended = false,
  });

  final String id;
  final String name;
  final String description;
  final bool isRecommended;
}

const List<GeminiModelOption> kGeminiModels = [
  GeminiModelOption(
    id: 'gemini-3.5-flash-lite',
    name: '3.5 Flash Lite',
    description: 'Fast, lightweight & reliable (Recommended)',
    isRecommended: true,
  ),
  GeminiModelOption(
    id: 'gemini-3.1-flash-lite',
    name: '3.1 Flash Lite',
    description: 'Ultra-low latency for fast generation',
  ),
  GeminiModelOption(
    id: 'gemini-3.8-flash',
    name: '3.8 Flash',
    description: 'Advanced reasoning with 1M context',
  ),
];

/// Provider for an optional user-entered Gemini API key in Settings.
final customGeminiApiKeyProvider =
    NotifierProvider<CustomApiKeyNotifier, String?>(
  CustomApiKeyNotifier.new,
);

class CustomApiKeyNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadFromStorage();
    return null;
  }

  Future<void> _loadFromStorage() async {
    try {
      final storage = ref.read(appStorageProvider);
      final saved = await storage.loadCustomApiKey();
      if (saved != null && saved.isNotEmpty) {
        state = saved;
      }
    } catch (_) {}
  }

  void setApiKey(String? key) {
    final trimmed = key?.trim();
    final value = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
    state = value;
    try {
      ref.read(appStorageProvider).saveCustomApiKey(value);
    } catch (_) {}
  }
}

/// Provider for the currently selected Gemini model.
final selectedGeminiModelProvider =
    NotifierProvider<SelectedGeminiModelNotifier, String>(
  SelectedGeminiModelNotifier.new,
);

class SelectedGeminiModelNotifier extends Notifier<String> {
  @override
  String build() {
    _loadFromStorage();
    return GeminiService.resolveDefaultModel();
  }

  Future<void> _loadFromStorage() async {
    try {
      final storage = ref.read(appStorageProvider);
      final saved = await storage.loadSelectedModel();
      if (saved != null && kGeminiModels.any((m) => m.id == saved)) {
        state = saved;
      }
    } catch (_) {}
  }

  void setModel(String modelId) {
    if (kGeminiModels.any((m) => m.id == modelId)) {
      state = modelId;
      try {
        ref.read(appStorageProvider).saveSelectedModel(modelId);
      } catch (_) {}
    }
  }
}

/// Provider for the Gemini AI topic and puzzle generation service.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final customKey = ref.watch(customGeminiApiKeyProvider);
  final selectedModel = ref.watch(selectedGeminiModelProvider);
  final resolvedKey = (customKey != null && customKey.isNotEmpty)
      ? customKey
      : GeminiService.resolveDefaultApiKey();
  return GeminiService(
    apiKey: resolvedKey,
    modelName: selectedModel,
  );
});

/// Generates thematic vocabulary words and educational clues using Gemini AI.
class GeminiService {
  GeminiService({
    String? apiKey,
    this.modelName = defaultModelName,
    this.model,
    this.rawJsonGenerator,
  }) : _apiKey = (apiKey != null && apiKey.isNotEmpty)
            ? apiKey
            : (const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty
                ? const String.fromEnvironment('GEMINI_API_KEY')
                : null);

  /// Default model: gemini-3.5-flash-lite (fast, reliable, active).
  static const String defaultModelName = 'gemini-3.5-flash-lite';

  /// Available model identifiers.
  static const List<String> availableModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.8-flash',
  ];

  /// Fallback models tried in order if transient high demand or errors occur.
  static const List<String> fallbackModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.8-flash',
  ];

  final String? _apiKey;
  final String modelName;
  final GenerativeModel? model;
  final Future<String?> Function(String systemInstruction, String prompt)?
      rawJsonGenerator;

  /// Resolves the Gemini API key from compile-time defines, environment, or .env file.
  static String? resolveDefaultApiKey() {
    const compileTimeKey = String.fromEnvironment('GEMINI_API_KEY');
    if (compileTimeKey.isNotEmpty && !compileTimeKey.startsWith('your_')) {
      return compileTimeKey.trim();
    }

    if (!kIsWeb) {
      try {
        final osEnv = Platform.environment['GEMINI_API_KEY'];
        if (osEnv != null && osEnv.trim().isNotEmpty && !osEnv.startsWith('your_')) {
          return osEnv.trim();
        }

        final candidates = [
          File('.env'),
          File('../.env'),
          File('${Directory.current.path}/.env'),
          File('${Directory.current.parent.path}/.env'),
        ];

        for (final file in candidates) {
          if (file.existsSync()) {
            final lines = file.readAsLinesSync();
            for (final line in lines) {
              final trimmed = line.trim();
              if (trimmed.startsWith('#') || !trimmed.contains('=')) continue;
              final idx = trimmed.indexOf('=');
              final k = trimmed.substring(0, idx).trim();
              if (k == 'GEMINI_API_KEY') {
                final v = trimmed
                    .substring(idx + 1)
                    .trim()
                    .replaceAll(RegExp(r'''^["']|["']$'''), '');
                if (v.isNotEmpty && !v.startsWith('your_')) {
                  return v;
                }
              }
            }
          }
        }
      } catch (_) {
        // Filesystem access restricted or failed
      }
    }

    return null;
  }

  /// Resolves the default Gemini model from compile-time defines, environment, or .env file.
  static String resolveDefaultModel() {
    const compileTimeModel = String.fromEnvironment('GEMINI_MODEL');
    if (compileTimeModel.isNotEmpty) return compileTimeModel.trim();

    if (!kIsWeb) {
      try {
        final envModel = Platform.environment['GEMINI_MODEL'];
        if (envModel != null && envModel.trim().isNotEmpty) {
          return envModel.trim();
        }

        final candidates = [
          File('.env'),
          File('../.env'),
          File('${Directory.current.path}/.env'),
          File('${Directory.current.parent.path}/.env'),
        ];

        for (final file in candidates) {
          if (file.existsSync()) {
            final lines = file.readAsLinesSync();
            for (final line in lines) {
              final trimmed = line.trim();
              if (trimmed.startsWith('#') || !trimmed.contains('=')) continue;
              final idx = trimmed.indexOf('=');
              final k = trimmed.substring(0, idx).trim();
              if (k == 'GEMINI_MODEL') {
                final v = trimmed
                    .substring(idx + 1)
                    .trim()
                    .replaceAll(RegExp(r'''^["']|["']$'''), '');
                if (v.isNotEmpty) return v;
              }
            }
          }
        }
      } catch (_) {
        // Filesystem access restricted or failed
      }
    }

    return defaultModelName;
  }

  /// True if a valid API key or mock generator is configured.
  bool get isConfigured {
    if (rawJsonGenerator != null || model != null) return true;
    final key = _apiKey;
    if (key != null && key.trim().isNotEmpty && !key.startsWith('your_')) {
      return true;
    }
    return false;
  }

  /// System prompt establishing educational lexicographer persona.
  static const String systemInstruction =
      'You are an expert educational game designer and lexicographer. '
      'Your task is to generate a list of vocabulary words and concise educational clues/definitions for a word search puzzle. '
      'Output MUST be valid JSON: an array of objects where each object has keys: '
      "'word' (string, single word, uppercase if latin/cyrillic, no spaces/hyphens), "
      "'clue' (string, concise definition or conceptual question, 1-2 sentences), "
      "'reading' (string, phonetic reading or romaji if non-latin, else null). "
      'Length of each word must be between 3 and 12 characters.';

  /// Generates a list of vocabulary entries with clues for [topic].
  /// Uses offline fallback on failure or when unconfigured.
  Future<List<Map<String, String?>>> generateWords({
    required String topic,
    String language = 'en',
    int count = 10,
    Difficulty difficulty = Difficulty.easy,
    ScriptType scriptType = ScriptType.latin,
  }) async {
    if (!isConfigured) {
      return offlineFallback(topic, language: language, count: count);
    }

    try {
      final words = await generateWordsOrThrow(
        topic: topic,
        language: language,
        count: count,
        difficulty: difficulty,
        scriptType: scriptType,
      );
      if (words.isNotEmpty) return words;
    } catch (_) {
      // Fallback offline generation on error or timeout
    }

    return offlineFallback(topic, language: language, count: count);
  }

  /// Like [generateWords] but throws on any API error or unconfigured state
  /// instead of falling back to the offline word bank.
  Future<List<Map<String, String?>>> generateWordsOrThrow({
    required String topic,
    String language = 'en',
    int count = 10,
    Difficulty difficulty = Difficulty.easy,
    ScriptType scriptType = ScriptType.latin,
  }) async {
    final trimmedTopic = topic.trim();
    if (trimmedTopic.isEmpty) {
      throw const GeminiConfigException('Please enter a topic to generate words.');
    }

    if (!isConfigured) {
      throw const GeminiConfigException(
        'Gemini API key is not configured. Please add GEMINI_API_KEY to your .env file or configure it in Settings.',
      );
    }

    final prompt =
        "Generate $count engaging vocabulary words related to the topic '$trimmedTopic'.\n"
        'Language: $language\n'
        'Script: ${scriptType.value}\n'
        'Difficulty level: ${difficulty.value}\n'
        'Ensure the words are relevant, educational, and fun to search for.';

    String? jsonResponse;

    if (rawJsonGenerator != null) {
      jsonResponse = await rawJsonGenerator!(systemInstruction, prompt);
    } else if (model != null) {
      final response = await model!.generateContent([Content.text(prompt)]);
      jsonResponse = response.text;
    } else {
      final candidates = [
        modelName,
        ...fallbackModels.where((m) => m != modelName),
      ];

      Exception? lastError;
      for (final candidate in candidates) {
        try {
          final client = GenerativeModel(
            model: candidate,
            apiKey: _apiKey!,
            systemInstruction: Content.system(systemInstruction),
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
              temperature: 0.7,
            ),
          );

          final response = await client.generateContent([Content.text(prompt)]);
          if (response.text != null && response.text!.trim().isNotEmpty) {
            jsonResponse = response.text;
            break;
          }
        } on Exception catch (e) {
          lastError = e;
        }
      }

      if (jsonResponse == null && lastError != null) {
        throw lastError;
      }
    }

    if (jsonResponse != null && jsonResponse.trim().isNotEmpty) {
      final cleanedJson = _cleanJsonMarkdown(jsonResponse);
      final dynamic parsed = jsonDecode(cleanedJson);

      List<dynamic> items = [];
      if (parsed is List) {
        items = parsed;
      } else if (parsed is Map) {
        if (parsed['words'] is List) {
          items = parsed['words'] as List;
        } else if (parsed['vocabulary'] is List) {
          items = parsed['vocabulary'] as List;
        } else {
          for (final val in parsed.values) {
            if (val is List && val.isNotEmpty) {
              items = val;
              break;
            }
          }
        }
      }

      if (items.isNotEmpty) {
        final words = <Map<String, String?>>[];
        final seen = <String>{};

        for (final item in items) {
          if (item is Map && item.containsKey('word')) {
            final rawWord = item['word']?.toString().trim() ?? '';
            final cleanWord =
                rawWord.replaceAll(RegExp(r'[\s\-_]'), '').toUpperCase();
            if (cleanWord.length >= 2 && seen.add(cleanWord)) {
              words.add({
                'word': cleanWord,
                'clue': item['clue']?.toString() ??
                    'Concept related to $trimmedTopic',
                'reading': item['reading']?.toString(),
              });
            }
          }
        }
        if (words.isNotEmpty) {
          return words.take(count).toList();
        }
      }
    }

    return [];
  }

  /// Generates a complete, ready-to-play [Puzzle] for [topic].
  Future<Puzzle> generatePuzzle({
    required String topic,
    String language = 'en',
    int count = 10,
    Difficulty difficulty = Difficulty.easy,
    ScriptType? scriptType,
    (int, int)? customDimensions,
    AssistConfig? assistConfig,
  }) async {
    final wordsData = await generateWords(
      topic: topic,
      language: language,
      count: count,
      difficulty: difficulty,
      scriptType: scriptType ?? ScriptType.latin,
    );

    return GridEngine.generatePuzzle(
      wordsData: wordsData,
      title: topic,
      theme: topic,
      language: language,
      difficulty: difficulty,
      scriptType: scriptType,
      customDimensions: customDimensions,
      assistConfig: assistConfig,
    );
  }

  /// Offline fallback word bank when AI is unconfigured or unreachable.
  static List<Map<String, String?>> offlineFallback(
    String topic, {
    String language = 'en',
    int count = 10,
  }) {
    final lower = topic.toLowerCase();
    final List<Map<String, String?>> themeList;

    if (lower.contains('space') ||
        lower.contains('astronom') ||
        lower.contains('star') ||
        lower.contains('cosmos')) {
      themeList = const [
        {
          'word': 'GALAXY',
          'clue': 'A system of millions or billions of stars.',
          'reading': null,
        },
        {
          'word': 'ORBIT',
          'clue': 'The curved path of a celestial object or spacecraft.',
          'reading': null,
        },
        {
          'word': 'PLANET',
          'clue': 'A celestial body moving in an orbit around a star.',
          'reading': null,
        },
        {
          'word': 'ASTEROID',
          'clue': 'A small rocky body orbiting the sun.',
          'reading': null,
        },
        {
          'word': 'COMET',
          'clue': 'An icy celestial body with a luminous tail.',
          'reading': null,
        },
        {
          'word': 'TELESCOPE',
          'clue': 'An optical instrument used for observing distant objects.',
          'reading': null,
        },
        {
          'word': 'NEBULA',
          'clue': 'A cloud of gas and dust in outer space.',
          'reading': null,
        },
        {
          'word': 'COSMOS',
          'clue': 'The universe seen as a well-ordered whole.',
          'reading': null,
        },
      ];
    } else if (lower.contains('animal') ||
        lower.contains('zoo') ||
        lower.contains('wildlife')) {
      themeList = const [
        {
          'word': 'DOLPHIN',
          'clue': 'An intelligent marine mammal.',
          'reading': null,
        },
        {
          'word': 'ELEPHANT',
          'clue': 'The largest existing land mammal.',
          'reading': null,
        },
        {
          'word': 'GIRAFFE',
          'clue': 'The tallest living terrestrial animal.',
          'reading': null,
        },
        {
          'word': 'PENGUIN',
          'clue': 'A flightless marine bird of the Southern Hemisphere.',
          'reading': null,
        },
        {
          'word': 'CHEETAH',
          'clue': 'The fastest land animal on Earth.',
          'reading': null,
        },
        {
          'word': 'TIGER',
          'clue': 'A large striped predatory cat.',
          'reading': null,
        },
        {
          'word': 'OCTOPUS',
          'clue': 'An eight-armed soft-bodied marine creature.',
          'reading': null,
        },
        {
          'word': 'KANGAROO',
          'clue': 'A marsupial native to Australia.',
          'reading': null,
        },
      ];
    } else {
      themeList = const [
        {
          'word': 'SEARCH',
          'clue':
              'To look into or through carefully in order to find something.',
          'reading': null,
        },
        {
          'word': 'PUZZLE',
          'clue':
              'A game, toy, or problem designed to test ingenuity or knowledge.',
          'reading': null,
        },
        {
          'word': 'DISCOVERY',
          'clue':
              'The act of finding or learning something for the first time.',
          'reading': null,
        },
        {
          'word': 'EXPLORE',
          'clue':
              'To travel in or through an unfamiliar area to learn about it.',
          'reading': null,
        },
        {
          'word': 'VOCABULARY',
          'clue':
              'The body of words used in a particular language or topic.',
          'reading': null,
        },
        {
          'word': 'LEARNING',
          'clue':
              'The acquisition of knowledge or skills through experience or study.',
          'reading': null,
        },
        {
          'word': 'INSIGHT',
          'clue':
              'An accurate and deep intuitive understanding of a person or thing.',
          'reading': null,
        },
        {
          'word': 'CONCEPT',
          'clue': 'An abstract idea or a general notion.',
          'reading': null,
        },
      ];
    }

    final effectiveCount = count.clamp(1, themeList.length);
    return themeList.take(effectiveCount).toList();
  }

  /// Strips optional ```json ... ``` markdown wrappers if returned by LLM.
  static String _cleanJsonMarkdown(String raw) {
    var text = raw.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }
}

