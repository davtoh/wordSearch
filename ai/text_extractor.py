"""Raw Text Concept and Vocabulary Extractor using Gemini AI."""
from __future__ import annotations

import re
from collections import Counter
from typing import Any, Dict, List

from ai.gemini_client import gemini_client


class TextExtractor:
    """Extracts key vocabulary, domain terms, and definitions from user-pasted text/notes."""

    @staticmethod
    def extract_from_text(
        raw_text: str,
        language: str = "en",
        count: int = 10,
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
