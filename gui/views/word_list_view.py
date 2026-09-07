"""Word Bank and Concept Clue Drawer View."""
from __future__ import annotations

from typing import Callable, List, Optional, Tuple

import pygame

from core.game_state import GameState
from core.models import WordEntry
from gui.font_manager import font_manager
from gui.theme import theme


class WordListView:
    """Renders the word target bank, concept clues, and per-word hint buttons."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 0)
        self.concept_first_mode: bool = False
        self.on_word_hint_clicked: Optional[Callable[[WordEntry], None]] = None
        self.hint_button_rects: List[Tuple[pygame.Rect, WordEntry]] = []
        self.scroll_y: int = 0

    def update_layout(self, container_rect: pygame.Rect, concept_mode: bool = False) -> None:
        self.rect = container_rect
        self.concept_first_mode = concept_mode

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for btn_rect, word_entry in self.hint_button_rects:
                if btn_rect.collidepoint(event.pos):
                    if self.on_word_hint_clicked:
                        self.on_word_hint_clicked(word_entry)
                    return True
        elif event.type == pygame.MOUSEWHEEL:
            if self.rect.collidepoint(pygame.mouse.get_pos()):
                self.scroll_y = max(0, self.scroll_y - event.y * 20)
                return True
        return False

    def draw(self, surface: pygame.Surface, game_state: GameState) -> None:
        # Background card
        pygame.draw.rect(surface, theme.card_bg, self.rect, border_radius=12)
        pygame.draw.rect(surface, theme.card_border, self.rect, width=1, border_radius=12)

        # Header
        header_title = "Concepts to Find" if self.concept_first_mode else "Word Bank"
        count_str = f"({len(game_state.found_words)}/{len(game_state.puzzle.words)})"
        font_manager.draw_text(
            surface,
            f"{header_title} {count_str}",
            (self.rect.x + 16, self.rect.y + 16),
            18,
            theme.text_primary,
            bold=True,
        )

        self.hint_button_rects.clear()

        # Render list of word cards
        start_y = self.rect.y + 50 - self.scroll_y
        card_w = self.rect.width - 24
        y = start_y

        for idx, word_entry in enumerate(game_state.puzzle.words):
            if y + 60 > self.rect.bottom:
                break
            if y < self.rect.y + 45:
                y += 62
                continue

            card_rect = pygame.Rect(self.rect.x + 12, y, card_w, 56)

            # Card background
            if word_entry.found:
                fill_color = theme.grid_cell_bg
                border_color = theme.success
            else:
                fill_color = theme.grid_cell_bg
                border_color = theme.card_border

            pygame.draw.rect(surface, fill_color, card_rect, border_radius=8)
            pygame.draw.rect(surface, border_color, card_rect, width=1, border_radius=8)

            # Determine title text
            if word_entry.found:
                title_text = f"✓ {word_entry.word}"
                txt_color = theme.success
            elif self.concept_first_mode and int(word_entry.hint_tier_used) < 2:
                title_text = f"❓ Concept #{idx + 1} ({len(word_entry.word)} letters)"
                txt_color = theme.accent
            else:
                title_text = word_entry.word
                txt_color = theme.text_primary

            if word_entry.reading and (word_entry.found or int(word_entry.hint_tier_used) >= 2):
                title_text += f" [{word_entry.reading}]"

            font_manager.draw_text(
                surface,
                title_text,
                (card_rect.x + 10, card_rect.y + 8),
                16,
                txt_color,
                bold=True,
            )

            # Clue text
            clue_text = word_entry.clue or "Find this word in the puzzle"
            if len(clue_text) > 42:
                clue_text = clue_text[:40] + "..."

            font_manager.draw_text(
                surface,
                clue_text,
                (card_rect.x + 10, card_rect.y + 30),
                12,
                theme.text_muted,
            )

            # Hint button on the right side if unfound
            if not word_entry.found:
                hint_btn_rect = pygame.Rect(card_rect.right - 44, card_rect.y + 12, 34, 32)
                pygame.draw.rect(surface, theme.card_bg, hint_btn_rect, border_radius=6)
                pygame.draw.rect(surface, theme.card_border, hint_btn_rect, width=1, border_radius=6)
                font_manager.draw_text(
                    surface,
                    "💡",
                    hint_btn_rect.center,
                    14,
                    theme.text_primary,
                    align="center",
                )
                self.hint_button_rects.append((hint_btn_rect, word_entry))

            y += 62
