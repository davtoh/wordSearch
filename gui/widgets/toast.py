"""Toast Notification Overlay Widget for In-Game Alerts and Proximity."""
from __future__ import annotations

import time
from typing import Optional, Tuple

import pygame

from gui.font_manager import font_manager
from gui.theme import theme


class Toast:
    """Displays temporary non-intrusive notification banners."""

    def __init__(self) -> None:
        self.message: str = ""
        self.color: Tuple[int, int, int] = (56, 189, 248)
        self.expires_at: float = 0.0
        self.duration: float = 3.0

    def show(
        self,
        message: str,
        color: Optional[Tuple[int, int, int]] = None,
        duration: float = 3.0,
    ) -> None:
        self.message = message
        self.color = color or theme.accent
        self.duration = duration
        self.expires_at = time.time() + duration

    @property
    def is_visible(self) -> bool:
        return time.time() < self.expires_at and bool(self.message)

    def draw(self, surface: pygame.Surface, screen_width: int, y_pos: int = 70) -> None:
        if not self.is_visible:
            return

        rendered_text = font_manager.render(self.message, 16, (255, 255, 255), bold=True)
        txt_rect = rendered_text.get_rect()

        banner_width = txt_rect.width + 40
        banner_height = 38
        banner_rect = pygame.Rect(
            (screen_width - banner_width) // 2,
            y_pos,
            banner_width,
            banner_height,
        )

        # Draw toast pill background
        pygame.draw.rect(surface, (20, 25, 38), banner_rect, border_radius=19)
        pygame.draw.rect(surface, self.color, banner_rect, width=2, border_radius=19)

        # Draw text
        txt_rect.center = banner_rect.center
        surface.blit(rendered_text, txt_rect)


# Global singleton instance
toast = Toast()
