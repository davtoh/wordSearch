"""Main Pygame Application Coordinator and Event Loop."""
from __future__ import annotations

import sys
import time
from typing import List, Optional, Tuple

import pygame

from ai.text_extractor import TextExtractor
from ai.topic_generator import TopicGenerator
from assists.registry import AssistRegistry
from config.settings import settings
from core.enums import Difficulty, GameMode, GameStatus, HintTier
from core.game_state import GameState
from core.grid_engine import GridEngine
from core.models import Puzzle, WordEntry
from gui.accessibility import AccessibilityController
from gui.font_manager import font_manager
from gui.theme import theme
from gui.views.board_view import BoardView
from gui.views.hud_view import HudView
from gui.views.mastery_view import MasteryView
from gui.views.menu_view import MenuView
from gui.views.review_view import ReviewView
from gui.views.word_list_view import WordListView
from gui.widgets.toast import toast
from learning.adaptive_recommender import AdaptiveRecommender
from storage.pack_loader import PackLoader, PuzzlePack
from telemetry.profile_manager import profile_manager
from telemetry.tracker import SessionTelemetry


class WordSearchApp:
    """Main application loop coordinating Pygame rendering, state machines, and assists."""

    def __init__(self) -> None:
        pygame.init()
        pygame.display.set_caption("AI Multilingual Word Search")

        self.width = settings.get("screen_width", 1024)
        self.height = settings.get("screen_height", 720)
        self.screen = pygame.display.set_mode((self.width, self.height), pygame.RESIZABLE)
        self.clock = pygame.time.Clock()
        self.fps = settings.get("fps", 60)

        font_manager.init()

        # Screens & Views
        self.screen_state: str = "MENU"  # "MENU", "PLAYING", "REVIEW", "MASTERY"
        self.menu_view = MenuView()
        self.board_view = BoardView()
        self.word_list_view = WordListView()
        self.hud_view = HudView()
        self.review_view = ReviewView()
        self.mastery_view = MasteryView()
        self.accessibility = AccessibilityController()

        # Engines & Services
        self.assists = AssistRegistry()
        self.game_state: Optional[GameState] = None
        self.telemetry: Optional[SessionTelemetry] = None
        self.current_pack: Optional[PuzzlePack] = None
        self.current_puzzle_index: int = 0

        # Dynamic mode shift timer
        self.last_shift_time: float = 0.0

        self._setup_callbacks()
        self.menu_view.refresh_packs()
        self._update_layouts()

    def _setup_callbacks(self) -> None:
        # Menu Callbacks
        self.menu_view.on_pack_selected = self.start_pack_puzzle
        self.menu_view.on_ai_topic_requested = self.start_ai_topic_puzzle
        self.menu_view.on_ai_text_requested = self.start_ai_text_puzzle
        self.menu_view.on_custom_words_requested = self.start_custom_puzzle
        self.menu_view.on_study_deck_requested = lambda: self._switch_state("MASTERY")

        # Board Callbacks
        self.board_view.on_selection_made = self._on_selection_made
        self.board_view.on_cell_tapped = self._on_cell_tapped

        # Word List Callbacks
        self.word_list_view.on_word_hint_clicked = self._on_word_hint_requested

        # HUD Callbacks
        self.hud_view.btn_menu.callback = lambda: self._switch_state("MENU")
        self.hud_view.btn_pause.callback = self._on_pause_toggled
        self.hud_view.btn_hint.callback = lambda: self._on_word_hint_requested(None)
        self.hud_view.btn_giveup.callback = self._on_give_up
        self.hud_view.btn_theme.callback = lambda: theme.toggle()

        # Review Screen Callbacks
        self.review_view.btn_menu.callback = lambda: self._switch_state("MENU")
        self.review_view.btn_study.callback = lambda: self._switch_state("MASTERY")
        self.review_view.btn_next.callback = self._on_next_puzzle

        # Mastery Callbacks
        self.mastery_view.btn_back.callback = lambda: self._switch_state("MENU")
        self.mastery_view.on_practice_requested = self._start_practice_puzzle

    def _switch_state(self, new_state: str) -> None:
        self.screen_state = new_state
        self._update_layouts()

    def _update_layouts(self) -> None:
        w, h = self.screen.get_size()
        self.width = w
        self.height = h

        self.menu_view.update_layout(pygame.Rect(0, 0, w, h))
        self.hud_view.update_layout(w)
        self.review_view.update_layout(pygame.Rect(0, 0, w, h))
        self.mastery_view.update_layout(pygame.Rect(0, 0, w, h))

        if self.game_state:
            # Split screen into Left Grid and Right Word List
            hud_h = 56
            avail_h = h - hud_h - 16
            list_w = min(320, int(w * 0.32))
            board_w = w - list_w - 32

            self.board_view.update_layout(
                pygame.Rect(16, hud_h + 10, board_w, avail_h),
                self.game_state.puzzle.rows,
                self.game_state.puzzle.cols,
            )
            self.word_list_view.update_layout(
                pygame.Rect(w - list_w - 16, hud_h + 10, list_w, avail_h),
                concept_mode=self.menu_view.concept_first_mode,
            )

    def start_pack_puzzle(self, pack: PuzzlePack, index: int = 0) -> None:
        self.current_pack = pack
        self.current_puzzle_index = index
        diff = self.menu_view.selected_difficulty
        puzzle = pack.get_puzzle(index, difficulty=diff)
        self._launch_puzzle(puzzle)

    def start_ai_topic_puzzle(self, topic: str, difficulty: Difficulty, mode: GameMode, concept_mode: bool) -> None:
        toast.show(f"Generating AI puzzle for '{topic}'...", duration=2.5)
        words_data = TopicGenerator.generate_words(topic, count=9, difficulty=difficulty.value)
        puzzle = GridEngine.generate_puzzle(
            words_data=words_data,
            title=f"AI: {topic}",
            theme=topic,
            difficulty=difficulty,
        )
        self.current_pack = None
        self._launch_puzzle(puzzle, mode=mode)

    def start_ai_text_puzzle(self, text: str, difficulty: Difficulty, mode: GameMode, concept_mode: bool) -> None:
        toast.show("Extracting concepts from text...", duration=2.5)
        words_data = TextExtractor.extract_from_text(text, count=9)
        puzzle = GridEngine.generate_puzzle(
            words_data=words_data,
            title="Text Concepts",
            theme="Notes",
            difficulty=difficulty,
        )
        self.current_pack = None
        self._launch_puzzle(puzzle, mode=mode)

    def start_custom_puzzle(self, words: List[str], difficulty: Difficulty, mode: GameMode, concept_mode: bool) -> None:
        words_data = [{"word": w, "clue": f"Custom word: {w}"} for w in words]
        puzzle = GridEngine.generate_puzzle(
            words_data=words_data,
            title="Custom Puzzle",
            theme="Custom",
            difficulty=difficulty,
        )
        self.current_pack = None
        self._launch_puzzle(puzzle, mode=mode)

    def _start_practice_puzzle(self) -> None:
        review_words = AdaptiveRecommender.get_review_words(profile_manager.profile, target_count=8)
        if not review_words:
            toast.show("No difficult words recorded yet. Play some puzzles first!", duration=3.0)
            return

        toast.show("Generating targeted practice puzzle...", duration=2.0)
        puzzle = GridEngine.generate_puzzle(
            words_data=review_words,
            title="Targeted Practice",
            theme="Vocabulary Review",
            difficulty=Difficulty.MEDIUM,
        )
        self.current_pack = None
        self._launch_puzzle(puzzle)

    def _launch_puzzle(self, puzzle: Puzzle, mode: Optional[GameMode] = None) -> None:
        play_mode = mode or self.menu_view.selected_mode
        self.game_state = GameState(puzzle, mode=play_mode)
        self.telemetry = SessionTelemetry()
        self.accessibility.reset_grid(puzzle.rows, puzzle.cols)
        self.last_shift_time = time.time()
        self._switch_state("PLAYING")

    def _on_selection_made(self, start: Tuple[int, int], end: Tuple[int, int]) -> None:
        if not self.game_state or not self.telemetry:
            return

        valid, word_entry, coords = self.game_state.check_selection(start, end)
        self.telemetry.record_selection_attempt(valid, target_word=word_entry.word if word_entry else None)

        if valid and word_entry:
            interval = self.telemetry.record_word_found(word_entry)
            self.assists.on_word_found(self.game_state, word_entry)
            toast.show(f"✓ Found '{word_entry.word}'! ({interval:.1f}s)", color=theme.success, duration=2.0)

            # Check win condition
            if self.game_state.status == GameStatus.WON:
                profile_manager.record_completed_session(self.game_state, self.telemetry)
                self._switch_state("REVIEW")

    def _on_cell_tapped(self, coord: Tuple[int, int]) -> None:
        if not self.game_state:
            return
        results = self.assists.on_cell_clicked(self.game_state, coord)
        for res in results:
            if "message" in res:
                toast.show(res["message"], color=res.get("color"), duration=1.5)

    def _on_word_hint_requested(self, target_word: Optional[WordEntry]) -> None:
        if not self.game_state or not self.telemetry:
            return
        hint_res = self.assists.hints.request_hint(self.game_state, target_word.word if target_word else None)
        if hint_res:
            self.telemetry.record_hint_used()
            toast.show(hint_res.message, color=theme.warning, duration=3.5)

    def _on_pause_toggled(self) -> None:
        if self.game_state and self.telemetry:
            is_paused = self.game_state.toggle_pause()
            self.telemetry.on_pause_toggled(is_paused)

    def _on_give_up(self) -> None:
        if self.game_state and self.telemetry:
            self.game_state.give_up()
            profile_manager.record_completed_session(self.game_state, self.telemetry)
            self._switch_state("REVIEW")

    def _on_next_puzzle(self) -> None:
        if self.current_pack and self.current_puzzle_index + 1 < self.current_pack.puzzle_count:
            self.start_pack_puzzle(self.current_pack, self.current_puzzle_index + 1)
        else:
            self._switch_state("MENU")

    def run(self) -> None:
        """Main game loop handling events, ticking timers, and rendering views."""
        running = True

        while running:
            delta_sec = self.clock.tick(self.fps) / 1000.0

            # 1. Process Pygame Events
            for event in pygame.event.type_compile() if hasattr(pygame.event, "type_compile") else []:
                pass

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                    break

                elif event.type == pygame.VIDEORESIZE:
                    self.screen = pygame.display.set_mode((event.w, event.h), pygame.RESIZABLE)
                    self._update_layouts()

                # Window focus lost/gained (avoids inactivity penalty during multitasking)
                elif event.type == pygame.ACTIVEEVENT:
                    if hasattr(event, "gain"):
                        if event.gain == 0:
                            if self.telemetry:
                                self.telemetry.on_focus_lost()
                        elif event.gain == 1:
                            if self.telemetry:
                                self.telemetry.on_focus_gained()

                # Route events based on active screen
                if self.screen_state == "MENU":
                    self.menu_view.handle_event(event)

                elif self.screen_state == "PLAYING":
                    # Check accessibility keys
                    if event.type == pygame.KEYDOWN and self.game_state:
                        handled = self.accessibility.handle_key_down(
                            event,
                            self.game_state.puzzle.rows,
                            self.game_state.puzzle.cols,
                            on_selection_confirm=self._on_selection_made,
                        )
                        if handled:
                            continue

                    self.hud_view.handle_event(event)
                    self.board_view.handle_event(event, self.game_state)
                    self.word_list_view.handle_event(event)

                elif self.screen_state == "REVIEW":
                    self.review_view.handle_event(event)

                elif self.screen_state == "MASTERY":
                    self.mastery_view.handle_event(event)

            # 2. Tick Active Timers & Assists
            if self.screen_state == "PLAYING" and self.game_state and self.telemetry:
                self.game_state.tick(delta_sec)
                self.telemetry.on_tick(delta_sec)
                events = self.assists.on_tick(self.game_state, delta_sec)
                for e in events:
                    if "message" in e:
                        toast.show(e["message"], color=theme.warning, duration=3.0)

                # Dynamic Shifting Mode (subtle distractor shift every 12 seconds)
                if self.game_state.puzzle.assist_config.is_shifting:
                    if time.time() - self.last_shift_time >= 12.0:
                        self.last_shift_time = time.time()
                        GridEngine.shift_distractor_cells(self.game_state.puzzle)

                # Check timed attack timeout
                if self.game_state.status == GameStatus.TIME_OUT:
                    self._on_give_up()

            # 3. Render Views
            self.screen.fill(theme.bg)

            if self.screen_state == "MENU":
                self.menu_view.draw(self.screen)

            elif self.screen_state == "PLAYING" and self.game_state and self.telemetry:
                self.board_view.draw(
                    self.screen,
                    self.game_state,
                    keyboard_cursor=self.accessibility.grid_cursor if self.accessibility.is_keyboard_active else None,
                    selection_start_kb=self.accessibility.selection_start,
                )
                self.word_list_view.draw(self.screen, self.game_state)
                self.hud_view.draw(self.screen, self.game_state, self.telemetry)

            elif self.screen_state == "REVIEW" and self.game_state and self.telemetry:
                # Draw board in background then overlay review
                self.board_view.draw(self.screen, self.game_state)
                self.review_view.draw(self.screen, self.game_state, self.telemetry)

            elif self.screen_state == "MASTERY":
                self.mastery_view.draw(self.screen, profile_manager.profile)

            # Draw Toast overlay on top of any screen
            toast.draw(self.screen, self.width)

            pygame.display.flip()

        pygame.quit()
        sys.exit(0)
