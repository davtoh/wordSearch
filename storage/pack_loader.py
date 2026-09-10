"""Puzzle Package Loader and Auto-Discovery."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional
from config.settings import settings

from core.enums import Difficulty, ScriptType
from core.grid_engine import GridEngine
from core.models import Puzzle

DATA_DIR = Path(__file__).parent.parent / "data"
DEFAULT_PACKS_DIR = DATA_DIR / "packs"
USER_PACKS_DIR = DATA_DIR / "user_packs"


class PuzzlePack:
    """Represents a collection of thematic word search puzzles."""

    def __init__(self, data: Dict[str, Any], filepath: Optional[Path] = None) -> None:
        self.raw_data = data
        self.filepath = filepath
        self.id: str = data.get("id", "pack_unknown")
        self.title: str = data.get("title", "Untitled Pack")
        self.description: str = data.get("description", "")
        self.language: str = data.get("language", settings.get("default_language", "en"))
        self.script_type: ScriptType = ScriptType(data.get("script_type", "latin"))
        self.puzzles_data: List[Dict[str, Any]] = data.get("puzzles", [])

    @property
    def puzzle_count(self) -> int:
        return len(self.puzzles_data)

    def get_puzzle(self, index: int = 0, difficulty: Optional[Difficulty] = None) -> Puzzle:
        """Instantiates and generates a Puzzle object from the specified index in the pack."""
        if not (0 <= index < len(self.puzzles_data)):
            raise IndexError(f"Puzzle index {index} out of range in pack '{self.title}'")

        p_info = self.puzzles_data[index]
        diff = difficulty or Difficulty(p_info.get("difficulty", "easy"))
        words_data = p_info.get("words", [])

        return GridEngine.generate_puzzle(
            words_data=words_data,
            title=p_info.get("title", self.title),
            theme=p_info.get("theme", self.title),
            language=self.language,
            difficulty=diff,
            script_type=self.script_type,
        )


class PackLoader:
    """Discovers, loads, and manages offline puzzle packages."""

    @staticmethod
    def load_pack_from_file(path: Path) -> Optional[PuzzlePack]:
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                return PuzzlePack(data, filepath=path)
        except Exception as e:
            print(f"Failed to load pack {path}: {e}")
            return None

    @classmethod
    def get_all_available_packs(cls) -> List[PuzzlePack]:
        """Scans data/packs/ and data/user_packs/ for all .pack.json files."""
        packs: List[PuzzlePack] = []
        directories = [DEFAULT_PACKS_DIR, USER_PACKS_DIR]

        for d in directories:
            if d.exists() and d.is_dir():
                for file_path in d.glob("*.pack.json"):
                    pack = cls.load_pack_from_file(file_path)
                    if pack:
                        packs.append(pack)

        # Sort packs by title
        packs.sort(key=lambda p: p.title)
        return packs
