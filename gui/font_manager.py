"""Multilingual & Native Emoji Composite Font Manager using Pygame FreeType."""
from __future__ import annotations

import os
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Enable FreeType backend before pygame font initialization
os.environ["PYGAME_FREETYPE"] = "1"

import pygame
import pygame.freetype

EMOJI_FONT_PATH = Path(__file__).parent.parent / "assets" / "fonts" / "NotoColorEmoji.ttf"


def is_emoji(char: str) -> bool:
    """Checks if a character is within common Unicode emoji codepoint ranges."""
    cp = ord(char)
    return (
        (0x1F300 <= cp <= 0x1FAFF)
        or (0x2600 <= cp <= 0x27BF)
        or (0x1F600 <= cp <= 0x1F64F)
        or (0x1F680 <= cp <= 0x1F6FF)
        or (0x1F900 <= cp <= 0x1F9FF)
        or (0x2300 <= cp <= 0x23FF)
        or (0x2B50 <= cp <= 0x2B55)
        or cp in (0x203C, 0x2049, 0x2705, 0x274C, 0x274E, 0x2757)
    )


class FontManager:
    """Discovers multilingual system fonts and provides native composite rendering for text & emojis."""

    def __init__(self) -> None:
        self._font_path: Optional[str] = None
        self._cjk_font_name: Optional[str] = None
        self._emoji_font: Optional[pygame.freetype.Font] = None
        self._text_fonts: Dict[Tuple[int, bool], pygame.freetype.Font] = {}
        self._surface_cache: Dict[Tuple[str, int, Tuple[int, int, int], bool], pygame.Surface] = {}
        self._initialized = False

    def init(self) -> None:
        """Initializes FreeType subsystem and locates optimal primary & emoji fonts."""
        if self._initialized:
            return
        if not pygame.freetype.get_init():
            pygame.freetype.init()

        # 1. Locate primary text / CJK system font
        candidates = [
            # macOS
            "/System/Library/Fonts/Hiragino Sans GB.ttc",
            "/System/Library/Fonts/PingFang.ttc",
            "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            # Android (Pydroid 3)
            "/system/fonts/NotoSansCJK-Regular.ttc",
            "/system/fonts/DroidSansFallback.ttf",
            "/system/fonts/Roboto-Regular.ttf",
            # Linux
            "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
            # Windows
            "C:\\Windows\\Fonts\\meiryo.ttc",
            "C:\\Windows\\Fonts\\msgothic.ttc",
            "C:\\Windows\\Fonts\\segoeui.ttf",
            "C:\\Windows\\Fonts\\arial.ttf",
        ]

        for path in candidates:
            if os.path.exists(path):
                try:
                    pygame.freetype.Font(path, 16)
                    self._font_path = path
                    break
                except Exception:
                    continue

        # 2. Load bundled emoji font if available
        if EMOJI_FONT_PATH.exists():
            try:
                self._emoji_font = pygame.freetype.Font(str(EMOJI_FONT_PATH))
            except Exception:
                self._emoji_font = None

        self._initialized = True

    def get_text_font(self, size: int, bold: bool = False) -> pygame.freetype.Font:
        """Retrieves or loads cached FreeType text font."""
        self.init()
        key = (size, bold)
        if key in self._text_fonts:
            return self._text_fonts[key]

        font: Optional[pygame.freetype.Font] = None
        if self._font_path:
            try:
                font = pygame.freetype.Font(self._font_path, size)
                if bold:
                    font.strong = True
            except Exception:
                font = None

        if font is None:
            try:
                font = pygame.freetype.SysFont("sans-serif", size)
                if bold:
                    font.strong = True
            except Exception:
                font = pygame.freetype.Font(None, size)
                if bold:
                    font.strong = True

        self._text_fonts[key] = font
        return font

    def render(
        self,
        text: str,
        size: int,
        color: Tuple[int, int, int],
        bold: bool = False,
    ) -> pygame.Surface:
        """Renders text and native color emojis into a composite anti-aliased surface with caching."""
        self.init()
        cache_key = (text, size, color, bold)
        if cache_key in self._surface_cache:
            return self._surface_cache[cache_key]

        text_font = self.get_text_font(size, bold=bold)

        # Check if text contains any emoji characters
        has_emojis = bool(self._emoji_font) and any(is_emoji(c) for c in text if c != "\ufe0f")

        if not has_emojis:
            # Fast path: pure text without emojis
            try:
                surf, _ = text_font.render(text, color, size=size)
            except Exception:
                ascii_text = text.encode("ascii", "replace").decode("ascii")
                surf, _ = text_font.render(ascii_text, color, size=size)
            self._surface_cache[cache_key] = surf
            return surf

        # Composite path: split text into text and emoji segments
        spans: List[Tuple[str, bool]] = []
        curr_str = ""
        curr_is_emoji = False

        for ch in text:
            if ch == "\ufe0f":  # variation selector
                continue
            em = is_emoji(ch)
            if em != curr_is_emoji:
                if curr_str:
                    spans.append((curr_str, curr_is_emoji))
                curr_str = ch
                curr_is_emoji = em
            else:
                curr_str += ch
        if curr_str:
            spans.append((curr_str, curr_is_emoji))

        surfaces: List[pygame.Surface] = []
        total_w = 0
        max_h = size

        for s, is_em in spans:
            if is_em and self._emoji_font:
                for ch in s:
                    try:
                        raw_surf, _ = self._emoji_font.render(ch)
                        em_size = int(size * 1.05)
                        em_surf = pygame.transform.smoothscale(raw_surf, (em_size, em_size))
                        surfaces.append(em_surf)
                        total_w += em_surf.get_width() + 2
                        max_h = max(max_h, em_surf.get_height())
                    except Exception:
                        pass
            else:
                try:
                    txt_surf, _ = text_font.render(s, color, size=size)
                    surfaces.append(txt_surf)
                    total_w += txt_surf.get_width()
                    max_h = max(max_h, txt_surf.get_height())
                except Exception:
                    pass

        if not surfaces:
            surf = pygame.Surface((1, 1), pygame.SRCALPHA)
            self._surface_cache[cache_key] = surf
            return surf

        composite_surf = pygame.Surface((total_w, max_h), pygame.SRCALPHA)
        cur_x = 0
        for surf in surfaces:
            y = (max_h - surf.get_height()) // 2
            composite_surf.blit(surf, (cur_x, y))
            cur_x += surf.get_width()

        self._surface_cache[cache_key] = composite_surf
        return composite_surf

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
        """Draws aligned text onto target surface and returns bounding Rect."""
        rendered = self.render(text, size, color, bold=bold)
        rect = rendered.get_rect()
        setattr(rect, align, pos)
        surface.blit(rendered, rect)
        return rect


# Global singleton instance
font_manager = FontManager()
