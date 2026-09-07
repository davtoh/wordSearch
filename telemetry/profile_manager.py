"""Player Profile Manager and Lifetime Telemetry Persistence."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

from core.enums import GameStatus
from core.game_state import GameState
from core.models import PlayerProfile
from learning.mastery_tracker import MasteryTracker
from telemetry.tracker import SessionTelemetry

DATA_DIR = Path(__file__).parent.parent / "data"
PROFILE_PATH = DATA_DIR / "player_profile.json"


class ProfileManager:
    """Manages persistent player stats and vocabulary mastery across game sessions."""

    def __init__(self, profile_path: Optional[Path] = None) -> None:
        self.profile_path = profile_path or PROFILE_PATH
        self.profile: PlayerProfile = self.load_profile()

    def load_profile(self) -> PlayerProfile:
        """Loads profile from JSON or creates a new empty one."""
        if self.profile_path.exists():
            try:
                with open(self.profile_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return PlayerProfile.model_validate(data)
            except Exception:
                pass
        return PlayerProfile()

    def save_profile(self) -> None:
        """Saves current player profile to JSON."""
        try:
            self.profile_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.profile_path, "w", encoding="utf-8") as f:
                f.write(self.profile.model_dump_json(indent=2))
        except Exception:
            pass

    def record_completed_session(
        self, game_state: GameState, telemetry: SessionTelemetry
    ) -> None:
        """Updates lifetime stats and vocabulary mastery after game finishes or user gives up."""
        self.profile.total_games_played += 1
        if game_state.status == GameStatus.WON:
            self.profile.total_games_won += 1

        self.profile.total_words_found += len(game_state.found_words)
        self.profile.total_play_time_seconds += telemetry.active_elapsed_seconds

        # Update best velocity
        vel = telemetry.current_velocity
        if vel > 0:
            if self.profile.best_velocity_spw == 0.0 or vel < self.profile.best_velocity_spw:
                self.profile.best_velocity_spw = vel

        # Update vocabulary mastery for all words in the puzzle
        lang = game_state.puzzle.metadata.language
        avg_word_time = vel if vel > 0 else (telemetry.active_elapsed_seconds / max(1, len(game_state.puzzle.words)))

        for word in game_state.puzzle.words:
            err_count = telemetry.error_clicks_per_word.get(word.word, 0)
            MasteryTracker.update_word_progress(
                self.profile,
                word,
                solve_time_seconds=avg_word_time,
                error_clicks=err_count,
                language=lang,
            )

        self.save_profile()


# Global singleton instance
profile_manager = ProfileManager()
