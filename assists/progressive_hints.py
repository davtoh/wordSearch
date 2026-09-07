"""Progressive 6-Tier Modular Hint Provider."""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from assists.base import BaseAssistProvider
from core.enums import HintTier
from core.game_state import GameState
from core.models import AssistConfig, WordEntry


class ProgressiveHintResult:
    def __init__(
        self,
        word_entry: WordEntry,
        tier: HintTier,
        message: str,
        highlight_coords: List[Tuple[int, int]],
    ) -> None:
        self.word_entry = word_entry
        self.tier = tier
        self.message = message
        self.highlight_coords = highlight_coords

    def to_dict(self) -> Dict[str, Any]:
        return {
            "word": self.word_entry.word,
            "tier": int(self.tier),
            "tier_name": self.tier.name,
            "message": self.message,
            "highlight_coords": self.highlight_coords,
        }


class ProgressiveHintProvider(BaseAssistProvider):
    """Provides granular, step-by-step hints from clues to full word glow."""

    @property
    def name(self) -> str:
        return "progressive_hints"

    def is_enabled(self, config: AssistConfig) -> bool:
        return len(config.allowed_hint_tiers) > 0

    def request_hint(
        self, game_state: GameState, target_word_str: Optional[str] = None
    ) -> Optional[ProgressiveHintResult]:
        """
        Escalates or provides the next hint level for a target word, or picks the first unfound word.
        Respects puzzle assist_config.allowed_hint_tiers.
        """
        unfound_words = [w for w in game_state.puzzle.words if not w.found]
        if not unfound_words:
            return None

        # Select target word
        target: Optional[WordEntry] = None
        if target_word_str:
            for w in unfound_words:
                if w.word == target_word_str:
                    target = w
                    break
        if not target:
            target = unfound_words[0]

        allowed_tiers = sorted(game_state.puzzle.assist_config.allowed_hint_tiers)
        if not allowed_tiers:
            return None

        # Determine next allowed tier
        current_tier_int = int(target.hint_tier_used)
        next_tiers = [t for t in allowed_tiers if t > current_tier_int]

        if next_tiers:
            next_tier = HintTier(next_tiers[0])
        else:
            # Already at maximum allowed tier, return info for current tier
            next_tier = target.hint_tier_used if target.hint_tier_used != HintTier.NONE else HintTier(allowed_tiers[-1])

        target.hint_tier_used = next_tier

        # Generate hint payload
        msg = ""
        highlight_coords: List[Tuple[int, int]] = []

        if next_tier == HintTier.TIER_1_CLUE:
            msg = f"Clue: {target.clue or 'No clue available for this word.'}"

        elif next_tier == HintTier.TIER_2_WORD_NAME:
            msg = f"Word: '{target.word}' ({len(target.word)} letters)"
            if target.reading:
                msg += f" [Reading: {target.reading}]"

        elif next_tier == HintTier.TIER_3_FIRST_LETTER:
            first_char = target.word[0] if target.word else "?"
            msg = f"Starts with '{first_char}' ({len(target.word)} letters)"

        elif next_tier == HintTier.TIER_4_ORIENTATION:
            dir_name = target.direction.human_readable if target.direction else "Unknown"
            msg = f"Word '{target.word}' is placed {dir_name}"

        elif next_tier == HintTier.TIER_5_START_COORDINATE:
            if target.start_coord:
                r, c = target.start_coord
                highlight_coords = [(r, c)]
                msg = f"'{target.word}' starts at Row {r + 1}, Col {c + 1}"
                game_state.active_hint_coords = set(highlight_coords)
                game_state.active_hint_word = target

        elif next_tier == HintTier.TIER_6_FULL_GLOW:
            highlight_coords = list(target.coords)
            msg = f"Revealing path for '{target.word}'"
            game_state.active_hint_coords = set(highlight_coords)
            game_state.active_hint_word = target

        return ProgressiveHintResult(target, next_tier, msg, highlight_coords)
