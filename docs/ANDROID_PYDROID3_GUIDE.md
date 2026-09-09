# Running on Android with Pydroid 3

This project is fully compatible with **Pydroid 3** on Android phones and tablets, featuring touch-drag word selection, responsive auto-scaling layouts, and offline puzzle packages.

---

## 1. Prerequisites on Pydroid 3

1. Install **Pydroid 3 - IDE for Python 3** from Google Play Store.
2. Open Pydroid 3, open the left side menu, and select **Pip**.
3. Install the required dependencies:
   - Type `pygame` and tap **Install**.
   - Type `pydantic` and tap **Install**.
   - Type `python-dotenv` and tap **Install**.
   - Type `requests` and tap **Install**.
   *(Optional for AI generation: type `google-genai` and tap Install)*.

---

## 2. Copying & Opening the Project

1. Copy the `wordSearch` directory into your device storage (e.g. `/sdcard/Documents/wordSearch/` or Google Drive synced folder).
2. If using Gemini AI, create or copy `.env` in the root folder with:
   ```bash
   GEMINI_API_KEY=your_key_here
   ```
3. In Pydroid 3, tap **Open** $\rightarrow$ Navigate to `wordSearch/main.py`.

---

## 3. Running the Game

1. Tap the big yellow **Play ▶** button at the bottom right.
2. The Pygame window will launch in full screen with touch support:
   - **Drag across letters** to select words in 8 directions.
   - **Tap individual cells** to receive "Hot & Cold" proximity feedback.
   - **Tap the 💡 Hint button** or word cards to escalate progressive hints.
   - **Tap 🌓** to toggle Dark / Light mode.
   - **Tap 📚 Study Deck** to inspect your learned vocabulary.

---

## 4. Troubleshooting on Mobile

- **Font Missing Glyph Issues**: The game includes automatic fallback detection for Android system fonts (`DroidSansFallback`, `NotoSansCJK`).
- **Screen Resolution**: The GUI automatically senses mobile screen dimensions and scales the cell sizes appropriately for portrait or landscape orientations.
