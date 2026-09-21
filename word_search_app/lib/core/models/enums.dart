/// Core enums for the Word Search domain layer.
/// Pure Dart — zero Flutter UI dependencies.
library;

// ─────────────────────────────────────────────────────────
// ScriptType
// ─────────────────────────────────────────────────────────

/// Supported writing scripts for grid generation and filler characters.
enum ScriptType {
  latin,
  latinAccented,
  hiragana,
  katakana,
  kanji,
  cyrillic,
  custom;

  /// Serialisation key (matches Python ScriptType values).
  String get value => switch (this) {
        ScriptType.latin => 'latin',
        ScriptType.latinAccented => 'latin_accented',
        ScriptType.hiragana => 'hiragana',
        ScriptType.katakana => 'katakana',
        ScriptType.kanji => 'kanji',
        ScriptType.cyrillic => 'cyrillic',
        ScriptType.custom => 'custom',
      };

  static ScriptType fromValue(String v) =>
      ScriptType.values.firstWhere((e) => e.value == v,
          orElse: () => ScriptType.latin);
}

// ─────────────────────────────────────────────────────────
// Difficulty
// ─────────────────────────────────────────────────────────

/// Game difficulty presets affecting grid size and allowed directions.
enum Difficulty {
  easy,
  medium,
  hard,
  expert,
  dynamic;

  String get value => name; // 'easy', 'medium', …

  static Difficulty fromValue(String v) =>
      Difficulty.values.firstWhere((e) => e.value == v,
          orElse: () => Difficulty.easy);
}

// ─────────────────────────────────────────────────────────
// ThemeMode
// ─────────────────────────────────────────────────────────

/// Game UI theme preference.
enum AppThemeMode {
  dark,
  light;

  String get value => name;
}

// ─────────────────────────────────────────────────────────
// Direction
// ─────────────────────────────────────────────────────────

/// Allowed 8-way directional vectors for word placement and selection.
enum Direction {
  horizontalLr,   // (0,  1)  → Right
  horizontalRl,   // (0, -1)  → Left
  verticalTb,     // (1,  0)  → Down
  verticalBt,     // (-1, 0)  → Up
  diagonalTlBr,   // (1,  1)  → Down-Right
  diagonalBrTl,   // (-1,-1)  → Up-Left
  diagonalBlTr,   // (-1, 1)  → Up-Right
  diagonalTrBl;   // (1, -1)  → Down-Left

  /// (dRow, dCol) unit step.
  (int, int) get delta => switch (this) {
        Direction.horizontalLr => (0, 1),
        Direction.horizontalRl => (0, -1),
        Direction.verticalTb => (1, 0),
        Direction.verticalBt => (-1, 0),
        Direction.diagonalTlBr => (1, 1),
        Direction.diagonalBrTl => (-1, -1),
        Direction.diagonalBlTr => (-1, 1),
        Direction.diagonalTrBl => (1, -1),
      };

  String get humanReadable => switch (this) {
        Direction.horizontalLr => 'Horizontal (Left → Right)',
        Direction.horizontalRl => 'Horizontal Reverse (Right → Left)',
        Direction.verticalTb => 'Vertical (Top → Bottom)',
        Direction.verticalBt => 'Vertical Reverse (Bottom → Top)',
        Direction.diagonalTlBr => 'Diagonal Down-Right ↘',
        Direction.diagonalBrTl => 'Diagonal Up-Left ↖',
        Direction.diagonalBlTr => 'Diagonal Up-Right ↗',
        Direction.diagonalTrBl => 'Diagonal Down-Left ↙',
      };

  /// Matches a (dRow, dCol) pair to its Direction, normalising to unit steps.
  static Direction? fromDelta(int dRow, int dCol) {
    int signR = dRow > 0
        ? 1
        : dRow < 0
            ? -1
            : 0;
    int signC = dCol > 0
        ? 1
        : dCol < 0
            ? -1
            : 0;
    for (final d in Direction.values) {
      final (r, c) = d.delta;
      if (r == signR && c == signC) return d;
    }
    return null;
  }

  String get value => switch (this) {
        Direction.horizontalLr => 'HORIZONTAL_LR',
        Direction.horizontalRl => 'HORIZONTAL_RL',
        Direction.verticalTb => 'VERTICAL_TB',
        Direction.verticalBt => 'VERTICAL_BT',
        Direction.diagonalTlBr => 'DIAGONAL_TL_BR',
        Direction.diagonalBrTl => 'DIAGONAL_BR_TL',
        Direction.diagonalBlTr => 'DIAGONAL_BL_TR',
        Direction.diagonalTrBl => 'DIAGONAL_TR_BL',
      };

  static Direction fromValue(String v) =>
      Direction.values.firstWhere((e) => e.value == v,
          orElse: () => Direction.horizontalLr);
}

// ─────────────────────────────────────────────────────────
// GameMode
// ─────────────────────────────────────────────────────────

/// Play mode selector.
enum GameMode {
  casual,
  timedAttack;

  String get value => switch (this) {
        GameMode.casual => 'casual',
        GameMode.timedAttack => 'timed_attack',
      };

  static GameMode fromValue(String v) =>
      GameMode.values.firstWhere((e) => e.value == v,
          orElse: () => GameMode.casual);
}

// ─────────────────────────────────────────────────────────
// GameStatus
// ─────────────────────────────────────────────────────────

/// Current state of a game session.
enum GameStatus {
  notStarted,
  playing,
  paused,
  won,
  timeOut,
  givenUp;

  String get value => switch (this) {
        GameStatus.notStarted => 'not_started',
        GameStatus.playing => 'playing',
        GameStatus.paused => 'paused',
        GameStatus.won => 'won',
        GameStatus.timeOut => 'time_out',
        GameStatus.givenUp => 'given_up',
      };

  static GameStatus fromValue(String v) =>
      GameStatus.values.firstWhere((e) => e.value == v,
          orElse: () => GameStatus.notStarted);
}

// ─────────────────────────────────────────────────────────
// HintTier
// ─────────────────────────────────────────────────────────

/// Progressive 6-tier hint stages.
enum HintTier {
  none(0),
  tier1Clue(1),
  tier2WordName(2),
  tier3FirstLetter(3),
  tier4Orientation(4),
  tier5StartCoordinate(5),
  tier6FullGlow(6);

  const HintTier(this.level);

  /// Numeric level (0–6), matching Python IntEnum.
  final int level;

  static HintTier fromLevel(int l) =>
      HintTier.values.firstWhere((e) => e.level == l,
          orElse: () => HintTier.none);
}

// ─────────────────────────────────────────────────────────
// MasteryLevel
// ─────────────────────────────────────────────────────────

/// Vocabulary familiarity / spaced-repetition classification.
enum MasteryLevel {
  unseen,
  learning,
  needsPractice,
  mastered;

  String get value => switch (this) {
        MasteryLevel.unseen => 'unseen',
        MasteryLevel.learning => 'learning',
        MasteryLevel.needsPractice => 'needs_practice',
        MasteryLevel.mastered => 'mastered',
      };

  static MasteryLevel fromValue(String v) =>
      MasteryLevel.values.firstWhere((e) => e.value == v,
          orElse: () => MasteryLevel.unseen);
}

