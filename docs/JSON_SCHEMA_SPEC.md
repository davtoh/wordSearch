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
