"""Targeted Practice Recommender and Review Puzzle Generator."""
from __future__ import annotations

import random
from typing import Any, Dict, List
from config.settings import settings

from core.enums import MasteryLevel
from core.models import PlayerProfile


class AdaptiveRecommender:
    """Generates targeted review vocabulary lists composed of words the user found difficult."""

    @staticmethod
    def get_review_words(
        profile: PlayerProfile,
        language: str = settings.get("default_language", "en"),
        target_count: int = settings.get("default_vocabulary_count", 10),
    ) -> List[Dict[str, Any]]:
        """
        Selects candidate review words prioritizing NEEDS_PRACTICE, then LEARNING.
        Returns words formatted for grid generation.
        """
        all_words = [
            w for w in profile.vocabulary_deck.values()
            if w.language.lower() == language.lower()
        ]

        needs_practice = [w for w in all_words if w.mastery_level == MasteryLevel.NEEDS_PRACTICE]
        learning = [w for w in all_words if w.mastery_level == MasteryLevel.LEARNING]
        mastered = [w for w in all_words if w.mastery_level == MasteryLevel.MASTERED]

        # Shuffle each pool
        random.shuffle(needs_practice)
        random.shuffle(learning)
        random.shuffle(mastered)

        selected: List[Any] = []

        # 1. Fill with difficult words first
        selected.extend(needs_practice[:target_count])

        # 2. Fill remainder with learning words
        if len(selected) < target_count:
            remainder = target_count - len(selected)
            selected.extend(learning[:remainder])

        # 3. If still not enough, add random mastered words for reinforcement
        if len(selected) < target_count:
            remainder = target_count - len(selected)
            selected.extend(mastered[:remainder])

        return [
            {
                "word": record.word,
                "clue": record.clue or f"Review word: {record.word}",
                "reading": record.reading,
            }
            for record in selected
        ]
