/// AI-Powered Topic and Puzzle Generator using Google Gemini.
/// Pure Dart / Riverpod integration with fallback offline generation.
/// Ported from ai/topic_generator.py and ai/gemini_client.py.
library;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/engine/grid_engine.dart';
import '../../../core/models/models.dart';

/// Provider for the Gemini AI topic and puzzle generation service.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Generates thematic vocabulary words and educational clues using Gemini AI.
class GeminiService {
  GeminiService({
    String? apiKey,
    this.modelName = 'gemini-2.5-flash',
    this.model,
    this.rawJsonGenerator,
  }) : _apiKey = apiKey ??
            (const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty
                ? const String.fromEnvironment('GEMINI_API_KEY')
                : null);

  final String? _apiKey;
  final String modelName;
  final GenerativeModel? model;
  final Future<String?> Function(String systemInstruction, String prompt)?
      rawJsonGenerator;

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

    final prompt =
        "Generate $count engaging vocabulary words related to the topic '$topic'.\n"
        'Language: $language\n'
        'Script: ${scriptType.value}\n'
        'Difficulty level: ${difficulty.value}\n'
        'Ensure the words are relevant, educational, and fun to search for.';

    try {
      String? jsonResponse;

      if (rawJsonGenerator != null) {
        jsonResponse = await rawJsonGenerator!(systemInstruction, prompt);
      } else {
        final client = model ??
            GenerativeModel(
              model: modelName,
              apiKey: _apiKey ?? '',
              systemInstruction: Content.system(systemInstruction),
              generationConfig: GenerationConfig(
                responseMimeType: 'application/json',
                temperature: 0.7,
              ),
            );

        final response = await client.generateContent([Content.text(prompt)]);
        jsonResponse = response.text;
      }

      if (jsonResponse != null && jsonResponse.trim().isNotEmpty) {
        final cleanedJson = _cleanJsonMarkdown(jsonResponse);
        final dynamic parsed = jsonDecode(cleanedJson);

        if (parsed is List && parsed.isNotEmpty) {
          final words = <Map<String, String?>>[];
          for (final item in parsed) {
            if (item is Map && item.containsKey('word')) {
              final rawWord = item['word']?.toString().trim() ?? '';
              if (rawWord.isNotEmpty) {
                words.add({
                  'word': rawWord,
                  'clue': item['clue']?.toString() ??
                      'Concept related to $topic',
                  'reading': item['reading']?.toString(),
                });
              }
            }
          }
          if (words.isNotEmpty) {
            return words;
          }
        }
      }
    } catch (_) {
      // Fallback offline generation on error or timeout
    }

    return offlineFallback(topic, language: language, count: count);
  }

  /// Like [generateWords] but throws on any API error instead of falling back
  /// to the offline word bank. Use when callers need to surface error states.
  Future<List<Map<String, String?>>> generateWordsOrThrow({
    required String topic,
    String language = 'en',
    int count = 10,
    Difficulty difficulty = Difficulty.easy,
    ScriptType scriptType = ScriptType.latin,
  }) async {
    final prompt =
        "Generate $count engaging vocabulary words related to the topic '$topic'.\n"
        'Language: $language\n'
        'Script: ${scriptType.value}\n'
        'Difficulty level: ${difficulty.value}\n'
        'Ensure the words are relevant, educational, and fun to search for.';

    String? jsonResponse;

    if (rawJsonGenerator != null) {
      jsonResponse = await rawJsonGenerator!(systemInstruction, prompt);
    } else if (!isConfigured) {
      return offlineFallback(topic, language: language, count: count);
    } else {
      final client = model ??
          GenerativeModel(
            model: modelName,
            apiKey: _apiKey ?? '',
            systemInstruction: Content.system(systemInstruction),
            generationConfig: GenerationConfig(
              responseMimeType: 'application/json',
              temperature: 0.7,
            ),
          );
      final response = await client.generateContent([Content.text(prompt)]);
      jsonResponse = response.text;
    }

    if (jsonResponse != null && jsonResponse.trim().isNotEmpty) {
      final cleanedJson = _cleanJsonMarkdown(jsonResponse);
      final dynamic parsed = jsonDecode(cleanedJson);
      if (parsed is List && parsed.isNotEmpty) {
        final words = <Map<String, String?>>[];
        for (final item in parsed) {
          if (item is Map && item.containsKey('word')) {
            final rawWord = item['word']?.toString().trim() ?? '';
            if (rawWord.isNotEmpty) {
              words.add({
                'word': rawWord,
                'clue': item['clue']?.toString() ?? 'Concept related to $topic',
                'reading': item['reading']?.toString(),
              });
            }
          }
        }
        if (words.isNotEmpty) return words;
      }
    }

    // Return empty list rather than throwing when JSON is just empty/malformed.
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
    const defaults = [
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

    final effectiveCount = count.clamp(1, defaults.length);
    return defaults.take(effectiveCount).toList();
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
