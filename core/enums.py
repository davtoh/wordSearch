"""Core Enums for Word Search Game."""
from __future__ import annotations

from enum import Enum, IntEnum
from typing import Optional, Tuple


class ScriptType(str, Enum):
    """Supported writing scripts for grid generation and filler characters."""
    LATIN = "latin"
    LATIN_ACCENTED = "latin_accented"
    HIRAGANA = "hiragana"
    KATAKANA = "katakana"
    KANJI = "kanji"
    CYRILLIC = "cyrillic"
    CUSTOM = "custom"


class Difficulty(str, Enum):
    """Game difficulty presets."""
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    EXPERT = "expert"
    DYNAMIC = "dynamic"


class ThemeMode(str, Enum):
    """Game theme presets."""
    DARK = "dark"
    LIGHT = "light"


class Direction(str, Enum):
    """Allowed 8-way directional vectors for word placement and selection."""
    HORIZONTAL_LR = "HORIZONTAL_LR"   # (0, 1)  -> Right
    HORIZONTAL_RL = "HORIZONTAL_RL"   # (0, -1) -> Left
    VERTICAL_TB = "VERTICAL_TB"       # (1, 0)  -> Down
    VERTICAL_BT = "VERTICAL_BT"       # (-1, 0) -> Up
    DIAGONAL_TL_BR = "DIAGONAL_TL_BR" # (1, 1)  -> Down-Right
    DIAGONAL_BR_TL = "DIAGONAL_BR_TL" # (-1, -1)-> Up-Left
    DIAGONAL_BL_TR = "DIAGONAL_BL_TR" # (-1, 1) -> Up-Right
    DIAGONAL_TR_BL = "DIAGONAL_TR_BL" # (1, -1) -> Down-Left

    @property
    def delta(self) -> Tuple[int, int]:
        """Returns (d_row, d_col) coordinate step."""
        vectors = {
            Direction.HORIZONTAL_LR: (0, 1),
            Direction.HORIZONTAL_RL: (0, -1),
            Direction.VERTICAL_TB: (1, 0),
            Direction.VERTICAL_BT: (-1, 0),
            Direction.DIAGONAL_TL_BR: (1, 1),
            Direction.DIAGONAL_BR_TL: (-1, -1),
            Direction.DIAGONAL_BL_TR: (-1, 1),
            Direction.DIAGONAL_TR_BL: (1, -1),
        }
        return vectors[self]

    @property
    def human_readable(self) -> str:
        names = {
            Direction.HORIZONTAL_LR: "Horizontal (Left → Right)",
            Direction.HORIZONTAL_RL: "Horizontal Reverse (Right → Left)",
            Direction.VERTICAL_TB: "Vertical (Top → Bottom)",
            Direction.VERTICAL_BT: "Vertical Reverse (Bottom → Top)",
            Direction.DIAGONAL_TL_BR: "Diagonal Down-Right ↘",
            Direction.DIAGONAL_BR_TL: "Diagonal Up-Left ↖",
            Direction.DIAGONAL_BL_TR: "Diagonal Up-Right ↗",
            Direction.DIAGONAL_TR_BL: "Diagonal Down-Left ↙",
        }
        return names.get(self, str(self.value))

    @classmethod
    def from_delta(cls, d_row: int, d_col: int) -> Optional[Direction]:
        # Normalize unit step
        sign_r = (d_row > 0) - (d_row < 0) if d_row != 0 else 0
        sign_c = (d_col > 0) - (d_col < 0) if d_col != 0 else 0
        for d in cls:
            if d.delta == (sign_r, sign_c):
                return d
        return None


class GameMode(str, Enum):
    """Play mode."""
    CASUAL = "casual"
    TIMED_ATTACK = "timed_attack"


class GameStatus(str, Enum):
    """Current state of a game session."""
    NOT_STARTED = "not_started"
    PLAYING = "playing"
    PAUSED = "paused"
    WON = "won"
    TIME_OUT = "time_out"
    GIVEN_UP = "given_up"


class HintTier(IntEnum):
    """Progressive 6-tier hint stages."""
    NONE = 0
    TIER_1_CLUE = 1               # Definition / Clue only
    TIER_2_WORD_NAME = 2          # Word string revealed
    TIER_3_FIRST_LETTER = 3       # First character + word length (no coords)
    TIER_4_ORIENTATION = 4        # Direction revealed
    TIER_5_START_COORDINATE = 5   # Starting (r, c) coordinate highlighted
    TIER_6_FULL_GLOW = 6          # Full word path highlighted


class MasteryLevel(str, Enum):
    """Vocabulary familiarity and spaced repetition classification."""
    UNSEEN = "unseen"
    LEARNING = "learning"
    NEEDS_PRACTICE = "needs_practice"
    MASTERED = "mastered"
