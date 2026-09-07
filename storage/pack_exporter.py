"""Puzzle and Package JSON Exporter."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional

from core.models import Puzzle

DATA_DIR = Path(__file__).parent.parent / "data"
USER_PACKS_DIR = DATA_DIR / "user_packs"


class PackExporter:
    """Exports generated puzzles and user collections into standardized JSON files."""

    @staticmethod
    def export_puzzle_to_json(puzzle: Puzzle, target_path: Path) -> bool:
        """Exports a single completed Puzzle instance to a standalone .puzzle.json file."""
        try:
            target_path.parent.mkdir(parents=True, exist_ok=True)
            with open(target_path, "w", encoding="utf-8") as f:
                f.write(puzzle.model_dump_json(indent=2))
            return True
        except Exception as e:
            print(f"Failed to export puzzle: {e}")
            return False

    @staticmethod
    def export_pack_to_json(
        pack_id: str,
        title: str,
        description: str,
        language: str,
        script_type: str,
        puzzles: List[Dict[str, Any]],
        target_path: Optional[Path] = None,
    ) -> Optional[Path]:
        """Exports a puzzle package dictionary to a .pack.json file."""
        path = target_path or (USER_PACKS_DIR / f"{pack_id}.pack.json")
        payload = {
            "id": pack_id,
            "title": title,
            "description": description,
            "language": language,
            "script_type": script_type,
            "puzzles": puzzles,
        }

        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            with open(path, "w", encoding="utf-8") as f:
                json.dump(payload, f, indent=2, ensure_ascii=False)
            return path
        except Exception as e:
            print(f"Failed to export pack: {e}")
            return None
