"""Unified Entry Point for AI Multilingual Word Search."""
from __future__ import annotations

import pygame
import argparse
import sys

from config.settings import settings
from core.enums import Difficulty, GameMode
from core.grid_engine import GridEngine
from storage.pack_loader import PackLoader


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="AI Multilingual Word Search Game (Python/Pygame & Terminal CLI)"
    )
    parser.add_argument(
        "--cli",
        action="store_true",
        help="Run game in lightweight ANSI Terminal CLI mode instead of Pygame GUI.",
    )
    parser.add_argument(
        "--topic",
        type=str,
        default=None,
        help="Generate puzzle immediately for a specific topic using AI (e.g. --topic 'Astronomy')",
    )
    parser.add_argument(
        "--difficulty",
        type=str,
        choices=["easy", "medium", "hard", "expert", "dynamic"],
        default="easy",
        help="Difficulty preset level.",
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=["casual", "timed"],
        default="casual",
        help="Game mode (casual or timed).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_arguments()
    diff = Difficulty(args.difficulty)
    gmode = GameMode.TIMED_ATTACK if args.mode == "timed" else GameMode.CASUAL

    if args.cli:
        from cli.terminal_game import TerminalGame

        if args.topic:
            from ai.topic_generator import TopicGenerator

            print(f"Generating puzzle for topic: {args.topic}...")
            words_data = TopicGenerator.generate_words(args.topic, difficulty=diff.value)
            puzzle = GridEngine.generate_puzzle(
                words_data=words_data,
                title=f"AI: {args.topic}",
                theme=args.topic,
                difficulty=diff,
            )
        else:
            packs = PackLoader.get_all_available_packs()
            if not packs:
                print("No puzzle packs found in data/packs/.")
                sys.exit(1)
            print(f"Loading pack: {packs[0].title}...")
            puzzle = packs[0].get_puzzle(0, difficulty=diff)

        runner = TerminalGame(puzzle, mode=gmode)
        runner.run()
    else:
        # Launch Pygame GUI
        # Initialize SDL from the entry point before importing GUI modules.
        # Pydroid owns the Android activity context used by pygame.display.
        pygame.init()
        from gui.app import WordSearchApp

        app = WordSearchApp()
        if args.topic:
            app.start_ai_topic_puzzle(args.topic, difficulty=diff, mode=gmode, concept_mode=False)
        app.run()


if __name__ == "__main__":
    main()
