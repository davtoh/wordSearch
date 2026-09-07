"""Time Bonus and Overtime Recovery Assist Provider."""
from __future__ import annotations

from typing import Any, Dict, Optional

from assists.base import BaseAssistProvider
from core.enums import GameMode
from core.game_state import GameState
from core.models import AssistConfig, WordEntry


class TimeBonusAssistProvider(BaseAssistProvider):
    """Manages overtime bonuses and emergency time boosts in Timed Attack mode."""

    @property
    def name(self) -> str:
        return "time_bonus"

    def is_enabled(self, config: AssistConfig) -> bool:
        return True

    def on_word_found(self, game_state: GameState, word: WordEntry) -> None:
        """Adds time reward when a word is solved."""
        if game_state.mode == GameMode.TIMED_ATTACK:
            bonus = game_state.bonus_per_word
            game_state.time_remaining += bonus

    def apply_emergency_time_boost(
        self, game_state: GameState, boost_seconds: float = 30.0
    ) -> Optional[Dict[str, Any]]:
        """Adds emergency time in timed attack mode."""
        if game_state.mode != GameMode.TIMED_ATTACK:
            return None

        game_state.time_remaining += boost_seconds
        return {
            "boost_seconds": boost_seconds,
            "new_time_remaining": game_state.time_remaining,
            "message": f"+{int(boost_seconds)}s Emergency Time Added!",
        }
