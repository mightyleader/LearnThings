# Learning Things

Learning Things is a SwiftUI learning app for young children, designed primarily for Apple TV. Explore letters, numbers, shapes and colours with large visuals and spoken names.

## Learning modes

- **Letters:** Browse A–Z, see uppercase and lowercase letters with example words, and hear each letter and word.
- **Numbers:** Explore 0–10 with number words and dots that show their quantities.
- **Shapes:** Browse familiar geometric shapes in a grid and see each shape with its name in detail.
- **Colours:** Browse 11 named colours; each detail screen fills with that colour and shows its name in contrasting text.

The mode selector also has a **Voices** button for previewing and choosing from the voices available on the device. Speech uses `AVSpeechSynthesizer`.

## Apple TV remote

- Move focus with the directional controls and press **Select** to open a grid item. Select on a detail screen repeats its speech.
- Press **Left** or **Right** in a detail screen to move through items, wrapping at either end.
- Press **Play/Pause** to start or stop automatic sequencing in a grid or detail screen.
- Press **Menu/Back** to return from detail to its grid, then from the grid to the mode selector.

## Open the project

Open `Learning Things.xcodeproj` in Xcode and use its shared **Learning Things** scheme to run the app on an Apple TV simulator or device. The project also includes iOS build settings and icons, but the current interface is optimized for tvOS.

Source files live in `Learn Letters/`; bundled Akzidenz Grotesk fonts are in `Learn Letters/Fonts/`. The shared learning colours are defined in `Learn Letters/Utilities/LearningPalette.swift`, and icon and Top Shelf artwork is in `Learn Letters/Assets.xcassets/`.
