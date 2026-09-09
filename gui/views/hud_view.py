"""Top Status HUD Bar with Timer, Velocity, Accuracy, and Action Controls."""
from __future__ import annotations

from typing import Callable, Optional

import pygame

from core.enums import GameMode, GameStatus
from core.game_state import GameState
from gui.font_manager import font_manager
from gui.theme import theme
from gui.widgets.button import Button
from telemetry.tracker import SessionTelemetry


class HudView:
    """Renders the top navigation bar with live telemetry and control buttons."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 56)
        self.btn_menu = Button((0, 0, 80, 36), "Menu", is_secondary=True)
        self.btn_pause = Button((0, 0, 80, 36), "Pause", is_secondary=True)
        self.btn_hint = Button((0, 0, 88, 36), "💡 Hint", is_secondary=False)
        self.btn_giveup = Button((0, 0, 90, 36), "Give Up", is_secondary=True)
        self.btn_theme = Button((0, 0, 44, 36), "🌓", is_secondary=True)

    def update_layout(self, width: int) -> None:
        self.rect = pygame.Rect(0, 0, width, 56)
        self.btn_menu.rect = pygame.Rect(12, 10, 76, 36)
        self.btn_pause.rect = pygame.Rect(96, 10, 76, 36)
        self.btn_theme.rect = pygame.Rect(180, 10, 44, 36)

        # Right-aligned buttons
        self.btn_giveup.rect = pygame.Rect(width - 96, 10, 86, 36)
        self.btn_hint.rect = pygame.Rect(width - 192, 10, 88, 36)

    def handle_event(self, event: pygame.event.Event) -> bool:
        if self.btn_menu.handle_event(event):
            return True
        if self.btn_pause.handle_event(event):
            return True
        if self.btn_hint.handle_event(event):
            return True
        if self.btn_giveup.handle_event(event):
            return True
        if self.btn_theme.handle_event(event):
            return True
        return False

    def draw(
        self,
        surface: pygame.Surface,
        game_state: GameState,
        telemetry: SessionTelemetry,
    ) -> None:
        # HUD background bar
        pygame.draw.rect(surface, theme.card_bg, self.rect)
        pygame.draw.line(surface, theme.card_border, self.rect.bottomleft, self.rect.bottomright, 1)

        # Update pause button label
        self.btn_pause.text = "Resume" if game_state.status == GameStatus.PAUSED else "Pause"

        # Draw buttons
        self.btn_menu.draw(surface)
        self.btn_pause.draw(surface)
        self.btn_theme.draw(surface)
        self.btn_hint.draw(surface)
        self.btn_giveup.draw(surface)

        # Center Telemetry Gauges
        center_x = self.rect.centerx
        y = self.rect.centery

        # 1. Timer
        if game_state.mode == GameMode.TIMED_ATTACK:
            time_left = max(0, int(game_state.time_remaining))
            mins, secs = divmod(time_left, 60)
            time_str = f"⏱️ {mins:02d}:{secs:02d}"
            timer_color = theme.danger if time_left <= 30 else theme.accent
        else:
            elapsed = int(telemetry.active_elapsed_seconds)
            mins, secs = divmod(elapsed, 60)
            time_str = f"⏱️ {mins:02d}:{secs:02d}"
            timer_color = theme.text_primary

        font_manager.draw_text(
            surface,
            time_str,
            (center_x - 120, y),
            18,
            timer_color,
            bold=True,
            align="center",
        )

        # 2. Velocity
        vel = telemetry.current_velocity
        vel_str = f"⚡ {vel:.1f}s/w" if vel > 0 else "⚡ --"
        font_manager.draw_text(
            surface,
            vel_str,
            (center_x, y),
            16,
            theme.text_secondary,
            bold=True,
            align="center",
        )

        # 3. Accuracy
        acc = telemetry.accuracy_rate
        font_manager.draw_text(
            surface,
            f"🎯 {int(acc)}%",
            (center_x + 110, y),
            16,
            theme.text_secondary,
            bold=True,
            align="center",
        )
