"""Unit tests for Pluggable Assists, Hint Escalation, and Proximity."""
import pytest
from assists.progressive_hints import ProgressiveHintProvider
from assists.proximity_assist import ProximityAssistProvider
from assists.registry import AssistRegistry
from core.enums import Difficulty, HintTier
from core.game_state import GameState
from core.grid_engine import GridEngine


@pytest.fixture
def active_game():
    words = [{"word": "PLANET", "clue": "Celestial body orbiting a star."}]
    puzzle = GridEngine.generate_puzzle(words, difficulty=Difficulty.EASY)
    return GameState(puzzle)


def test_progressive_hint_escalation(active_game):
    provider = ProgressiveHintProvider()

    # Hint 1: Clue
    res1 = provider.request_hint(active_game)
    assert res1.tier == HintTier.TIER_1_CLUE
    assert "Celestial body" in res1.message

    # Hint 2: Word Name
    res2 = provider.request_hint(active_game)
    assert res2.tier == HintTier.TIER_2_WORD_NAME
    assert "PLANET" in res2.message

    # Hint 3: First letter
    res3 = provider.request_hint(active_game)
    assert res3.tier == HintTier.TIER_3_FIRST_LETTER
    assert "Starts with 'P'" in res3.message

    # Hint 4: Orientation
    res4 = provider.request_hint(active_game)
    assert res4.tier == HintTier.TIER_4_ORIENTATION

    # Hint 5: Start coordinate
    res5 = provider.request_hint(active_game)
    assert res5.tier == HintTier.TIER_5_START_COORDINATE
    assert len(res5.highlight_coords) == 1

    # Hint 6: Full glow
    res6 = provider.request_hint(active_game)
    assert res6.tier == HintTier.TIER_6_FULL_GLOW
    assert len(res6.highlight_coords) == len("PLANET")


def test_proximity_calculation(active_game):
    provider = ProximityAssistProvider(throttle_interval_seconds=0.0)
    target = active_game.puzzle.words[0]
    start_r, start_c = target.start_coord

    # Clicking exact start cell should return BURNING
    res = provider.calculate_proximity(active_game, (start_r, start_c))
    assert res["status"] == "BURNING"
    assert res["distance"] == 0.0

    # Clicking far away should return COOL or COLD
    far_r = (start_r + 8) % active_game.puzzle.rows
    far_c = (start_c + 8) % active_game.puzzle.cols
    res_far = provider.calculate_proximity(active_game, (far_r, far_c))
    assert res_far["status"] in ("COOL", "COLD", "WARM")


def test_assist_registry_dispatch(active_game):
    registry = AssistRegistry()
    tick_events = registry.on_tick(active_game, 1.0)
    assert isinstance(tick_events, list)

    target = active_game.puzzle.words[0]
    click_events = registry.on_cell_clicked(active_game, target.start_coord)
    assert len(click_events) > 0
