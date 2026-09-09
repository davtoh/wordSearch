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
