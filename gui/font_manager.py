"""Multilingual & Native Emoji Composite Font Manager using Pygame FreeType."""
from __future__ import annotations

import os
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from config.settings import settings

# Enable FreeType backend before pygame font initialization when available.
os.environ["PYGAME_FREETYPE"] = "1"

import pygame

HAS_PYGAME_FONT = hasattr(pygame, "font")
if HAS_PYGAME_FONT:
    pygame.font.init()

try:
    import pygame.freetype as pygame_freetype
except (ImportError, ModuleNotFoundError):
    # Some lightweight test shims expose freetype as an attribute only.
    pygame_freetype = getattr(pygame, "freetype", None)

HAS_FREETYPE = pygame_freetype is not None
if HAS_FREETYPE:
    try:
        pygame_freetype.init()
    except Exception:
        pygame_freetype = None
        HAS_FREETYPE = False

EMOJI_FONT_PATH = Path(__file__).parent.parent / "assets" / "fonts" / "NotoColorEmoji.ttf"


class FontManager:
    """Discovers multilingual system fonts and provides native composite rendering for text & emojis."""

    def __init__(self) -> None:
        self._font_path: Optional[str] = None
        self._emoji_font: Optional[pygame.freetype.Font] = None
        self._text_fonts: Dict[Tuple[int, bool], pygame.freetype.Font] = {}
        self._surface_cache: Dict[Tuple[str, int, Tuple[int, int, int], bool], pygame.Surface] = {}
        self._initialized = False

    def init(self) -> None:
        """Initializes FreeType subsystem and locates optimal primary & emoji fonts."""
        if self._initialized:
            return
        if HAS_FREETYPE and not pygame_freetype.get_init():
            pygame_freetype.init()

        # 1. Locate primary text / CJK system font with broad Unicode coverage
        candidates = [
            # macOS
            "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
            "/System/Library/Fonts/PingFang.ttc",
            "/System/Library/Fonts/Hiragino Sans GB.ttc",
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
                    self._load_font(path, 16)
                    self._font_path = path
                    break
                except Exception:
                    continue

        # 2. Load bundled emoji font if available
        if EMOJI_FONT_PATH.exists():
            try:
                if HAS_FREETYPE:
                    # Keep the original FreeType behavior: color emoji fonts
                    # choose their own size and reject explicit pixel sizes.
                    self._emoji_font = pygame_freetype.Font(str(EMOJI_FONT_PATH))
                else:
                    self._emoji_font = pygame.font.Font(str(EMOJI_FONT_PATH), 16)
            except Exception:
                self._emoji_font = None

        self._initialized = True

    @staticmethod
    def has_glyph(font: Optional[pygame.freetype.Font], char: str) -> bool:
        """Checks dynamically if a font contains a rendered glyph for a character."""
        if not font or not char:
            return False
        try:
            metrics = font.get_metrics(char)
            return bool(metrics and metrics[0] is not None)
        except Exception:
            return False

    @staticmethod
    def _load_font(font_path: Optional[str], size: int) -> pygame.freetype.Font:
        if HAS_FREETYPE:
            return pygame_freetype.Font(font_path, size)
        return pygame.font.Font(font_path, size)

    @staticmethod
    def _render_font(font: pygame.freetype.Font, text: str, color: Tuple[int, int, int], size: int) -> pygame.Surface:
        if HAS_FREETYPE:
            rendered, _ = font.render(text, color, size=size)
            return rendered
        return font.render(text, True, color)

    @staticmethod
    def _is_emoji_or_symbol(cp: int) -> bool:
        """Checks if a Unicode codepoint belongs to emoji or symbolic blocks."""
        return (
            (0x1F300 <= cp <= 0x1FAFF)
            or (0x2600 <= cp <= 0x27BF)
            or (0x1F600 <= cp <= 0x1F64F)
            or (0x1F680 <= cp <= 0x1F6FF)
            or (0x1F900 <= cp <= 0x1F9FF)
            or (0x2300 <= cp <= 0x23FF)
            or (0x2500 <= cp <= 0x25FF)  # Geometric shapes e.g. ▶, ◀
            or (0x2B50 <= cp <= 0x2B55)
            or cp in (0x203C, 0x2049, 0x2705, 0x274C, 0x274E, 0x2757)
        )

    def get_text_font(self, size: int, bold: bool = False) -> pygame.freetype.Font:
        """Retrieves a cached FreeType or pygame.font text font."""
        self.init()
        key = (size, bold)
        if key in self._text_fonts:
            return self._text_fonts[key]

        font: Optional[pygame.freetype.Font] = None
        if self._font_path:
            try:
                font = self._load_font(self._font_path, size)
            except Exception:
                font = None

        if font is None:
            try:
                if HAS_FREETYPE:
                    font = pygame_freetype.SysFont("sans-serif", size)
                else:
                    font = pygame.font.SysFont("sans-serif", size)
            except Exception:
                font = self._load_font(None, size)

        if bold:
            if HAS_FREETYPE:
                font.strong = True
            else:
                font.set_bold(True)

        self._text_fonts[key] = font
        return font

    def render(
        self,
        text: str,
        size: int,
        color: Tuple[int, int, int],
        bold: bool = False,
    ) -> pygame.Surface:
        """Renders text and native color emojis into a composite surface via dynamic glyph chaining."""
        self.init()
        cache_key = (text, size, color, bold)
        if cache_key in self._surface_cache:
            return self._surface_cache[cache_key]

        text_font = self.get_text_font(size, bold=bold)

        # Dynamic glyph classification & span partitioning
        spans: List[Tuple[str, bool]] = []
        curr_str = ""
        curr_is_emoji = False

        for ch in text:
            if ch == "\ufe0f":  # variation selector
                continue
            cp = ord(ch)
            has_tf = self.has_glyph(text_font, ch)
            has_ef = self.has_glyph(self._emoji_font, ch)

            if has_ef and (not has_tf or self._is_emoji_or_symbol(cp)):
                is_em = True
            elif has_tf:
                is_em = False
            elif has_ef:
                is_em = True
            else:
                is_em = False

            if is_em != curr_is_emoji:
                if curr_str:
                    spans.append((curr_str, curr_is_emoji))
                curr_str = ch
                curr_is_emoji = is_em
            else:
                curr_str += ch

        if curr_str:
            spans.append((curr_str, curr_is_emoji))

        if not spans:
            surf = pygame.Surface((1, 1), pygame.SRCALPHA)
            self._surface_cache[cache_key] = surf
            return surf

        # Fast path if no emoji spans exist
        if not any(is_em for _, is_em in spans):
            try:
                surf = self._render_font(text_font, text, color, size)
            except Exception:
                ascii_text = text.encode("ascii", "replace").decode("ascii")
                surf = self._render_font(text_font, ascii_text, color, size)
            self._surface_cache[cache_key] = surf
            return surf

        # Composite rendering with scaled emoji glyphs
        surfaces: List[pygame.Surface] = []
        total_w = 0
        max_h = size

        for s, is_em in spans:
            if is_em and self._emoji_font:
                for ch in s:
                    try:
                        if HAS_FREETYPE:
                            raw_surf, _ = self._emoji_font.render(ch)
                        else:
                            raw_surf = self._emoji_font.render(ch, True, color)
                        em_size = int(size * 1.05)
                        em_surf = pygame.transform.smoothscale(raw_surf, (em_size, em_size))
                        surfaces.append(em_surf)
                        total_w += em_surf.get_width() + 1
                        max_h = max(max_h, em_surf.get_height())
                    except Exception:
                        pass
            else:
                try:
                    txt_surf = self._render_font(text_font, s, color, size)
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

