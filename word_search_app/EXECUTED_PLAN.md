# EXECUTED PLAN: Task 2 - Pack Library & JSON Import/Export View

## Current Objective
Implement Task 2:
- Target files:
  - `lib/features/packs/presentation/pack_library_screen.dart`
  - `lib/features/packs/data/pack_repository.dart`
- Requirements:
  - Built-in script pools (Spanish accents, Hiragana, Katakana, Kanji, Cyrillic) ported from `core/scripts.py` rendered as rich interactive UI cards.
  - JSON file import button (file_picker integration) to load external word search packs.
  - Export functionality to serialize active puzzles into standard JSON schemas.
  - Test suite at `test/features/packs/pack_repository_test.dart` verified with:
    `flutter test test/features/packs/pack_repository_test.dart`.

## Step Progress
- [x] Initialized workspace and checked git status.
- [x] Added `file_picker` dependency to `pubspec.yaml`.
- [ ] Implement `lib/features/packs/data/pack_repository.dart` with:
  - `PuzzlePack` and `PackRepository` models & repository.
  - Built-in packs including Spanish accents, Hiragana, Katakana, Kanji, Cyrillic (ported from `core/scripts.py` & `core/constants/scripts.dart`).
  - Serialization / export of active puzzles & packs into standard JSON.
  - Integration with file importer / JSON loader.
- [ ] Connect `lib/features/word_search/data/pack_repository.dart` to export or align with `features/packs/data/pack_repository.dart`.
- [ ] Implement `lib/features/packs/presentation/pack_library_screen.dart` with:
  - UI cards for built-in script pools (Spanish accents, Hiragana, Katakana, Kanji, Cyrillic) displaying script badges, sample characters, and word counts.
  - File picker button to import JSON packs.
  - Export button for active puzzles / packs to JSON with share/download/preview dialog.
  - Play button / tap on pack/puzzle to start game or preview.
- [ ] Update `lib/app_router.dart` to use the new `PackLibraryScreen` from `lib/features/packs/presentation/pack_library_screen.dart`.
- [ ] Write unit & widget tests in `test/features/packs/pack_repository_test.dart`.
- [ ] Run `flutter test test/features/packs/pack_repository_test.dart` and full test suite.
