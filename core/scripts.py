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

    # Return script with the highest representation
    best_script = max(counts.items(), key=lambda item: item[1])[0]
    return best_script


def normalize_word_for_puzzle(word: str, script: ScriptType) -> str:
    """Normalizes whitespace and casing according to the script."""
    cleaned = "".join(word.strip().split())
    if script in (ScriptType.LATIN, ScriptType.LATIN_ACCENTED, ScriptType.CYRILLIC):
        return cleaned.upper()
    return cleaned
