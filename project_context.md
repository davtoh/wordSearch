.env.example
---
# Environment Configuration for AI Word Search Game
# Copy this file to .env and set your Gemini API key:
#   cp .env.example .env

GEMINI_API_KEY=your_gemini_api_key_here


---
.gitignore
---
# Python bytecode
__pycache__/
*.py[cod]
*$py.class

# Virtual environments
.venv/
venv/
env/
.env

# Editor and OS junk
.DS_Store
.vscode/

# Local test/cache artifacts
.pytest_cache/
.mypy_cache/
.ruff_cache/

# Distribution/build outputs
build/
dist/
*.egg-info/

# Logs and databases
*.log
assets/
*.json

---
README.md
---
# 🔍 AI Multilingual Word Search Game

An adaptive, multilingual, AI-powered Word Search game built in **Python 3.12** with **Pygame**, featuring Google Gemini AI topic & text concept extraction, UTF-8/CJK script support (*Japanese Hiragana, Katakana, Kanji, Spanish accents, Cyrillic*), dynamic grid sizing, timed attack mode, **pluggable assists (throttled proximity & 6-tier modular hints)**, a **dedicated Learning & Vocabulary Mastery module**, keyboard/Tab accessibility, and a cross-platform migration roadmap to **Flutter / Android Play Store**.

---

## ✨ Key Features

- **Multilingual & CJK Script Engine**: Native support for English, Spanish (*Á, É, Í, Ó, Ú, Ñ, Ü*), Japanese Hiragana (*あ-ん*), Katakana (*ア-ン*), Kanji (*常用漢字*), and Cyrillic. Distractor filler characters automatically match the puzzle's script.
- **AI-Powered Generation (Google Gemini)**:
  - **Topic Generator**: Generate custom word searches with educational definitions for any topic (*e.g., "Quantum Physics", "JLPT N5 Verbs", "Marine Biology"*).
  - **Text Concept Extractor**: Paste articles or notes to extract key vocabulary concepts and definitions.
- **Offline JSON Puzzle Packages**: Pre-bundled offline packs (`Cosmos & Computing`, `Ciencia en Español`, `Basic Japanese Hiragana`, `Essential Kanji`). Custom packs can be created, edited, imported, or exported freely as `.pack.json`.
- **Pluggable Assists & 6-Tier Hints**:
  - **Tier 1**: Concept Clue / Definition
  - **Tier 2**: Target Word Name revealed
  - **Tier 3**: Starting character + word length (*without coordinates*)
  - **Tier 4**: Placement orientation (*e.g., "Diagonal Down-Right"*)
  - **Tier 5**: Starting grid coordinate pinpoint pulse
  - **Tier 6**: Full word solution glow
  - **Proximity Radar**: Throttled "Hot & Cold" feedback when tapping or inspecting cells.
- **Learning & Vocabulary Mastery Module**:
  - Spaced repetition tracker classifying words as `🌟 MASTERED`, `📖 LEARNING`, or `⚠️ NEEDS PRACTICE`.
  - **Study Deck & Glossary**: Searchable and filterable vocabulary glossary.
  - **Targeted Practice Generator**: One-click custom puzzle generator focused on words you found difficult.
- **Timed Attack & Bonus Time**: Countdown timer with overtime reward mechanics (+seconds per found word) and emergency time boosts.
- **Give Up & Learn Mode**: Surrender anytime to reveal all word locations on the board and open an educational review glossary.
- **Focus-Aware Telemetry**: Auto-pauses timers on window blur (`pygame.ACTIVEEVENT` / `WINDOWFOCUSLOST`) so multitasking on PC/phone does not penalize velocity metrics.
- **Accessibility & Themes**: Native Dark Mode (default) and Light Mode, plus full keyboard/Tab navigation (`Tab`, `Arrows`, `Space`/`Enter`).
- **Pydroid 3 & PC Ready**: Runs seamlessly on desktop (macOS/Windows/Linux) and mobile phones via Pydroid 3.

---

## 🚀 Quickstart Guide

### 1. Setup Python 3.12 Virtual Environment

```bash
# Clone or navigate to the repository
cd wordSearch

# Create Python 3.12 virtual environment
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Gemini API Key (Optional for AI Generation)

```bash
cp .env.example .env
```
Edit `.env` and insert your Gemini API key:
```bash
GEMINI_API_KEY=your_actual_gemini_api_key_here
```
*(Note: If no API key is provided, the game seamlessly runs all offline bundled packs and uses local frequency extraction fallback!)*

### 3. Launch the Game

```bash
# Launch Pygame Graphical Interface
python main.py

# Launch Lightweight Terminal / CLI Mode
python main.py --cli

# Generate an AI topic puzzle directly from CLI
python main.py --cli --topic "Astronomy" --difficulty medium
```

---

## 📦 Required Fonts

The project includes an `assets/fonts/` directory containing the following font files:

- `NotoColorEmoji.ttf` – provides full emoji support.
- `NotoEmoji-Regular.ttf` – additional emoji glyphs.
- `Symbola.otf` / `Symbola.ttf` – fallback for various symbols and icons.

These fonts are required for proper rendering of emojis and special symbols used throughout the UI (e.g., 📚, ▶, 🎮). If the `assets/fonts/` directory is missing, download the fonts from the official sources:

- **Noto Color Emoji**: https://github.com/googlefonts/noto-emoji/releases
- **Noto Emoji**: https://github.com/googlefonts/noto-emoji/releases
- **Symbola**: https://github.com/konsumer/symbola

After downloading, place the `.ttf`/`.otf` files into `assets/fonts/`. The repository’s `.gitignore` already excludes the `assets/` directory to keep the repo lightweight.

## 🎮 How to Play

### In Pygame GUI:
- **Mouse / Touch Drag**: Click/touch and drag across the start and end letters of a word. Supports all 8 straight-line directions (forward and reverse).
- **Proximity Radar**: Click/tap single cells to see if you are close to an unfound word ("Burning Hot", "Warm", "Cold").
- **Hints**: Click the top **💡 Hint** button or the individual **💡** button on any word card in the drawer.
- **Give Up**: Click **Give Up** to reveal all remaining words and view the concept glossary review.
- **Keyboard Navigation**:
  - `Tab` / `Shift-Tab`: Cycle between interactive buttons.
  - `Arrow Keys` / `WASD`: Move grid cursor.
  - `Space` / `Enter`: Start and confirm drag selection.
  - `Escape`: Cancel selection.

---

## 📁 Package Architecture

```text
wordSearch/
├── main.py                          # Unified entrypoint (GUI or --cli)
├── config/                          # Game settings and difficulty presets
│   ├── settings.py                  # Settings manager
│   ├── difficulty_presets.json      # Easy, Medium, Hard, Expert, Dynamic presets
│   └── default_config.json          # Default configuration
├── core/                            # Pure UI-Agnostic Core Engine
│   ├── models.py                    # Pydantic models (Puzzle, WordEntry, Metadata)
│   ├── enums.py                     # Enums (ScriptType, Difficulty, Direction, HintTier)
│   ├── scripts.py                   # Script pools (Latin, Spanish, Hiragana, Katakana, Kanji, Cyrillic)
│   ├── grid_engine.py               # Auto-sizing, placement, script filler, dynamic shift
│   └── game_state.py                # Game state machine (selection line, timed attack, give-up)
├── assists/                         # Pluggable Assist & Hint Engine
│   ├── base.py                      # BaseAssistProvider interface
│   ├── registry.py                  # AssistRegistry (dispatch & throttling)
│   ├── progressive_hints.py         # 6-Tier Hint Provider
│   ├── proximity_assist.py          # Throttled/Cached Proximity "Hot & Cold"
│   ├── time_bonus_assist.py         # Overtime bonus (+seconds on word find)
│   └── auto_stall_detector.py       # Inactivity / stall detector
├── learning/                        # Vocabulary Mastery & Spaced Learning
│   ├── mastery_tracker.py           # Classifies MASTERED, LEARNING, NEEDS_PRACTICE
│   ├── vocabulary_deck.py           # Searchable glossary deck
│   └── adaptive_recommender.py      # Targeted practice generator for difficult words
├── telemetry/                       # Focus-Aware Session Metrics & Profile Persistence
│   ├── tracker.py                   # Velocity, accuracy, window blur pause handling
│   └── profile_manager.py           # Saves data/player_profile.json
├── ai/                              # Google Gemini AI Integration
│   ├── gemini_client.py             # SDK / REST fallback client
│   ├── topic_generator.py           # AI Topic -> Words + Definitions
│   └── text_extractor.py            # AI Raw Text -> Key Concepts + Definitions
├── storage/                         # Package & File I/O
│   ├── pack_loader.py               # Discovers and loads .pack.json files
│   └── pack_exporter.py             # Exports single puzzles and custom packs
├── data/                            # Standalone JSON Data
│   ├── packs/                       # Pre-bundled offline packages
│   │   ├── english_science.pack.json
│   │   ├── spanish_general.pack.json
│   │   ├── japanese_basics.pack.json
│   │   └── japanese_kanji.pack.json
│   ├── user_packs/                  # Directory for custom user packs
│   └── player_profile.json          # Lifetime player stats & vocabulary deck
├── gui/                             # Responsive Pygame UI
│   ├── app.py                       # Main Pygame event loop & state router
│   ├── font_manager.py              # Multilingual Unicode / CJK font loader
│   ├── theme.py                     # Dark / Light mode color palettes
│   ├── accessibility.py             # Keyboard / Tab navigation controller
│   ├── views/                       # BoardView, WordListView, HudView, ReviewView, MasteryView, MenuView
│   └── widgets/                     # Button, Toast, InputBox
├── cli/                             # Lightweight Terminal Runner
│   └── terminal_game.py             # ANSI text console player
├── tests/                           # Complete pytest unit test suite (20 tests)
└── docs/                            # Documentation
    ├── FLUTTER_MIGRATION_ROADMAP.md # Blueprint for Flutter/Dart & Play Store release
    ├── JSON_SCHEMA_SPEC.md          # Open JSON Specification
    └── ANDROID_PYDROID3_GUIDE.md    # Instructions for running in Pydroid 3
```

---

## 🧪 Running Tests

```bash
pytest tests/ -v
```

All 20 automated tests validate:
- UTF-8 and CJK script placement (*Latin, Spanish accents, Hiragana, Katakana, Kanji*).
- Directional placement restrictions and dynamic distractor shifting.
- Timed Attack countdown, overtime bonus addition, and straight-line selection checks.
- 6-tier progressive hint escalation and proximity calculations.
- Vocabulary mastery classification and targeted practice recommendations.
- Focus-aware active time tracking during window blur / app switching.
- JSON puzzle pack loading and serialization round-trips.

---

## 📱 Cross-Platform Migration to Flutter

See [docs/FLUTTER_MIGRATION_ROADMAP.md](docs/FLUTTER_MIGRATION_ROADMAP.md) for complete details on porting the core engine to Dart, rendering the grid with `CustomPainter`, and publishing to Google Play Store and iOS App Store.


---
ai/__init__.py
---


---
ai/gemini_client.py
---
"""Gemini API Client for AI Word Search Generation."""
from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
import dotenv
import requests

# Load .env file from project root
dotenv.load_dotenv(Path(__file__).parent.parent / ".env")


class GeminiClient:
    """Communicates with Google Gemini API using official SDK or direct REST fallback."""

    def __init__(self, api_key: Optional[str] = None) -> None:
        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        self.model_name = "gemini-2.5-flash"

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.api_key.strip() and not self.api_key.startswith("your_"))

    def generate_json_content(self, system_instruction: str, prompt: str) -> Optional[List[Dict[str, Any]]]:
        """Generates structured JSON list of word entries via Gemini."""
        if not self.is_configured:
            return None

        # 1. Try google-genai SDK if installed
        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=self.api_key)
            response = client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    response_mime_type="application/json",
                    temperature=0.7,
                ),
            )
            if response.text:
                return json.loads(response.text)
        except Exception as sdk_err:
            # Fall back to direct REST request if SDK fails
            pass

        # 2. REST Fallback
        try:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model_name}:generateContent?key={self.api_key}"
            payload = {
                "contents": [{"parts": [{"text": prompt}]}],
                "systemInstruction": {"parts": [{"text": system_instruction}]},
                "generationConfig": {
                    "responseMimeType": "application/json",
                    "temperature": 0.7,
                },
            }
            resp = requests.post(url, json=payload, timeout=20)
            if resp.status_code == 200:
                data = resp.json()
                text = data["candidates"][0]["content"]["parts"][0]["text"]
                return json.loads(text)
        except Exception as rest_err:
            print(f"Gemini API request failed: {rest_err}")

        return None


# Global singleton instance
gemini_client = GeminiClient()


---
ai/text_extractor.py
---
"""Raw Text Concept and Vocabulary Extractor using Gemini AI."""
from __future__ import annotations

import re
from collections import Counter
from typing import Any, Dict, List
from config.settings import settings

from ai.gemini_client import gemini_client


class TextExtractor:
    """Extracts key vocabulary, domain terms, and definitions from user-pasted text/notes."""

    @staticmethod
    def extract_from_text(
        raw_text: str,
        language: str = settings.get("default_language", "en"),
        count: int = settings.get("default_vocabulary_count", 10),
    ) -> List[Dict[str, Any]]:
        """Extracts key vocabulary words and generates educational clues from input text."""
        if not raw_text.strip():
            return []

        system_instruction = (
            "You are an advanced text analysis and educational concept extraction assistant. "
            "Given a passage of text (such as student notes, technical documentation, or an article), "
            "extract the most important keywords, technical concepts, and domain terms to turn into a word search puzzle. "
            "Output MUST be valid JSON: an array of objects where each object has: "
            "'word' (string, single word, uppercase, 3-12 characters), "
            "'clue' (string, concise definition based on the text context, 1 sentence), "
            "'reading' (string, phonetic reading if applicable, else null)."
        )

        prompt = (
            f"Analyze the following text and extract up to {count} key concepts/vocabulary terms:\n"
            f"Language: {language}\n\n"
            f"--- TEXT START ---\n{raw_text[:4000]}\n--- TEXT END ---\n"
        )

        result = gemini_client.generate_json_content(system_instruction, prompt)
        if isinstance(result, list) and len(result) > 0:
            cleaned = []
            for item in result:
                if isinstance(item, dict) and "word" in item:
                    cleaned.append({
                        "word": str(item["word"]).strip(),
                        "clue": str(item.get("clue", "Extracted from source text.")),
                        "reading": item.get("reading"),
                    })
            if cleaned:
                return cleaned

        # Fallback offline extraction using frequency analysis
        return TextExtractor._offline_fallback_extractor(raw_text, count)

    @staticmethod
    def _offline_fallback_extractor(raw_text: str, count: int) -> List[Dict[str, Any]]:
        """Extracts most frequent substantial words from raw text."""
        words = re.findall(r"\b[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]{4,12}\b", raw_text)
        stopwords = {
            "this", "that", "with", "from", "have", "were", "they", "will", "would",
            "there", "their", "about", "which", "could", "other", "these", "after",
            "este", "esta", "como", "para", "pero", "sobre", "entre", "cuando", "desde"
        }
        filtered = [w.upper() for w in words if w.lower() not in stopwords]
        common = Counter(filtered).most_common(count)

        return [
            {
                "word": word,
                "clue": f"Key term appearing {freq} times in source text.",
                "reading": None,
            }
            for word, freq in common
        ]


---
ai/topic_generator.py
---
"""AI-Powered Topic and Subject Word Search Generator."""
from __future__ import annotations

from typing import Any, Dict, List
from config.settings import settings

from ai.gemini_client import gemini_client
from core.enums import Difficulty


class TopicGenerator:
    """Generates thematic vocabulary words and educational clues using Gemini AI."""

    @staticmethod
    def generate_words(
        topic: str,
        language: str = settings.get("default_language", "en"),
        count: int = settings.get("default_vocabulary_count", 10),
        difficulty: str = settings.get("default_difficulty", Difficulty.EASY),
        script: str = settings.get("default_script", "latin"),
    ) -> List[Dict[str, Any]]:
        """Generates a structured list of words and clues for a requested topic."""
        system_instruction = (
            "You are an expert educational game designer and lexicographer. "
            "Your task is to generate a list of vocabulary words and concise educational clues/definitions for a word search puzzle. "
            "Output MUST be valid JSON: an array of objects where each object has keys: "
            "'word' (string, single word, uppercase if latin/cyrillic, no spaces/hyphens), "
            "'clue' (string, concise definition or conceptual question, 1-2 sentences), "
            "'reading' (string, phonetic reading or romaji if non-latin, else null). "
            "Length of each word must be between 3 and 12 characters."
        )

        prompt = (
            f"Generate {count} engaging vocabulary words related to the topic '{topic}'.\n"
            f"Language: {language}\n"
            f"Script: {script}\n"
            f"Difficulty level: {difficulty}\n"
            "Ensure the words are relevant, educational, and fun to search for."
        )

        result = gemini_client.generate_json_content(system_instruction, prompt)
        if isinstance(result, list) and len(result) > 0:
            cleaned = []
            for item in result:
                if isinstance(item, dict) and "word" in item:
                    cleaned.append({
                        "word": str(item["word"]).strip(),
                        "clue": str(item.get("clue", f"Concept related to {topic}")),
                        "reading": item.get("reading"),
                    })
            if cleaned:
                return cleaned

        # Fallback offline generation if API is unavailable
        return TopicGenerator._offline_fallback(topic, language, count)

    @staticmethod
    def _offline_fallback(topic: str, language: str, count: int) -> List[Dict[str, Any]]:
        """Provides default words if AI call is offline."""
        defaults = [
            {"word": "SEARCH", "clue": "To look into or through carefully in order to find something."},
            {"word": "PUZZLE", "clue": "A game, toy, or problem designed to test ingenuity or knowledge."},
            {"word": "DISCOVERY", "clue": "The act of finding or learning something for the first time."},
            {"word": "EXPLORE", "clue": "To travel in or through an unfamiliar area to learn about it."},
            {"word": "VOCABULARY", "clue": "The body of words used in a particular language or topic."},
            {"word": "LEARNING", "clue": "The acquisition of knowledge or skills through experience or study."},
            {"word": "INSIGHT", "clue": "An accurate and deep intuitive understanding of a person or thing."},
            {"word": "CONCEPT", "clue": "An abstract idea or a general notion."},
        ]
        return defaults[:count]


---
assists/__init__.py
---


---
assists/auto_stall_detector.py
---
"""Auto Stall and Player Inactivity Assist Detector."""
from __future__ import annotations

from typing import Any, Dict, Optional

from assists.base import BaseAssistProvider
from core.game_state import GameState
from core.models import AssistConfig, WordEntry
from config.settings import settings


class AutoStallDetector(BaseAssistProvider):
    """Detects when player has stalled or struggled and prompts an assistance reminder."""

    def __init__(self, stall_threshold_seconds: float = None) -> None:
        self.stall_threshold = stall_threshold_seconds or settings.get("auto_stall_hint_seconds", 45.0)
        self.seconds_since_last_find = 0.0
        self.stall_triggered = False

    @property
    def name(self) -> str:
        return "auto_stall_detector"

    def is_enabled(self, config: AssistConfig) -> bool:
        return True

    def on_tick(self, game_state: GameState, delta_seconds: float) -> Optional[Dict[str, Any]]:
        self.seconds_since_last_find += delta_seconds
        if (
            self.seconds_since_last_find >= self.stall_threshold
            and not self.stall_triggered
            and not game_state.puzzle.is_complete
        ):
            self.stall_triggered = True
            return {
                "stalled": True,
                "seconds_idle": round(self.seconds_since_last_find, 1),
                "message": "Need a hint? Press the Clue button or tap on a word in the list!",
            }
        return None

    def on_word_found(self, game_state: GameState, word: WordEntry) -> None:
        self.seconds_since_last_find = 0.0
        self.stall_triggered = False

    def reset(self) -> None:
        self.seconds_since_last_find = 0.0
        self.stall_triggered = False


---
assists/base.py
---
"""Abstract Base Interface for Pluggable Assist Providers."""
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, Tuple

from core.game_state import GameState
from core.models import AssistConfig, WordEntry


class BaseAssistProvider(ABC):
    """Base interface for gameplay aids, hint mechanisms, and performance throttled assists."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Unique identifier name of the assist provider."""
        pass

    @abstractmethod
    def is_enabled(self, config: AssistConfig) -> bool:
        """Checks if this assist provider is enabled in the active configuration."""
        pass

    def on_tick(self, game_state: GameState, delta_seconds: float) -> Optional[Dict[str, Any]]:
        """Called on each game loop tick (optional)."""
        return None

    def on_cell_clicked(
        self, game_state: GameState, coord: Tuple[int, int]
    ) -> Optional[Dict[str, Any]]:
        """Called when a user clicks/taps a cell on the grid (optional)."""
        return None

    def on_word_found(self, game_state: GameState, word: WordEntry) -> None:
        """Called when a word is successfully found (optional)."""
        pass


---
assists/progressive_hints.py
---
"""Progressive 6-Tier Modular Hint Provider."""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from assists.base import BaseAssistProvider
from core.enums import HintTier
from core.game_state import GameState
from core.models import AssistConfig, WordEntry


class ProgressiveHintResult:
    def __init__(
        self,
        word_entry: WordEntry,
        tier: HintTier,
        message: str,
        highlight_coords: List[Tuple[int, int]],
    ) -> None:
        self.word_entry = word_entry
        self.tier = tier
        self.message = message
        self.highlight_coords = highlight_coords

    def to_dict(self) -> Dict[str, Any]:
        return {
            "word": self.word_entry.word,
            "tier": int(self.tier),
            "tier_name": self.tier.name,
            "message": self.message,
            "highlight_coords": self.highlight_coords,
        }


class ProgressiveHintProvider(BaseAssistProvider):
    """Provides granular, step-by-step hints from clues to full word glow."""

    @property
    def name(self) -> str:
        return "progressive_hints"

    def is_enabled(self, config: AssistConfig) -> bool:
        return len(config.allowed_hint_tiers) > 0

    def request_hint(
        self, game_state: GameState, target_word_str: Optional[str] = None
    ) -> Optional[ProgressiveHintResult]:
        """
        Escalates or provides the next hint level for a target word, or picks the first unfound word.
        Respects puzzle assist_config.allowed_hint_tiers.
        """
        unfound_words = [w for w in game_state.puzzle.words if not w.found]
        if not unfound_words:
            return None

        # Select target word
        target: Optional[WordEntry] = None
        if target_word_str:
            for w in unfound_words:
                if w.word == target_word_str:
                    target = w
                    break
        if not target:
            target = unfound_words[0]

        allowed_tiers = sorted(game_state.puzzle.assist_config.allowed_hint_tiers)
        if not allowed_tiers:
            return None

        # Determine next allowed tier
        current_tier_int = int(target.hint_tier_used)
        next_tiers = [t for t in allowed_tiers if t > current_tier_int]

        if next_tiers:
            next_tier = HintTier(next_tiers[0])
        else:
            # Already at maximum allowed tier, return info for current tier
            next_tier = target.hint_tier_used if target.hint_tier_used != HintTier.NONE else HintTier(allowed_tiers[-1])

        target.hint_tier_used = next_tier

        # Generate hint payload
        msg = ""
        highlight_coords: List[Tuple[int, int]] = []

        if next_tier == HintTier.TIER_1_CLUE:
            msg = f"Clue: {target.clue or 'No clue available for this word.'}"

        elif next_tier == HintTier.TIER_2_WORD_NAME:
            msg = f"Word: '{target.word}' ({len(target.word)} letters)"
            if target.reading:
                msg += f" [Reading: {target.reading}]"

        elif next_tier == HintTier.TIER_3_FIRST_LETTER:
            first_char = target.word[0] if target.word else "?"
            msg = f"Starts with '{first_char}' ({len(target.word)} letters)"

        elif next_tier == HintTier.TIER_4_ORIENTATION:
            dir_name = target.direction.human_readable if target.direction else "Unknown"
            msg = f"Word '{target.word}' is placed {dir_name}"

        elif next_tier == HintTier.TIER_5_START_COORDINATE:
            if target.start_coord:
                r, c = target.start_coord
                highlight_coords = [(r, c)]
                msg = f"'{target.word}' starts at Row {r + 1}, Col {c + 1}"
                game_state.active_hint_coords = set(highlight_coords)
                game_state.active_hint_word = target

        elif next_tier == HintTier.TIER_6_FULL_GLOW:
            highlight_coords = list(target.coords)
            msg = f"Revealing path for '{target.word}'"
            game_state.active_hint_coords = set(highlight_coords)
            game_state.active_hint_word = target

        return ProgressiveHintResult(target, next_tier, msg, highlight_coords)


---
assists/proximity_assist.py
---
"""Throttled and Cached Proximity 'Hot & Cold' Assist Provider."""
from __future__ import annotations

import time
from typing import Any, Dict, Optional, Tuple

from assists.base import BaseAssistProvider
from core.game_state import GameState
from core.models import AssistConfig


class ProximityAssistProvider(BaseAssistProvider):
    """Provides real-time, low-overhead proximity feedback when tapping or inspecting cells."""

    def __init__(self, throttle_interval_seconds: float = 0.10) -> None:
        self.throttle_interval = throttle_interval_seconds
        self._last_calc_time = 0.0
        self._cached_coord: Optional[Tuple[int, int]] = None
        self._cached_result: Optional[Dict[str, Any]] = None

    @property
    def name(self) -> str:
        return "proximity_assist"

    def is_enabled(self, config: AssistConfig) -> bool:
        return config.proximity_enabled

    def on_cell_clicked(
        self, game_state: GameState, coord: Tuple[int, int]
    ) -> Optional[Dict[str, Any]]:
        return self.calculate_proximity(game_state, coord)

    def calculate_proximity(
        self, game_state: GameState, coord: Tuple[int, int]
    ) -> Optional[Dict[str, Any]]:
        """Calculates proximity distance with throttling and caching."""
        if not self.is_enabled(game_state.puzzle.assist_config):
            return None

        now = time.time()
        # Return cache if coordinate is identical and within throttle window
        if self._cached_coord == coord and (now - self._last_calc_time) < self.throttle_interval:
            return self._cached_result

        self._last_calc_time = now
        self._cached_coord = coord

        dist = game_state.get_nearest_unfound_word_distance(coord)
        if dist is None:
            self._cached_result = None
            return None

        if dist <= 1.0:
            status = "BURNING"
            message = "🔥 Burning Hot! A word starts right here!"
            color = (255, 60, 60)
        elif dist <= 2.0:
            status = "HOT"
            message = "⚡ Hot! Very close to a word start."
            color = (255, 140, 0)
        elif dist <= 3.5:
            status = "WARM"
            message = "✨ Warm... in the right neighborhood."
            color = (255, 215, 0)
        elif dist <= 5.0:
            status = "COOL"
            message = "❄️ Cool. Still a bit far."
            color = (100, 180, 255)
        else:
            status = "COLD"
            message = "🧊 Cold."
            color = (150, 150, 180)

        result = {
            "status": status,
            "distance": round(dist, 2),
            "message": message,
            "color": color,
            "coord": coord,
        }
        self._cached_result = result
        return result


---
assists/registry.py
---
"""Pluggable Assist Registry for Dispatching Game Assists."""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from assists.auto_stall_detector import AutoStallDetector
from assists.base import BaseAssistProvider
from assists.progressive_hints import ProgressiveHintProvider
from assists.proximity_assist import ProximityAssistProvider
from assists.time_bonus_assist import TimeBonusAssistProvider
from core.game_state import GameState
from core.models import WordEntry
from config.settings import settings


class AssistRegistry:
    """Central registry that coordinates all active assist and hint providers."""

    def __init__(self) -> None:
        self.providers: Dict[str, BaseAssistProvider] = {}
        self.hints = ProgressiveHintProvider()
        self.proximity = ProximityAssistProvider()
        self.time_bonus = TimeBonusAssistProvider()
        self.stall_detector = AutoStallDetector()

        self.register(self.hints)
        if settings.get("proximity_assist_enabled", True):
            self.register(self.proximity)
        self.register(self.time_bonus)
        self.register(self.stall_detector)

    def register(self, provider: BaseAssistProvider) -> None:
        self.providers[provider.name] = provider

    def get(self, name: str) -> Optional[BaseAssistProvider]:
        return self.providers.get(name)

    def on_tick(self, game_state: GameState, delta_seconds: float) -> List[Dict[str, Any]]:
        events = []
        for provider in self.providers.values():
            if provider.is_enabled(game_state.puzzle.assist_config):
                res = provider.on_tick(game_state, delta_seconds)
                if res:
                    events.append(res)
        return events

    def on_cell_clicked(
        self, game_state: GameState, coord: Tuple[int, int]
    ) -> List[Dict[str, Any]]:
        events = []
        for provider in self.providers.values():
            if provider.is_enabled(game_state.puzzle.assist_config):
                res = provider.on_cell_clicked(game_state, coord)
                if res:
                    events.append(res)
        return events

    def on_word_found(self, game_state: GameState, word: WordEntry) -> None:
        for provider in self.providers.values():
            if provider.is_enabled(game_state.puzzle.assist_config):
                provider.on_word_found(game_state, word)


---
assists/time_bonus_assist.py
---
"""Time Bonus and Overtime Recovery Assist Provider."""
from __future__ import annotations

from typing import Any, Dict, Optional

from assists.base import BaseAssistProvider
from core.enums import GameMode
from core.game_state import GameState
from core.models import AssistConfig, WordEntry


class TimeBonusAssistProvider(BaseAssistProvider):
    """Manages overtime bonuses and emergency time boosts in Timed Attack mode."""

    @property
    def name(self) -> str:
        return "time_bonus"

    def is_enabled(self, config: AssistConfig) -> bool:
        return True

    def on_word_found(self, game_state: GameState, word: WordEntry) -> None:
        """Adds time reward when a word is solved."""
        if game_state.mode == GameMode.TIMED_ATTACK:
            bonus = game_state.bonus_per_word
            game_state.time_remaining += bonus

    def apply_emergency_time_boost(
        self, game_state: GameState, boost_seconds: float = 30.0
    ) -> Optional[Dict[str, Any]]:
        """Adds emergency time in timed attack mode."""
        if game_state.mode != GameMode.TIMED_ATTACK:
            return None

        game_state.time_remaining += boost_seconds
        return {
            "boost_seconds": boost_seconds,
            "new_time_remaining": game_state.time_remaining,
            "message": f"+{int(boost_seconds)}s Emergency Time Added!",
        }


---
cli/__init__.py
---


---
cli/terminal_game.py
---
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


---
config/__init__.py
---


---
config/settings.py
---
"""Settings and Configuration Manager for the Word Search Game."""
from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, Optional

from core.enums import Difficulty, GameMode, ThemeMode

CONFIG_DIR = Path(__file__).parent
DEFAULT_CONFIG_PATH = CONFIG_DIR / "default_config.json"
DIFFICULTY_PRESETS_PATH = CONFIG_DIR / "difficulty_presets.json"
USER_CONFIG_PATH = CONFIG_DIR / "user_config.json"


class Settings:
    """Manages application settings with persistent JSON storage."""

    def __init__(self, config_path: Optional[Path] = None) -> None:
        self.config_path = config_path or USER_CONFIG_PATH
        self._config: Dict[str, Any] = self._load_default_config()
        self._difficulty_presets: Dict[str, Any] = self._load_presets()
        self.load()

    def _load_default_config(self) -> Dict[str, Any]:
        if DEFAULT_CONFIG_PATH.exists():
            try:
                with open(DEFAULT_CONFIG_PATH, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
        return {
            "theme": ThemeMode.DARK,
            "default_language": "en",
            "default_difficulty": Difficulty.EASY,
            "concept_first_mode": False,
            "game_mode": GameMode.CASUAL,
            "timed_attack_seconds": 240,
            "sound_enabled": True,
            "proximity_assist_enabled": True,
            "auto_stall_hint_seconds": 45.0,
            "mastery_needs_practice_threshold": 45.0,
            "font_size": 16, # TODO: Make this dynamic based on screen size and user preference
            "ui_scale": 1.05,
            "screen_width": 1024,
            "screen_height": 720,
            "fps": 60,
        }

    def _load_presets(self) -> Dict[str, Any]:
        if DIFFICULTY_PRESETS_PATH.exists():
            try:
                with open(DIFFICULTY_PRESETS_PATH, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass
        return {}

    def load(self) -> None:
        """Loads user overrides if they exist."""
        if self.config_path.exists():
            try:
                with open(self.config_path, "r", encoding="utf-8") as f:
                    user_cfg = json.load(f)
                    self._config.update(user_cfg)
            except Exception:
                pass

    def save(self) -> None:
        """Persists current configuration to user_config.json."""
        try:
            tmp_path = self.config_path.with_suffix('.tmp.json')
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(self._config, f, indent=2, ensure_ascii=False)
            os.replace(tmp_path, self.config_path)
        except Exception:
            pass

    def get(self, key: str, default: Any = None) -> Any:
        return self._config.get(key, default)

    def set(self, key: str, value: Any, auto_save: bool = True) -> None:
        self._config[key] = value
        if auto_save:
            self.save()

    def get_difficulty_preset(self, difficulty: str) -> Dict[str, Any]:
        diff_lower = difficulty.lower()
        if diff_lower in self._difficulty_presets:
            return self._difficulty_presets[diff_lower]
        return self._difficulty_presets.get("easy", {})

    @property
    def all_presets(self) -> Dict[str, Any]:
        return self._difficulty_presets

    @property
    def as_dict(self) -> Dict[str, Any]:
        return self._config.copy()


# Global singleton settings instance
settings = Settings()


---
core/__init__.py
---


---
core/enums.py
---
"""Core Enums for Word Search Game."""
from __future__ import annotations

from enum import Enum, IntEnum
from typing import Optional, Tuple


class ScriptType(str, Enum):
    """Supported writing scripts for grid generation and filler characters."""
    LATIN = "latin"
    LATIN_ACCENTED = "latin_accented"
    HIRAGANA = "hiragana"
    KATAKANA = "katakana"
    KANJI = "kanji"
    CYRILLIC = "cyrillic"
    CUSTOM = "custom"


class Difficulty(str, Enum):
    """Game difficulty presets."""
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    EXPERT = "expert"
    DYNAMIC = "dynamic"


class ThemeMode(str, Enum):
    """Game theme presets."""
    DARK = "dark"
    LIGHT = "light"


class Direction(str, Enum):
    """Allowed 8-way directional vectors for word placement and selection."""
    HORIZONTAL_LR = "HORIZONTAL_LR"   # (0, 1)  -> Right
    HORIZONTAL_RL = "HORIZONTAL_RL"   # (0, -1) -> Left
    VERTICAL_TB = "VERTICAL_TB"       # (1, 0)  -> Down
    VERTICAL_BT = "VERTICAL_BT"       # (-1, 0) -> Up
    DIAGONAL_TL_BR = "DIAGONAL_TL_BR" # (1, 1)  -> Down-Right
    DIAGONAL_BR_TL = "DIAGONAL_BR_TL" # (-1, -1)-> Up-Left
    DIAGONAL_BL_TR = "DIAGONAL_BL_TR" # (-1, 1) -> Up-Right
    DIAGONAL_TR_BL = "DIAGONAL_TR_BL" # (1, -1) -> Down-Left

    @property
    def delta(self) -> Tuple[int, int]:
        """Returns (d_row, d_col) coordinate step."""
        vectors = {
            Direction.HORIZONTAL_LR: (0, 1),
            Direction.HORIZONTAL_RL: (0, -1),
            Direction.VERTICAL_TB: (1, 0),
            Direction.VERTICAL_BT: (-1, 0),
            Direction.DIAGONAL_TL_BR: (1, 1),
            Direction.DIAGONAL_BR_TL: (-1, -1),
            Direction.DIAGONAL_BL_TR: (-1, 1),
            Direction.DIAGONAL_TR_BL: (1, -1),
        }
        return vectors[self]

    @property
    def human_readable(self) -> str:
        names = {
            Direction.HORIZONTAL_LR: "Horizontal (Left → Right)",
            Direction.HORIZONTAL_RL: "Horizontal Reverse (Right → Left)",
            Direction.VERTICAL_TB: "Vertical (Top → Bottom)",
            Direction.VERTICAL_BT: "Vertical Reverse (Bottom → Top)",
            Direction.DIAGONAL_TL_BR: "Diagonal Down-Right ↘",
            Direction.DIAGONAL_BR_TL: "Diagonal Up-Left ↖",
            Direction.DIAGONAL_BL_TR: "Diagonal Up-Right ↗",
            Direction.DIAGONAL_TR_BL: "Diagonal Down-Left ↙",
        }
        return names.get(self, str(self.value))

    @classmethod
    def from_delta(cls, d_row: int, d_col: int) -> Optional[Direction]:
        # Normalize unit step
        sign_r = (d_row > 0) - (d_row < 0) if d_row != 0 else 0
        sign_c = (d_col > 0) - (d_col < 0) if d_col != 0 else 0
        for d in cls:
            if d.delta == (sign_r, sign_c):
                return d
        return None


class GameMode(str, Enum):
    """Play mode."""
    CASUAL = "casual"
    TIMED_ATTACK = "timed_attack"


class GameStatus(str, Enum):
    """Current state of a game session."""
    NOT_STARTED = "not_started"
    PLAYING = "playing"
    PAUSED = "paused"
    WON = "won"
    TIME_OUT = "time_out"
    GIVEN_UP = "given_up"


class HintTier(IntEnum):
    """Progressive 6-tier hint stages."""
    NONE = 0
    TIER_1_CLUE = 1               # Definition / Clue only
    TIER_2_WORD_NAME = 2          # Word string revealed
    TIER_3_FIRST_LETTER = 3       # First character + word length (no coords)
    TIER_4_ORIENTATION = 4        # Direction revealed
    TIER_5_START_COORDINATE = 5   # Starting (r, c) coordinate highlighted
    TIER_6_FULL_GLOW = 6          # Full word path highlighted


class MasteryLevel(str, Enum):
    """Vocabulary familiarity and spaced repetition classification."""
    UNSEEN = "unseen"
    LEARNING = "learning"
    NEEDS_PRACTICE = "needs_practice"
    MASTERED = "mastered"


---
core/game_state.py
---
"""Pure UI-Agnostic Game State Machine and Selection Validator."""
from __future__ import annotations

import math
from typing import Dict, List, Optional, Set, Tuple

from core.enums import Direction, GameMode, GameStatus, HintTier
from core.models import Puzzle, WordEntry


class GameState:
    """Manages active puzzle progression, timed countdown, selection checks, and win/give-up states."""

    def __init__(self, puzzle: Puzzle, mode: GameMode = GameMode.CASUAL) -> None:
        self.puzzle = puzzle
        self.mode = mode
        self.status = GameStatus.PLAYING
        self.found_words: List[WordEntry] = []
        self.found_coords_map: Dict[Tuple[int, int], str] = {}  # (r, c) -> word

        # Timed Attack Timer
        self.time_limit = puzzle.assist_config.time_limit_seconds
        self.time_remaining = float(self.time_limit)
        self.bonus_per_word = puzzle.assist_config.bonus_time_per_word
        self.total_elapsed_seconds: float = 0.0

        # Highlights and hints
        self.active_hint_coords: Set[Tuple[int, int]] = set()
        self.active_hint_word: Optional[WordEntry] = None
        self.revealed_all_on_giveup: bool = False

    def check_selection(
        self, start_coord: Tuple[int, int], end_coord: Tuple[int, int]
    ) -> Tuple[bool, Optional[WordEntry], List[Tuple[int, int]]]:
        """
        Validates if the drag line from start_coord to end_coord matches an unfound word.
        Supports both forward and reverse drag selection!
        """
        if self.status != GameStatus.PLAYING:
            return False, None, []

        coords = self.interpolate_line(start_coord, end_coord)
        if not coords:
            return False, None, []

        # Read characters along the line
        selected_chars = [self.puzzle.grid[r][c] for r, c in coords]
        forward_str = "".join(selected_chars)
        reverse_str = forward_str[::-1]

        for word_entry in self.puzzle.words:
            if word_entry.found:
                continue

            # Match exact coordinates or forward/reverse strings
            if coords == word_entry.coords or coords == list(reversed(word_entry.coords)):
                self._mark_word_found(word_entry)
                return True, word_entry, coords
            elif forward_str == word_entry.word or reverse_str == word_entry.word:
                # In case of duplicate strings placed elsewhere, verify coordinates
                if len(coords) == len(word_entry.coords):
                    self._mark_word_found(word_entry)
                    return True, word_entry, coords

        return False, None, coords

    def _mark_word_found(self, word_entry: WordEntry) -> None:
        """Marks a word as found and checks for game completion."""
        word_entry.found = True
        self.found_words.append(word_entry)
        for coord in word_entry.coords:
            self.found_coords_map[coord] = word_entry.word

        # Add time bonus in Timed Attack mode
        if self.mode == GameMode.TIMED_ATTACK:
            self.time_remaining += self.bonus_per_word

        # Clear any active hints for this word
        if self.active_hint_word and self.active_hint_word.word == word_entry.word:
            self.active_hint_word = None
            self.active_hint_coords.clear()

        # Check win condition
        if self.puzzle.is_complete:
            self.status = GameStatus.WON

    def interpolate_line(
        self, start: Tuple[int, int], end: Tuple[int, int]
    ) -> List[Tuple[int, int]]:
        """Returns the list of straight grid cells from start to end in 8 directions."""
        r0, c0 = start
        r1, c1 = end

        # Boundary checks
        if not (0 <= r0 < self.puzzle.rows and 0 <= c0 < self.puzzle.cols):
            return []
        if not (0 <= r1 < self.puzzle.rows and 0 <= c1 < self.puzzle.cols):
            return []

        dr = r1 - r0
        dc = c1 - c0

        # Single cell click
        if dr == 0 and dc == 0:
            return [(r0, c0)]

        # Must be horizontal, vertical, or true 45-degree diagonal
        abs_dr = abs(dr)
        abs_dc = abs(dc)

        if not (dr == 0 or dc == 0 or abs_dr == abs_dc):
            return []

        step_r = (dr > 0) - (dr < 0) if dr != 0 else 0
        step_c = (dc > 0) - (dc < 0) if dc != 0 else 0

        steps = max(abs_dr, abs_dc)
        line = [(r0 + i * step_r, c0 + i * step_c) for i in range(steps + 1)]
        return line

    def tick(self, delta_seconds: float) -> None:
        """Updates timers during active gameplay."""
        if self.status != GameStatus.PLAYING:
            return

        self.total_elapsed_seconds += delta_seconds

        if self.mode == GameMode.TIMED_ATTACK:
            self.time_remaining -= delta_seconds
            if self.time_remaining <= 0:
                self.time_remaining = 0
                self.status = GameStatus.TIME_OUT

    def give_up(self) -> None:
        """Surrenders the game, reveals all words for review, and transitions to GIVEN_UP."""
        self.status = GameStatus.GIVEN_UP
        self.revealed_all_on_giveup = True
        for w in self.puzzle.words:
            for coord in w.coords:
                if coord not in self.found_coords_map:
                    self.found_coords_map[coord] = w.word

    def toggle_pause(self) -> bool:
        """Toggles between PLAYING and PAUSED."""
        if self.status == GameStatus.PLAYING:
            self.status = GameStatus.PAUSED
            return True
        elif self.status == GameStatus.PAUSED:
            self.status = GameStatus.PLAYING
            return False
        return False

    def get_nearest_unfound_word_distance(self, coord: Tuple[int, int]) -> Optional[float]:
        """Calculates distance from (r, c) to the nearest unfound word's start coordinate."""
        r, c = coord
        unfound = [w for w in self.puzzle.words if not w.found and w.start_coord]
        if not unfound:
            return None

        min_dist = float("inf")
        for w in unfound:
            sr, sc = w.start_coord  # type: ignore
            dist = math.hypot(r - sr, c - sc)
            if dist < min_dist:
                min_dist = dist
        return min_dist


---
core/grid_engine.py
---
"""Grid Placement Engine for Multilingual Word Search Puzzles."""
from __future__ import annotations

import math
import random
from typing import Any, Dict, List, Optional, Set, Tuple
from config.settings import settings

from core.enums import Difficulty, Direction, ScriptType
from core.models import AssistConfig, Puzzle, PuzzleMetadata, WordEntry
from core.scripts import (
    detect_script,
    get_character_pool,
    normalize_word_for_puzzle,
    random_filler_char,
)


def get_allowed_directions(difficulty: Difficulty) -> List[Direction]:
    """Returns allowed placement directions based on difficulty preset."""
    if difficulty == Difficulty.EASY:
        return [Direction.HORIZONTAL_LR, Direction.VERTICAL_TB]
    elif difficulty == Difficulty.MEDIUM:
        return [
            Direction.HORIZONTAL_LR,
            Direction.VERTICAL_TB,
            Direction.DIAGONAL_TL_BR,
            Direction.DIAGONAL_BL_TR,
        ]
    else:  # HARD, EXPERT, DYNAMIC
        return list(Direction)


def calculate_optimal_dimensions(
    words: List[str],
    difficulty: Difficulty,
    target_density: float = 0.65,
    custom_size: Optional[Tuple[int, int]] = None,
) -> Tuple[int, int]:
    """Calculates optimal grid (rows, cols) based on word lengths, count, and density."""
    if custom_size:
        return custom_size

    if not words:
        return (10, 10)

    max_len = max(len(w) for w in words)
    total_chars = sum(len(w) for w in words)

    # Minimum dimension must fit the longest word with at least 1-2 buffer cells
    min_dim = max(max_len + 2, 8)

    # Estimate required area based on fill density (e.g. 60-70% letters)
    estimated_area = total_chars / max(0.2, min(0.9, target_density))
    side = max(min_dim, math.ceil(math.sqrt(estimated_area)))

    # Difficulty buffer: Easy boards are slightly more spacious; Expert boards are compact
    if difficulty == Difficulty.EASY:
        side = max(side, max_len + 3)
    elif difficulty == Difficulty.EXPERT:
        side = max(min_dim, math.ceil(math.sqrt(total_chars / 0.85)))

    # Clamp dimensions between 8x8 and 30x30 for mobile/desktop usability
    side = max(8, min(30, side))
    return (side, side)


class GridEngine:
    """Core algorithm for placing words and generating multilingual word search boards."""

    @classmethod
    def generate_puzzle(
        cls,
        words_data: List[Dict[str, Any]],
        title: str = "Word Search",
        theme: str = "General",
        language: str = settings.get("default_language", "en"),
        difficulty: Difficulty = Difficulty.EASY,
        custom_dimensions: Optional[Tuple[int, int]] = None,
        script_type: Optional[ScriptType] = None,
        assist_config: Optional[AssistConfig] = None,
        max_retries: int = 50,
    ) -> Puzzle:
        """Generates a complete Puzzle object with placed words and script-aware fillers."""
        raw_words = [item.get("word", "") for item in words_data if item.get("word")]
        detected_script = script_type or detect_script(raw_words)

        # Normalize words
        normalized_entries: List[WordEntry] = []
        for item in words_data:
            w_raw = item.get("word", "").strip()
            if not w_raw:
                continue
            w_norm = normalize_word_for_puzzle(w_raw, detected_script)
            normalized_entries.append(
                WordEntry(
                    word=w_norm,
                    clue=item.get("clue"),
                    reading=item.get("reading"),
                )
            )

        # Remove duplicate words while preserving order
        unique_entries: List[WordEntry] = []
        seen_words: Set[str] = set()
        for entry in normalized_entries:
            if entry.word not in seen_words and len(entry.word) >= 2:
                seen_words.add(entry.word)
                unique_entries.append(entry)

        if not unique_entries:
            raise ValueError("No valid words provided for puzzle generation.")

        # Determine dimensions and directions
        cfg = assist_config or AssistConfig()
        rows, cols = calculate_optimal_dimensions(
            [e.word for e in unique_entries],
            difficulty,
            target_density=cfg.density_target,
            custom_size=custom_dimensions,
        )
        allowed_dirs = get_allowed_directions(difficulty)

        # Try generating board
        for attempt in range(max_retries):
            grid, placed_words = cls._try_place_all(
                unique_entries, rows, cols, allowed_dirs, detected_script
            )
            if len(placed_words) == len(unique_entries):
                # Successfully placed all words! Fill remaining empty cells
                cls._fill_empty_cells(grid, detected_script)
                metadata = PuzzleMetadata(
                    title=title,
                    theme=theme,
                    language=language,
                    script_type=detected_script,
                    difficulty=difficulty,
                )
                return Puzzle(
                    metadata=metadata,
                    rows=rows,
                    cols=cols,
                    grid=grid,
                    words=placed_words,
                    allowed_directions=allowed_dirs,
                    assist_config=cfg,
                )
            # If board was too tight, increase dimension slightly on later retries
            if attempt > max_retries // 2:
                rows += 1
                cols += 1

        # Fallback: place as many as possible
        grid, placed_words = cls._try_place_all(
            unique_entries, rows, cols, allowed_dirs, detected_script
        )
        cls._fill_empty_cells(grid, detected_script)
        metadata = PuzzleMetadata(
            title=title,
            theme=theme,
            language=language,
            script_type=detected_script,
            difficulty=difficulty,
        )
        return Puzzle(
            metadata=metadata,
            rows=rows,
            cols=cols,
            grid=grid,
            words=placed_words,
            allowed_directions=allowed_dirs,
            assist_config=cfg,
        )

    @classmethod
    def _try_place_all(
        cls,
        entries: List[WordEntry],
        rows: int,
        cols: int,
        allowed_dirs: List[Direction],
        script: ScriptType,
    ) -> Tuple[List[List[str]], List[WordEntry]]:
        grid: List[List[str]] = [["" for _ in range(cols)] for _ in range(rows)]
        placed: List[WordEntry] = []

        # Sort entries longest first for easier placement
        sorted_entries = sorted(entries, key=lambda e: len(e.word), reverse=True)

        for entry in sorted_entries:
            success, coords, direction = cls._place_word(grid, entry.word, rows, cols, allowed_dirs)
            if success:
                new_entry = entry.model_copy()
                new_entry.coords = coords
                new_entry.direction = direction
                placed.append(new_entry)

        return grid, placed

    @classmethod
    def _place_word(
        cls,
        grid: List[List[str]],
        word: str,
        rows: int,
        cols: int,
        allowed_dirs: List[Direction],
        max_attempts_per_word: int = 150,
    ) -> Tuple[bool, List[Tuple[int, int]], Optional[Direction]]:
        word_chars = list(word)
        w_len = len(word_chars)

        # Generate list of random candidate start locations and directions
        start_candidates = [
            (r, c) for r in range(rows) for c in range(cols)
        ]
        random.shuffle(start_candidates)

        for r, c in start_candidates:
            shuffled_dirs = allowed_dirs.copy()
            random.shuffle(shuffled_dirs)

            for d in shuffled_dirs:
                dr, dc = d.delta
                end_r = r + (w_len - 1) * dr
                end_c = c + (w_len - 1) * dc

                if 0 <= end_r < rows and 0 <= end_c < cols:
                    # Check if word fits without conflicting with existing letters
                    can_place = True
                    coords: List[Tuple[int, int]] = []

                    for i, char in enumerate(word_chars):
                        curr_r = r + i * dr
                        curr_c = c + i * dc
                        cell_val = grid[curr_r][curr_c]

                        if cell_val != "" and cell_val != char:
                            can_place = False
                            break
                        coords.append((curr_r, curr_c))

                    if can_place:
                        # Write characters to grid
                        for (cr, cc), char in zip(coords, word_chars):
                            grid[cr][cc] = char
                        return True, coords, d

        return False, [], None

    @classmethod
    def _fill_empty_cells(cls, grid: List[List[str]], script: ScriptType) -> None:
        rows = len(grid)
        cols = len(grid[0]) if rows > 0 else 0
        pool = get_character_pool(script)

        for r in range(rows):
            for c in range(cols):
                if grid[r][c] == "":
                    grid[r][c] = random.choice(pool)

    @classmethod
    def shift_distractor_cells(cls, puzzle: Puzzle) -> None:
        """Dynamic Mode: Safely shuffles non-word filler letters to create subtle dynamic shifting."""
        protected_coords: Set[Tuple[int, int]] = set()
        for w in puzzle.words:
            for coord in w.coords:
                protected_coords.add(coord)

        rows = puzzle.rows
        cols = puzzle.cols
        pool = get_character_pool(puzzle.metadata.script_type)

        for r in range(rows):
            for c in range(cols):
                if (r, c) not in protected_coords:
                    # 30% chance to re-randomize this distractor cell
                    if random.random() < 0.30:
                        puzzle.grid[r][c] = random.choice(pool)


---
core/models.py
---
"""Data Models and Pydantic Schemas for Word Search Puzzles."""
from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple
from pydantic import BaseModel, Field
from config.settings import settings

from core.enums import Difficulty, Direction, HintTier, MasteryLevel, ScriptType


class WordEntry(BaseModel):
    """Represents a single word in the puzzle with placement and definition."""
    word: str
    clue: Optional[str] = None
    reading: Optional[str] = None  # e.g., Hiragana/Romaji reading for Kanji or phonetic info
    coords: List[Tuple[int, int]] = Field(default_factory=list)
    direction: Optional[Direction] = None
    found: bool = False
    hint_tier_used: HintTier = HintTier.NONE

    @property
    def start_coord(self) -> Optional[Tuple[int, int]]:
        return self.coords[0] if self.coords else None

    @property
    def end_coord(self) -> Optional[Tuple[int, int]]:
        return self.coords[-1] if self.coords else None

    @property
    def length(self) -> int:
        return len(self.word)


class PuzzleMetadata(BaseModel):
    """Metadata describing a puzzle's provenance, theme, and settings."""
    id: str = Field(default_factory=lambda: str(uuid.uuid4())[:8])
    title: str = "Word Search"
    theme: str = "General"
    language: str = settings.get("default_language", "en")
    script_type: ScriptType = ScriptType.LATIN
    difficulty: Difficulty = settings.get("default_difficulty", Difficulty.EASY)
    author: str = "System"
    created_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    description: Optional[str] = None


class AssistConfig(BaseModel):
    """Pluggable assist settings and difficulty constraints."""
    allowed_hint_tiers: List[int] = Field(default_factory=lambda: [1, 2, 3, 4, 5, 6])
    proximity_enabled: bool = settings.get("proximity_assist_enabled", True)
    time_limit_seconds: int = settings.get("timed_attack_seconds", 240)
    bonus_time_per_word: int = 15
    is_shifting: bool = False
    density_target: float = 0.65


class Puzzle(BaseModel):
    """Self-contained, serializable Word Search Puzzle object."""
    metadata: PuzzleMetadata
    rows: int
    cols: int
    grid: List[List[str]]
    words: List[WordEntry]
    allowed_directions: List[Direction] = Field(default_factory=list)
    assist_config: AssistConfig = Field(default_factory=AssistConfig)

    def get_word(self, word_str: str) -> Optional[WordEntry]:
        for w in self.words:
            if w.word == word_str:
                return w
        return None

    @property
    def total_words(self) -> int:
        return len(self.words)

    @property
    def found_words_count(self) -> int:
        return sum(1 for w in self.words if w.found)

    @property
    def is_complete(self) -> bool:
        return self.found_words_count == self.total_words and self.total_words > 0


class WordMasteryRecord(BaseModel):
    """Tracks player mastery metrics for an individual vocabulary word."""
    word: str
    language: str = settings.get("default_language", "en")
    clue: Optional[str] = None
    reading: Optional[str] = None
    times_encountered: int = 0
    times_solved: int = 0
    total_solve_time_seconds: float = 0.0
    hint_tiers_history: List[int] = Field(default_factory=list)
    error_clicks: int = 0
    last_encountered_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    mastery_level: MasteryLevel = MasteryLevel.UNSEEN

    @property
    def average_solve_time(self) -> float:
        return self.total_solve_time_seconds / max(1, self.times_solved)


class PlayerProfile(BaseModel):
    """Persistent player profile with statistics and vocabulary deck."""
    total_games_played: int = 0
    total_games_won: int = 0
    total_words_found: int = 0
    total_play_time_seconds: float = 0.0
    best_velocity_spw: float = 0.0  # seconds per word (lower is faster)
    overall_accuracy: float = 100.0
    timed_attack_high_scores: Dict[str, int] = Field(default_factory=dict)
    vocabulary_deck: Dict[str, WordMasteryRecord] = Field(default_factory=dict)


---
core/scripts.py
---
"""Unicode & Multilingual Script Pools for Grid Generation and Distractor Fillers."""
from __future__ import annotations

import random
import unicodedata
from typing import List, Set

from core.enums import ScriptType

# Latin uppercase
LATIN_CHARS = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

# Spanish with accents & Ñ
SPANISH_CHARS = list("ABCDEFGHIJKLMNÑOPQRSTUVWXYZÁÉÍÓÚÜ")

# Japanese Hiragana (common gojuon + dakuon)
HIRAGANA_CHARS = list(
    "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"
    "がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ"
)

# Japanese Katakana
KATAKANA_CHARS = list(
    "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"
    "ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ"
)

# Common Elementary / JLPT Kanji for general puzzles
COMMON_KANJI_CHARS = list(
    "日月年大中小人一二三四五六七八九十百千万水火木金土天学校先生名本子手足目口山川本語国車時"
    "気電話何白赤青雨今半分前後外内上下右左友父母買食飲行来休"
)

# Cyrillic uppercase
CYRILLIC_CHARS = list("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")


def get_character_pool(script: ScriptType) -> List[str]:
    """Returns the distractor character pool for the specified script."""
    if script == ScriptType.HIRAGANA:
        return HIRAGANA_CHARS
    elif script == ScriptType.KATAKANA:
        return KATAKANA_CHARS
    elif script == ScriptType.KANJI:
        return COMMON_KANJI_CHARS
    elif script == ScriptType.LATIN_ACCENTED:
        return SPANISH_CHARS
    elif script == ScriptType.CYRILLIC:
        return CYRILLIC_CHARS
    elif script == ScriptType.LATIN:
        return LATIN_CHARS
    return LATIN_CHARS


def random_filler_char(script: ScriptType, custom_pool: List[str] | None = None) -> str:
    """Generates a random distractor character matching the script pool."""
    pool = custom_pool if custom_pool else get_character_pool(script)
    return random.choice(pool)


def is_hiragana(char: str) -> bool:
    return "\u3040" <= char <= "\u309f"


def is_katakana(char: str) -> bool:
    return "\u30a0" <= char <= "\u30ff"


def is_kanji(char: str) -> bool:
    return "\u4e00" <= char <= "\u9fff"


def is_cyrillic(char: str) -> bool:
    return "\u0400" <= char <= "\u04ff"


def is_latin_accented(char: str) -> bool:
    return char.upper() in "ÁÉÍÓÚÜÑ"


def detect_script(words: List[str]) -> ScriptType:
    """Auto-detects the predominant script type from a collection of words."""
    if not words:
        return ScriptType.LATIN

    all_chars = "".join(words).replace(" ", "")
    if not all_chars:
        return ScriptType.LATIN

    counts = {
        ScriptType.HIRAGANA: 0,
        ScriptType.KATAKANA: 0,
        ScriptType.KANJI: 0,
        ScriptType.CYRILLIC: 0,
        ScriptType.LATIN_ACCENTED: 0,
        ScriptType.LATIN: 0,
    }

    for c in all_chars:
        if is_hiragana(c):
            counts[ScriptType.HIRAGANA] += 1
        elif is_katakana(c):
            counts[ScriptType.KATAKANA] += 1
        elif is_kanji(c):
            counts[ScriptType.KANJI] += 1
        elif is_cyrillic(c):
            counts[ScriptType.CYRILLIC] += 1
        elif is_latin_accented(c):
            counts[ScriptType.LATIN_ACCENTED] += 1
        else:
            counts[ScriptType.LATIN] += 1

    # If any CJK characters are present, prioritize CJK script with highest count
    cjk_total = counts[ScriptType.HIRAGANA] + counts[ScriptType.KATAKANA] + counts[ScriptType.KANJI]
    if cjk_total > 0:
        cjk_scores = {
            ScriptType.HIRAGANA: counts[ScriptType.HIRAGANA],
            ScriptType.KATAKANA: counts[ScriptType.KATAKANA],
            ScriptType.KANJI: counts[ScriptType.KANJI],
        }
        return max(cjk_scores.items(), key=lambda item: item[1])[0]

    if counts[ScriptType.CYRILLIC] > 0:
        return ScriptType.CYRILLIC

    # If Latin accented characters are present, use Latin Accented pool
    if counts[ScriptType.LATIN_ACCENTED] > 0:
        return ScriptType.LATIN_ACCENTED

    return ScriptType.LATIN


def normalize_word_for_puzzle(word: str, script: ScriptType) -> str:
    """Normalizes whitespace and casing according to the script."""
    cleaned = "".join(word.strip().split())
    if script in (ScriptType.LATIN, ScriptType.LATIN_ACCENTED, ScriptType.CYRILLIC):
        return cleaned.upper()
    return cleaned


---
docs/ANDROID_PYDROID3_GUIDE.md
---
# Running on Android with Pydroid 3

This project is fully compatible with **Pydroid 3** on Android phones and tablets, featuring touch-drag word selection, responsive auto-scaling layouts, and offline puzzle packages.

---

## 1. Prerequisites on Pydroid 3

1. Install **Pydroid 3 - IDE for Python 3** from Google Play Store.
2. Open Pydroid 3, open the left side menu, and select **Pip**.
3. Install the required dependencies:
   - Type `pygame` and tap **Install**.
   - Type `pydantic` and tap **Install**.
   - Type `python-dotenv` and tap **Install**.
   - Type `requests` and tap **Install**.
   *(Optional for AI generation: type `google-genai` and tap Install)*.

---

## 2. Copying & Opening the Project

1. Copy the `wordSearch` directory into your device storage (e.g. `/sdcard/Documents/wordSearch/` or Google Drive synced folder).
2. If using Gemini AI, create or copy `.env` in the root folder with:
   ```bash
   GEMINI_API_KEY=your_key_here
   ```
3. In Pydroid 3, tap **Open** $\rightarrow$ Navigate to `wordSearch/main.py`.

---

## 3. Running the Game

1. Tap the big yellow **Play ▶** button at the bottom right.
2. The Pygame window will launch in full screen with touch support:
   - **Drag across letters** to select words in 8 directions.
   - **Tap individual cells** to receive "Hot & Cold" proximity feedback.
   - **Tap the 💡 Hint button** or word cards to escalate progressive hints.
   - **Tap 🌓** to toggle Dark / Light mode.
   - **Tap 📚 Study Deck** to inspect your learned vocabulary.

---

## 4. Troubleshooting on Mobile

- **Font Missing Glyph Issues**: The game includes automatic fallback detection for Android system fonts (`DroidSansFallback`, `NotoSansCJK`).
- **Screen Resolution**: The GUI automatically senses mobile screen dimensions and scales the cell sizes appropriately for portrait or landscape orientations.


---
docs/FLUTTER_MIGRATION_ROADMAP.md
---
# Flutter & Dart Cross-Platform Migration Roadmap

This document outlines the technical blueprint for migrating the **AI Multilingual Word Search** game from its decoupled Python engine to a native, high-performance Flutter/Dart application targeting iOS, Android (Google Play Store), macOS, Windows, and Web (PWA).

---

## 1. Architecture Mapping (Python → Dart)

Because the Python engine was designed with strict decoupling (zero GUI dependency in `core/`, `learning/`, `assists/`, `telemetry/`, and `storage/`), the business logic maps 1:1 to Dart domain models and services.

| Python Component | Dart / Flutter Equivalent | Purpose |
| :--- | :--- | :--- |
| `core/models.py` | `lib/models/puzzle.dart`, `word_entry.dart` | Immutable data classes using `freezed` or `json_serializable` |
| `core/grid_engine.py` | `lib/services/grid_engine.dart` | 8-way directional word placement & script distractor generation |
| `core/scripts.py` | `lib/constants/scripts.dart` | Unicode & CJK character pools (Hiragana, Katakana, Kanji, Spanish) |
| `core/game_state.py` | `lib/controllers/game_controller.dart` | State management using `Riverpod`, `Bloc`, or `ChangeNotifier` |
| `assists/` | `lib/services/assists/` | Pluggable assist providers (Proximity, 6-Tier Hints, Inactivity detector) |
| `learning/` | `lib/services/learning/` | Spaced repetition vocabulary mastery tracker & study deck |
| `telemetry/` | `lib/services/telemetry_service.dart` | Focus-aware velocity, error rates, and local profile storage |
| `storage/` | `lib/repositories/pack_repository.dart` | JSON asset loader and local cache via `shared_preferences` / `hive` |
| `gui/views/board_view.py` | `lib/widgets/word_search_grid.dart` | Custom `GestureDetector` + `CustomPainter` with straight-line snapping |

---

## 2. Interactive Drag Selection in Flutter (`CustomPainter`)

In Flutter, the word search board is rendered as a single high-performance `CustomPainter` inside a `GestureDetector`:

```dart
// Conceptual snippet for Flutter Grid Touch Drag:
GestureDetector(
  onPanStart: (details) {
    final cell = _calculateCell(details.localPosition);
    controller.startSelection(cell);
  },
  onPanUpdate: (details) {
    final cell = _calculateCell(details.localPosition);
    controller.updateSelection(cell);
  },
  onPanEnd: (_) {
    controller.confirmSelection();
  },
  child: CustomPaint(
    painter: WordSearchGridPainter(
      grid: puzzle.grid,
      foundWords: state.foundWords,
      activeSelection: state.activeSelectionLine,
      hintCoords: state.hintCoords,
      theme: currentTheme,
    ),
    size: Size.square(boardDimension),
  ),
)
```

---

## 3. Google Gemini API Integration in Flutter

In Dart, use the official `@google/genai` or `google_generative_ai` package:

```dart
import 'package:google_generative_ai/google_generative_ai.dart';

final model = GenerativeModel(
  model: 'gemini-2.5-flash',
  apiKey: envApiKey,
  generationConfig: GenerationConfig(responseMimeType: 'application/json'),
);
```

---

## 4. Google Play Store Deployment Checklist

1. **Android App Bundle (AAB)**:
   - Configure `android/app/build.gradle` with unique `applicationId` (e.g. `com.yourname.wordsearch`).
   - Enable ProGuard / R8 code shrinking and resource shrinking.
2. **Release Keystore Signing**:
   - Generate signing key with `keytool -genkey -v -keystore release-key.jks ...`
   - Store credentials safely in `key.properties`.
3. **App Icons & Adaptive Assets**:
   - Use `flutter_launcher_icons` to generate adaptive icons for Android 13+ with themed monochrome icons.
4. **Haptics & Audio**:
   - Use `services.HapticFeedback.lightImpact()` on cell drag and `audioplayers` for rewarding sound effects.


---
docs/JSON_SCHEMA_SPEC.md
---
# Open JSON Specification for Puzzle Packages & Player Profiles

This document specifies the standard JSON schemas used for puzzle packs (`*.pack.json`), individual puzzles (`*.puzzle.json`), and player profiles (`player_profile.json`).

---

## 1. Puzzle Package Schema (`*.pack.json`)

```json
{
  "id": "english_science",
  "title": "Cosmos & Computing",
  "description": "Explore astronomical wonders and computer science fundamentals.",
  "language": "en",
  "script_type": "latin",
  "puzzles": [
    {
      "id": "space_exploration",
      "title": "Space & Astronomy",
      "theme": "Space",
      "difficulty": "easy",
      "words": [
        {
          "word": "GALAXY",
          "clue": "A massive gravitational system of stars, stellar remnants, and dark matter.",
          "reading": null
        },
        {
          "word": "NEBULA",
          "clue": "An interstellar cloud of dust, hydrogen, helium and other ionized gases.",
          "reading": null
        }
      ]
    }
  ]
}
```

### Field Definitions:
- `id` *(string)*: Unique slug identifier for the package.
- `title` *(string)*: Human-readable title of the puzzle collection.
- `description` *(string)*: Summary of the themes and educational content.
- `language` *(string)*: ISO 639-1 language code (`en`, `es`, `ja`, `ru`, etc.).
- `script_type` *(string)*: One of `latin`, `latin_accented`, `hiragana`, `katakana`, `kanji`, `cyrillic`.
- `puzzles` *(array)*: List of puzzle objects containing `id`, `title`, `theme`, `difficulty`, and `words`.

---

## 2. Word Entry Schema

```json
{
  "word": "ありがとう",
  "clue": "Thank you (Gratitude)",
  "reading": "arigatou",
  "coords": [[1, 2], [1, 3], [1, 4], [1, 5], [1, 6]],
  "direction": "HORIZONTAL_LR",
  "found": false,
  "hint_tier_used": 0
}
```

---

## 3. Player Profile Schema (`player_profile.json`)

```json
{
  "total_games_played": 12,
  "total_games_won": 11,
  "total_words_found": 96,
  "total_play_time_seconds": 842.5,
  "best_velocity_spw": 4.2,
  "overall_accuracy": 94.5,
  "timed_attack_high_scores": {
    "english_science": 1420
  },
  "vocabulary_deck": {
    "en:GALAXY": {
      "word": "GALAXY",
      "language": "en",
      "clue": "A massive gravitational system of stars.",
      "reading": null,
      "times_encountered": 3,
      "times_solved": 3,
      "total_solve_time_seconds": 18.2,
      "hint_tiers_history": [0, 1, 0],
      "error_clicks": 0,
      "last_encountered_at": "2026-09-01T12:00:00Z",
      "mastery_level": "mastered"
    }
  }
}
```


---
gui/__init__.py
---


---
gui/accessibility.py
---
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


---
gui/app.py
---
"""Main Pygame Application Coordinator and Event Loop."""
from __future__ import annotations

import os
import sys
import time
from typing import List, Optional, Tuple

os.environ["PYGAME_FREETYPE"] = "1"
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


---
gui/font_manager.py
---
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

ENABLE_PYGAME_FREETYPE = False # disable pygame.freetype for now due to rendering issues on some platforms
HAS_FREETYPE = ENABLE_PYGAME_FREETYPE and pygame_freetype is not None
if HAS_FREETYPE:
    try:
        pygame_freetype.init()
    except Exception:
        pygame_freetype = None
        HAS_FREETYPE = False

try:
    from pygame_emojis import load_emoji
except (ImportError, ModuleNotFoundError):
    load_emoji = None

HAS_PYGAME_EMOJIS = load_emoji is not None

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

            if not HAS_FREETYPE and HAS_PYGAME_EMOJIS and self._is_emoji_or_symbol(cp):
                is_em = True
            elif has_ef and (not has_tf or self._is_emoji_or_symbol(cp)):
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
            if is_em and (self._emoji_font or HAS_PYGAME_EMOJIS):
                for ch in s:
                    try:
                        em_size = int(size * settings.get("ui_scale", 1.05))
                        if HAS_PYGAME_EMOJIS:
                            raw_surf = load_emoji(ch, (em_size, em_size))
                        else:
                            if HAS_FREETYPE:
                                raw_surf, _ = self._emoji_font.render(ch)
                            else:
                                raw_surf = self._emoji_font.render(ch, True, color)
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



---
gui/theme.py
---
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


---
gui/views/__init__.py
---


---
gui/views/board_view.py
---
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


---
gui/views/hud_view.py
---
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


---
gui/views/mastery_view.py
---
"""Vocabulary Mastery and Study Deck Screen."""
from __future__ import annotations

from typing import Callable, List, Optional

import pygame

from core.enums import MasteryLevel
from core.models import PlayerProfile, WordMasteryRecord
from gui.font_manager import font_manager
from gui.theme import theme
from gui.widgets.button import Button
from learning.vocabulary_deck import VocabularyDeckManager


class MasteryView:
    """Allows players to browse lifetime learned vocabulary, inspect progress, and trigger review puzzles."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 0)
        self.btn_back = Button((0, 0, 110, 38), "← Back", is_secondary=True)
        self.btn_practice = Button((0, 0, 220, 38), "🎯 Practice Difficult Words")

        self.btn_filter_all = Button((0, 0, 90, 32), "All", is_secondary=False)
        self.btn_filter_mastered = Button((0, 0, 130, 32), "🌟 Mastered", is_secondary=True)
        self.btn_filter_learning = Button((0, 0, 120, 32), "📖 Learning", is_secondary=True)
        self.btn_filter_practice = Button((0, 0, 150, 32), "⚠️ Needs Practice", is_secondary=True)

        self.active_filter: Optional[MasteryLevel] = None
        self.scroll_y = 0

        self.on_practice_requested: Optional[Callable[[], None]] = None

    def update_layout(self, container_rect: pygame.Rect) -> None:
        self.rect = container_rect
        self.btn_back.rect = pygame.Rect(24, 20, 110, 38)
        self.btn_practice.rect = pygame.Rect(container_rect.width - 244, 20, 220, 38)

        # Filters
        fy = 75
        self.btn_filter_all.rect = pygame.Rect(24, fy, 80, 32)
        self.btn_filter_mastered.rect = pygame.Rect(112, fy, 130, 32)
        self.btn_filter_learning.rect = pygame.Rect(250, fy, 120, 32)
        self.btn_filter_practice.rect = pygame.Rect(378, fy, 160, 32)

    def handle_event(self, event: pygame.event.Event) -> bool:
        if self.btn_back.handle_event(event):
            return True
        if self.btn_practice.handle_event(event):
            if self.on_practice_requested:
                self.on_practice_requested()
            return True

        if self.btn_filter_all.handle_event(event):
            self.active_filter = None
            self._update_filter_buttons()
            return True
        if self.btn_filter_mastered.handle_event(event):
            self.active_filter = MasteryLevel.MASTERED
            self._update_filter_buttons()
            return True
        if self.btn_filter_learning.handle_event(event):
            self.active_filter = MasteryLevel.LEARNING
            self._update_filter_buttons()
            return True
        if self.btn_filter_practice.handle_event(event):
            self.active_filter = MasteryLevel.NEEDS_PRACTICE
            self._update_filter_buttons()
            return True

        if event.type == pygame.MOUSEWHEEL:
            self.scroll_y = max(0, self.scroll_y - event.y * 25)
            return True

        return False

    def _update_filter_buttons(self) -> None:
        self.btn_filter_all.is_secondary = (self.active_filter is not None)
        self.btn_filter_mastered.is_secondary = (self.active_filter != MasteryLevel.MASTERED)
        self.btn_filter_learning.is_secondary = (self.active_filter != MasteryLevel.LEARNING)
        self.btn_filter_practice.is_secondary = (self.active_filter != MasteryLevel.NEEDS_PRACTICE)

    def draw(self, surface: pygame.Surface, profile: PlayerProfile) -> None:
        pygame.draw.rect(surface, theme.bg, self.rect)

        # Header Title
        font_manager.draw_text(
            surface,
            "📚 Vocabulary Study Deck & Mastery",
            (self.rect.centerx, 38),
            24,
            theme.text_primary,
            bold=True,
            align="center",
        )

        # Draw Controls
        self.btn_back.draw(surface)
        self.btn_practice.draw(surface)

        self.btn_filter_all.draw(surface)
        self.btn_filter_mastered.draw(surface)
        self.btn_filter_learning.draw(surface)
        self.btn_filter_practice.draw(surface)

        # Filtered word list
        words = VocabularyDeckManager.filter_words(profile, mastery_level=self.active_filter)

        stats = VocabularyDeckManager.get_summary_stats(profile)
        stats_text = (
            f"Total: {stats['total_words']}  |  "
            f"Mastered: {stats['mastered']}  |  "
            f"Learning: {stats['learning']}  |  "
            f"Needs Practice: {stats['needs_practice']}"
        )
        font_manager.draw_text(
            surface,
            stats_text,
            (self.rect.width - 24, 88),
            14,
            theme.text_muted,
            align="topright",
        )

        # Render list of cards
        list_y = 125 - self.scroll_y
        card_w = self.rect.width - 48
        clip_rect = pygame.Rect(24, 120, card_w, self.rect.height - 140)
        surface.set_clip(clip_rect)

        if not words:
            font_manager.draw_text(
                surface,
                "No vocabulary records matching current filter.",
                (self.rect.centerx, 220),
                18,
                theme.text_muted,
                align="center",
            )
        else:
            for rec in words:
                if list_y + 70 < clip_rect.top or list_y > clip_rect.bottom:
                    list_y += 74
                    continue

                card = pygame.Rect(24, list_y, card_w, 66)
                pygame.draw.rect(surface, theme.card_bg, card, border_radius=8)

                if rec.mastery_level == MasteryLevel.MASTERED:
                    level_color = theme.success
                    badge_str = "🌟 MASTERED"
                elif rec.mastery_level == MasteryLevel.LEARNING:
                    level_color = theme.accent
                    badge_str = "📖 LEARNING"
                else:
                    level_color = theme.warning
                    badge_str = "⚠️ NEEDS PRACTICE"

                pygame.draw.rect(surface, theme.card_border, card, width=1, border_radius=8)

                # Word & Reading
                w_str = rec.word
                if rec.reading:
                    w_str += f"  [{rec.reading}]"

                font_manager.draw_text(
                    surface,
                    w_str,
                    (card.x + 14, card.y + 10),
                    17,
                    theme.text_primary,
                    bold=True,
                )

                # Clue / Meaning
                font_manager.draw_text(
                    surface,
                    rec.clue or "Vocabulary concept",
                    (card.x + 14, card.y + 36),
                    13,
                    theme.text_muted,
                )

                # Mastery Badge on right
                font_manager.draw_text(
                    surface,
                    badge_str,
                    (card.right - 16, card.y + 12),
                    14,
                    level_color,
                    bold=True,
                    align="topright",
                )

                # Stats info
                solve_info = f"Encountered: {rec.times_encountered}x  |  Avg: {rec.average_solve_time:.1f}s"
                font_manager.draw_text(
                    surface,
                    solve_info,
                    (card.right - 16, card.y + 36),
                    12,
                    theme.text_muted,
                    align="topright",
                )

                list_y += 74

        surface.set_clip(None)


---
gui/views/menu_view.py
---
"""Main Menu and Puzzle Configuration Screen."""
from __future__ import annotations

from typing import Callable, List, Optional

import pygame

from core.enums import Difficulty, GameMode
from gui.font_manager import font_manager
from gui.theme import theme
from gui.widgets.button import Button
from gui.widgets.input_box import InputBox
from config.settings import settings
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
        self.selected_difficulty: Difficulty = Difficulty(settings.get('default_difficulty', Difficulty.EASY))
        self.selected_mode: GameMode = GameMode(settings.get('game_mode', GameMode.CASUAL))
        self.concept_first_mode: bool = settings.get('concept_first_mode', False)

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


---
gui/views/review_view.py
---
"""Give Up & Learn Mode: Educational Review Screen with Glossary and Solution Insights."""
from __future__ import annotations

from typing import Callable, Optional

import pygame

from core.enums import GameStatus
from core.game_state import GameState
from gui.font_manager import font_manager
from gui.theme import theme
from gui.widgets.button import Button
from telemetry.tracker import SessionTelemetry


class ReviewView:
    """Displays post-game educational review, concept glossary, and performance analytics."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 0)
        self.btn_next = Button((0, 0, 140, 42), "Next Puzzle")
        self.btn_menu = Button((0, 0, 140, 42), "Main Menu", is_secondary=True)
        self.btn_study = Button((0, 0, 140, 42), "📚 Study Deck", is_secondary=True)
        self.scroll_y = 0

    def update_layout(self, container_rect: pygame.Rect) -> None:
        self.rect = container_rect
        center_x = container_rect.centerx
        bottom_y = container_rect.bottom - 60

        self.btn_next.rect = pygame.Rect(center_x + 80, bottom_y, 140, 42)
        self.btn_study.rect = pygame.Rect(center_x - 70, bottom_y, 140, 42)
        self.btn_menu.rect = pygame.Rect(center_x - 220, bottom_y, 140, 42)

    def handle_event(self, event: pygame.event.Event) -> bool:
        if self.btn_next.handle_event(event):
            return True
        if self.btn_study.handle_event(event):
            return True
        if self.btn_menu.handle_event(event):
            return True
        if event.type == pygame.MOUSEWHEEL:
            self.scroll_y = max(0, self.scroll_y - event.y * 25)
            return True
        return False

    def draw(
        self,
        surface: pygame.Surface,
        game_state: GameState,
        telemetry: SessionTelemetry,
    ) -> None:
        # Dim overlay
        dim_surf = pygame.Surface((self.rect.width, self.rect.height), pygame.SRCALPHA)
        dim_surf.fill((0, 0, 0, 180))
        surface.blit(dim_surf, (0, 0))

        # Main Card Modal
        modal_w = min(840, self.rect.width - 40)
        modal_h = min(620, self.rect.height - 40)
        modal_rect = pygame.Rect(
            (self.rect.width - modal_w) // 2,
            (self.rect.height - modal_h) // 2,
            modal_w,
            modal_h,
        )

        pygame.draw.rect(surface, theme.card_bg, modal_rect, border_radius=16)
        pygame.draw.rect(surface, theme.card_border, modal_rect, width=1, border_radius=16)

        # Title & Status
        is_won = (game_state.status == GameStatus.WON)
        title_text = "🎉 Puzzle Completed!" if is_won else "📚 Learning & Concept Review"
        title_color = theme.success if is_won else theme.accent

        font_manager.draw_text(
            surface,
            title_text,
            (modal_rect.centerx, modal_rect.y + 24),
            26,
            title_color,
            bold=True,
            align="center",
        )

        # Summary Stats Chips
        stats_y = modal_rect.y + 65
        stats_str = (
            f"⏱️ Time: {int(telemetry.active_elapsed_seconds)}s   |   "
            f"⚡ Speed: {telemetry.current_velocity:.1f}s/w   |   "
            f"🎯 Accuracy: {int(telemetry.accuracy_rate)}%   |   "
            f"✓ Found: {len(game_state.found_words)}/{len(game_state.puzzle.words)}"
        )
        font_manager.draw_text(
            surface,
            stats_str,
            (modal_rect.centerx, stats_y),
            15,
            theme.text_secondary,
            align="center",
        )

        # Glossary List Subheader
        font_manager.draw_text(
            surface,
            "Vocabulary & Concept Breakdown:",
            (modal_rect.x + 28, stats_y + 35),
            18,
            theme.text_primary,
            bold=True,
        )

        # Render Word Glossary Cards
        list_y = stats_y + 65 - self.scroll_y
        card_w = modal_rect.width - 56

        clip_rect = pygame.Rect(modal_rect.x + 20, stats_y + 60, card_w + 16, modal_h - 200)
        surface.set_clip(clip_rect)

        for w in game_state.puzzle.words:
            if list_y + 70 < clip_rect.top or list_y > clip_rect.bottom:
                list_y += 76
                continue

            card = pygame.Rect(modal_rect.x + 28, list_y, card_w, 68)
            pygame.draw.rect(surface, theme.grid_cell_bg, card, border_radius=8)

            badge_color = theme.success if w.found else theme.warning
            pygame.draw.rect(surface, badge_color, card, width=1, border_radius=8)

            # Word Name + Reading
            w_str = f"{'✓' if w.found else '🔍'} {w.word}"
            if w.reading:
                w_str += f"  [{w.reading}]"

            font_manager.draw_text(
                surface,
                w_str,
                (card.x + 12, card.y + 8),
                16,
                badge_color,
                bold=True,
            )

            # Definition / Concept Clue
            clue = w.clue or "Concept definition"
            font_manager.draw_text(
                surface,
                clue,
                (card.x + 12, card.y + 34),
                13,
                theme.text_secondary,
            )

            list_y += 76

        surface.set_clip(None)

        # Action Buttons
        self.btn_menu.draw(surface)
        self.btn_study.draw(surface)
        self.btn_next.draw(surface)


---
gui/views/word_list_view.py
---
"""Word Bank and Concept Clue Drawer View."""
from __future__ import annotations

from typing import Callable, List, Optional, Tuple

import pygame

from core.game_state import GameState
from core.models import WordEntry
from gui.font_manager import font_manager
from gui.theme import theme


class WordListView:
    """Renders the word target bank, concept clues, and per-word hint buttons."""

    def __init__(self) -> None:
        self.rect = pygame.Rect(0, 0, 0, 0)
        self.concept_first_mode: bool = False
        self.on_word_hint_clicked: Optional[Callable[[WordEntry], None]] = None
        self.hint_button_rects: List[Tuple[pygame.Rect, WordEntry]] = []
        self.scroll_y: int = 0

    def update_layout(self, container_rect: pygame.Rect, concept_mode: bool = False) -> None:
        self.rect = container_rect
        self.concept_first_mode = concept_mode

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            for btn_rect, word_entry in self.hint_button_rects:
                if btn_rect.collidepoint(event.pos):
                    if self.on_word_hint_clicked:
                        self.on_word_hint_clicked(word_entry)
                    return True
        elif event.type == pygame.MOUSEWHEEL:
            if self.rect.collidepoint(pygame.mouse.get_pos()):
                self.scroll_y = max(0, self.scroll_y - event.y * 20)
                return True
        return False

    def draw(self, surface: pygame.Surface, game_state: GameState) -> None:
        # Background card
        pygame.draw.rect(surface, theme.card_bg, self.rect, border_radius=12)
        pygame.draw.rect(surface, theme.card_border, self.rect, width=1, border_radius=12)

        # Header
        header_title = "Concepts to Find" if self.concept_first_mode else "Word Bank"
        count_str = f"({len(game_state.found_words)}/{len(game_state.puzzle.words)})"
        font_manager.draw_text(
            surface,
            f"{header_title} {count_str}",
            (self.rect.x + 16, self.rect.y + 16),
            18,
            theme.text_primary,
            bold=True,
        )

        self.hint_button_rects.clear()

        # Render list of word cards
        start_y = self.rect.y + 50 - self.scroll_y
        card_w = self.rect.width - 24
        y = start_y

        for idx, word_entry in enumerate(game_state.puzzle.words):
            if y + 60 > self.rect.bottom:
                break
            if y < self.rect.y + 45:
                y += 62
                continue

            card_rect = pygame.Rect(self.rect.x + 12, y, card_w, 56)

            # Card background
            if word_entry.found:
                fill_color = theme.grid_cell_bg
                border_color = theme.success
            else:
                fill_color = theme.grid_cell_bg
                border_color = theme.card_border

            pygame.draw.rect(surface, fill_color, card_rect, border_radius=8)
            pygame.draw.rect(surface, border_color, card_rect, width=1, border_radius=8)

            # Determine title text
            if word_entry.found:
                title_text = f"✓ {word_entry.word}"
                txt_color = theme.success
            elif self.concept_first_mode and int(word_entry.hint_tier_used) < 2:
                title_text = f"❓ Concept #{idx + 1} ({len(word_entry.word)} letters)"
                txt_color = theme.accent
            else:
                title_text = word_entry.word
                txt_color = theme.text_primary

            if word_entry.reading and (word_entry.found or int(word_entry.hint_tier_used) >= 2):
                title_text += f" [{word_entry.reading}]"

            font_manager.draw_text(
                surface,
                title_text,
                (card_rect.x + 10, card_rect.y + 8),
                16,
                txt_color,
                bold=True,
            )

            # Clue text
            clue_text = word_entry.clue or "Find this word in the puzzle"
            if len(clue_text) > 42:
                clue_text = clue_text[:40] + "..."

            font_manager.draw_text(
                surface,
                clue_text,
                (card_rect.x + 10, card_rect.y + 30),
                12,
                theme.text_muted,
            )

            # Hint button on the right side if unfound
            if not word_entry.found:
                hint_btn_rect = pygame.Rect(card_rect.right - 44, card_rect.y + 12, 34, 32)
                pygame.draw.rect(surface, theme.card_bg, hint_btn_rect, border_radius=6)
                pygame.draw.rect(surface, theme.card_border, hint_btn_rect, width=1, border_radius=6)
                font_manager.draw_text(
                    surface,
                    "💡",
                    hint_btn_rect.center,
                    14,
                    theme.text_primary,
                    align="center",
                )
                self.hint_button_rects.append((hint_btn_rect, word_entry))

            y += 62


---
gui/widgets/__init__.py
---


---
gui/widgets/button.py
---
"""Interactive Button Widget with Smooth Hover and Accessibility Outline."""
from __future__ import annotations

from typing import Callable, Optional, Tuple

import pygame

from gui.font_manager import font_manager
from gui.theme import theme


class Button:
    """A tactile, styled button supporting mouse hover, clicks, and keyboard focus."""

    def __init__(
        self,
        rect: Tuple[int, int, int, int],
        text: str,
        callback: Optional[Callable[[], None]] = None,
        font_size: int = 18,
        bg_color: Optional[Tuple[int, int, int]] = None,
        text_color: Optional[Tuple[int, int, int]] = None,
        hover_color: Optional[Tuple[int, int, int]] = None,
        border_radius: int = 8,
        is_secondary: bool = False,
    ) -> None:
        self.rect = pygame.Rect(rect)
        self.text = text
        self.callback = callback
        self.font_size = font_size
        self.custom_bg = bg_color
        self.custom_text = text_color
        self.custom_hover = hover_color
        self.border_radius = border_radius
        self.is_secondary = is_secondary
        self.is_hovered = False
        self.is_focused = False
        self.is_pressed = False

    def handle_event(self, event: pygame.event.Event) -> bool:
        """Processes mouse/touch events and executes callback on click.
        The click is only triggered on mouse button release to avoid toggling on press.
        """
        if event.type == pygame.MOUSEMOTION:
            self.is_hovered = self.rect.collidepoint(event.pos)
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.rect.collidepoint(event.pos):
                self.is_pressed = True
        elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
            if self.is_pressed:
                self.is_pressed = False
                if self.rect.collidepoint(event.pos):
                    if self.callback:
                        self.callback()
                    return True
        return False

    def draw(self, surface: pygame.Surface) -> None:
        """Renders button surface with active styling and focus outline."""
        # Determine background color
        if self.custom_bg:
            base_bg = self.custom_bg
            hover_bg = self.custom_hover or self.custom_bg
        elif self.is_secondary:
            base_bg = theme.card_bg
            hover_bg = theme.grid_cell_hover
        else:
            base_bg = theme.accent
            hover_bg = theme.accent_hover

        fill_color = hover_bg if (self.is_hovered or self.is_pressed) else base_bg

        # Draw rounded rectangle
        pygame.draw.rect(surface, fill_color, self.rect, border_radius=self.border_radius)

        # Draw border
        border_color = theme.cursor_border if self.is_focused else theme.card_border
        border_width = 3 if self.is_focused else 1
        pygame.draw.rect(surface, border_color, self.rect, width=border_width, border_radius=self.border_radius)

        # Draw text (with native color emoji & CJK support)
        txt_color = self.custom_text or (theme.text_primary if self.is_secondary else (255, 255, 255))
        font_manager.draw_text(
            surface,
            self.text,
            self.rect.center,
            self.font_size,
            txt_color,
            bold=True,
            align="center",
        )


---
gui/widgets/input_box.py
---
"""Single and Multi-line Text Input Widget with Cursor and Paste Support."""
from __future__ import annotations

import time
from typing import Optional, Tuple

import pygame

from gui.font_manager import font_manager
from gui.theme import theme


class InputBox:
    """Text input box supporting typing, backspace, clipboard paste, and active focus."""

    def __init__(
        self,
        rect: Tuple[int, int, int, int],
        placeholder: str = "Type here...",
        initial_text: str = "",
        font_size: int = 18,
        is_multiline: bool = False,
    ) -> None:
        self.rect = pygame.Rect(rect)
        self.placeholder = placeholder
        self.text = initial_text
        self.font_size = font_size
        self.is_multiline = is_multiline
        self.is_focused = False
        self.cursor_visible = True
        self.last_cursor_blink = time.time()

    def handle_event(self, event: pygame.event.Event) -> bool:
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            self.is_focused = self.rect.collidepoint(event.pos)
            return self.is_focused

        if not self.is_focused:
            return False

        if event.type == pygame.KEYDOWN:
            # Paste from clipboard
            if event.key == pygame.K_v and (pygame.key.get_mods() & (pygame.KMOD_CTRL | pygame.KMOD_META)):
                try:
                    pasted = pygame.scrap.get(pygame.SCRAP_TEXT)
                    if pasted:
                        self.text += pasted.decode("utf-8", errors="ignore").replace("\x00", "")
                        return True
                except Exception:
                    pass

            if event.key == pygame.K_BACKSPACE:
                self.text = self.text[:-1]
                return True
            elif event.key == pygame.K_RETURN:
                if self.is_multiline:
                    self.text += "\n"
                    return True
            elif event.unicode and event.unicode.isprintable():
                self.text += event.unicode
                return True

        return False

    def draw(self, surface: pygame.Surface) -> None:
        # Background
        pygame.draw.rect(surface, theme.card_bg, self.rect, border_radius=8)

        # Border
        border_color = theme.accent if self.is_focused else theme.card_border
        border_w = 2 if self.is_focused else 1
        pygame.draw.rect(surface, border_color, self.rect, width=border_w, border_radius=8)

        # Content text or placeholder
        display_text = self.text if self.text else self.placeholder
        text_color = theme.text_primary if self.text else theme.text_muted

        # Cursor blink
        if time.time() - self.last_cursor_blink > 0.5:
            self.cursor_visible = not self.cursor_visible
            self.last_cursor_blink = time.time()

        if self.is_focused and self.cursor_visible and self.text:
            display_text += "|"

        # Render text (clip to box)
        margin = 10
        inner_rect = pygame.Rect(
            self.rect.x + margin,
            self.rect.y + margin,
            self.rect.width - 2 * margin,
            self.rect.height - 2 * margin,
        )

        rendered = font_manager.render(display_text, self.font_size, text_color)
        surface.blit(rendered, inner_rect)


---
gui/widgets/toast.py
---
"""Toast Notification Overlay Widget for In-Game Alerts and Proximity."""
from __future__ import annotations

import time
from typing import Optional, Tuple

import pygame

from gui.font_manager import font_manager
from gui.theme import theme


class Toast:
    """Displays temporary non-intrusive notification banners."""

    def __init__(self) -> None:
        self.message: str = ""
        self.color: Tuple[int, int, int] = (56, 189, 248)
        self.expires_at: float = 0.0
        self.duration: float = 3.0

    def show(
        self,
        message: str,
        color: Optional[Tuple[int, int, int]] = None,
        duration: float = 3.0,
    ) -> None:
        self.message = message
        self.color = color or theme.accent
        self.duration = duration
        self.expires_at = time.time() + duration

    @property
    def is_visible(self) -> bool:
        return time.time() < self.expires_at and bool(self.message)

    def draw(self, surface: pygame.Surface, screen_width: int, y_pos: int = 70) -> None:
        if not self.is_visible:
            return

        rendered_text = font_manager.render(self.message, 16, (255, 255, 255), bold=True)
        txt_rect = rendered_text.get_rect()

        banner_width = txt_rect.width + 40
        banner_height = 38
        banner_rect = pygame.Rect(
            (screen_width - banner_width) // 2,
            y_pos,
            banner_width,
            banner_height,
        )

        # Draw toast pill background
        pygame.draw.rect(surface, (20, 25, 38), banner_rect, border_radius=19)
        pygame.draw.rect(surface, self.color, banner_rect, width=2, border_radius=19)

        # Draw text
        txt_rect.center = banner_rect.center
        surface.blit(rendered_text, txt_rect)


# Global singleton instance
toast = Toast()


---
learning/__init__.py
---


---
learning/adaptive_recommender.py
---
"""Targeted Practice Recommender and Review Puzzle Generator."""
from __future__ import annotations

import random
from typing import Any, Dict, List
from config.settings import settings

from core.enums import MasteryLevel
from core.models import PlayerProfile


class AdaptiveRecommender:
    """Generates targeted review vocabulary lists composed of words the user found difficult."""

    @staticmethod
    def get_review_words(
        profile: PlayerProfile,
        language: str = settings.get("default_language", "en"),
        target_count: int = settings.get("default_vocabulary_count", 10),
    ) -> List[Dict[str, Any]]:
        """
        Selects candidate review words prioritizing NEEDS_PRACTICE, then LEARNING.
        Returns words formatted for grid generation.
        """
        all_words = [
            w for w in profile.vocabulary_deck.values()
            if w.language.lower() == language.lower()
        ]

        needs_practice = [w for w in all_words if w.mastery_level == MasteryLevel.NEEDS_PRACTICE]
        learning = [w for w in all_words if w.mastery_level == MasteryLevel.LEARNING]
        mastered = [w for w in all_words if w.mastery_level == MasteryLevel.MASTERED]

        # Shuffle each pool
        random.shuffle(needs_practice)
        random.shuffle(learning)
        random.shuffle(mastered)

        selected: List[Any] = []

        # 1. Fill with difficult words first
        selected.extend(needs_practice[:target_count])

        # 2. Fill remainder with learning words
        if len(selected) < target_count:
            remainder = target_count - len(selected)
            selected.extend(learning[:remainder])

        # 3. If still not enough, add random mastered words for reinforcement
        if len(selected) < target_count:
            remainder = target_count - len(selected)
            selected.extend(mastered[:remainder])

        return [
            {
                "word": record.word,
                "clue": record.clue or f"Review word: {record.word}",
                "reading": record.reading,
            }
            for record in selected
        ]


---
learning/mastery_tracker.py
---
"""Vocabulary Mastery and Spaced Learning Classifier."""
from __future__ import annotations

from datetime import datetime, timezone
from config.settings import settings

from core.enums import HintTier, MasteryLevel
from core.models import PlayerProfile, WordEntry, WordMasteryRecord


class MasteryTracker:
    """Classifies vocabulary familiarity based on solve velocity, error rate, and hint dependency."""

    @staticmethod
    def update_word_progress(
        profile: PlayerProfile,
        word_entry: WordEntry,
        solve_time_seconds: float,
        error_clicks: int = 0,
        language: str = settings.get("default_language", "en"),
    ) -> WordMasteryRecord:
        """Updates or creates a vocabulary mastery record in the player's profile."""
        key = f"{language}:{word_entry.word.upper()}"
        record = profile.vocabulary_deck.get(key)

        if not record:
            record = WordMasteryRecord(
                word=word_entry.word,
                language=language,
                clue=word_entry.clue,
                reading=word_entry.reading,
            )
            profile.vocabulary_deck[key] = record

        # Update stats
        record.times_encountered += 1
        if word_entry.found:
            record.times_solved += 1
            record.total_solve_time_seconds += solve_time_seconds

        record.hint_tiers_history.append(int(word_entry.hint_tier_used))
        record.error_clicks += error_clicks
        record.last_encountered_at = datetime.now(timezone.utc).isoformat()

        # Classify mastery
        record.mastery_level = MasteryTracker.evaluate_mastery_level(record)
        return record

    @staticmethod
    def evaluate_mastery_level(record: WordMasteryRecord) -> MasteryLevel:
        """Determines if a word is MASTERED, LEARNING, or NEEDS_PRACTICE."""
        if record.times_solved == 0:
            return MasteryLevel.NEEDS_PRACTICE

        avg_time = record.average_solve_time
        max_hint = max(record.hint_tiers_history) if record.hint_tiers_history else 0

        # Mastered: solved at least twice, very fast (<=15s), minimal hints
        if record.times_solved >= 2 and avg_time <= 15.0 and max_hint <= int(HintTier.TIER_2_WORD_NAME):
            return MasteryLevel.MASTERED

        # Needs practice: slow (>45s) or required heavy hints (Tier 4+) or high errors
        if avg_time > settings.get("mastery_needs_practice_threshold", 45.0) or max_hint >= int(HintTier.TIER_4_ORIENTATION) or (record.error_clicks / record.times_encountered) >= 3:
            return MasteryLevel.NEEDS_PRACTICE

        return MasteryLevel.LEARNING


---
learning/vocabulary_deck.py
---
"""Searchable and Filterable Vocabulary Deck."""
from __future__ import annotations

from typing import List, Optional

from core.enums import MasteryLevel
from core.models import PlayerProfile, WordMasteryRecord


class VocabularyDeckManager:
    """Provides querying and filtering over the player's saved vocabulary records."""

    @staticmethod
    def filter_words(
        profile: PlayerProfile,
        language: Optional[str] = None,
        mastery_level: Optional[MasteryLevel] = None,
        search_query: Optional[str] = None,
    ) -> List[WordMasteryRecord]:
        """Filters player vocabulary records by language, level, and text query."""
        results = list(profile.vocabulary_deck.values())

        if language:
            results = [r for r in results if r.language.lower() == language.lower()]

        if mastery_level:
            results = [r for r in results if r.mastery_level == mastery_level]

        if search_query:
            q = search_query.lower().strip()
            results = [
                r for r in results
                if q in r.word.lower()
                or (r.clue and q in r.clue.lower())
                or (r.reading and q in r.reading.lower())
            ]

        # Sort by most recently encountered
        results.sort(key=lambda r: r.last_encountered_at, reverse=True)
        return results

    @staticmethod
    def get_summary_stats(profile: PlayerProfile, language: Optional[str] = None) -> dict:
        words = list(profile.vocabulary_deck.values())
        if language:
            words = [w for w in words if w.language == language]

        total = len(words)
        mastered = sum(1 for w in words if w.mastery_level == MasteryLevel.MASTERED)
        learning = sum(1 for w in words if w.mastery_level == MasteryLevel.LEARNING)
        needs_practice = sum(1 for w in words if w.mastery_level == MasteryLevel.NEEDS_PRACTICE)

        return {
            "total_words": total,
            "mastered": mastered,
            "learning": learning,
            "needs_practice": needs_practice,
            "mastery_rate": round((mastered / max(1, total)) * 100, 1),
        }


---
main.py
---
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


---
requirements.txt
---
pygame>=2.5.0
pygame-emojis>=0.2.0
google-genai>=1.0.0
python-dotenv>=1.0.0
pydantic>=2.0.0
pytest>=8.0.0
requests>=2.31.0


---
storage/__init__.py
---


---
storage/pack_exporter.py
---
"""Puzzle and Package JSON Exporter."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional

from core.models import Puzzle

DATA_DIR = Path(__file__).parent.parent / "data"
USER_PACKS_DIR = DATA_DIR / "user_packs"


class PackExporter:
    """Exports generated puzzles and user collections into standardized JSON files."""

    @staticmethod
    def export_puzzle_to_json(puzzle: Puzzle, target_path: Path) -> bool:
        """Exports a single completed Puzzle instance to a standalone .puzzle.json file."""
        try:
            target_path.parent.mkdir(parents=True, exist_ok=True)
            with open(target_path, "w", encoding="utf-8") as f:
                f.write(puzzle.model_dump_json(indent=2))
            return True
        except Exception as e:
            print(f"Failed to export puzzle: {e}")
            return False

    @staticmethod
    def export_pack_to_json(
        pack_id: str,
        title: str,
        description: str,
        language: str,
        script_type: str,
        puzzles: List[Dict[str, Any]],
        target_path: Optional[Path] = None,
    ) -> Optional[Path]:
        """Exports a puzzle package dictionary to a .pack.json file."""
        path = target_path or (USER_PACKS_DIR / f"{pack_id}.pack.json")
        payload = {
            "id": pack_id,
            "title": title,
            "description": description,
            "language": language,
            "script_type": script_type,
            "puzzles": puzzles,
        }

        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            with open(path, "w", encoding="utf-8") as f:
                json.dump(payload, f, indent=2, ensure_ascii=False)
            return path
        except Exception as e:
            print(f"Failed to export pack: {e}")
            return None


---
storage/pack_loader.py
---
"""Puzzle Package Loader and Auto-Discovery."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Optional
from config.settings import settings

from core.enums import Difficulty, ScriptType
from core.grid_engine import GridEngine
from core.models import Puzzle

DATA_DIR = Path(__file__).parent.parent / "data"
DEFAULT_PACKS_DIR = DATA_DIR / "packs"
USER_PACKS_DIR = DATA_DIR / "user_packs"


class PuzzlePack:
    """Represents a collection of thematic word search puzzles."""

    def __init__(self, data: Dict[str, Any], filepath: Optional[Path] = None) -> None:
        self.raw_data = data
        self.filepath = filepath
        self.id: str = data.get("id", "pack_unknown")
        self.title: str = data.get("title", "Untitled Pack")
        self.description: str = data.get("description", "")
        self.language: str = data.get("language", settings.get("default_language", "en"))
        self.script_type: ScriptType = ScriptType(data.get("script_type", "latin"))
        self.puzzles_data: List[Dict[str, Any]] = data.get("puzzles", [])

    @property
    def puzzle_count(self) -> int:
        return len(self.puzzles_data)

    def get_puzzle(self, index: int = 0, difficulty: Optional[Difficulty] = None) -> Puzzle:
        """Instantiates and generates a Puzzle object from the specified index in the pack."""
        if not (0 <= index < len(self.puzzles_data)):
            raise IndexError(f"Puzzle index {index} out of range in pack '{self.title}'")

        p_info = self.puzzles_data[index]
        diff = difficulty or Difficulty(p_info.get("difficulty", "easy"))
        words_data = p_info.get("words", [])

        return GridEngine.generate_puzzle(
            words_data=words_data,
            title=p_info.get("title", self.title),
            theme=p_info.get("theme", self.title),
            language=self.language,
            difficulty=diff,
            script_type=self.script_type,
        )


class PackLoader:
    """Discovers, loads, and manages offline puzzle packages."""

    @staticmethod
    def load_pack_from_file(path: Path) -> Optional[PuzzlePack]:
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
                return PuzzlePack(data, filepath=path)
        except Exception as e:
            print(f"Failed to load pack {path}: {e}")
            return None

    @classmethod
    def get_all_available_packs(cls) -> List[PuzzlePack]:
        """Scans data/packs/ and data/user_packs/ for all .pack.json files."""
        packs: List[PuzzlePack] = []
        directories = [DEFAULT_PACKS_DIR, USER_PACKS_DIR]

        for d in directories:
            if d.exists() and d.is_dir():
                for file_path in d.glob("*.pack.json"):
                    pack = cls.load_pack_from_file(file_path)
                    if pack:
                        packs.append(pack)

        # Sort packs by title
        packs.sort(key=lambda p: p.title)
        return packs


---
telemetry/__init__.py
---


---
telemetry/profile_manager.py
---
"""Player Profile Manager and Lifetime Telemetry Persistence."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

from core.enums import GameStatus
from core.game_state import GameState
from core.models import PlayerProfile
from learning.mastery_tracker import MasteryTracker
from telemetry.tracker import SessionTelemetry

DATA_DIR = Path(__file__).parent.parent / "data"
PROFILE_PATH = DATA_DIR / "player_profile.json"


class ProfileManager:
    """Manages persistent player stats and vocabulary mastery across game sessions."""

    def __init__(self, profile_path: Optional[Path] = None) -> None:
        self.profile_path = profile_path or PROFILE_PATH
        self.profile: PlayerProfile = self.load_profile()

    def load_profile(self) -> PlayerProfile:
        """Loads profile from JSON or creates a new empty one."""
        if self.profile_path.exists():
            try:
                with open(self.profile_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    return PlayerProfile.model_validate(data)
            except Exception:
                pass
        return PlayerProfile()

    def save_profile(self) -> None:
        """Saves current player profile to JSON."""
        try:
            self.profile_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.profile_path, "w", encoding="utf-8") as f:
                f.write(self.profile.model_dump_json(indent=2))
        except Exception:
            pass

    def record_completed_session(
        self, game_state: GameState, telemetry: SessionTelemetry
    ) -> None:
        """Updates lifetime stats and vocabulary mastery after game finishes or user gives up."""
        self.profile.total_games_played += 1
        if game_state.status == GameStatus.WON:
            self.profile.total_games_won += 1

        self.profile.total_words_found += len(game_state.found_words)
        self.profile.total_play_time_seconds += telemetry.active_elapsed_seconds

        # Update best velocity
        vel = telemetry.current_velocity
        if vel > 0:
            if self.profile.best_velocity_spw == 0.0 or vel < self.profile.best_velocity_spw:
                self.profile.best_velocity_spw = vel

        # Update vocabulary mastery for all words in the puzzle
        lang = game_state.puzzle.metadata.language
        avg_word_time = vel if vel > 0 else (telemetry.active_elapsed_seconds / max(1, len(game_state.puzzle.words)))

        for word in game_state.puzzle.words:
            err_count = telemetry.error_clicks_per_word.get(word.word, 0)
            MasteryTracker.update_word_progress(
                self.profile,
                word,
                solve_time_seconds=avg_word_time,
                error_clicks=err_count,
                language=lang,
            )

        self.save_profile()


# Global singleton instance
profile_manager = ProfileManager()


---
telemetry/tracker.py
---
"""Focus-Aware Telemetry and Player Performance Metrics Tracker."""
from __future__ import annotations

import time
from typing import Any, Dict, List, Optional, Tuple

from core.models import WordEntry


class SessionTelemetry:
    """Tracks real-time player velocity, accuracy, and focus-aware active playtime."""

    def __init__(self) -> None:
        self.start_wall_time = time.time()
        self.active_elapsed_seconds: float = 0.0
        self.is_focused: bool = True
        self.is_paused: bool = False

        self.word_find_intervals: List[float] = []  # time taken between consecutive finds
        self.last_find_active_time: float = 0.0

        self.valid_selections: int = 0
        self.invalid_selections: int = 0
        self.error_clicks_per_word: Dict[str, int] = {}
        self.hint_requests_count: int = 0

    def on_tick(self, delta_seconds: float) -> None:
        """Accumulates active gameplay time only if window is focused and unpaused."""
        if self.is_focused and not self.is_paused:
            self.active_elapsed_seconds += delta_seconds

    def on_focus_lost(self) -> None:
        """Pauses timer and metrics accumulation when user switches apps or tabs out."""
        self.is_focused = False

    def on_focus_gained(self) -> None:
        """Resumes timer and metrics accumulation when app regains focus."""
        self.is_focused = True

    def on_pause_toggled(self, is_paused: bool) -> None:
        self.is_paused = is_paused

    def record_selection_attempt(self, is_valid: bool, target_word: Optional[str] = None) -> None:
        if is_valid:
            self.valid_selections += 1
        else:
            self.invalid_selections += 1
            if target_word:
                self.error_clicks_per_word[target_word] = self.error_clicks_per_word.get(target_word, 0) + 1

    def record_word_found(self, word_entry: WordEntry) -> float:
        """Records word discovery and returns the interval taken to find this specific word."""
        interval = self.active_elapsed_seconds - self.last_find_active_time
        interval = max(0.1, interval)
        self.word_find_intervals.append(interval)
        self.last_find_active_time = self.active_elapsed_seconds
        return interval

    def record_hint_used(self) -> None:
        self.hint_requests_count += 1

    @property
    def current_velocity(self) -> float:
        """Average seconds per word found (lower is faster)."""
        if not self.word_find_intervals:
            return 0.0
        return sum(self.word_find_intervals) / len(self.word_find_intervals)

    @property
    def accuracy_rate(self) -> float:
        """Percentage of valid selection attempts (0% - 100%)."""
        total = self.valid_selections + self.invalid_selections
        if total == 0:
            return 100.0
        return (self.valid_selections / total) * 100.0

    @property
    def seconds_since_last_find(self) -> float:
        return self.active_elapsed_seconds - self.last_find_active_time

    def summary(self) -> Dict[str, Any]:
        return {
            "active_time_seconds": round(self.active_elapsed_seconds, 1),
            "words_found": len(self.word_find_intervals),
            "average_velocity_spw": round(self.current_velocity, 1),
            "accuracy_percentage": round(self.accuracy_rate, 1),
            "valid_attempts": self.valid_selections,
            "invalid_attempts": self.invalid_selections,
            "hints_used": self.hint_requests_count,
        }


---
tests/__init__.py
---


---
tests/test_assists.py
---
"""Unit tests for Pluggable Assists, Hint Escalation, and Proximity."""
import pytest
from assists.progressive_hints import ProgressiveHintProvider
from assists.proximity_assist import ProximityAssistProvider
from assists.registry import AssistRegistry
from core.enums import Difficulty, HintTier
from core.game_state import GameState
from core.grid_engine import GridEngine


@pytest.fixture
def active_game():
    words = [{"word": "PLANET", "clue": "Celestial body orbiting a star."}]
    puzzle = GridEngine.generate_puzzle(words, difficulty=Difficulty.EASY, custom_dimensions=(12, 12))
    return GameState(puzzle)


def test_progressive_hint_escalation(active_game):
    provider = ProgressiveHintProvider()

    # Hint 1: Clue
    res1 = provider.request_hint(active_game)
    assert res1.tier == HintTier.TIER_1_CLUE
    assert "Celestial body" in res1.message

    # Hint 2: Word Name
    res2 = provider.request_hint(active_game)
    assert res2.tier == HintTier.TIER_2_WORD_NAME
    assert "PLANET" in res2.message

    # Hint 3: First letter
    res3 = provider.request_hint(active_game)
    assert res3.tier == HintTier.TIER_3_FIRST_LETTER
    assert "Starts with 'P'" in res3.message

    # Hint 4: Orientation
    res4 = provider.request_hint(active_game)
    assert res4.tier == HintTier.TIER_4_ORIENTATION

    # Hint 5: Start coordinate
    res5 = provider.request_hint(active_game)
    assert res5.tier == HintTier.TIER_5_START_COORDINATE
    assert len(res5.highlight_coords) == 1

    # Hint 6: Full glow
    res6 = provider.request_hint(active_game)
    assert res6.tier == HintTier.TIER_6_FULL_GLOW
    assert len(res6.highlight_coords) == len("PLANET")


def test_proximity_calculation(active_game):
    provider = ProximityAssistProvider(throttle_interval_seconds=0.0)
    target = active_game.puzzle.words[0]
    start_r, start_c = target.start_coord

    # Clicking exact start cell should return BURNING
    res = provider.calculate_proximity(active_game, (start_r, start_c))
    assert res["status"] == "BURNING"
    assert res["distance"] == 0.0

    # Pick the furthest opposite corner on the 12x12 board
    far_r = 0 if start_r > 6 else 11
    far_c = 0 if start_c > 6 else 11
    res_far = provider.calculate_proximity(active_game, (far_r, far_c))
    assert res_far["distance"] >= 4.0
    assert res_far["status"] in ("COOL", "COLD")


def test_assist_registry_dispatch(active_game):
    registry = AssistRegistry()
    tick_events = registry.on_tick(active_game, 1.0)
    assert isinstance(tick_events, list)

    target = active_game.puzzle.words[0]
    click_events = registry.on_cell_clicked(active_game, target.start_coord)
    assert len(click_events) > 0


---
tests/test_font_manager.py
---
"""Tests for Multilingual & Native Emoji Composite Font Manager."""
from gui.font_manager import font_manager


def test_font_manager_initialization():
    font_manager.init()
    assert font_manager._initialized is True
    assert font_manager._emoji_font is not None


def test_font_manager_render_ascii_and_multilingual():
    font_manager.init()
    surf_ascii = font_manager.render("Hello World", 18, (255, 255, 255))
    assert surf_ascii.get_width() > 0
    assert surf_ascii.get_height() > 0

    surf_spanish = font_manager.render("✓ MONTAÑA", 18, (255, 255, 255))
    assert surf_spanish.get_width() > 0

    surf_japanese = font_manager.render("日本語 ひらがな", 18, (255, 255, 255))
    assert surf_japanese.get_width() > 0


def test_font_manager_render_native_emojis_and_symbols():
    font_manager.init()
    test_cases = [
        "Play ▶",
        "📦 Offline Packs",
        "✨ AI Topic",
        "📝 AI Notes",
        "✏️ Custom List",
        "📚 Study Deck",
        "🌓",
        "⏱️ Timed Attack",
        "🚀 Generate Puzzle",
        "🔍 Extract & Play",
        "Level 1: Easy (6x6) 🎯",
        "💡 Hint",
    ]

    for tc in test_cases:
        surf = font_manager.render(tc, 20, (255, 255, 255))
        assert surf.get_width() > 0, f"Rendered surface width is 0 for {tc}"
        assert surf.get_height() > 0, f"Rendered surface height is 0 for {tc}"


def test_font_manager_surface_caching():
    font_manager.init()
    surf1 = font_manager.render("Caching Test 🎯", 20, (255, 255, 255))
    surf2 = font_manager.render("Caching Test 🎯", 20, (255, 255, 255))
    assert surf1 is surf2


---
tests/test_game_state.py
---
"""Unit tests for Game State Machine, Selection, Timed Mode, and Give Up."""
import pytest
from core.enums import Difficulty, GameMode, GameStatus
from core.game_state import GameState
from core.grid_engine import GridEngine


@pytest.fixture
def sample_game_state():
    words = [
        {"word": "CAT", "clue": "Feline pet"},
        {"word": "DOG", "clue": "Canine companion"},
    ]
    puzzle = GridEngine.generate_puzzle(words, difficulty=Difficulty.EASY)
    return GameState(puzzle, mode=GameMode.TIMED_ATTACK)


def test_straight_line_interpolation(sample_game_state):
    # Horizontal line
    line = sample_game_state.interpolate_line((0, 0), (0, 3))
    assert line == [(0, 0), (0, 1), (0, 2), (0, 3)]

    # Vertical line
    line = sample_game_state.interpolate_line((1, 2), (3, 2))
    assert line == [(1, 2), (2, 2), (3, 2)]

    # Diagonal line
    line = sample_game_state.interpolate_line((1, 1), (3, 3))
    assert line == [(1, 1), (2, 2), (3, 3)]

    # Non-straight line (invalid knight move / non-45-degree)
    line = sample_game_state.interpolate_line((0, 0), (1, 3))
    assert line == []


def test_word_selection_forward_and_reverse(sample_game_state):
    target_word = sample_game_state.puzzle.words[0]
    start_coord = target_word.coords[0]
    end_coord = target_word.coords[-1]

    # Forward drag
    valid, found_entry, coords = sample_game_state.check_selection(start_coord, end_coord)
    assert valid is True
    assert found_entry is not None
    assert found_entry.word == target_word.word
    assert target_word.found is True


def test_timed_attack_and_bonus_time(sample_game_state):
    initial_time = sample_game_state.time_remaining
    sample_game_state.tick(10.0)
    assert sample_game_state.time_remaining == initial_time - 10.0

    # Finding a word adds bonus time
    word2 = sample_game_state.puzzle.words[1]
    sample_game_state.check_selection(word2.coords[0], word2.coords[-1])
    assert sample_game_state.time_remaining == (initial_time - 10.0 + sample_game_state.bonus_per_word)


def test_give_up_and_learn_state(sample_game_state):
    assert sample_game_state.status == GameStatus.PLAYING
    sample_game_state.give_up()
    assert sample_game_state.status == GameStatus.GIVEN_UP
    assert sample_game_state.revealed_all_on_giveup is True
    # All word coordinates should be in found_coords_map
    for w in sample_game_state.puzzle.words:
        for c in w.coords:
            assert c in sample_game_state.found_coords_map


---
tests/test_grid_engine.py
---
"""Unit tests for the Grid Engine, Placement, and Unicode/CJK Scripts."""
import pytest
from core.enums import Difficulty, Direction, ScriptType
from core.grid_engine import GridEngine, calculate_optimal_dimensions, get_allowed_directions
from core.scripts import detect_script, get_character_pool


def test_allowed_directions():
    easy_dirs = get_allowed_directions(Difficulty.EASY)
    assert Direction.HORIZONTAL_LR in easy_dirs
    assert Direction.VERTICAL_TB in easy_dirs
    assert Direction.HORIZONTAL_RL not in easy_dirs

    med_dirs = get_allowed_directions(Difficulty.MEDIUM)
    assert Direction.DIAGONAL_TL_BR in med_dirs
    assert Direction.HORIZONTAL_RL not in med_dirs

    hard_dirs = get_allowed_directions(Difficulty.HARD)
    assert len(hard_dirs) == 8


def test_script_detection():
    assert detect_script(["HELLO", "WORLD"]) == ScriptType.LATIN
    assert detect_script(["MONTAÑA", "VOLCÁN", "PINGÜINO"]) == ScriptType.LATIN_ACCENTED
    assert detect_script(["ありがとう", "さくら", "やま"]) == ScriptType.HIRAGANA
    assert detect_script(["コンピューター", "テスト"]) == ScriptType.KATAKANA
    assert detect_script(["日月", "学校", "先生"]) == ScriptType.KANJI


def test_english_puzzle_generation():
    words = [
        {"word": "PYTHON", "clue": "A popular programming language."},
        {"word": "SEARCH", "clue": "To find something."},
        {"word": "GAME", "clue": "An activity for fun."},
    ]
    puzzle = GridEngine.generate_puzzle(
        words_data=words,
        title="Coding Test",
        theme="Programming",
        difficulty=Difficulty.EASY,
    )

    assert puzzle.rows >= 8
    assert puzzle.cols >= 8
    assert len(puzzle.words) == 3
    assert all(len(w.coords) == len(w.word) for w in puzzle.words)

    # Verify grid contains the word characters at placed coords
    for w in puzzle.words:
        chars_on_grid = "".join(puzzle.grid[r][c] for r, c in w.coords)
        assert chars_on_grid == w.word


def test_spanish_accented_puzzle_generation():
    words = [
        {"word": "VOLCÁN", "clue": "Estructura geológica."},
        {"word": "PINGÜINO", "clue": "Ave marina polar."},
        {"word": "MONTAÑA", "clue": "Elevación de terreno."},
    ]
    puzzle = GridEngine.generate_puzzle(
        words_data=words,
        title="Español Test",
        theme="Naturaleza",
        difficulty=Difficulty.MEDIUM,
        script_type=ScriptType.LATIN_ACCENTED,
    )

    assert puzzle.metadata.script_type == ScriptType.LATIN_ACCENTED
    assert len(puzzle.words) == 3
    for w in puzzle.words:
        chars_on_grid = "".join(puzzle.grid[r][c] for r, c in w.coords)
        assert chars_on_grid == w.word


def test_japanese_hiragana_puzzle_generation():
    words = [
        {"word": "ありがとう", "clue": "Thank you", "reading": "arigatou"},
        {"word": "さくら", "clue": "Cherry blossom", "reading": "sakura"},
        {"word": "せんせい", "clue": "Teacher", "reading": "sensei"},
    ]
    puzzle = GridEngine.generate_puzzle(
        words_data=words,
        title="Japanese Test",
        theme="Greetings",
        difficulty=Difficulty.EASY,
        script_type=ScriptType.HIRAGANA,
    )

    assert puzzle.metadata.script_type == ScriptType.HIRAGANA
    assert len(puzzle.words) == 3
    for w in puzzle.words:
        chars_on_grid = "".join(puzzle.grid[r][c] for r, c in w.coords)
        assert chars_on_grid == w.word


def test_dynamic_distractor_shift():
    words = [{"word": "ALPHA", "clue": "First letter"}]
    puzzle = GridEngine.generate_puzzle(words, difficulty=Difficulty.DYNAMIC)

    word_coords = set(puzzle.words[0].coords)
    initial_word_chars = [puzzle.grid[r][c] for r, c in word_coords]

    # Shift distractor cells
    GridEngine.shift_distractor_cells(puzzle)

    # Word characters must remain intact!
    new_word_chars = [puzzle.grid[r][c] for r, c in word_coords]
    assert initial_word_chars == new_word_chars


---
tests/test_mastery.py
---
"""Unit tests for Vocabulary Mastery, Spaced Learning, and Review Deck."""
import pytest
from core.enums import HintTier, MasteryLevel
from core.models import PlayerProfile, WordEntry
from learning.adaptive_recommender import AdaptiveRecommender
from learning.mastery_tracker import MasteryTracker
from learning.vocabulary_deck import VocabularyDeckManager


def test_mastery_classification():
    profile = PlayerProfile()
    word_fast = WordEntry(word="FAST", clue="High speed", found=True)

    # Solve fast 2 times -> MASTERED
    MasteryTracker.update_word_progress(profile, word_fast, solve_time_seconds=5.0, language="en")
    rec = MasteryTracker.update_word_progress(profile, word_fast, solve_time_seconds=6.0, language="en")
    assert rec.mastery_level == MasteryLevel.MASTERED

    # Word needing practice (slow and heavy hints)
    word_hard = WordEntry(word="DIFFICULT", clue="Hard concept", found=True, hint_tier_used=HintTier.TIER_5_START_COORDINATE)
    rec2 = MasteryTracker.update_word_progress(profile, word_hard, solve_time_seconds=60.0, language="en")
    assert rec2.mastery_level == MasteryLevel.NEEDS_PRACTICE


def test_vocabulary_deck_filtering():
    profile = PlayerProfile()
    w1 = WordEntry(word="GALAXY", clue="Star system", found=True)
    w2 = WordEntry(word="NEBULA", clue="Dust cloud", found=True, hint_tier_used=HintTier.TIER_6_FULL_GLOW)

    MasteryTracker.update_word_progress(profile, w1, solve_time_seconds=5.0, language="en")
    MasteryTracker.update_word_progress(profile, w1, solve_time_seconds=5.0, language="en")
    MasteryTracker.update_word_progress(profile, w2, solve_time_seconds=70.0, language="en")

    mastered = VocabularyDeckManager.filter_words(profile, mastery_level=MasteryLevel.MASTERED)
    assert len(mastered) == 1
    assert mastered[0].word == "GALAXY"

    needs_prac = VocabularyDeckManager.filter_words(profile, mastery_level=MasteryLevel.NEEDS_PRACTICE)
    assert len(needs_prac) == 1
    assert needs_prac[0].word == "NEBULA"


def test_adaptive_recommender():
    profile = PlayerProfile()
    w_hard = WordEntry(word="HARDWORD", clue="Hard clue", found=True, hint_tier_used=HintTier.TIER_5_START_COORDINATE)
    MasteryTracker.update_word_progress(profile, w_hard, solve_time_seconds=90.0, language="en")

    review_list = AdaptiveRecommender.get_review_words(profile, language="en", target_count=5)
    assert len(review_list) >= 1
    assert review_list[0]["word"] == "HARDWORD"


---
tests/test_storage.py
---
"""Unit tests for JSON Package Discovery, Loading, and Export."""
import json
from pathlib import Path
import pytest
from core.enums import Difficulty
from storage.pack_exporter import PackExporter
from storage.pack_loader import PackLoader


def test_discover_and_load_bundled_packs():
    packs = PackLoader.get_all_available_packs()
    assert len(packs) >= 3

    pack_ids = [p.id for p in packs]
    assert "english_science" in pack_ids
    assert "spanish_general" in pack_ids
    assert "japanese_basics" in pack_ids

    # Generate a puzzle from English pack
    eng_pack = next(p for p in packs if p.id == "english_science")
    puzzle = eng_pack.get_puzzle(index=0, difficulty=Difficulty.EASY)
    assert puzzle.total_words > 0
    assert puzzle.rows >= 8


def test_export_and_import_roundtrip(tmp_path):
    sample_pack_id = "test_custom_pack"
    puzzles_data = [{
        "id": "p1",
        "title": "Custom Test Puzzle",
        "difficulty": "easy",
        "words": [{"word": "ALPHA", "clue": "First"}, {"word": "BETA", "clue": "Second"}]
    }]

    target_file = tmp_path / "custom.pack.json"
    exported_path = PackExporter.export_pack_to_json(
        pack_id=sample_pack_id,
        title="Custom Title",
        description="Testing pack export",
        language="en",
        script_type="latin",
        puzzles=puzzles_data,
        target_path=target_file,
    )
    assert exported_path is not None
    assert exported_path.exists()

    loaded_pack = PackLoader.load_pack_from_file(exported_path)
    assert loaded_pack is not None
    assert loaded_pack.title == "Custom Title"
    puzzle = loaded_pack.get_puzzle(0)
    assert puzzle.total_words == 2


---
tests/test_telemetry.py
---
"""Unit tests for Focus-Aware Telemetry and Metrics."""
import pytest
from core.models import WordEntry
from telemetry.tracker import SessionTelemetry


def test_focus_aware_time_tracking():
    tel = SessionTelemetry()
    tel.on_tick(5.0)
    assert tel.active_elapsed_seconds == 5.0

    # User leaves app (focus lost)
    tel.on_focus_lost()
    tel.on_tick(5.0)
    assert tel.active_elapsed_seconds == 5.0  # Must not accumulate time!

    # User returns
    tel.on_focus_gained()
    tel.on_tick(2.0)
    assert tel.active_elapsed_seconds == 7.0


def test_velocity_and_accuracy():
    tel = SessionTelemetry()
    tel.on_tick(10.0)

    # 1 invalid selection attempt
    tel.record_selection_attempt(is_valid=False)

    # 1 valid selection and word found
    tel.record_selection_attempt(is_valid=True)
    word = WordEntry(word="TEST", clue="A test word")
    tel.record_word_found(word)

    assert tel.accuracy_rate == 50.0
    assert tel.current_velocity == 10.0


---
