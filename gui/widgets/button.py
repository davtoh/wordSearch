"""Interactive Button Widget with Smooth Hover and Accessibility Outline."""
from __future__ import annotations

from typing import Callable, Optional, Tuple

import pygame

from gui.font_manager import font_manager
from gui.theme import theme


class Button:
    """A tactile, styled button supporting mouse hover, clicks, and keyboard focus."""

    def __init__(
        self,
        rect: Tuple[int, int, int, int],
        text: str,
        callback: Optional[Callable[[], None]] = None,
        font_size: int = 18,
        bg_color: Optional[Tuple[int, int, int]] = None,
        text_color: Optional[Tuple[int, int, int]] = None,
        hover_color: Optional[Tuple[int, int, int]] = None,
        border_radius: int = 8,
        is_secondary: bool = False,
    ) -> None:
        self.rect = pygame.Rect(rect)
        self.text = text
        self.callback = callback
        self.font_size = font_size
        self.custom_bg = bg_color
        self.custom_text = text_color
        self.custom_hover = hover_color
        self.border_radius = border_radius
        self.is_secondary = is_secondary
        self.is_hovered = False
        self.is_focused = False
        self.is_pressed = False

    def handle_event(self, event: pygame.event.Event) -> bool:
        """Processes mouse/touch events and executes callback on click.
        The click is only triggered on mouse button release to avoid toggling on press.
        """
        if event.type == pygame.MOUSEMOTION:
            self.is_hovered = self.rect.collidepoint(event.pos)
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.rect.collidepoint(event.pos):
                self.is_pressed = True
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            if self.is_pressed:
                self.is_pressed = False
                if self.rect.collidepoint(event.pos):
                    if self.callback:
                        self.callback()
                    return True
        return False

    def draw(self, surface: pygame.Surface) -> None:
        """Renders button surface with active styling and focus outline."""
        # Determine background color
        if self.custom_bg:
            base_bg = self.custom_bg
            hover_bg = self.custom_hover or self.custom_bg
        elif self.is_secondary:
            base_bg = theme.card_bg
            hover_bg = theme.grid_cell_hover
        else:
            base_bg = theme.accent
            hover_bg = theme.accent_hover

        fill_color = hover_bg if (self.is_hovered or self.is_pressed) else base_bg

        # Draw rounded rectangle
        pygame.draw.rect(surface, fill_color, self.rect, border_radius=self.border_radius)

        # Draw border
        border_color = theme.cursor_border if self.is_focused else theme.card_border
        border_width = 3 if self.is_focused else 1
        pygame.draw.rect(surface, border_color, self.rect, width=border_width, border_radius=self.border_radius)

        # Draw text (with native color emoji & CJK support)
        txt_color = self.custom_text or (theme.text_primary if self.is_secondary else (255, 255, 255))
        font_manager.draw_text(
            surface,
            self.text,
            self.rect.center,
            self.font_size,
            txt_color,
            bold=True,
            align="center",
        )
