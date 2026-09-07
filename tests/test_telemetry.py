"""Unit tests for Focus-Aware Telemetry and Metrics."""
import pytest
from core.models import WordEntry
from telemetry.tracker import SessionTelemetry


def test_focus_aware_time_tracking():
    tel = SessionTelemetry()
    tel.on_tick(5.0)
    assert tel.active_elapsed_seconds == 5.0

    # User leaves app (focus lost)
    tel.on_focus_lost()
    tel.on_tick(5.0)
    assert tel.active_elapsed_seconds == 5.0  # Must not accumulate time!

    # User returns
    tel.on_focus_gained()
    tel.on_tick(2.0)
    assert tel.active_elapsed_seconds == 7.0


def test_velocity_and_accuracy():
    tel = SessionTelemetry()
    tel.on_tick(10.0)

    # 1 invalid selection attempt
    tel.record_selection_attempt(is_valid=False)

    # 1 valid selection and word found
    tel.record_selection_attempt(is_valid=True)
    word = WordEntry(word="TEST", clue="A test word")
    tel.record_word_found(word)

    assert tel.accuracy_rate == 50.0
    assert tel.current_velocity == 10.0
