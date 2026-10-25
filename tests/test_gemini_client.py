"""Tests for GeminiClient configuration, dynamic model selection, and fallbacks."""
import os
import unittest
from ai.gemini_client import GeminiClient
from config.settings import settings


class TestGeminiClient(unittest.TestCase):
    def test_available_models_defined(self):
        self.assertIn("gemini-3.5-flash-lite", GeminiClient.AVAILABLE_MODELS)
        self.assertIn("gemini-3.1-flash-lite", GeminiClient.AVAILABLE_MODELS)
        self.assertIn("gemini-3.8-flash", GeminiClient.AVAILABLE_MODELS)

    def test_default_model_initialization(self):
        client = GeminiClient(api_key="test-key")
        self.assertIsNotNone(client.model_name)
        self.assertEqual(client.model_name, settings.get("gemini_model", "gemini-3.5-flash-lite"))

    def test_custom_model_initialization(self):
        client = GeminiClient(api_key="test-key", model_name="gemini-3.8-flash")
        self.assertEqual(client.model_name, "gemini-3.8-flash")

    def test_set_model(self):
        client = GeminiClient(api_key="test-key", model_name="gemini-3.5-flash-lite")
        client.set_model("gemini-3.1-flash-lite")
        self.assertEqual(client.model_name, "gemini-3.1-flash-lite")

    def test_is_configured(self):
        unconfigured = GeminiClient(api_key="")
        self.assertFalse(unconfigured.is_configured)

        placeholder = GeminiClient(api_key="your_gemini_api_key_here")
        self.assertFalse(placeholder.is_configured)

        configured = GeminiClient(api_key="AIzaSyValidMockKey")
        self.assertTrue(configured.is_configured)


if __name__ == "__main__":
    unittest.main()
