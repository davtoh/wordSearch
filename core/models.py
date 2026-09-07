"""Data Models and Pydantic Schemas for Word Search Puzzles."""
from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple
from pydantic import BaseModel, Field

from core.enums import Difficulty, Direction, HintTier, MasteryLevel, ScriptType


class WordEntry(BaseModel):
    """Represents a single word in the puzzle with placement and definition."""
    word: str
    clue: Optional[str] = None
    reading: Optional[str] = None  # e.g., Hiragana/Romaji reading for Kanji or phonetic info
    coords: List[Tuple[int, int]] = Field(default_factory=list)
    direction: Optional[Direction] = None
    found: bool = False
    hint_tier_used: HintTier = HintTier.NONE

    @property
    def start_coord(self) -> Optional[Tuple[int, int]]:
        return self.coords[0] if self.coords else None

    @property
    def end_coord(self) -> Optional[Tuple[int, int]]:
        return self.coords[-1] if self.coords else None

    @property
    def length(self) -> int:
        return len(self.word)


class PuzzleMetadata(BaseModel):
    """Metadata describing a puzzle's provenance, theme, and settings."""
    id: str = Field(default_factory=lambda: str(uuid.uuid4())[:8])
    title: str = "Word Search"
    theme: str = "General"
    language: str = "en"
    script_type: ScriptType = ScriptType.LATIN
    difficulty: Difficulty = Difficulty.EASY
    author: str = "System"
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    description: Optional[str] = None


class AssistConfig(BaseModel):
    """Pluggable assist settings and difficulty constraints."""
    allowed_hint_tiers: List[int] = Field(default_factory=lambda: [1, 2, 3, 4, 5, 6])
    proximity_enabled: bool = True
    time_limit_seconds: int = 240
    bonus_time_per_word: int = 15
    is_shifting: bool = False
    density_target: float = 0.65


class Puzzle(BaseModel):
    """Self-contained, serializable Word Search Puzzle object."""
    metadata: PuzzleMetadata
    rows: int
    cols: int
    grid: List[List[str]]
    words: List[WordEntry]
    allowed_directions: List[Direction] = Field(default_factory=list)
    assist_config: AssistConfig = Field(default_factory=AssistConfig)

    def get_word(self, word_str: str) -> Optional[WordEntry]:
        for w in self.words:
            if w.word == word_str:
                return w
        return None

    @property
    def total_words(self) -> int:
        return len(self.words)

    @property
    def found_words_count(self) -> int:
        return sum(1 for w in self.words if w.found)

    @property
    def is_complete(self) -> bool:
        return self.found_words_count == self.total_words and self.total_words > 0


class WordMasteryRecord(BaseModel):
    """Tracks player mastery metrics for an individual vocabulary word."""
    word: str
    language: str = "en"
    clue: Optional[str] = None
    reading: Optional[str] = None
    times_encountered: int = 0
    times_solved: int = 0
    total_solve_time_seconds: float = 0.0
    hint_tiers_history: List[int] = Field(default_factory=list)
    error_clicks: int = 0
    last_encountered_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    mastery_level: MasteryLevel = MasteryLevel.UNSEEN

    @property
    def average_solve_time(self) -> float:
        return self.total_solve_time_seconds / max(1, self.times_solved)


class PlayerProfile(BaseModel):
    """Persistent player profile with statistics and vocabulary deck."""
    total_games_played: int = 0
    total_games_won: int = 0
    total_words_found: int = 0
    total_play_time_seconds: float = 0.0
    best_velocity_spw: float = 0.0  # seconds per word (lower is faster)
    overall_accuracy: float = 100.0
    timed_attack_high_scores: Dict[str, int] = Field(default_factory=dict)
    vocabulary_deck: Dict[str, WordMasteryRecord] = Field(default_factory=dict)
