"""Pluggable Assist Registry for Dispatching Game Assists."""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from assists.auto_stall_detector import AutoStallDetector
from assists.base import BaseAssistProvider
from assists.progressive_hints import ProgressiveHintProvider
from assists.proximity_assist import ProximityAssistProvider
from assists.time_bonus_assist import TimeBonusAssistProvider
from core.game_state import GameState
from core.models import WordEntry
from config.settings import settings


class AssistRegistry:
    """Central registry that coordinates all active assist and hint providers."""

    def __init__(self) -> None:
        self.providers: Dict[str, BaseAssistProvider] = {}
        self.hints = ProgressiveHintProvider()
        self.proximity = ProximityAssistProvider()
        self.time_bonus = TimeBonusAssistProvider()
        self.stall_detector = AutoStallDetector()

        self.register(self.hints)
        if settings.get("proximity_assist_enabled", True):
            self.register(self.proximity)
        self.register(self.time_bonus)
        self.register(self.stall_detector)

    def register(self, provider: BaseAssistProvider) -> None:
        self.providers[provider.name] = provider

    def get(self, name: str) -> Optional[BaseAssistProvider]:
        return self.providers.get(name)

    def on_tick(self, game_state: GameState, delta_seconds: float) -> List[Dict[str, Any]]:
        events = []
        for provider in self.providers.values():
            if provider.is_enabled(game_state.puzzle.assist_config):
                res = provider.on_tick(game_state, delta_seconds)
                if res:
                    events.append(res)
        return events

    def on_cell_clicked(
        self, game_state: GameState, coord: Tuple[int, int]
    ) -> List[Dict[str, Any]]:
        events = []
        for provider in self.providers.values():
            if provider.is_enabled(game_state.puzzle.assist_config):
                res = provider.on_cell_clicked(game_state, coord)
                if res:
                    events.append(res)
        return events

    def on_word_found(self, game_state: GameState, word: WordEntry) -> None:
        for provider in self.providers.values():
            if provider.is_enabled(game_state.puzzle.assist_config):
                provider.on_word_found(game_state, word)
