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
