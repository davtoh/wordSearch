"""Main Menu and Puzzle Configuration Screen."""
from __future__ import annotations

from typing import Callable, List, Optional

import pygame

from core.enums import Difficulty, GameMode
from gui.font_manager import font_manager
from gui.theme import theme
from gui.widgets.button import Button
from gui.widgets.input_box import InputBox
from storage.pack_loader import PackLoader, PuzzlePack


class MenuView:
    """Main menu providing pack selection, AI generation prompts, and gameplay settings."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 0)
        self.active_tab: str = "packs"  # "packs", "ai_topic", "ai_text", "custom"

        # Tab navigation buttons with native Unicode emojis
        self.btn_tab_packs = Button((0, 0, 150, 40), "📦 Offline Packs")
        self.btn_tab_topic = Button((0, 0, 150, 40), "✨ AI Topic", is_secondary=True)
        self.btn_tab_text = Button((0, 0, 160, 40), "📝 AI Notes", is_secondary=True)
        self.btn_tab_custom = Button((0, 0, 140, 40), "✏️ Custom List", is_secondary=True)

        self.btn_study_deck = Button((0, 0, 140, 40), "📚 Study Deck", is_secondary=True)
        self.btn_theme_toggle = Button((0, 0, 44, 40), "🌓", is_secondary=True)

        # Options buttons
        self.selected_difficulty: Difficulty = Difficulty.EASY
        self.selected_mode: GameMode = GameMode.CASUAL
        self.concept_first_mode: bool = False

        self.btn_diff_easy = Button((0, 0, 80, 32), "Easy")
        self.btn_diff_med = Button((0, 0, 90, 32), "Medium", is_secondary=True)
        self.btn_diff_hard = Button((0, 0, 80, 32), "Hard", is_secondary=True)
        self.btn_diff_dyn = Button((0, 0, 90, 32), "Dynamic", is_secondary=True)

        self.btn_mode_casual = Button((0, 0, 90, 32), "Casual")
        self.btn_mode_timed = Button((0, 0, 140, 32), "⏱️ Timed Attack", is_secondary=True)
        self.btn_toggle_concept = Button((0, 0, 180, 32), "Concept-First: OFF", is_secondary=True)

        # Input boxes for AI & Custom
        self.input_topic = InputBox((0, 0, 500, 42), placeholder="e.g. Space Exploration, Marine Biology, Japanese verbs")
        self.btn_generate_topic = Button((0, 0, 180, 42), "🚀 Generate Puzzle")

        self.input_text = InputBox((0, 0, 500, 120), placeholder="Paste student notes, article, or documentation here...", is_multiline=True)
        self.btn_extract_text = Button((0, 0, 180, 42), "🔍 Extract & Play")

        self.input_custom = InputBox((0, 0, 500, 42), placeholder="Enter words separated by commas: PYTHON, CODE, GAME")
        self.btn_play_custom = Button((0, 0, 170, 42), "▶ Play Custom")

        # Available packs list
        self.packs: List[PuzzlePack] = []
        self.pack_button_rects: List[tuple] = []
        self.scroll_y = 0

        # Callbacks
        self.on_pack_selected: Optional[Callable[[PuzzlePack, int], None]] = None
        self.on_ai_topic_requested: Optional[Callable[[str, Difficulty, GameMode, bool], None]] = None
        self.on_ai_text_requested: Optional[Callable[[str, Difficulty, GameMode, bool], None]] = None
        self.on_custom_words_requested: Optional[Callable[[List[str], Difficulty, GameMode, bool], None]] = None
        self.on_study_deck_requested: Optional[Callable[[], None]] = None

    def refresh_packs(self) -> None:
        self.packs = PackLoader.get_all_available_packs()

    def update_layout(self, container_rect: pygame.Rect) -> None:
        self.rect = container_rect

        # Header Tabs
        ty = 65
        self.btn_tab_packs.rect = pygame.Rect(30, ty, 150, 40)
        self.btn_tab_topic.rect = pygame.Rect(188, ty, 140, 40)
        self.btn_tab_text.rect = pygame.Rect(336, ty, 140, 40)
        self.btn_tab_custom.rect = pygame.Rect(484, ty, 140, 40)

        self.btn_study_deck.rect = pygame.Rect(container_rect.width - 210, ty, 140, 40)
        self.btn_theme_toggle.rect = pygame.Rect(container_rect.width - 60, ty, 44, 40)

        # Options Row at bottom of settings
        oy = 120
        self.btn_diff_easy.rect = pygame.Rect(30, oy, 75, 30)
        self.btn_diff_med.rect = pygame.Rect(110, oy, 85, 30)
        self.btn_diff_hard.rect = pygame.Rect(200, oy, 75, 30)
        self.btn_diff_dyn.rect = pygame.Rect(280, oy, 90, 30)

        self.btn_mode_casual.rect = pygame.Rect(390, oy, 80, 30)
        self.btn_mode_timed.rect = pygame.Rect(475, oy, 140, 30)
        self.btn_toggle_concept.rect = pygame.Rect(625, oy, 175, 30)

        # AI inputs positioning
        center_x = container_rect.centerx
        self.input_topic.rect = pygame.Rect(center_x - 300, 220, 420, 42)
        self.btn_generate_topic.rect = pygame.Rect(center_x + 130, 220, 180, 42)

        self.input_text.rect = pygame.Rect(center_x - 300, 200, 600, 160)
        self.btn_extract_text.rect = pygame.Rect(center_x - 90, 375, 180, 42)

        self.input_custom.rect = pygame.Rect(center_x - 300, 220, 420, 42)
        self.btn_play_custom.rect = pygame.Rect(center_x + 130, 220, 170, 42)

    def handle_event(self, event: pygame.event.Event) -> bool:
        # Tab changes
        if self.btn_tab_packs.handle_event(event):
            self.active_tab = "packs"
            self._update_tab_buttons()
            return True
        if self.btn_tab_topic.handle_event(event):
            self.active_tab = "ai_topic"
            self._update_tab_buttons()
            return True
        if self.btn_tab_text.handle_event(event):
            self.active_tab = "ai_text"
            self._update_tab_buttons()
            return True
        if self.btn_tab_custom.handle_event(event):
            self.active_tab = "custom"
            self._update_tab_buttons()
            return True

        if self.btn_study_deck.handle_event(event):
            if self.on_study_deck_requested:
                self.on_study_deck_requested()
            return True

        if self.btn_theme_toggle.handle_event(event):
            theme.toggle()
            return True

        # Difficulty buttons
        if self.btn_diff_easy.handle_event(event):
            self.selected_difficulty = Difficulty.EASY
            self._update_diff_buttons()
            return True
        if self.btn_diff_med.handle_event(event):
            self.selected_difficulty = Difficulty.MEDIUM
            self._update_diff_buttons()
            return True
        if self.btn_diff_hard.handle_event(event):
            self.selected_difficulty = Difficulty.HARD
            self._update_diff_buttons()
            return True
        if self.btn_diff_dyn.handle_event(event):
            self.selected_difficulty = Difficulty.DYNAMIC
            self._update_diff_buttons()
            return True

        # Mode buttons
        if self.btn_mode_casual.handle_event(event):
            self.selected_mode = GameMode.CASUAL
            self.btn_mode_casual.is_secondary = False
            self.btn_mode_timed.is_secondary = True
            return True
        if self.btn_mode_timed.handle_event(event):
            self.selected_mode = GameMode.TIMED_ATTACK
            self.btn_mode_casual.is_secondary = True
            self.btn_mode_timed.is_secondary = False
            return True

        # Concept toggle
        if self.btn_toggle_concept.handle_event(event):
            self.concept_first_mode = not self.concept_first_mode
            self.btn_toggle_concept.text = f"Concept-First: {'ON' if self.concept_first_mode else 'OFF'}"
            self.btn_toggle_concept.is_secondary = not self.concept_first_mode
            return True

        # Active Tab event processing
        if self.active_tab == "packs":
            if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                for btn_rect, pack, p_idx in self.pack_button_rects:
                    if btn_rect.collidepoint(event.pos):
                        if self.on_pack_selected:
                            self.on_pack_selected(pack, p_idx)
                        return True
            elif event.type == pygame.MOUSEWHEEL:
                self.scroll_y = max(0, self.scroll_y - event.y * 25)
                return True

        elif self.active_tab == "ai_topic":
            self.input_topic.handle_event(event)
            if self.btn_generate_topic.handle_event(event):
                if self.input_topic.text.strip() and self.on_ai_topic_requested:
                    self.on_ai_topic_requested(
                        self.input_topic.text.strip(),
                        self.selected_difficulty,
                        self.selected_mode,
                        self.concept_first_mode,
                    )
                return True

        elif self.active_tab == "ai_text":
            self.input_text.handle_event(event)
            if self.btn_extract_text.handle_event(event):
                if self.input_text.text.strip() and self.on_ai_text_requested:
                    self.on_ai_text_requested(
                        self.input_text.text.strip(),
                        self.selected_difficulty,
                        self.selected_mode,
                        self.concept_first_mode,
                    )
                return True

        elif self.active_tab == "custom":
            self.input_custom.handle_event(event)
            if self.btn_play_custom.handle_event(event):
                words = [w.strip() for w in self.input_custom.text.split(",") if w.strip()]
                if words and self.on_custom_words_requested:
                    self.on_custom_words_requested(
                        words,
                        self.selected_difficulty,
                        self.selected_mode,
                        self.concept_first_mode,
                    )
                return True

        return False

    def _update_tab_buttons(self) -> None:
        self.btn_tab_packs.is_secondary = (self.active_tab != "packs")
        self.btn_tab_topic.is_secondary = (self.active_tab != "ai_topic")
        self.btn_tab_text.is_secondary = (self.active_tab != "ai_text")
        self.btn_tab_custom.is_secondary = (self.active_tab != "custom")

    def _update_diff_buttons(self) -> None:
        self.btn_diff_easy.is_secondary = (self.selected_difficulty != Difficulty.EASY)
        self.btn_diff_med.is_secondary = (self.selected_difficulty != Difficulty.MEDIUM)
        self.btn_diff_hard.is_secondary = (self.selected_difficulty != Difficulty.HARD)
        self.btn_diff_dyn.is_secondary = (self.selected_difficulty != Difficulty.DYNAMIC)

    def draw(self, surface: pygame.Surface) -> None:
        pygame.draw.rect(surface, theme.bg, self.rect)

        # Title Banner
        font_manager.draw_text(
            surface,
            "🔍 AI Multilingual Word Search",
            (30, 22),
            24,
            theme.text_primary,
            bold=True,
        )

        # Draw Nav Tabs
        self.btn_tab_packs.draw(surface)
        self.btn_tab_topic.draw(surface)
        self.btn_tab_text.draw(surface)
        self.btn_tab_custom.draw(surface)
        self.btn_study_deck.draw(surface)
        self.btn_theme_toggle.draw(surface)

        # Draw Options Bar
        self.btn_diff_easy.draw(surface)
        self.btn_diff_med.draw(surface)
        self.btn_diff_hard.draw(surface)
        self.btn_diff_dyn.draw(surface)
        self.btn_mode_casual.draw(surface)
        self.btn_mode_timed.draw(surface)
        self.btn_toggle_concept.draw(surface)

        pygame.draw.line(surface, theme.card_border, (30, 160), (self.rect.width - 30, 160), 1)

        # Active tab content
        if self.active_tab == "packs":
            self._draw_packs_list(surface)
        elif self.active_tab == "ai_topic":
            self._draw_ai_topic(surface)
        elif self.active_tab == "ai_text":
            self._draw_ai_text(surface)
        elif self.active_tab == "custom":
            self._draw_custom(surface)

    def _draw_packs_list(self, surface: pygame.Surface) -> None:
        self.pack_button_rects.clear()
        start_y = 175 - self.scroll_y
        card_w = self.rect.width - 60
        clip_rect = pygame.Rect(30, 165, card_w, self.rect.height - 180)
        surface.set_clip(clip_rect)

        y = start_y
        for pack in self.packs:
            for p_idx, p_info in enumerate(pack.puzzles_data):
                if y + 85 < clip_rect.top or y > clip_rect.bottom:
                    y += 90
                    continue

                card_rect = pygame.Rect(30, y, card_w, 78)
                pygame.draw.rect(surface, theme.card_bg, card_rect, border_radius=10)
                pygame.draw.rect(surface, theme.card_border, card_rect, width=1, border_radius=10)

                # Pack Title & Language Badge
                lang_tag = f"[{pack.language.upper()} - {pack.script_type.value}]"
                font_manager.draw_text(
                    surface,
                    f"{p_info.get('title', pack.title)}  {lang_tag}",
                    (card_rect.x + 16, card_rect.y + 12),
                    18,
                    theme.text_primary,
                    bold=True,
                )

                # Description
                desc = p_info.get("description", pack.description)
                font_manager.draw_text(
                    surface,
                    f"{desc}  ({len(p_info.get('words', []))} words)",
                    (card_rect.x + 16, card_rect.y + 40),
                    13,
                    theme.text_muted,
                )

                # Play Button on right
                play_btn_rect = pygame.Rect(card_rect.right - 110, card_rect.y + 18, 94, 40)
                pygame.draw.rect(surface, theme.accent, play_btn_rect, border_radius=8)
                font_manager.draw_text(
                    surface,
                    "Play ▶",
                    play_btn_rect.center,
                    15,
                    (255, 255, 255),
                    bold=True,
                    align="center",
                )

                self.pack_button_rects.append((play_btn_rect, pack, p_idx))
                y += 90

        surface.set_clip(None)

    def _draw_ai_topic(self, surface: pygame.Surface) -> None:
        font_manager.draw_text(
            surface,
            "✨ Generate Thematic Puzzle with Gemini AI",
            (self.rect.centerx, 185),
            20,
            theme.accent,
            bold=True,
            align="center",
        )
        self.input_topic.draw(surface)
        self.btn_generate_topic.draw(surface)

    def _draw_ai_text(self, surface: pygame.Surface) -> None:
        font_manager.draw_text(
            surface,
            "📝 Extract Concept Vocabulary from Notes / Article",
            (self.rect.centerx, 175),
            18,
            theme.accent,
            bold=True,
            align="center",
        )
        self.input_text.draw(surface)
        self.btn_extract_text.draw(surface)

    def _draw_custom(self, surface: pygame.Surface) -> None:
        font_manager.draw_text(
            surface,
            "✏️ Create Puzzle from Custom Words",
            (self.rect.centerx, 185),
            20,
            theme.accent,
            bold=True,
            align="center",
        )
        self.input_custom.draw(surface)
        self.btn_play_custom.draw(surface)
