"""Vocabulary Mastery and Spaced Learning Classifier."""
from __future__ import annotations

from datetime import datetime, timezone
from config.settings import settings

from core.enums import HintTier, MasteryLevel
from core.models import PlayerProfile, WordEntry, WordMasteryRecord


class MasteryTracker:
    """Classifies vocabulary familiarity based on solve velocity, error rate, and hint dependency."""

    @staticmethod
    def update_word_progress(
        profile: PlayerProfile,
        word_entry: WordEntry,
        solve_time_seconds: float,
        error_clicks: int = 0,
        language: str = settings.get("default_language", "en"),
    ) -> WordMasteryRecord:
        """Updates or creates a vocabulary mastery record in the player's profile."""
        key = f"{language}:{word_entry.word.upper()}"
        record = profile.vocabulary_deck.get(key)

        if not record:
            record = WordMasteryRecord(
                word=word_entry.word,
                language=language,
                clue=word_entry.clue,
                reading=word_entry.reading,
            )
            profile.vocabulary_deck[key] = record

        # Update stats
        record.times_encountered += 1
        if word_entry.found:
            record.times_solved += 1
            record.total_solve_time_seconds += solve_time_seconds

        record.hint_tiers_history.append(int(word_entry.hint_tier_used))
        record.error_clicks += error_clicks
        record.last_encountered_at = datetime.now(timezone.utc).isoformat()

        # Classify mastery
        record.mastery_level = MasteryTracker.evaluate_mastery_level(record)
        return record

    @staticmethod
    def evaluate_mastery_level(record: WordMasteryRecord) -> MasteryLevel:
        """Determines if a word is MASTERED, LEARNING, or NEEDS_PRACTICE."""
        if record.times_solved == 0:
            return MasteryLevel.NEEDS_PRACTICE

        avg_time = record.average_solve_time
        max_hint = max(record.hint_tiers_history) if record.hint_tiers_history else 0

        # Mastered: solved at least twice, very fast (<=15s), minimal hints
        if record.times_solved >= 2 and avg_time <= 15.0 and max_hint <= int(HintTier.TIER_2_WORD_NAME):
            return MasteryLevel.MASTERED

        # Needs practice: slow (>45s) or required heavy hints (Tier 4+) or high errors
        if avg_time > settings.get("mastery_needs_practice_threshold", 45.0) or max_hint >= int(HintTier.TIER_4_ORIENTATION) or (record.error_clicks / record.times_encountered) >= 3:
            return MasteryLevel.NEEDS_PRACTICE

        return MasteryLevel.LEARNING
