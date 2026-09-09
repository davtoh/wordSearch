"""Tests for Multilingual & Native Emoji Composite Font Manager."""
from gui.font_manager import font_manager


def test_font_manager_initialization():
    font_manager.init()
    assert font_manager._initialized is True
    assert font_manager._emoji_font is not None


def test_font_manager_render_ascii_and_multilingual():
    font_manager.init()
    surf_ascii = font_manager.render("Hello World", 18, (255, 255, 255))
    assert surf_ascii.get_width() > 0
    assert surf_ascii.get_height() > 0

    surf_spanish = font_manager.render("✓ MONTAÑA", 18, (255, 255, 255))
    assert surf_spanish.get_width() > 0

    surf_japanese = font_manager.render("日本語 ひらがな", 18, (255, 255, 255))
    assert surf_japanese.get_width() > 0


def test_font_manager_render_native_emojis_and_symbols():
    font_manager.init()
    test_cases = [
        "Play ▶",
        "📦 Offline Packs",
        "✨ AI Topic",
        "📝 AI Notes",
        "✏️ Custom List",
        "📚 Study Deck",
        "🌓",
        "⏱️ Timed Attack",
        "🚀 Generate Puzzle",
        "🔍 Extract & Play",
        "Level 1: Easy (6x6) 🎯",
        "💡 Hint",
    ]

    for tc in test_cases:
        surf = font_manager.render(tc, 20, (255, 255, 255))
        assert surf.get_width() > 0, f"Rendered surface width is 0 for {tc}"
        assert surf.get_height() > 0, f"Rendered surface height is 0 for {tc}"


def test_font_manager_surface_caching():
    font_manager.init()
    surf1 = font_manager.render("Caching Test 🎯", 20, (255, 255, 255))
    surf2 = font_manager.render("Caching Test 🎯", 20, (255, 255, 255))
    assert surf1 is surf2
