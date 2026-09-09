"""Single and Multi-line Text Input Widget with Cursor and Paste Support."""
from __future__ import annotations

import time
from typing import Optional, Tuple

import pygame

from gui.font_manager import font_manager
from gui.theme import theme


class InputBox:
    """Text input box supporting typing, backspace, clipboard paste, and active focus."""

    def __init__(
        self,
        rect: Tuple[int, int, int, int],
        placeholder: str = "Type here...",
        initial_text: str = "",
        font_size: int = 18,
        is_multiline: bool = False,
    ) -> None:
        self.rect = pygame.Rect(rect)
        self.placeholder = placeholder
        self.text = initial_text
        self.font_size = font_size
        self.is_multiline = is_multiline
        self.is_focused = False
        self.cursor_visible = True
        self.last_cursor_blink = time.time()

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            self.is_focused = self.rect.collidepoint(event.pos)
            return self.is_focused

        if not self.is_focused:
            return False

        if event.type == pygame.KEYDOWN:
            # Paste from clipboard
            if event.key == pygame.K_v and (pygame.key.get_mods() & (pygame.KMOD_CTRL | pygame.KMOD_META)):
                try:
                    pasted = pygame.scrap.get(pygame.SCRAP_TEXT)
                    if pasted:
                        self.text += pasted.decode("utf-8", errors="ignore").replace("\x00", "")
                        return True
                except Exception:
                    pass

            if event.key == pygame.K_BACKSPACE:
                self.text = self.text[:-1]
                return True
            elif event.key == pygame.K_RETURN:
                if self.is_multiline:
                    self.text += "\n"
                    return True
            elif event.unicode and event.unicode.isprintable():
                self.text += event.unicode
                return True

        return False

    def draw(self, surface: pygame.Surface) -> None:
        # Background
        pygame.draw.rect(surface, theme.card_bg, self.rect, border_radius=8)

        # Border
        border_color = theme.accent if self.is_focused else theme.card_border
        border_w = 2 if self.is_focused else 1
        pygame.draw.rect(surface, border_color, self.rect, width=border_w, border_radius=8)

        # Content text or placeholder
        display_text = self.text if self.text else self.placeholder
        text_color = theme.text_primary if self.text else theme.text_muted

        # Cursor blink
        if time.time() - self.last_cursor_blink > 0.5:
            self.cursor_visible = not self.cursor_visible
            self.last_cursor_blink = time.time()

        if self.is_focused and self.cursor_visible and self.text:
            display_text += "|"

        # Render text (clip to box)
        margin = 10
        inner_rect = pygame.Rect(
            self.rect.x + margin,
            self.rect.y + margin,
            self.rect.width - 2 * margin,
            self.rect.height - 2 * margin,
        )

        rendered = font_manager.render(display_text, self.font_size, text_color)
        surface.blit(rendered, inner_rect)
