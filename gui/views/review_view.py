"""Give Up & Learn Mode: Educational Review Screen with Glossary and Solution Insights."""
from __future__ import annotations

from typing import Callable, Optional

import pygame

from core.enums import GameStatus
from core.game_state import GameState
from gui.font_manager import font_manager
from gui.theme import theme
from gui.widgets.button import Button
from telemetry.tracker import SessionTelemetry


class ReviewView:
    """Displays post-game educational review, concept glossary, and performance analytics."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 0)
        self.btn_next = Button((0, 0, 140, 42), "Next Puzzle")
        self.btn_menu = Button((0, 0, 140, 42), "Main Menu", is_secondary=True)
        self.btn_study = Button((0, 0, 140, 42), "Study Deck", is_secondary=True)
        self.scroll_y = 0

    def update_layout(self, container_rect: pygame.Rect) -> None:
        self.rect = container_rect
        center_x = container_rect.centerx
        bottom_y = container_rect.bottom - 60

        self.btn_next.rect = pygame.Rect(center_x + 80, bottom_y, 140, 42)
        self.btn_study.rect = pygame.Rect(center_x - 70, bottom_y, 140, 42)
        self.btn_menu.rect = pygame.Rect(center_x - 220, bottom_y, 140, 42)

    def handle_event(self, event: pygame.event.Event) -> bool:
        if self.btn_next.handle_event(event):
            return True
        if self.btn_study.handle_event(event):
            return True
        if self.btn_menu.handle_event(event):
            return True
        if event.type == pygame.MOUSEWHEEL:
            self.scroll_y = max(0, self.scroll_y - event.y * 25)
            return True
        return False

    def draw(
        self,
        surface: pygame.Surface,
        game_state: GameState,
        telemetry: SessionTelemetry,
    ) -> None:
        # Dim overlay
        dim_surf = pygame.Surface((self.rect.width, self.rect.height), pygame.SRCALPHA)
        dim_surf.fill((0, 0, 0, 180))
        surface.blit(dim_surf, (0, 0))

        # Main Card Modal
        modal_w = min(840, self.rect.width - 40)
        modal_h = min(620, self.rect.height - 40)
        modal_rect = pygame.Rect(
            (self.rect.width - modal_w) // 2,
            (self.rect.height - modal_h) // 2,
            modal_w,
            modal_h,
        )

        pygame.draw.rect(surface, theme.card_bg, modal_rect, border_radius=16)
        pygame.draw.rect(surface, theme.card_border, modal_rect, width=1, border_radius=16)

        # Title & Status
        is_won = (game_state.status == GameStatus.WON)
        title_text = "🎉 Puzzle Completed!" if is_won else "📚 Learning & Concept Review"
        title_color = theme.success if is_won else theme.accent

        font_manager.draw_text(
            surface,
            title_text,
            (modal_rect.centerx, modal_rect.y + 24),
            26,
            title_color,
            bold=True,
            align="center",
        )

        # Summary Stats Chips
        stats_y = modal_rect.y + 65
        stats_str = (
            f"⏱️ Time: {int(telemetry.active_elapsed_seconds)}s   |   "
            f"⚡ Velocity: {telemetry.current_velocity:.1f}s/word   |   "
            f"🎯 Accuracy: {int(telemetry.accuracy_rate)}%   |   "
            f"✓ Found: {len(game_state.found_words)}/{len(game_state.puzzle.words)}"
        )
        font_manager.draw_text(
            surface,
            stats_str,
            (modal_rect.centerx, stats_y),
            15,
            theme.text_secondary,
            align="center",
        )

        # Glossary List Subheader
        font_manager.draw_text(
            surface,
            "Vocabulary & Concept Breakdown:",
            (modal_rect.x + 28, stats_y + 35),
            18,
            theme.text_primary,
            bold=True,
        )

        # Render Word Glossary Cards
        list_y = stats_y + 65 - self.scroll_y
        card_w = modal_rect.width - 56

        clip_rect = pygame.Rect(modal_rect.x + 20, stats_y + 60, card_w + 16, modal_h - 200)
        surface.set_clip(clip_rect)

        for w in game_state.puzzle.words:
            if list_y + 70 < clip_rect.top or list_y > clip_rect.bottom:
                list_y += 76
                continue

            card = pygame.Rect(modal_rect.x + 28, list_y, card_w, 68)
            pygame.draw.rect(surface, theme.grid_cell_bg, card, border_radius=8)

            badge_color = theme.success if w.found else theme.warning
            pygame.draw.rect(surface, badge_color, card, width=1, border_radius=8)

            # Word Name + Reading
            w_str = f"{'✓' if w.found else '🔍'} {w.word}"
            if w.reading:
                w_str += f"  [{w.reading}]"

            font_manager.draw_text(
                surface,
                w_str,
                (card.x + 12, card.y + 8),
                16,
                badge_color,
                bold=True,
            )

            # Definition / Concept Clue
            clue = w.clue or "Concept definition"
            font_manager.draw_text(
                surface,
                clue,
                (card.x + 12, card.y + 34),
                13,
                theme.text_secondary,
            )

            list_y += 76

        surface.set_clip(None)

        # Action Buttons
        self.btn_menu.draw(surface)
        self.btn_study.draw(surface)
        self.btn_next.draw(surface)
