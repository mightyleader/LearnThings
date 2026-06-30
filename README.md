# Learn Letters

A simple tvOS SwiftUI app for learning the alphabet.

## Current features

- White minimal letter card with uppercase and lowercase side by side
- Left and right remote navigation on the featured card
- Focusable A–Z browser grid
- Example word for every letter
- Spoken letter and word using speech synthesis

## Project structure

- `Learn Letters/ContentView.swift` — main learning experience
- `Learn Letters/Learn_LettersApp.swift` — app entry point

## Running the app

Open the project in Xcode and run the `Learn Letters` scheme on an Apple TV simulator or device.

## Custom fonts

The app is set up to use:

- `AkzidenzGroteskBE-Md` for letters
- `AkzidenzGroteskBE-Light` for example words

Put font files in:

- `Learn Letters/Fonts/`

Then in Xcode:

1. Drag the font files into the `Learn Letters/Fonts/` group.
2. Check **Copy items if needed**.
3. Ensure the `Learn Letters` target is selected.
4. In target settings, add each font file name to **Info > Fonts provided by application**.

If a font is missing or not registered yet, the UI falls back to a system font.

## Interaction

- Move focus to the large letter card and swipe left/right to change letters
- Browse the alphabet grid to jump directly to a letter
- Press **Speak** or click the large card to hear the current letter and word
