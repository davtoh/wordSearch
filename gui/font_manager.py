"""Multilingual Font Manager with Unicode & CJK Fallbacks for Pygame."""
from __future__ import annotations

import os
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import pygame


class FontManager:
    """Discovers, loads, and caches Unicode-capable system fonts for seamless CJK & accented text."""

    def __init__(self) -> None:
        self._fonts_cache: Dict[Tuple[int, bool], pygame.font.Font] = {}
        self._cjk_font_name: Optional[str] = None
        self._initialized = False

    def init(self) -> None:
        """Initializes font subsystem and searches for optimal multilingual font."""
        if self._initialized:
            return
        if not pygame.font.get_init():
            pygame.font.init()

        # Preferred font candidates with broad Unicode & CJK glyph coverage
        candidates = [
            # macOS
            "hiraginosans",
            "hiraginokakugothicpro",
            "applegothic",
            "arialunicodems",
            "pingfangsc",
            "helveticaneue",
            # Windows
            "meiryo",
            "msgothic",
            "yugothic",
            "segoeui",
            "arial",
            # Linux & Android (Pydroid 3)
            "notosanscjkjp",
            "notosanscjk",
            "droidsansfallback",
            "dejavusans",
            "freesans",
        ]

        sys_fonts = set(pygame.font.get_fonts())
        for candidate in candidates:
            if candidate in sys_fonts:
                self._cjk_font_name = candidate
                break

        self._initialized = True

    def get_font(self, size: int, bold: bool = False) -> pygame.font.Font:
        """Retrieves a cached font of specified size and weight."""
        self.init()
        key = (size, bold)
        if key in self._fonts_cache:
            return self._fonts_cache[key]

        font: Optional[pygame.font.Font] = None

        if self._cjk_font_name:
            try:
                font = pygame.font.SysFont(self._cjk_font_name, size, bold=bold)
            except Exception:
                pass

        if font is None:
            # Default Pygame system font
            font = pygame.font.SysFont("sans-serif", size, bold=bold)

        self._fonts_cache[key] = font
        return font

    def render(
        self,
        text: str,
        size: int,
        color: Tuple[int, int, int],
        bold: bool = False,
    ) -> pygame.Surface:
        """Renders text surface with anti-aliasing."""
        font = self.get_font(size, bold=bold)
        return font.render(text, True, color)

    def draw_text(
        self,
        surface: pygame.Surface,
        text: str,
        pos: Tuple[int, int],
        size: int,
        color: Tuple[int, int, int],
        bold: bool = False,
        align: str = "topleft",
    ) -> pygame.Rect:
        """Draws aligned text onto a target surface and returns bounding Rect."""
        rendered = self.render(text, size, color, bold=bold)
        rect = rendered.get_rect()
        setattr(rect, align, pos)
        surface.blit(rendered, rect)
        return rect


# Global singleton instance
font_manager = FontManager()
