# Master Flutter Migration & Architecture Plan

**Goal:** Migrate the legacy Python/Pygame word search game (detailed in `project_context.md`) to a responsive, multi-platform Flutter app. This migration resolves past mobile UX issues (cramped layouts, fixed orientation, unexpected virtual keyboards, poor tap targets) while establishing a modular, feature-first architecture.

---

## Phase 1: Environment Setup & Documentation (`docs/ENVIRONMENT_SETUP.md`)
- **Target AI Model:** Gemini 3.8 Flash
- **Reasoning Level:** Low
- [x] Create `docs/ENVIRONMENT_SETUP.md` with complete, step-by-step installation instructions for Flutter SDK (Dart 3.x), Android Studio, Xcode, and VS Code extensions.
- [x] Document OS-specific paths and environment variable setups (e.g., `PATH` for macOS/Linux, System Variables for Windows).
- [x] Execute `flutter doctor` in the terminal to verify local machine dependencies.
- [x] Resolve any missing toolchains (e.g., Android cmdline-tools, CocoaPods for iOS) and document the fixes in the setup guide.

*Verification:* `docs/ENVIRONMENT_SETUP.md` exists and is populated. Running `flutter doctor` returns a clean, fully configured status for the target development platforms.

---

## Phase 2: Project Initialization & Modular Folder Structure
- **Target AI Model:** Gemini 3.8 Flash
- **Reasoning Level:** Low / Medium
- [x] Initialize the new Flutter app using `flutter create --org com.wordsearch word_search_app`.
- [x] Configure `pubspec.yaml` with core architectural dependencies: state management (e.g., `flutter_riverpod` or `flutter_bloc`), equality (`equatable`), and functional utilities if needed (`fpdart`).
- [x] Establish a Feature-First directory structure:
  - `lib/core/` (Pure Dart domain logic, constants, base models)
  - `lib/features/word_search/domain/` (Entities, game rules)
  - `lib/features/word_search/application/` (State management, Riverpod/Bloc providers)
  - `lib/features/word_search/presentation/` (UI widgets, pages, layouts)
- [x] Clean up `lib/main.dart` to serve strictly as the bootstrap/entry point.

*Verification:* Project builds cleanly on a local target runner (`flutter run -d chrome` or native emulator) without syntax errors. Folder structure matches the defined architecture.

---

## Phase 3: Core Word Search Engine Migration (Pure Dart Domain Layer)
- **Target AI Model:** Claude Sonnet 4.6 (or Claude Opus 4.6 for complex algorithms)
- **Reasoning Level:** High
- [x] Read `project_context.md` to analyze the existing Python `GridEngine`, `GameState`, and multilingual scripts logic.
- [x] Port the puzzle generation algorithms, grid matrix resolvers, and character script pools into pure Dart classes within `lib/core/` and `lib/features/word_search/domain/`.
- [x] Ensure ZERO Flutter UI imports (`package:flutter/material.dart`, etc.) exist in the domain layer to guarantee framework-agnostic modularity.
- [x] Create a comprehensive unit test suite in `test/core/grid_engine_test.dart` to verify grid generation, boundary collision, and multi-directional word placements.

*Verification:* All 49 pure Dart unit tests pass successfully via `flutter test test/core/grid_engine_test.dart`. `flutter analyze` reports No issues found.


---

## Phase 4: State Management & Game State Logic
- **Target AI Model:** Claude Sonnet 4.6
- **Reasoning Level:** Medium
- [x] Connect the pure Dart domain logic to the application layer using Riverpod (`lib/features/word_search/application/game_provider.dart` & `domain/game_state.dart`).
- [x] Port the pluggable assist mechanics (6-tier progressive hints, proximity radar, auto stall detector, time bonus) into `lib/features/word_search/application/assists_service.dart`.
- [x] Implement timer loops for active elapsed time and Timed Attack countdowns with timeout handling.
- [x] Implement drag selection line interpolation and forward/reverse word validation.

*Verification:* Unit test suite in `test/features/word_search/` passes 100% (36 tests). `flutter analyze` reports No issues found.

---

## Phase 5: Responsive UI Architecture & Focus/Orientation Controls
- **Target AI Model:** Claude Sonnet 4.6
- **Reasoning Level:** Medium / High
- [ ] Implement `LayoutBuilder` and `MediaQuery` wrappers in `lib/features/word_search/presentation/game_screen.dart` to build adaptive screens (e.g., `NavigationRail` + side-by-side grids on Desktop/Web; `NavigationBar` + vertical stacks on Mobile).
- [ ] Implement `lib/features/word_search/presentation/widgets/board_widget.dart` using a `CustomPainter` to draw the grid cells, selection pill highlights, drag line, and hint glows smoothly.
- [ ] Implement strict `FocusNode` management: wrap the scaffold in a `GestureDetector` that calls `FocusScope.of(context).unfocus()` so virtual soft keyboards do not pop up during gameplay.
- [ ] Configure orientation handling in `lib/main.dart` using `SystemChrome.setPreferredOrientations` to lock mobile devices to Portrait, while leaving tablet/web/desktop orientations flexible.

*Verification:* The app UI reflows cleanly without pixel overflow warnings across dynamic window resizes. Tapping grid cells does not trigger the OS virtual keyboard.

---

## Phase 6: Accessibility (a11y) & Interactive UX Polish
- **Target AI Model:** Claude Sonnet 4.6
- **Reasoning Level:** Medium
- [ ] Enforce a minimum touch target size of 48x48 dp across all interactive grid cells, menu buttons, and HUD controls.
- [ ] Wrap all critical interactive components (especially the puzzle grid cells and target words) in `Semantics` widgets with clear accessibility labels (e.g., `label: "Letter A, Row 2, Column 3"`).
- [ ] Support dynamic OS text scaling by using responsive typography that scales without breaking fixed-height containers.
- [ ] Verify that UI color palettes meet WCAG AA contrast standards for both Light and Dark themes.

*Verification:* OS screen reader tools (TalkBack / VoiceOver) correctly pronounce grid positions and button states.

---

## Phase 7: AI Integration, Testing & Multi-Platform Build Check
- **Target AI Model:** Gemini 3.8 Flash
- **Reasoning Level:** Low / Medium
- [ ] Port `ai/topic_generator.py` to `lib/features/ai/application/gemini_service.dart` using the `google_generative_ai` package to fetch custom JSON topics.
- [ ] Write widget interaction tests in `test/features/word_search/presentation/` to simulate drag-selections and button taps.
- [ ] Execute `flutter test` to ensure 100% pass rate on all unit and widget tests.
- [ ] Verify build targets across available platforms:
  - Mobile: `flutter build apk` (or `ios`)
  - Web: `flutter build web --wasm`
  - Desktop: `flutter build macos` / `windows` / `linux`
- [ ] Update `docs/FLUTTER_MIGRATION_ROADMAP.md` to reflect the completed migration.

*Verification:* All tests pass green. Target build commands successfully output ready-to-deploy native binaries and WebAssembly bundles.