"""Abstract Base Interface for Pluggable Assist Providers."""
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, Tuple

from core.game_state import GameState
from core.models import AssistConfig, WordEntry


class BaseAssistProvider(ABC):
    """Base interface for gameplay aids, hint mechanisms, and performance throttled assists."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Unique identifier name of the assist provider."""
        pass

    @abstractmethod
    def is_enabled(self, config: AssistConfig) -> bool:
        """Checks if this assist provider is enabled in the active configuration."""
        pass

    def on_tick(self, game_state: GameState, delta_seconds: float) -> Optional[Dict[str, Any]]:
        """Called on each game loop tick (optional)."""
        return None

    def on_cell_clicked(
        self, game_state: GameState, coord: Tuple[int, int]
    ) -> Optional[Dict[str, Any]]:
        """Called when a user clicks/taps a cell on the grid (optional)."""
        return None

    def on_word_found(self, game_state: GameState, word: WordEntry) -> None:
        """Called when a word is successfully found (optional)."""
        pass
