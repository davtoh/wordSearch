"""Throttled and Cached Proximity 'Hot & Cold' Assist Provider."""
from __future__ import annotations

import time
from typing import Any, Dict, Optional, Tuple

from assists.base import BaseAssistProvider
from core.game_state import GameState
from core.models import AssistConfig


class ProximityAssistProvider(BaseAssistProvider):
    """Provides real-time, low-overhead proximity feedback when tapping or inspecting cells."""

    def __init__(self, throttle_interval_seconds: float = 0.10) -> None:
        self.throttle_interval = throttle_interval_seconds
        self._last_calc_time = 0.0
        self._cached_coord: Optional[Tuple[int, int]] = None
        self._cached_result: Optional[Dict[str, Any]] = None

    @property
    def name(self) -> str:
        return "proximity_assist"

    def is_enabled(self, config: AssistConfig) -> bool:
        return config.proximity_enabled

    def on_cell_clicked(
        self, game_state: GameState, coord: Tuple[int, int]
    ) -> Optional[Dict[str, Any]]:
        return self.calculate_proximity(game_state, coord)

    def calculate_proximity(
        self, game_state: GameState, coord: Tuple[int, int]
    ) -> Optional[Dict[str, Any]]:
        """Calculates proximity distance with throttling and caching."""
        if not self.is_enabled(game_state.puzzle.assist_config):
            return None

        now = time.time()
        # Return cache if coordinate is identical and within throttle window
        if self._cached_coord == coord and (now - self._last_calc_time) < self.throttle_interval:
            return self._cached_result

        self._last_calc_time = now
        self._cached_coord = coord

        dist = game_state.get_nearest_unfound_word_distance(coord)
        if dist is None:
            self._cached_result = None
            return None

        if dist <= 1.0:
            status = "BURNING"
            message = "🔥 Burning Hot! A word starts right here!"
            color = (255, 60, 60)
        elif dist <= 2.0:
            status = "HOT"
            message = "⚡ Hot! Very close to a word start."
            color = (255, 140, 0)
        elif dist <= 3.5:
            status = "WARM"
            message = "✨ Warm... in the right neighborhood."
            color = (255, 215, 0)
        elif dist <= 5.0:
            status = "COOL"
            message = "❄️ Cool. Still a bit far."
            color = (100, 180, 255)
        else:
            status = "COLD"
            message = "🧊 Cold."
            color = (150, 150, 180)

        result = {
            "status": status,
            "distance": round(dist, 2),
            "message": message,
            "color": color,
            "coord": coord,
        }
        self._cached_result = result
        return result
