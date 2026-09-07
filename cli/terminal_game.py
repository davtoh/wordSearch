"""Terminal / CLI Text Runner for Multilingual Word Search."""
from __future__ import annotations

import sys
from typing import Optional

from assists.registry import AssistRegistry
from core.enums import Difficulty, GameMode, GameStatus
from core.game_state import GameState
from core.models import Puzzle
from storage.pack_loader import PackLoader
from telemetry.tracker import SessionTelemetry


class TerminalGame:
    """Lightweight ANSI terminal interface for playing word search puzzles in the console."""

    def __init__(self, puzzle: Puzzle, mode: GameMode = GameMode.CASUAL) -> None:
        self.game_state = GameState(puzzle, mode=mode)
        self.telemetry = SessionTelemetry()
        self.assists = AssistRegistry()

    def print_board(self) -> None:
        grid = self.game_state.puzzle.grid
        rows = self.game_state.puzzle.rows
        cols = self.game_state.puzzle.cols

        print("\n" + "=" * 50)
        print(f"  {self.game_state.puzzle.metadata.title}  [{self.game_state.puzzle.metadata.difficulty.value.upper()}]")
        print("=" * 50)

        # Print column headers
        col_header = "    " + " ".join(f"{c:2d}" for c in range(cols))
        print(col_header)
        print("   " + "-" * (cols * 3 + 1))

        # Print rows with ANSI coloring for found cells
        for r in range(rows):
            row_str = f"{r:2d} |"
            for c in range(cols):
                char = grid[r][c]
                if (r, c) in self.game_state.found_coords_map:
                    # Green text for found words
                    row_str += f" \033[92m{char}\033[0m "
                elif (r, c) in self.game_state.active_hint_coords:
                    # Yellow text for active hint
                    row_str += f" \033[93m{char}\033[0m "
                else:
                    row_str += f" {char} "
            print(row_str)

        print("-" * (cols * 3 + 5))

        # Word List
        print("\nTarget Words:")
        for idx, w in enumerate(self.game_state.puzzle.words):
            status = "✓ [FOUND]" if w.found else "  [ ]"
            clue = f" - {w.clue}" if w.clue else ""
            reading = f" ({w.reading})" if w.reading else ""
            print(f"  {status} {w.word}{reading}{clue}")

        print(f"\nStats: Time: {int(self.telemetry.active_elapsed_seconds)}s | Velocity: {self.telemetry.current_velocity:.1f}s/word | Accuracy: {int(self.telemetry.accuracy_rate)}%")
        print("Commands: '<r1> <c1> <r2> <c2>' (e.g. 0 0 0 5), 'hint', 'giveup', 'quit'")

    def run(self) -> None:
        while self.game_state.status == GameStatus.PLAYING:
            self.print_board()
            try:
                cmd = input("\nEnter move or command > ").strip().lower()
            except (EOFError, KeyboardInterrupt):
                print("\nExiting.")
                break

            if not cmd:
                continue
            if cmd in ("quit", "q", "exit"):
                break
            elif cmd in ("giveup", "surrender"):
                self.game_state.give_up()
                print("\nAll words revealed:")
                self.print_board()
                break
            elif cmd == "hint":
                res = self.assists.hints.request_hint(self.game_state)
                if res:
                    self.telemetry.record_hint_used()
                    print(f"\n💡 Hint: {res.message}")
            else:
                parts = cmd.split()
                if len(parts) == 4 and all(p.lstrip("-").isdigit() for p in parts):
                    r1, c1, r2, c2 = map(int, parts)
                    valid, word_entry, _ = self.game_state.check_selection((r1, c1), (r2, c2))
                    self.telemetry.record_selection_attempt(valid, word_entry.word if word_entry else None)
                    if valid and word_entry:
                        interval = self.telemetry.record_word_found(word_entry)
                        print(f"\n🎉 Correct! Found '{word_entry.word}' in {interval:.1f}s!")
                    else:
                        print("\n❌ Invalid selection or no word found along that line.")
                else:
                    print("\nUnrecognized input. Enter 4 integers: r1 c1 r2 c2, or 'hint', 'giveup', 'quit'.")

        if self.game_state.status == GameStatus.WON:
            print("\n" + "🌟" * 20)
            print("CONGRATULATIONS! You solved the entire puzzle!")
            print(f"Total Time: {int(self.telemetry.active_elapsed_seconds)}s")
            print(f"Accuracy: {int(self.telemetry.accuracy_rate)}%")
            print("🌟" * 20)
