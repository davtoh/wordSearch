"""Gemini API Client for AI Word Search Generation."""
from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
import dotenv
import requests

# Load .env file from project root
dotenv.load_dotenv(Path(__file__).parent.parent / ".env")


class GeminiClient:
    """Communicates with Google Gemini API using official SDK or direct REST fallback."""

    def __init__(self, api_key: Optional[str] = None) -> None:
        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        self.model_name = "gemini-2.5-flash"

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.api_key.strip() and not self.api_key.startswith("your_"))

    def generate_json_content(self, system_instruction: str, prompt: str) -> Optional[List[Dict[str, Any]]]:
        """Generates structured JSON list of word entries via Gemini."""
        if not self.is_configured:
            return None

        # 1. Try google-genai SDK if installed
        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=self.api_key)
            response = client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    response_mime_type="application/json",
                    temperature=0.7,
                ),
            )
            if response.text:
                return json.loads(response.text)
        except Exception as sdk_err:
            # Fall back to direct REST request if SDK fails
            pass

        # 2. REST Fallback
        try:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.model_name}:generateContent?key={self.api_key}"
            payload = {
                "contents": [{"parts": [{"text": prompt}]}],
                "systemInstruction": {"parts": [{"text": system_instruction}]},
                "generationConfig": {
                    "responseMimeType": "application/json",
                    "temperature": 0.7,
                },
            }
            resp = requests.post(url, json=payload, timeout=20)
            if resp.status_code == 200:
                data = resp.json()
                text = data["candidates"][0]["content"]["parts"][0]["text"]
                return json.loads(text)
        except Exception as rest_err:
            print(f"Gemini API request failed: {rest_err}")

        return None


# Global singleton instance
gemini_client = GeminiClient()
