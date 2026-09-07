"""Responsive Grid Board View with Touch/Mouse Drag Selection and Visual Highlights."""
from __future__ import annotations

import math
import time
from typing import Callable, List, Optional, Set, Tuple

import pygame

from core.game_state import GameState
from core.models import WordEntry
from gui.font_manager import font_manager
from gui.theme import theme


class BoardView:
    """Renders the word search letter grid with responsive scaling and smooth selection highlights."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 0)
        self.cell_size: int = 40
        self.grid_origin_x: int = 0
        self.grid_origin_y: int = 0

        # Mouse / Touch drag state
        self.is_dragging: bool = False
        self.drag_start_coord: Optional[Tuple[int, int]] = None
        self.drag_current_coord: Optional[Tuple[int, int]] = None

        # Callbacks
        self.on_selection_made: Optional[Callable[[Tuple[int, int], Tuple[int, int]], None]] = None
        self.on_cell_tapped: Optional[Callable[[Tuple[int, int]], None]] = None

    def update_layout(self, container_rect: pygame.Rect, rows: int, cols: int) -> None:
        """Calculates optimal cell size and centering within container bounds."""
        self.rect = container_rect
        if rows <= 0 or cols <= 0:
            return

        padding = 10
        avail_w = container_rect.width - 2 * padding
        avail_h = container_rect.height - 2 * padding

        cell_w = avail_w // cols
        cell_h = avail_h // rows
        self.cell_size = max(24, min(cell_w, cell_h, 60))

        grid_w = self.cell_size * cols
        grid_h = self.cell_size * rows
        self.grid_origin_x = container_rect.x + (container_rect.width - grid_w) // 2
        self.grid_origin_y = container_rect.y + (container_rect.height - grid_h) // 2

    def get_cell_at_pixel(self, pixel_pos: Tuple[int, int], rows: int, cols: int) -> Optional[Tuple[int, int]]:
        """Maps screen pixel coordinate (x, y) to grid (row, col)."""
        px, py = pixel_pos
        rel_x = px - self.grid_origin_x
        rel_y = py - self.grid_origin_y

        if rel_x < 0 or rel_y < 0:
            return None

        c = rel_x // self.cell_size
        r = rel_y // self.cell_size

        if 0 <= r < rows and 0 <= c < cols:
            return (int(r), int(c))
        return None

    def handle_event(self, event: pygame.event.Event, game_state: GameState) -> bool:
        """Handles mouse and touch drag selection events."""
        rows = game_state.puzzle.rows
        cols = game_state.puzzle.cols

        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            cell = self.get_cell_at_pixel(event.pos, rows, cols)
            if cell:
                self.is_dragging = True
                self.drag_start_coord = cell
                self.drag_current_coord = cell
                if self.on_cell_tapped:
                    self.on_cell_tapped(cell)
                return True

        elif event.type == pygame.MOUSEMOTION:
            if self.is_dragging:
                cell = self.get_cell_at_pixel(event.pos, rows, cols)
                if cell:
                    self.drag_current_coord = cell
                return True

        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            if self.is_dragging:
                self.is_dragging = False
                if self.drag_start_coord and self.drag_current_coord and self.on_selection_made:
                    self.on_selection_made(self.drag_start_coord, self.drag_current_coord)
                self.drag_start_coord = None
                self.drag_current_coord = None
                return True

        return False

    def draw(
        self,
        surface: pygame.Surface,
        game_state: GameState,
        keyboard_cursor: Optional[Tuple[int, int]] = None,
        selection_start_kb: Optional[Tuple[int, int]] = None,
    ) -> None:
        """Renders the grid board, background cells, found words, drag lines, and pulsating hints."""
        puzzle = game_state.puzzle
        rows = puzzle.rows
        cols = puzzle.cols
        cs = self.cell_size

        # 1. Background grid board card
        board_rect = pygame.Rect(
            self.grid_origin_x - 6,
            self.grid_origin_y - 6,
            cols * cs + 12,
            rows * cs + 12,
        )
        pygame.draw.rect(surface, theme.card_bg, board_rect, border_radius=12)
        pygame.draw.rect(surface, theme.card_border, board_rect, width=1, border_radius=12)

        # 2. Draw cell backgrounds and characters
        font_size = max(14, int(cs * 0.55))

        for r in range(rows):
            for c in range(cols):
                cell_rect = pygame.Rect(
                    self.grid_origin_x + c * cs,
                    self.grid_origin_y + r * cs,
                    cs - 2,
                    cs - 2,
                )

                # Default cell background
                pygame.draw.rect(surface, theme.grid_cell_bg, cell_rect, border_radius=6)

        # 3. Draw found word highlighter pills with distinct colors
        for idx, word_entry in enumerate(game_state.found_words):
            color = theme.get_word_color(idx)
            for r, c in word_entry.coords:
                cell_rect = pygame.Rect(
                    self.grid_origin_x + c * cs,
                    self.grid_origin_y + r * cs,
                    cs - 2,
                    cs - 2,
                )
                # Draw translucent pill
                pill_surf = pygame.Surface((cell_rect.width, cell_rect.height), pygame.SRCALPHA)
                pill_surf.fill((*color, 120))
                surface.blit(pill_surf, cell_rect.topleft)
                pygame.draw.rect(surface, color, cell_rect, width=2, border_radius=6)

        # 4. Draw active hint highlights (Tier 3, 5, 6) with pulsing animation
        if game_state.active_hint_coords:
            pulse = (math.sin(time.time() * 6.0) + 1.0) / 2.0  # 0.0 to 1.0
            pulse_alpha = int(100 + pulse * 140)
            gold_color = (250, 204, 21)

            for r, c in game_state.active_hint_coords:
                cell_rect = pygame.Rect(
                    self.grid_origin_x + c * cs,
                    self.grid_origin_y + r * cs,
                    cs - 2,
                    cs - 2,
                )
                hint_surf = pygame.Surface((cell_rect.width, cell_rect.height), pygame.SRCALPHA)
                hint_surf.fill((*gold_color, pulse_alpha))
                surface.blit(hint_surf, cell_rect.topleft)
                pygame.draw.rect(surface, gold_color, cell_rect, width=3, border_radius=6)

        # 5. Draw active drag selection rubber-band
        active_line: List[Tuple[int, int]] = []
        if self.is_dragging and self.drag_start_coord and self.drag_current_coord:
            active_line = game_state.interpolate_line(self.drag_start_coord, self.drag_current_coord)
        elif selection_start_kb and keyboard_cursor:
            active_line = game_state.interpolate_line(selection_start_kb, keyboard_cursor)

        if active_line:
            for r, c in active_line:
                cell_rect = pygame.Rect(
                    self.grid_origin_x + c * cs,
                    self.grid_origin_y + r * cs,
                    cs - 2,
                    cs - 2,
                )
                drag_surf = pygame.Surface((cell_rect.width, cell_rect.height), pygame.SRCALPHA)
                drag_surf.fill((56, 189, 248, 140))
                surface.blit(drag_surf, cell_rect.topleft)
                pygame.draw.rect(surface, (56, 189, 248), cell_rect, width=2, border_radius=6)

        # 6. Render characters on top
        for r in range(rows):
            for c in range(cols):
                char = puzzle.grid[r][c]
                center_x = self.grid_origin_x + c * cs + (cs - 2) // 2
                center_y = self.grid_origin_y + r * cs + (cs - 2) // 2

                font_manager.draw_text(
                    surface,
                    char,
                    (center_x, center_y),
                    font_size,
                    theme.grid_text,
                    bold=True,
                    align="center",
                )

        # 7. Draw keyboard cursor focus box
        if keyboard_cursor:
            kr, kc = keyboard_cursor
            cursor_rect = pygame.Rect(
                self.grid_origin_x + kc * cs,
                self.grid_origin_y + kr * cs,
                cs - 2,
                cs - 2,
            )
            pygame.draw.rect(surface, theme.cursor_border, cursor_rect, width=3, border_radius=6)
