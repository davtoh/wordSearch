"""Unit tests for JSON Package Discovery, Loading, and Export."""
import json
from pathlib import Path
import pytest
from core.enums import Difficulty
from storage.pack_exporter import PackExporter
from storage.pack_loader import PackLoader


def test_discover_and_load_bundled_packs():
    packs = PackLoader.get_all_available_packs()
    assert len(packs) >= 3

    pack_ids = [p.id for p in packs]
    assert "english_science" in pack_ids
    assert "spanish_general" in pack_ids
    assert "japanese_basics" in pack_ids

    # Generate a puzzle from English pack
    eng_pack = next(p for p in packs if p.id == "english_science")
    puzzle = eng_pack.get_puzzle(index=0, difficulty=Difficulty.EASY)
    assert puzzle.total_words > 0
    assert puzzle.rows >= 8


def test_export_and_import_roundtrip(tmp_path):
    sample_pack_id = "test_custom_pack"
    puzzles_data = [{
        "id": "p1",
        "title": "Custom Test Puzzle",
        "difficulty": "easy",
        "words": [{"word": "ALPHA", "clue": "First"}, {"word": "BETA", "clue": "Second"}]
    }]

    target_file = tmp_path / "custom.pack.json"
    exported_path = PackExporter.export_pack_to_json(
        pack_id=sample_pack_id,
        title="Custom Title",
        description="Testing pack export",
        language="en",
        script_type="latin",
        puzzles=puzzles_data,
        target_path=target_file,
    )
    assert exported_path is not None
    assert exported_path.exists()

    loaded_pack = PackLoader.load_pack_from_file(exported_path)
    assert loaded_pack is not None
    assert loaded_pack.title == "Custom Title"
    puzzle = loaded_pack.get_puzzle(0)
    assert puzzle.total_words == 2
