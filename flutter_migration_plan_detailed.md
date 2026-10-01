# Master Flutter Migration & Architecture Plan

**Goal:** Migrate the legacy Python/Pygame word search game to a responsive, multi-platform Flutter app. Address Pygame's smartphone drawbacks (cramped UI, lack of screen orientation control, unneeded virtual keyboards) and establish a pure Dart domain layer.

---

## Phase 1: Environment Setup & Reproduction Docs
- **Target Model:** Gemini 3.8 Flash
- **Reasoning Level:** Low
- [x] Create a `docs/ENVIRONMENT_SETUP.md` file.
- [x] Document the exact commands to install Flutter SDK (Dart 3.x) for the host OS.
- [x] Document the required platform tools (Android Studio for Android SDK/emulators, Xcode for macOS/iOS).
- [x] Document the required VS Code extensions (Flutter, Dart).
- [x] Run `flutter doctor -v` in the terminal to verify the local target execution environment is ready. (Executed: Flutter SDK currently not installed on host machine; see recommendations).

## Phase 2: Project Initialization & Architecture Setup
- **Target Model:** Gemini 3.8 Flash
- **Reasoning Level:** Low
- [x] Run `flutter create --org com.wordsearch word_search_app` in the root (or specified target directory).
- [x] Update `pubspec.yaml` to include core dependencies:
  - `flutter_riverpod` (State Management)
  - `google_generative_ai` (Gemini API Integration)
  - `freezed_annotation` & `json_annotation` (Data modeling)
  - `audioplayers` & `flutter_launcher_icons`
- [x] Delete the default counter app code in `lib/main.dart`.
- [x] Establish the Feature-First directory structure:
  - `lib/core/models/`
  - `lib/core/engine/`
  - `lib/core/utils/`
  - `lib/features/word_search/domain/`
  - `lib/features/word_search/application/`
  - `lib/features/word_search/presentation/widgets/`

## Phase 3: Pure Dart Word Search Domain Engine
- **Target Model:** Claude Sonnet 4.6 (or Opus 4.6 for complex algorithms)
- **Reasoning Level:** High
- [x] **Migrate Models:** Port `core/models.py` to Dart. Created `lib/core/models/word_entry.dart`, `puzzle.dart`, `puzzle_metadata.dart`, `assist_config.dart`, `player_profile.dart`, and `models.dart` (barrel) using pure Dart classes with Equatable (no freezed code generation).
- [x] **Migrate Enums:** Port `core/enums.py` to `lib/core/models/enums.dart` (Direction, Difficulty, ScriptType, GameMode, GameStatus, HintTier, MasteryLevel, AppThemeMode) — Dart 3 enums with switch expressions and `fromValue`/`fromDelta` factory methods.
- [x] **Migrate Engine:** Port `core/grid_engine.py` and `core/scripts.py` to `lib/core/engine/grid_engine.dart` and `lib/core/constants/scripts.dart`. 8-way directional word placement, CJK/Unicode character pools, script auto-detection, word normalisation — 100% framework-agnostic (zero Flutter UI imports).
- [x] **Write Tests:** Created `test/core/grid_engine_test.dart` with 49 tests covering enums, models, script detection, grid generation, boundary collision, directional constraints, distractor shifting, JSON round-trips, and Equatable equality. All 49 tests pass (`flutter test test/core/grid_engine_test.dart`).


## Phase 4: State Management & Game State Logic
- **Target Model:** Claude Sonnet 4.6
- **Reasoning Level:** Medium
- [x] **Migrate Game State:** Port `core/game_state.py` to a Riverpod Notifier at `lib/features/word_search/application/game_provider.dart` and domain model at `lib/features/word_search/domain/game_state.dart`.
- [x] **Implement Timers:** Add the timed attack countdown and active elapsed time tracking to the provider state with periodic and tick step loops.
- [x] **Selection Logic:** Port the line-interpolation logic to validate drag selections (forward and reverse) into the provider (`startSelection`, `updateSelection`, `confirmSelection`, `checkSelection`).
- [x] **Migrate Assists:** Port the proximity radar, 6-tier progressive hint mechanics, auto stall detector, and emergency time bonuses from `assists/` into `lib/features/word_search/application/assists_service.dart`.


## Phase 5: Responsive UI Architecture & Focus Management
- **Target Model:** Claude Sonnet 4.6
- **Reasoning Level:** Medium
- [x] **Base Layout:** Create `lib/features/word_search/presentation/game_screen.dart`. Use `LayoutBuilder` to render a `NavigationBar` + vertical stack on narrow screens, and a `NavigationRail` + side-by-side grid on wide screens.
- [x] **Orientation:** In `main.dart`, use `SystemChrome.setPreferredOrientations` to lock mobile devices to Portrait, while allowing flexible orientations on tablets/desktop.
- [x] **Focus Management:** Wrap the main scaffold body in a `GestureDetector` that calls `FocusScope.of(context).unfocus()` to ensure soft keyboards never pop up unless the AI Prompt text field is explicitly tapped.
- [x] **Grid Painter:** Implement `lib/features/word_search/presentation/widgets/board_widget.dart` using a `CustomPainter` to draw the grid, selection pill highlights, and drag lines smoothly.


## Phase 6: Accessibility (a11y) & Touch Target Polish
- **Target Model:** Claude Sonnet 4.6
- **Reasoning Level:** Medium
- [x] **Touch Targets:** Enforce `BoxConstraints(minWidth: 48, minHeight: 48)` on all interactive HUD buttons and word list cards.
- [x] **Grid Accessibility:** Wrap the `CustomPainter` (or individual grid hitboxes) in `Semantics` widgets. Apply labels like `label: "Letter A at Row 1 Column 2"`.
- [x] **Text Scaling:** Use `FittedBox` or dynamic typography sizing in the Word Bank drawer so that OS-level font scaling does not cause pixel overflow errors (`RenderFlex overflowed`).


## Phase 7: AI Integration, Learning Mode & Cross-Platform Verification
- **Target Model:** Gemini 3.8 Flash
- **Reasoning Level:** Low / Medium
- [x] **Gemini API:** Port `ai/topic_generator.py` to `lib/features/ai/application/gemini_service.dart` using `google_generative_ai` with JSON schema prompts, fallback defaults, and Riverpod DI.
- [x] **Pack Repository:** Port `storage/pack_loader.py` and `pack_exporter.py` to `lib/features/word_search/data/pack_repository.dart` with bundled packs (Science, Computing, Japanese), dynamic JSON loading, and puzzle export.
- [x] **Learning Mode:** Port `learning/` to `lib/features/learning/application/` (`mastery_tracker.dart`, `vocabulary_deck.dart`, `adaptive_recommender.dart`, and `learning_provider.dart`) for spaced repetition mastery classification, deck filtering, and targeted review puzzles.
- [x] **Test Suite & Code Quality:** All 125 unit and widget tests pass 100% via `flutter test`. `flutter analyze` reports No issues found.
- [x] **Build Verification:** Verified web compilation with `flutter build web --wasm`.
- [x] **Finalize:** Updated `docs/FLUTTER_MIGRATION_ROADMAP.md` and migration plans to mark the migration completed.