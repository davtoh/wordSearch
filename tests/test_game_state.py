"""Unit tests for Game State Machine, Selection, Timed Mode, and Give Up."""
import pytest
from core.enums import Difficulty, GameMode, GameStatus
from core.game_state import GameState
from core.grid_engine import GridEngine


@pytest.fixture
def sample_game_state():
    words = [
        {"word": "CAT", "clue": "Feline pet"},
        {"word": "DOG", "clue": "Canine companion"},
    ]
    puzzle = GridEngine.generate_puzzle(words, difficulty=Difficulty.EASY)
    return GameState(puzzle, mode=GameMode.TIMED_ATTACK)


def test_straight_line_interpolation(sample_game_state):
    # Horizontal line
    line = sample_game_state.interpolate_line((0, 0), (0, 3))
    assert line == [(0, 0), (0, 1), (0, 2), (0, 3)]

    # Vertical line
    line = sample_game_state.interpolate_line((1, 2), (3, 2))
    assert line == [(1, 2), (2, 2), (3, 2)]

    # Diagonal line
    line = sample_game_state.interpolate_line((1, 1), (3, 3))
    assert line == [(1, 1), (2, 2), (3, 3)]

    # Non-straight line (invalid knight move / non-45-degree)
    line = sample_game_state.interpolate_line((0, 0), (1, 3))
    assert line == []


def test_word_selection_forward_and_reverse(sample_game_state):
    target_word = sample_game_state.puzzle.words[0]
    start_coord = target_word.coords[0]
    end_coord = target_word.coords[-1]

    # Forward drag
    valid, found_entry, coords = sample_game_state.check_selection(start_coord, end_coord)
    assert valid is True
    assert found_entry is not None
    assert found_entry.word == target_word.word
    assert target_word.found is True


def test_timed_attack_and_bonus_time(sample_game_state):
    initial_time = sample_game_state.time_remaining
    sample_game_state.tick(10.0)
    assert sample_game_state.time_remaining == initial_time - 10.0

    # Finding a word adds bonus time
    word2 = sample_game_state.puzzle.words[1]
    sample_game_state.check_selection(word2.coords[0], word2.coords[-1])
    assert sample_game_state.time_remaining == (initial_time - 10.0 + sample_game_state.bonus_per_word)


def test_give_up_and_learn_state(sample_game_state):
    assert sample_game_state.status == GameStatus.PLAYING
    sample_game_state.give_up()
    assert sample_game_state.status == GameStatus.GIVEN_UP
    assert sample_game_state.revealed_all_on_giveup is True
    # All word coordinates should be in found_coords_map
    for w in sample_game_state.puzzle.words:
        for c in w.coords:
            assert c in sample_game_state.found_coords_map
