"""Unit tests for the Grid Engine, Placement, and Unicode/CJK Scripts."""
import pytest
from core.enums import Difficulty, Direction, ScriptType
from core.grid_engine import GridEngine, calculate_optimal_dimensions, get_allowed_directions
from core.scripts import detect_script, get_character_pool


def test_allowed_directions():
    easy_dirs = get_allowed_directions(Difficulty.EASY)
    assert Direction.HORIZONTAL_LR in easy_dirs
    assert Direction.VERTICAL_TB in easy_dirs
    assert Direction.HORIZONTAL_RL not in easy_dirs

    med_dirs = get_allowed_directions(Difficulty.MEDIUM)
    assert Direction.DIAGONAL_TL_BR in med_dirs
    assert Direction.HORIZONTAL_RL not in med_dirs

    hard_dirs = get_allowed_directions(Difficulty.HARD)
    assert len(hard_dirs) == 8


def test_script_detection():
    assert detect_script(["HELLO", "WORLD"]) == ScriptType.LATIN
    assert detect_script(["MONTAÑA", "VOLCÁN", "PINGÜINO"]) == ScriptType.LATIN_ACCENTED
    assert detect_script(["ありがとう", "さくら", "やま"]) == ScriptType.HIRAGANA
    assert detect_script(["コンピューター", "テスト"]) == ScriptType.KATAKANA
    assert detect_script(["日月", "学校", "先生"]) == ScriptType.KANJI


def test_english_puzzle_generation():
    words = [
        {"word": "PYTHON", "clue": "A popular programming language."},
        {"word": "SEARCH", "clue": "To find something."},
        {"word": "GAME", "clue": "An activity for fun."},
    ]
    puzzle = GridEngine.generate_puzzle(
        words_data=words,
        title="Coding Test",
        theme="Programming",
        difficulty=Difficulty.EASY,
    )

    assert puzzle.rows >= 8
    assert puzzle.cols >= 8
    assert len(puzzle.words) == 3
    assert all(len(w.coords) == len(w.word) for w in puzzle.words)

    # Verify grid contains the word characters at placed coords
    for w in puzzle.words:
        chars_on_grid = "".join(puzzle.grid[r][c] for r, c in w.coords)
        assert chars_on_grid == w.word


def test_spanish_accented_puzzle_generation():
    words = [
        {"word": "VOLCÁN", "clue": "Estructura geológica."},
        {"word": "PINGÜINO", "clue": "Ave marina polar."},
        {"word": "MONTAÑA", "clue": "Elevación de terreno."},
    ]
    puzzle = GridEngine.generate_puzzle(
        words_data=words,
        title="Español Test",
        theme="Naturaleza",
        difficulty=Difficulty.MEDIUM,
        script_type=ScriptType.LATIN_ACCENTED,
    )

    assert puzzle.metadata.script_type == ScriptType.LATIN_ACCENTED
    assert len(puzzle.words) == 3
    for w in puzzle.words:
        chars_on_grid = "".join(puzzle.grid[r][c] for r, c in w.coords)
        assert chars_on_grid == w.word


def test_japanese_hiragana_puzzle_generation():
    words = [
        {"word": "ありがとう", "clue": "Thank you", "reading": "arigatou"},
        {"word": "さくら", "clue": "Cherry blossom", "reading": "sakura"},
        {"word": "せんせい", "clue": "Teacher", "reading": "sensei"},
    ]
    puzzle = GridEngine.generate_puzzle(
        words_data=words,
        title="Japanese Test",
        theme="Greetings",
        difficulty=Difficulty.EASY,
        script_type=ScriptType.HIRAGANA,
    )

    assert puzzle.metadata.script_type == ScriptType.HIRAGANA
    assert len(puzzle.words) == 3
    for w in puzzle.words:
        chars_on_grid = "".join(puzzle.grid[r][c] for r, c in w.coords)
        assert chars_on_grid == w.word


def test_dynamic_distractor_shift():
    words = [{"word": "ALPHA", "clue": "First letter"}]
    puzzle = GridEngine.generate_puzzle(words, difficulty=Difficulty.DYNAMIC)

    word_coords = set(puzzle.words[0].coords)
    initial_word_chars = [puzzle.grid[r][c] for r, c in word_coords]

    # Shift distractor cells
    GridEngine.shift_distractor_cells(puzzle)

    # Word characters must remain intact!
    new_word_chars = [puzzle.grid[r][c] for r, c in word_coords]
    assert initial_word_chars == new_word_chars
