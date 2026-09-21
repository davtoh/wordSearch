/// Unicode & Multilingual Script Pools for Grid Generation and Distractor Fillers.
/// Pure Dart — zero Flutter UI dependencies.
/// Ported from core/scripts.py.
library;

import '../models/enums.dart';

// ─────────────────────────────────────────────────────────
// Character pools
// ─────────────────────────────────────────────────────────

/// Standard 26-letter uppercase Latin alphabet.
const List<String> latinChars = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

/// Spanish alphabet: standard Latin + Ñ and accented vowels.
const List<String> spanishChars = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'Á', 'É', 'Í', 'Ó', 'Ú', 'Ü',
];

/// Japanese Hiragana — common gojuon + dakuon characters.
final List<String> hiraganaChars = _splitChars(
  'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん'
  'がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ',
);

/// Japanese Katakana — common gojuon + dakuon characters.
final List<String> katakanaChars = _splitChars(
  'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン'
  'ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ',
);

/// Common elementary / JLPT-N5 Kanji for general puzzles.
final List<String> commonKanjiChars = _splitChars(
  '日月年大中小人一二三四五六七八九十百千万水火木金土天学校先生名本子手足目口山川本語国車時'
  '気電話何白赤青雨今半分前後外内上下右左友父母買食飲行来休',
);

/// Cyrillic uppercase alphabet.
const List<String> cyrillicChars = [
  'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й', 'К', 'Л',
  'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш',
  'Щ', 'Ъ', 'Ы', 'Ь', 'Э', 'Ю', 'Я',
];

// ─────────────────────────────────────────────────────────
// API
// ─────────────────────────────────────────────────────────

/// Returns the distractor character pool for [script].
List<String> getCharacterPool(ScriptType script) => switch (script) {
      ScriptType.hiragana => hiraganaChars,
      ScriptType.katakana => katakanaChars,
      ScriptType.kanji => commonKanjiChars,
      ScriptType.latinAccented => spanishChars,
      ScriptType.cyrillic => cyrillicChars,
      _ => latinChars, // ScriptType.latin and ScriptType.custom
    };

/// Returns `true` if [char] is a Hiragana code-point (U+3040–U+309F).
bool isHiragana(String char) {
  if (char.isEmpty) return false;
  final cp = char.runes.first;
  return cp >= 0x3040 && cp <= 0x309F;
}

/// Returns `true` if [char] is a Katakana code-point (U+30A0–U+30FF).
bool isKatakana(String char) {
  if (char.isEmpty) return false;
  final cp = char.runes.first;
  return cp >= 0x30A0 && cp <= 0x30FF;
}

/// Returns `true` if [char] is a CJK Unified Ideograph (U+4E00–U+9FFF).
bool isKanji(String char) {
  if (char.isEmpty) return false;
  final cp = char.runes.first;
  return cp >= 0x4E00 && cp <= 0x9FFF;
}

/// Returns `true` if [char] is a Cyrillic code-point (U+0400–U+04FF).
bool isCyrillic(String char) {
  if (char.isEmpty) return false;
  final cp = char.runes.first;
  return cp >= 0x0400 && cp <= 0x04FF;
}

/// Returns `true` if [char] is a Latin character with an accent or Ñ.
bool isLatinAccented(String char) =>
    'ÁÉÍÓÚÜÑ'.contains(char.toUpperCase());

/// Auto-detects the predominant [ScriptType] from a collection of [words].
ScriptType detectScript(List<String> words) {
  if (words.isEmpty) return ScriptType.latin;

  final allChars = words.join().replaceAll(' ', '');
  if (allChars.isEmpty) return ScriptType.latin;

  final counts = <ScriptType, int>{
    ScriptType.hiragana: 0,
    ScriptType.katakana: 0,
    ScriptType.kanji: 0,
    ScriptType.cyrillic: 0,
    ScriptType.latinAccented: 0,
    ScriptType.latin: 0,
  };

  for (final char in allChars.split('')) {
    if (isHiragana(char)) {
      counts[ScriptType.hiragana] = counts[ScriptType.hiragana]! + 1;
    } else if (isKatakana(char)) {
      counts[ScriptType.katakana] = counts[ScriptType.katakana]! + 1;
    } else if (isKanji(char)) {
      counts[ScriptType.kanji] = counts[ScriptType.kanji]! + 1;
    } else if (isCyrillic(char)) {
      counts[ScriptType.cyrillic] = counts[ScriptType.cyrillic]! + 1;
    } else if (isLatinAccented(char)) {
      counts[ScriptType.latinAccented] = counts[ScriptType.latinAccented]! + 1;
    } else {
      counts[ScriptType.latin] = counts[ScriptType.latin]! + 1;
    }
  }

  final cjkTotal = counts[ScriptType.hiragana]! +
      counts[ScriptType.katakana]! +
      counts[ScriptType.kanji]!;

  if (cjkTotal > 0) {
    // Prioritise the CJK sub-type with the highest count.
    final cjkScores = {
      ScriptType.hiragana: counts[ScriptType.hiragana]!,
      ScriptType.katakana: counts[ScriptType.katakana]!,
      ScriptType.kanji: counts[ScriptType.kanji]!,
    };
    return cjkScores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  if (counts[ScriptType.cyrillic]! > 0) return ScriptType.cyrillic;
  if (counts[ScriptType.latinAccented]! > 0) return ScriptType.latinAccented;
  return ScriptType.latin;
}

/// Strips whitespace and uppercases Latin/Cyrillic words.
/// CJK scripts are returned without uppercasing.
String normalizeWordForPuzzle(String word, ScriptType script) {
  final cleaned = word.trim().replaceAll(RegExp(r'\s+'), '');
  if (script == ScriptType.latin ||
      script == ScriptType.latinAccented ||
      script == ScriptType.cyrillic) {
    return cleaned.toUpperCase();
  }
  return cleaned;
}

// ─────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────

/// Splits a string of Unicode characters into a list of grapheme clusters.
List<String> _splitChars(String s) =>
    s.runes.map((r) => String.fromCharCode(r)).toList();

