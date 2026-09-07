"""AI-Powered Topic and Subject Word Search Generator."""
from __future__ import annotations

from typing import Any, Dict, List

from ai.gemini_client import gemini_client


class TopicGenerator:
    """Generates thematic vocabulary words and educational clues using Gemini AI."""

    @staticmethod
    def generate_words(
        topic: str,
        language: str = "en",
        count: int = 10,
        difficulty: str = "medium",
        script: str = "latin",
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
