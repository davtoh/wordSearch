/// PuzzleMetadata — provenance information for a generated puzzle.
/// Pure Dart — zero Flutter UI dependencies.
library;

import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Metadata describing a puzzle's origin, theme, script, and difficulty.
class PuzzleMetadata extends Equatable {
  PuzzleMetadata({
    String? id,
    this.title = 'Word Search',
    this.theme = 'General',
    this.language = 'en',
    this.scriptType = ScriptType.latin,
    this.difficulty = Difficulty.easy,
    this.author = 'System',
    DateTime? createdAt,
    this.description,
  })  : id = id ?? _shortId(),
        createdAt = createdAt ?? DateTime.now().toUtc();

  final String id;
  final String title;
  final String theme;
  final String language;
  final ScriptType scriptType;
  final Difficulty difficulty;
  final String author;
  final DateTime createdAt;
  final String? description;

  static String _shortId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return ts.substring(ts.length > 8 ? ts.length - 8 : 0);
  }

  PuzzleMetadata copyWith({
    String? id,
    String? title,
    String? theme,
    String? language,
    ScriptType? scriptType,
    Difficulty? difficulty,
    String? author,
    DateTime? createdAt,
    String? description,
  }) =>
      PuzzleMetadata(
        id: id ?? this.id,
        title: title ?? this.title,
        theme: theme ?? this.theme,
        language: language ?? this.language,
        scriptType: scriptType ?? this.scriptType,
        difficulty: difficulty ?? this.difficulty,
        author: author ?? this.author,
        createdAt: createdAt ?? this.createdAt,
        description: description ?? this.description,
      );

  factory PuzzleMetadata.fromJson(Map<String, dynamic> json) => PuzzleMetadata(
        id: json['id'] as String?,
        title: json['title'] as String? ?? 'Word Search',
        theme: json['theme'] as String? ?? 'General',
        language: json['language'] as String? ?? 'en',
        scriptType: ScriptType.fromValue(
            json['script_type'] as String? ?? 'latin'),
        difficulty: Difficulty.fromValue(
            json['difficulty'] as String? ?? 'easy'),
        author: json['author'] as String? ?? 'System',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'theme': theme,
        'language': language,
        'script_type': scriptType.value,
        'difficulty': difficulty.value,
        'author': author,
        'created_at': createdAt.toIso8601String(),
        if (description != null) 'description': description,
      };

  @override
  List<Object?> get props => [
        id, title, theme, language, scriptType,
        difficulty, author, createdAt, description,
      ];
}

