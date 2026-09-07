"""Unit tests for Vocabulary Mastery, Spaced Learning, and Review Deck."""
import pytest
from core.enums import HintTier, MasteryLevel
from core.models import PlayerProfile, WordEntry
from learning.adaptive_recommender import AdaptiveRecommender
from learning.mastery_tracker import MasteryTracker
from learning.vocabulary_deck import VocabularyDeckManager


def test_mastery_classification():
    profile = PlayerProfile()
    word_fast = WordEntry(word="FAST", clue="High speed", found=True)

    # Solve fast 2 times -> MASTERED
    MasteryTracker.update_word_progress(profile, word_fast, solve_time_seconds=5.0, language="en")
    rec = MasteryTracker.update_word_progress(profile, word_fast, solve_time_seconds=6.0, language="en")
    assert rec.mastery_level == MasteryLevel.MASTERED

    # Word needing practice (slow and heavy hints)
    word_hard = WordEntry(word="DIFFICULT", clue="Hard concept", found=True, hint_tier_used=HintTier.TIER_5_START_COORDINATE)
    rec2 = MasteryTracker.update_word_progress(profile, word_hard, solve_time_seconds=60.0, language="en")
    assert rec2.mastery_level == MasteryLevel.NEEDS_PRACTICE


def test_vocabulary_deck_filtering():
    profile = PlayerProfile()
    w1 = WordEntry(word="GALAXY", clue="Star system", found=True)
    w2 = WordEntry(word="NEBULA", clue="Dust cloud", found=True, hint_tier_used=HintTier.TIER_6_FULL_GLOW)

    MasteryTracker.update_word_progress(profile, w1, solve_time_seconds=5.0, language="en")
    MasteryTracker.update_word_progress(profile, w1, solve_time_seconds=5.0, language="en")
    MasteryTracker.update_word_progress(profile, w2, solve_time_seconds=70.0, language="en")

    mastered = VocabularyDeckManager.filter_words(profile, mastery_level=MasteryLevel.MASTERED)
    assert len(mastered) == 1
    assert mastered[0].word == "GALAXY"

    needs_prac = VocabularyDeckManager.filter_words(profile, mastery_level=MasteryLevel.NEEDS_PRACTICE)
    assert len(needs_prac) == 1
    assert needs_prac[0].word == "NEBULA"


def test_adaptive_recommender():
    profile = PlayerProfile()
    w_hard = WordEntry(word="HARDWORD", clue="Hard clue", found=True, hint_tier_used=HintTier.TIER_5_START_COORDINATE)
    MasteryTracker.update_word_progress(profile, w_hard, solve_time_seconds=90.0, language="en")

    review_list = AdaptiveRecommender.get_review_words(profile, language="en", target_count=5)
    assert len(review_list) >= 1
    assert review_list[0]["word"] == "HARDWORD"
