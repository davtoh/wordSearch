"""Focus-Aware Telemetry and Player Performance Metrics Tracker."""
from __future__ import annotations

import time
from typing import Any, Dict, List, Optional, Tuple

from core.models import WordEntry


class SessionTelemetry:
    """Tracks real-time player velocity, accuracy, and focus-aware active playtime."""

    def __init__(self) -> None:
        self.start_wall_time = time.time()
        self.active_elapsed_seconds: float = 0.0
        self.is_focused: bool = True
        self.is_paused: bool = False

        self.word_find_intervals: List[float] = []  # time taken between consecutive finds
        self.last_find_active_time: float = 0.0

        self.valid_selections: int = 0
        self.invalid_selections: int = 0
        self.error_clicks_per_word: Dict[str, int] = {}
        self.hint_requests_count: int = 0

    def on_tick(self, delta_seconds: float) -> None:
        """Accumulates active gameplay time only if window is focused and unpaused."""
        if self.is_focused and not self.is_paused:
            self.active_elapsed_seconds += delta_seconds

    def on_focus_lost(self) -> None:
        """Pauses timer and metrics accumulation when user switches apps or tabs out."""
        self.is_focused = False

    def on_focus_gained(self) -> None:
        """Resumes timer and metrics accumulation when app regains focus."""
        self.is_focused = True

    def on_pause_toggled(self, is_paused: bool) -> None:
        self.is_paused = is_paused

    def record_selection_attempt(self, is_valid: bool, target_word: Optional[str] = None) -> None:
        if is_valid:
            self.valid_selections += 1
        else:
            self.invalid_selections += 1
            if target_word:
                self.error_clicks_per_word[target_word] = self.error_clicks_per_word.get(target_word, 0) + 1

    def record_word_found(self, word_entry: WordEntry) -> float:
        """Records word discovery and returns the interval taken to find this specific word."""
        interval = self.active_elapsed_seconds - self.last_find_active_time
        interval = max(0.1, interval)
        self.word_find_intervals.append(interval)
        self.last_find_active_time = self.active_elapsed_seconds
        return interval

    def record_hint_used(self) -> None:
        self.hint_requests_count += 1

    @property
    def current_velocity(self) -> float:
        """Average seconds per word found (lower is faster)."""
        if not self.word_find_intervals:
            return 0.0
        return sum(self.word_find_intervals) / len(self.word_find_intervals)

    @property
    def accuracy_rate(self) -> float:
        """Percentage of valid selection attempts (0% - 100%)."""
        total = self.valid_selections + self.invalid_selections
        if total == 0:
            return 100.0
        return (self.valid_selections / total) * 100.0

    @property
    def seconds_since_last_find(self) -> float:
        return self.active_elapsed_seconds - self.last_find_active_time

    def summary(self) -> Dict[str, Any]:
        return {
            "active_time_seconds": round(self.active_elapsed_seconds, 1),
            "words_found": len(self.word_find_intervals),
            "average_velocity_spw": round(self.current_velocity, 1),
            "accuracy_percentage": round(self.accuracy_rate, 1),
            "valid_attempts": self.valid_selections,
            "invalid_attempts": self.invalid_selections,
            "hints_used": self.hint_requests_count,
        }
