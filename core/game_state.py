"""Pure UI-Agnostic Game State Machine and Selection Validator."""
from __future__ import annotations

import math
from typing import Dict, List, Optional, Set, Tuple

from core.enums import Direction, GameMode, GameStatus, HintTier
from core.models import Puzzle, WordEntry


class GameState:
    """Manages active puzzle progression, timed countdown, selection checks, and win/give-up states."""

    def __init__(self, puzzle: Puzzle, mode: GameMode = GameMode.CASUAL) -> None:
        self.puzzle = puzzle
        self.mode = mode
        self.status = GameStatus.PLAYING
        self.found_words: List[WordEntry] = []
        self.found_coords_map: Dict[Tuple[int, int], str] = {}  # (r, c) -> word

        # Timed Attack Timer
        self.time_limit = puzzle.assist_config.time_limit_seconds
        self.time_remaining = float(self.time_limit)
        self.bonus_per_word = puzzle.assist_config.bonus_time_per_word
        self.total_elapsed_seconds: float = 0.0

        # Highlights and hints
        self.active_hint_coords: Set[Tuple[int, int]] = set()
        self.active_hint_word: Optional[WordEntry] = None
        self.revealed_all_on_giveup: bool = False

    def check_selection(
        self, start_coord: Tuple[int, int], end_coord: Tuple[int, int]
    ) -> Tuple[bool, Optional[WordEntry], List[Tuple[int, int]]]:
        """
        Validates if the drag line from start_coord to end_coord matches an unfound word.
        Supports both forward and reverse drag selection!
        """
        if self.status != GameStatus.PLAYING:
            return False, None, []

        coords = self.interpolate_line(start_coord, end_coord)
        if not coords:
            return False, None, []

        # Read characters along the line
        selected_chars = [self.puzzle.grid[r][c] for r, c in coords]
        forward_str = "".join(selected_chars)
        reverse_str = forward_str[::-1]

        for word_entry in self.puzzle.words:
            if word_entry.found:
                continue

            # Match exact coordinates or forward/reverse strings
            if coords == word_entry.coords or coords == list(reversed(word_entry.coords)):
                self._mark_word_found(word_entry)
                return True, word_entry, coords
            elif forward_str == word_entry.word or reverse_str == word_entry.word:
                # In case of duplicate strings placed elsewhere, verify coordinates
                if len(coords) == len(word_entry.coords):
                    self._mark_word_found(word_entry)
                    return True, word_entry, coords

        return False, None, coords

    def _mark_word_found(self, word_entry: WordEntry) -> None:
        """Marks a word as found and checks for game completion."""
        word_entry.found = True
        self.found_words.append(word_entry)
        for coord in word_entry.coords:
            self.found_coords_map[coord] = word_entry.word

        # Add time bonus in Timed Attack mode
        if self.mode == GameMode.TIMED_ATTACK:
            self.time_remaining += self.bonus_per_word

        # Clear any active hints for this word
        if self.active_hint_word and self.active_hint_word.word == word_entry.word:
            self.active_hint_word = None
            self.active_hint_coords.clear()

        # Check win condition
        if self.puzzle.is_complete:
            self.status = GameStatus.WON

    def interpolate_line(
        self, start: Tuple[int, int], end: Tuple[int, int]
    ) -> List[Tuple[int, int]]:
        """Returns the list of straight grid cells from start to end in 8 directions."""
        r0, c0 = start
        r1, c1 = end

        # Boundary checks
        if not (0 <= r0 < self.puzzle.rows and 0 <= c0 < self.puzzle.cols):
            return []
        if not (0 <= r1 < self.puzzle.rows and 0 <= c1 < self.puzzle.cols):
            return []

        dr = r1 - r0
        dc = c1 - c0

        # Single cell click
        if dr == 0 and dc == 0:
            return [(r0, c0)]

        # Must be horizontal, vertical, or true 45-degree diagonal
        abs_dr = abs(dr)
        abs_dc = abs(dc)

        if not (dr == 0 or dc == 0 or abs_dr == abs_dc):
            return []

        step_r = (dr > 0) - (dr < 0) if dr != 0 else 0
        step_c = (dc > 0) - (dc < 0) if dc != 0 else 0

        steps = max(abs_dr, abs_dc)
        line = [(r0 + i * step_r, c0 + i * step_c) for i in range(steps + 1)]
        return line

    def tick(self, delta_seconds: float) -> None:
        """Updates timers during active gameplay."""
        if self.status != GameStatus.PLAYING:
            return

        self.total_elapsed_seconds += delta_seconds

        if self.mode == GameMode.TIMED_ATTACK:
            self.time_remaining -= delta_seconds
            if self.time_remaining <= 0:
                self.time_remaining = 0
                self.status = GameStatus.TIME_OUT

    def give_up(self) -> None:
        """Surrenders the game, reveals all words for review, and transitions to GIVEN_UP."""
        self.status = GameStatus.GIVEN_UP
        self.revealed_all_on_giveup = True
        for w in self.puzzle.words:
            for coord in w.coords:
                if coord not in self.found_coords_map:
                    self.found_coords_map[coord] = w.word

    def toggle_pause(self) -> bool:
        """Toggles between PLAYING and PAUSED."""
        if self.status == GameStatus.PLAYING:
            self.status = GameStatus.PAUSED
            return True
        elif self.status == GameStatus.PAUSED:
            self.status = GameStatus.PLAYING
            return False
        return False

    def get_nearest_unfound_word_distance(self, coord: Tuple[int, int]) -> Optional[float]:
        """Calculates distance from (r, c) to the nearest unfound word's start coordinate."""
        r, c = coord
        unfound = [w for w in self.puzzle.words if not w.found and w.start_coord]
        if not unfound:
            return None

        min_dist = float("inf")
        for w in unfound:
            sr, sc = w.start_coord  # type: ignore
            dist = math.hypot(r - sr, c - sc)
            if dist < min_dist:
                min_dist = dist
        return min_dist
