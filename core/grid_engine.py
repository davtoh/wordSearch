"""Grid Placement Engine for Multilingual Word Search Puzzles."""
from __future__ import annotations

import math
import random
from typing import Any, Dict, List, Optional, Set, Tuple
from config.settings import settings

from core.enums import Difficulty, Direction, ScriptType
from core.models import AssistConfig, Puzzle, PuzzleMetadata, WordEntry
from core.scripts import (
    detect_script,
    get_character_pool,
    normalize_word_for_puzzle,
    random_filler_char,
)


def get_allowed_directions(difficulty: Difficulty) -> List[Direction]:
    """Returns allowed placement directions based on difficulty preset."""
    if difficulty == Difficulty.EASY:
        return [Direction.HORIZONTAL_LR, Direction.VERTICAL_TB]
    elif difficulty == Difficulty.MEDIUM:
        return [
            Direction.HORIZONTAL_LR,
            Direction.VERTICAL_TB,
            Direction.DIAGONAL_TL_BR,
            Direction.DIAGONAL_BL_TR,
        ]
    else:  # HARD, EXPERT, DYNAMIC
        return list(Direction)


def calculate_optimal_dimensions(
    words: List[str],
    difficulty: Difficulty,
    target_density: float = 0.65,
    custom_size: Optional[Tuple[int, int]] = None,
) -> Tuple[int, int]:
    """Calculates optimal grid (rows, cols) based on word lengths, count, and density."""
    if custom_size:
        return custom_size

    if not words:
        return (10, 10)

    max_len = max(len(w) for w in words)
    total_chars = sum(len(w) for w in words)

    # Minimum dimension must fit the longest word with at least 1-2 buffer cells
    min_dim = max(max_len + 2, 8)

    # Estimate required area based on fill density (e.g. 60-70% letters)
    estimated_area = total_chars / max(0.2, min(0.9, target_density))
    side = max(min_dim, math.ceil(math.sqrt(estimated_area)))

    # Difficulty buffer: Easy boards are slightly more spacious; Expert boards are compact
    if difficulty == Difficulty.EASY:
        side = max(side, max_len + 3)
    elif difficulty == Difficulty.EXPERT:
        side = max(min_dim, math.ceil(math.sqrt(total_chars / 0.85)))

    # Clamp dimensions between 8x8 and 30x30 for mobile/desktop usability
    side = max(8, min(30, side))
    return (side, side)


class GridEngine:
    """Core algorithm for placing words and generating multilingual word search boards."""

    @classmethod
    def generate_puzzle(
        cls,
        words_data: List[Dict[str, Any]],
        title: str = "Word Search",
        theme: str = "General",
        language: str = settings.get("default_language", "en"),
        difficulty: Difficulty = Difficulty.EASY,
        custom_dimensions: Optional[Tuple[int, int]] = None,
        script_type: Optional[ScriptType] = None,
        assist_config: Optional[AssistConfig] = None,
        max_retries: int = 50,
    ) -> Puzzle:
        """Generates a complete Puzzle object with placed words and script-aware fillers."""
        raw_words = [item.get("word", "") for item in words_data if item.get("word")]
        detected_script = script_type or detect_script(raw_words)

        # Normalize words
        normalized_entries: List[WordEntry] = []
        for item in words_data:
            w_raw = item.get("word", "").strip()
            if not w_raw:
                continue
            w_norm = normalize_word_for_puzzle(w_raw, detected_script)
            normalized_entries.append(
                WordEntry(
                    word=w_norm,
                    clue=item.get("clue"),
                    reading=item.get("reading"),
                )
            )

        # Remove duplicate words while preserving order
        unique_entries: List[WordEntry] = []
        seen_words: Set[str] = set()
        for entry in normalized_entries:
            if entry.word not in seen_words and len(entry.word) >= 2:
                seen_words.add(entry.word)
                unique_entries.append(entry)

        if not unique_entries:
            raise ValueError("No valid words provided for puzzle generation.")

        # Determine dimensions and directions
        cfg = assist_config or AssistConfig()
        rows, cols = calculate_optimal_dimensions(
            [e.word for e in unique_entries],
            difficulty,
            target_density=cfg.density_target,
            custom_size=custom_dimensions,
        )
        allowed_dirs = get_allowed_directions(difficulty)

        # Try generating board
        for attempt in range(max_retries):
            grid, placed_words = cls._try_place_all(
                unique_entries, rows, cols, allowed_dirs, detected_script
            )
            if len(placed_words) == len(unique_entries):
                # Successfully placed all words! Fill remaining empty cells
                cls._fill_empty_cells(grid, detected_script)
                metadata = PuzzleMetadata(
                    title=title,
                    theme=theme,
                    language=language,
                    script_type=detected_script,
                    difficulty=difficulty,
                )
                return Puzzle(
                    metadata=metadata,
                    rows=rows,
                    cols=cols,
                    grid=grid,
                    words=placed_words,
                    allowed_directions=allowed_dirs,
                    assist_config=cfg,
                )
            # If board was too tight, increase dimension slightly on later retries
            if attempt > max_retries // 2:
                rows += 1
                cols += 1

        # Fallback: place as many as possible
        grid, placed_words = cls._try_place_all(
            unique_entries, rows, cols, allowed_dirs, detected_script
        )
        cls._fill_empty_cells(grid, detected_script)
        metadata = PuzzleMetadata(
            title=title,
            theme=theme,
            language=language,
            script_type=detected_script,
            difficulty=difficulty,
        )
        return Puzzle(
            metadata=metadata,
            rows=rows,
            cols=cols,
            grid=grid,
            words=placed_words,
            allowed_directions=allowed_dirs,
            assist_config=cfg,
        )

    @classmethod
    def _try_place_all(
        cls,
        entries: List[WordEntry],
        rows: int,
        cols: int,
        allowed_dirs: List[Direction],
        script: ScriptType,
    ) -> Tuple[List[List[str]], List[WordEntry]]:
        grid: List[List[str]] = [["" for _ in range(cols)] for _ in range(rows)]
        placed: List[WordEntry] = []

        # Sort entries longest first for easier placement
        sorted_entries = sorted(entries, key=lambda e: len(e.word), reverse=True)

        for entry in sorted_entries:
            success, coords, direction = cls._place_word(grid, entry.word, rows, cols, allowed_dirs)
            if success:
                new_entry = entry.model_copy()
                new_entry.coords = coords
                new_entry.direction = direction
                placed.append(new_entry)

        return grid, placed

    @classmethod
    def _place_word(
        cls,
        grid: List[List[str]],
        word: str,
        rows: int,
        cols: int,
        allowed_dirs: List[Direction],
        max_attempts_per_word: int = 150,
    ) -> Tuple[bool, List[Tuple[int, int]], Optional[Direction]]:
        word_chars = list(word)
        w_len = len(word_chars)

        # Generate list of random candidate start locations and directions
        start_candidates = [
            (r, c) for r in range(rows) for c in range(cols)
        ]
        random.shuffle(start_candidates)

        for r, c in start_candidates:
            shuffled_dirs = allowed_dirs.copy()
            random.shuffle(shuffled_dirs)

            for d in shuffled_dirs:
                dr, dc = d.delta
                end_r = r + (w_len - 1) * dr
                end_c = c + (w_len - 1) * dc

                if 0 <= end_r < rows and 0 <= end_c < cols:
                    # Check if word fits without conflicting with existing letters
                    can_place = True
                    coords: List[Tuple[int, int]] = []

                    for i, char in enumerate(word_chars):
                        curr_r = r + i * dr
                        curr_c = c + i * dc
                        cell_val = grid[curr_r][curr_c]

                        if cell_val != "" and cell_val != char:
                            can_place = False
                            break
                        coords.append((curr_r, curr_c))

                    if can_place:
                        # Write characters to grid
                        for (cr, cc), char in zip(coords, word_chars):
                            grid[cr][cc] = char
                        return True, coords, d

        return False, [], None

    @classmethod
    def _fill_empty_cells(cls, grid: List[List[str]], script: ScriptType) -> None:
        rows = len(grid)
        cols = len(grid[0]) if rows > 0 else 0
        pool = get_character_pool(script)

        for r in range(rows):
            for c in range(cols):
                if grid[r][c] == "":
                    grid[r][c] = random.choice(pool)

    @classmethod
    def shift_distractor_cells(cls, puzzle: Puzzle) -> None:
        """Dynamic Mode: Safely shuffles non-word filler letters to create subtle dynamic shifting."""
        protected_coords: Set[Tuple[int, int]] = set()
        for w in puzzle.words:
            for coord in w.coords:
                protected_coords.add(coord)

        rows = puzzle.rows
        cols = puzzle.cols
        pool = get_character_pool(puzzle.metadata.script_type)

        for r in range(rows):
            for c in range(cols):
                if (r, c) not in protected_coords:
                    # 30% chance to re-randomize this distractor cell
                    if random.random() < 0.30:
                        puzzle.grid[r][c] = random.choice(pool)
