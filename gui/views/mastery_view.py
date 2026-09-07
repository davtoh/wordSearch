"""Vocabulary Mastery and Study Deck Screen."""
from __future__ import annotations

from typing import Callable, List, Optional

import pygame

from core.enums import MasteryLevel
from core.models import PlayerProfile, WordMasteryRecord
from gui.font_manager import font_manager
from gui.theme import theme
from gui.widgets.button import Button
from learning.vocabulary_deck import VocabularyDeckManager


class MasteryView:
    """Allows players to browse lifetime learned vocabulary, inspect progress, and trigger review puzzles."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 0)
        self.btn_back = Button((0, 0, 120, 38), "← Back", is_secondary=True)
        self.btn_practice = Button((0, 0, 200, 38), "🎯 Practice Difficult Words")

        self.btn_filter_all = Button((0, 0, 100, 32), "All", is_secondary=False)
        self.btn_filter_mastered = Button((0, 0, 130, 32), "🌟 Mastered", is_secondary=True)
        self.btn_filter_learning = Button((0, 0, 120, 32), "📖 Learning", is_secondary=True)
        self.btn_filter_practice = Button((0, 0, 150, 32), "⚠️ Needs Practice", is_secondary=True)

        self.active_filter: Optional[MasteryLevel] = None
        self.scroll_y = 0

        self.on_practice_requested: Optional[Callable[[], None]] = None

    def update_layout(self, container_rect: pygame.Rect) -> None:
        self.rect = container_rect
        self.btn_back.rect = pygame.Rect(24, 20, 110, 38)
        self.btn_practice.rect = pygame.Rect(container_rect.width - 234, 20, 210, 38)

        # Filters
        fy = 75
        self.btn_filter_all.rect = pygame.Rect(24, fy, 90, 32)
        self.btn_filter_mastered.rect = pygame.Rect(122, fy, 130, 32)
        self.btn_filter_learning.rect = pygame.Rect(260, fy, 120, 32)
        self.btn_filter_practice.rect = pygame.Rect(388, fy, 160, 32)

    def handle_event(self, event: pygame.event.Event) -> bool:
        if self.btn_back.handle_event(event):
            return True
        if self.btn_practice.handle_event(event):
            if self.on_practice_requested:
                self.on_practice_requested()
            return True

        if self.btn_filter_all.handle_event(event):
            self.active_filter = None
            self._update_filter_buttons()
            return True
        if self.btn_filter_mastered.handle_event(event):
            self.active_filter = MasteryLevel.MASTERED
            self._update_filter_buttons()
            return True
        if self.btn_filter_learning.handle_event(event):
            self.active_filter = MasteryLevel.LEARNING
            self._update_filter_buttons()
            return True
        if self.btn_filter_practice.handle_event(event):
            self.active_filter = MasteryLevel.NEEDS_PRACTICE
            self._update_filter_buttons()
            return True

        if event.type == pygame.MOUSEWHEEL:
            self.scroll_y = max(0, self.scroll_y - event.y * 25)
            return True

        return False

    def _update_filter_buttons(self) -> None:
        self.btn_filter_all.is_secondary = (self.active_filter is not None)
        self.btn_filter_mastered.is_secondary = (self.active_filter != MasteryLevel.MASTERED)
        self.btn_filter_learning.is_secondary = (self.active_filter != MasteryLevel.LEARNING)
        self.btn_filter_practice.is_secondary = (self.active_filter != MasteryLevel.NEEDS_PRACTICE)

    def draw(self, surface: pygame.Surface, profile: PlayerProfile) -> None:
        pygame.draw.rect(surface, theme.bg, self.rect)

        # Header Title
        font_manager.draw_text(
            surface,
            "📚 Vocabulary Study Deck & Mastery",
            (self.rect.centerx, 38),
            24,
            theme.text_primary,
            bold=True,
            align="center",
        )

        # Draw Controls
        self.btn_back.draw(surface)
        self.btn_practice.draw(surface)

        self.btn_filter_all.draw(surface)
        self.btn_filter_mastered.draw(surface)
        self.btn_filter_learning.draw(surface)
        self.btn_filter_practice.draw(surface)

        # Filtered word list
        words = VocabularyDeckManager.filter_words(profile, mastery_level=self.active_filter)

        stats = VocabularyDeckManager.get_summary_stats(profile)
        stats_text = (
            f"Total Words: {stats['total_words']}  |  "
            f"Mastered: {stats['mastered']}  |  "
            f"Learning: {stats['learning']}  |  "
            f"Needs Practice: {stats['needs_practice']}"
        )
        font_manager.draw_text(
            surface,
            stats_text,
            (self.rect.width - 24, 88),
            14,
            theme.text_muted,
            align="topright",
        )

        # Render list of cards
        list_y = 125 - self.scroll_y
        card_w = self.rect.width - 48
        clip_rect = pygame.Rect(24, 120, card_w, self.rect.height - 140)
        surface.set_clip(clip_rect)

        if not words:
            font_manager.draw_text(
                surface,
                "No vocabulary records matching current filter.",
                (self.rect.centerx, 220),
                18,
                theme.text_muted,
                align="center",
            )
        else:
            for rec in words:
                if list_y + 70 < clip_rect.top or list_y > clip_rect.bottom:
                    list_y += 74
                    continue

                card = pygame.Rect(24, list_y, card_w, 66)
                pygame.draw.rect(surface, theme.card_bg, card, border_radius=8)

                if rec.mastery_level == MasteryLevel.MASTERED:
                    level_color = theme.success
                    badge_str = "🌟 MASTERED"
                elif rec.mastery_level == MasteryLevel.LEARNING:
                    level_color = theme.accent
                    badge_str = "📖 LEARNING"
                else:
                    level_color = theme.warning
                    badge_str = "⚠️ NEEDS PRACTICE"

                pygame.draw.rect(surface, theme.card_border, card, width=1, border_radius=8)

                # Word & Reading
                w_str = rec.word
                if rec.reading:
                    w_str += f"  [{rec.reading}]"

                font_manager.draw_text(
                    surface,
                    w_str,
                    (card.x + 14, card.y + 10),
                    17,
                    theme.text_primary,
                    bold=True,
                )

                # Clue / Meaning
                font_manager.draw_text(
                    surface,
                    rec.clue or "Vocabulary concept",
                    (card.x + 14, card.y + 36),
                    13,
                    theme.text_muted,
                )

                # Mastery Badge on right
                font_manager.draw_text(
                    surface,
                    badge_str,
                    (card.right - 16, card.y + 12),
                    14,
                    level_color,
                    bold=True,
                    align="topright",
                )

                # Stats info
                solve_info = f"Encountered: {rec.times_encountered}x  |  Avg: {rec.average_solve_time:.1f}s"
                font_manager.draw_text(
                    surface,
                    solve_info,
                    (card.right - 16, card.y + 36),
                    12,
                    theme.text_muted,
                    align="topright",
                )

                list_y += 74

        surface.set_clip(None)
