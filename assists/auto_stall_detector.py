"""Auto Stall and Player Inactivity Assist Detector."""
from __future__ import annotations

from typing import Any, Dict, Optional

from assists.base import BaseAssistProvider
from core.game_state import GameState
from core.models import AssistConfig, WordEntry
from config.settings import settings


class AutoStallDetector(BaseAssistProvider):
    """Detects when player has stalled or struggled and prompts an assistance reminder."""

    def __init__(self, stall_threshold_seconds: float = None) -> None:
        self.stall_threshold = stall_threshold_seconds or settings.get("auto_stall_hint_seconds", 45.0)
        self.seconds_since_last_find = 0.0
        self.stall_triggered = False

    @property
    def name(self) -> str:
        return "auto_stall_detector"

    def is_enabled(self, config: AssistConfig) -> bool:
        return True

    def on_tick(self, game_state: GameState, delta_seconds: float) -> Optional[Dict[str, Any]]:
        self.seconds_since_last_find += delta_seconds
        if (
            self.seconds_since_last_find >= self.stall_threshold
            and not self.stall_triggered
            and not game_state.puzzle.is_complete
        ):
            self.stall_triggered = True
            return {
                "stalled": True,
                "seconds_idle": round(self.seconds_since_last_find, 1),
                "message": "Need a hint? Press the Clue button or tap on a word in the list!",
            }
        return None

    def on_word_found(self, game_state: GameState, word: WordEntry) -> None:
        self.seconds_since_last_find = 0.0
        self.stall_triggered = False

    def reset(self) -> None:
        self.seconds_since_last_find = 0.0
        self.stall_triggered = False
