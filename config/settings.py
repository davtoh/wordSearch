"""Settings and Configuration Manager for the Word Search Game."""
from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, Optional

from core.enums import Difficulty, GameMode, ThemeMode

CONFIG_DIR = Path(__file__).parent
DEFAULT_CONFIG_PATH = CONFIG_DIR / "default_config.json"
DIFFICULTY_PRESETS_PATH = CONFIG_DIR / "difficulty_presets.json"
USER_CONFIG_PATH = CONFIG_DIR / "user_config.json"


class Settings:
    """Manages application settings with persistent JSON storage."""

    def __init__(self, config_path: Optional[Path] = None) -> None:
        self.config_path = config_path or USER_CONFIG_PATH
        self._config: Dict[str, Any] = self._load_default_config()
        self._difficulty_presets: Dict[str, Any] = self._load_presets()
        self.load()

    def _load_default_config(self) -> Dict[str, Any]:
        if DEFAULT_CONFIG_PATH.exists():
            try:
                with open(DEFAULT_CONFIG_PATH, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
        return {
            "theme": ThemeMode.DARK,
            "default_language": "en",
            "default_difficulty": Difficulty.EASY,
            "gemini_model": os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite"),
            "concept_first_mode": False,
            "game_mode": GameMode.CASUAL,
            "timed_attack_seconds": 240,
            "sound_enabled": True,
            "proximity_assist_enabled": True,
            "auto_stall_hint_seconds": 45.0,
            "mastery_needs_practice_threshold": 45.0,
            "font_size": 16, # TODO: Make this dynamic based on screen size and user preference
            "ui_scale": 1.05,
            "screen_width": 1024,
            "screen_height": 720,
            "fps": 60,
        }

    def _load_presets(self) -> Dict[str, Any]:
        if DIFFICULTY_PRESETS_PATH.exists():
            try:
                with open(DIFFICULTY_PRESETS_PATH, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
        return {}

    def load(self) -> None:
        """Loads user overrides if they exist."""
        if self.config_path.exists():
            try:
                with open(self.config_path, "r", encoding="utf-8") as f:
                    user_cfg = json.load(f)
                    self._config.update(user_cfg)
            except Exception:
                pass

    def save(self) -> None:
        """Persists current configuration to user_config.json."""
        try:
            tmp_path = self.config_path.with_suffix('.tmp.json')
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(self._config, f, indent=2, ensure_ascii=False)
            os.replace(tmp_path, self.config_path)
        except Exception:
            pass

    def get(self, key: str, default: Any = None) -> Any:
        return self._config.get(key, default)

    def set(self, key: str, value: Any, auto_save: bool = True) -> None:
        self._config[key] = value
        if auto_save:
            self.save()

    def get_difficulty_preset(self, difficulty: str) -> Dict[str, Any]:
        diff_lower = difficulty.lower()
        if diff_lower in self._difficulty_presets:
            return self._difficulty_presets[diff_lower]
        return self._difficulty_presets.get("easy", {})

    @property
    def all_presets(self) -> Dict[str, Any]:
        return self._difficulty_presets

    @property
    def as_dict(self) -> Dict[str, Any]:
        return self._config.copy()


# Global singleton settings instance
settings = Settings()
