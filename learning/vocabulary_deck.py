"""Searchable and Filterable Vocabulary Deck."""
from __future__ import annotations

from typing import List, Optional

from core.enums import MasteryLevel
from core.models import PlayerProfile, WordMasteryRecord


class VocabularyDeckManager:
    """Provides querying and filtering over the player's saved vocabulary records."""

    @staticmethod
    def filter_words(
        profile: PlayerProfile,
        language: Optional[str] = None,
        mastery_level: Optional[MasteryLevel] = None,
        search_query: Optional[str] = None,
    ) -> List[WordMasteryRecord]:
        """Filters player vocabulary records by language, level, and text query."""
        results = list(profile.vocabulary_deck.values())

        if language:
            results = [r for r in results if r.language.lower() == language.lower()]

        if mastery_level:
            results = [r for r in results if r.mastery_level == mastery_level]

        if search_query:
            q = search_query.lower().strip()
            results = [
                r for r in results
                if q in r.word.lower()
                or (r.clue and q in r.clue.lower())
                or (r.reading and q in r.reading.lower())
            ]

        # Sort by most recently encountered
        results.sort(key=lambda r: r.last_encountered_at, reverse=True)
        return results

    @staticmethod
    def get_summary_stats(profile: PlayerProfile, language: Optional[str] = None) -> dict:
        words = list(profile.vocabulary_deck.values())
        if language:
            words = [w for w in words if w.language == language]

        total = len(words)
        mastered = sum(1 for w in words if w.mastery_level == MasteryLevel.MASTERED)
        learning = sum(1 for w in words if w.mastery_level == MasteryLevel.LEARNING)
        needs_practice = sum(1 for w in words if w.mastery_level == MasteryLevel.NEEDS_PRACTICE)

        return {
            "total_words": total,
            "mastered": mastered,
            "learning": learning,
            "needs_practice": needs_practice,
            "mastery_rate": round((mastered / max(1, total)) * 100, 1),
        }
