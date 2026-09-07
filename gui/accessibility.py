"""Keyboard and Tab Accessibility Controller for Mouseless Navigation."""
from __future__ import annotations

from typing import Callable, List, Optional, Tuple

import pygame


class AccessibilityController:
    """Manages keyboard focus, Tab cycles, and grid cursor navigation for accessibility."""

    def __init__(self) -> None:
        self.grid_cursor: Tuple[int, int] = (0, 0)
        self.selection_start: Optional[Tuple[int, int]] = None
        self.is_keyboard_active: bool = False

        self.tab_targets: List[Tuple[str, pygame.Rect, Callable[[], None]]] = []
        self.focused_target_index: int = -1

    def reset_grid(self, rows: int, cols: int) -> None:
        self.grid_cursor = (0, 0)
        self.selection_start = None

    def register_tab_target(
        self, name: str, rect: pygame.Rect, callback: Callable[[], None]
    ) -> None:
        self.tab_targets.append((name, rect, callback))

    def clear_tab_targets(self) -> None:
        self.tab_targets.clear()

    def handle_key_down(
        self,
        event: pygame.event.Event,
        rows: int,
        cols: int,
        on_selection_confirm: Optional[Callable[[Tuple[int, int], Tuple[int, int]], None]] = None,
    ) -> bool:
        """Processes keyboard navigation events (Tab, Arrows, Space, Enter, Escape)."""
        self.is_keyboard_active = True
        r, c = self.grid_cursor

        if event.key == pygame.K_TAB:
            # Cycle through UI buttons
            if not self.tab_targets:
                return False
            shift_held = bool(pygame.key.get_mods() & pygame.KMOD_SHIFT)
            if shift_held:
                self.focused_target_index = (self.focused_target_index - 1) % len(self.tab_targets)
            else:
                self.focused_target_index = (self.focused_target_index + 1) % len(self.tab_targets)
            return True

        elif event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
            # If a UI button is focused with Tab, trigger it
            if 0 <= self.focused_target_index < len(self.tab_targets):
                name, rect, callback = self.tab_targets[self.focused_target_index]
                if callback:
                    callback()
                return True

            # Otherwise, toggle grid drag selection
            if self.selection_start is None:
                self.selection_start = (r, c)
            else:
                if on_selection_confirm:
                    on_selection_confirm(self.selection_start, (r, c))
                self.selection_start = None
            return True

        elif event.key == pygame.K_SPACE:
            if self.selection_start is None:
                self.selection_start = (r, c)
            else:
                if on_selection_confirm:
                    on_selection_confirm(self.selection_start, (r, c))
                self.selection_start = None
            return True

        elif event.key == pygame.K_ESCAPE:
            self.selection_start = None
            self.focused_target_index = -1
            return True

        # Grid arrow navigation
        elif event.key in (pygame.K_UP, pygame.K_w):
            self.grid_cursor = (max(0, r - 1), c)
            self.focused_target_index = -1
            return True

        elif event.key in (pygame.K_DOWN, pygame.K_s):
            self.grid_cursor = (min(rows - 1, r + 1), c)
            self.focused_target_index = -1
            return True

        elif event.key in (pygame.K_LEFT, pygame.K_a):
            self.grid_cursor = (r, max(0, c - 1))
            self.focused_target_index = -1
            return True

        elif event.key in (pygame.K_RIGHT, pygame.K_d):
            self.grid_cursor = (r, min(cols - 1, c + 1))
            self.focused_target_index = -1
            return True

        return False
