"""Visual Themes and Color Palettes for Pygame GUI."""
from __future__ import annotations

from typing import List, Tuple
from config.settings import settings
from core.enums import ThemeMode


class Theme:
    """Color definitions for Light and Dark modes with accessibility high-contrast accents."""

    def __init__(self, mode: ThemeMode = settings.get('theme', ThemeMode.DARK)) -> None:
        self.is_dark = (mode == ThemeMode.DARK)
        self._set_colors()

    def _set_colors(self) -> None:
        if self.is_dark:
            self.bg = (18, 22, 32)
            self.card_bg = (28, 34, 48)
            self.card_border = (45, 55, 78)
            self.text_primary = (240, 244, 255)
            self.text_secondary = (160, 175, 205)
            self.text_muted = (110, 125, 150)
            self.accent = (56, 189, 248)  # Bright sky blue
            self.accent_hover = (14, 165, 233)
            self.success = (34, 197, 94)   # Vibrant emerald
            self.warning = (245, 158, 11)  # Amber
            self.danger = (239, 68, 68)    # Coral Red
            self.grid_cell_bg = (33, 40, 58)
            self.grid_cell_hover = (48, 58, 82)
            self.grid_cell_select = (56, 189, 248, 120)  # semi-transparent selection
            self.grid_text = (245, 250, 255)
            self.cursor_border = (250, 204, 21) # Yellow cursor
        else:  # Light Mode
            self.bg = (244, 246, 250)
            self.card_bg = (255, 255, 255)
            self.card_border = (210, 218, 230)
            self.text_primary = (20, 25, 38)
            self.text_secondary = (75, 85, 105)
            self.text_muted = (140, 150, 170)
            self.accent = (14, 165, 233)
            self.accent_hover = (2, 132, 199)
            self.success = (22, 163, 74)
            self.warning = (217, 119, 6)
            self.danger = (220, 38, 38)
            self.grid_cell_bg = (235, 240, 248)
            self.grid_cell_hover = (218, 228, 242)
            self.grid_cell_select = (14, 165, 233, 120)
            self.grid_text = (15, 23, 42)
            self.cursor_border = (202, 138, 4)

        # Highlighting colors for found words (distinct pastel/neon hues)
        self.word_highlighters: List[Tuple[int, int, int]] = [
            (56, 189, 248),   # Sky Cyan
            (74, 222, 128),   # Light Emerald
            (244, 114, 182),  # Pink Rose
            (251, 191, 36),   # Sun Amber
            (192, 132, 252),  # Purple Lavender
            (45, 212, 191),   # Mint Teal
            (251, 146, 60),   # Warm Orange
            (129, 140, 248),  # Indigo Periwinkle
        ]

    def toggle(self) -> str:
        self.is_dark = not self.is_dark
        self._set_colors()
        settings.set('theme', ThemeMode.DARK if self.is_dark else ThemeMode.LIGHT)
        return ThemeMode.DARK if self.is_dark else ThemeMode.LIGHT

    def get_word_color(self, index: int) -> Tuple[int, int, int]:
        return self.word_highlighters[index % len(self.word_highlighters)]


theme = Theme(settings.get('theme', ThemeMode.DARK))
