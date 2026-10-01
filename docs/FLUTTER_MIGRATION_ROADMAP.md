# Flutter & Dart Cross-Platform Migration Roadmap

This document outlines the technical blueprint for migrating the **AI Multilingual Word Search** game from its decoupled Python engine to a native, high-performance Flutter/Dart application targeting iOS, Android (Google Play Store), macOS, Windows, and Web (PWA).

---

## 1. Architecture Mapping (Python → Dart)

Because the Python engine was designed with strict decoupling (zero GUI dependency in `core/`, `learning/`, `assists/`, `telemetry/`, and `storage/`), the business logic maps 1:1 to Dart domain models and services using a Feature-First structure.

> For the live tracking of migrated components, design decisions, and synchronization steps with the Python codebase, see [docs/MIGRATION_LOG.md](MIGRATION_LOG.md).

| Python Component | Dart / Flutter Path | Status | Purpose |
| :--- | :--- | :--- | :--- |
| `core/enums.py` | `word_search_app/lib/core/models/enums.dart` | ✅ Complete | Dart 3 enums with delta vectors, human-readable labels, and serialization |
| `core/models.py` | `word_search_app/lib/core/models/` (`word_entry.dart`, `puzzle.dart`, etc.) | ✅ Complete | Immutable data classes using `Equatable`, `copyWith`, and JSON parsing |
| `core/scripts.py` | `word_search_app/lib/core/constants/scripts.dart` | ✅ Complete | Unicode & CJK character pools (Hiragana, Katakana, Kanji, Spanish, Cyrillic) |
| `core/grid_engine.py` | `word_search_app/lib/core/engine/grid_engine.dart` | ✅ Complete | 8-way directional word placement, density calculation, and distractor shifting |
| `core/game_state.py` | `word_search_app/lib/features/word_search/application/game_provider.dart` | ✅ Complete | State management using `flutter_riverpod` (Notifier & State) |
| `assists/` | `word_search_app/lib/features/word_search/application/assists_service.dart` | ✅ Complete | Pluggable assist providers (Proximity radar, 6-Tier Hints, Inactivity detector) |
| `gui/views/board_view.py` | `word_search_app/lib/features/word_search/presentation/widgets/board_widget.dart` | ✅ Complete | Custom `GestureDetector` + `CustomPainter` with straight-line drag snapping |
| `learning/` & `telemetry/` | `word_search_app/lib/features/learning/application/` | ✅ Complete | Spaced repetition vocabulary tracker and session telemetry |
| `storage/` | `word_search_app/lib/features/word_search/data/pack_repository.dart` | ✅ Complete | JSON asset pack loader, exporter, and local cache |
| `ai/` (`topic_generator.py`) | `word_search_app/lib/features/ai/application/gemini_service.dart` | ✅ Complete | Gemini SDK client (`google_generative_ai`) for AI puzzle generation |

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
