# Learning Things

Learning Things is a SwiftUI learning app for young children across Apple TV, iPhone, and iPad. It presents big, simple visuals, spoken prompts, and touch or remote-friendly navigation for early learning.

The app currently includes:

- letters
- numbers
- shapes
- colours
- a random prompt mode for quick mixed practice
- device voice selection with preview and speech on/off control

## Features

### Learning modes

- **Letters**
  - Browse A–Z.
  - See large uppercase and lowercase letter presentation.
  - Hear the letter and a matching word prompt.

- **Numbers**
  - Browse 0–10.
  - See the number word plus quantity dots in detail view.
  - Hear the spoken number.

- **Shapes**
  - Explore 15 shape types including circle, oval, triangle, square, rectangle, diamond, arrow, heart, crescent, star, cloud, pentagon, hexagon, octagon, and rhombus.
  - Uses custom SwiftUI shape rendering rather than generic symbols.

- **Colours**
  - Browse named colours with strong contrast-aware labels.
  - Colour detail fills the full content area with the selected colour.

- **Random**
  - Generates a random coloured letter, number, or shape prompt.
  - Tap/select once to reveal the answer.
  - Tap/select again to generate the next prompt.

### Voice and speech

Speech is powered by `AVSpeechSynthesizer`.

- Voices can be turned on or off.
- A voice can be selected from the voices installed on the current device.
- Each available voice can be previewed before selection.
- The app keeps the selected voice in persistent storage.
- The voice picker highlights a recommended voice when available.

Speech is used throughout the app for:

- letters
- numbers
- shapes
- colours
- voice previews

## Platform behaviour

### Apple TV

The tvOS experience is designed for the Siri Remote / Apple TV Remote.

- Move with the directional controls.
- Press **Select** to open an item.
- In detail view, use **Left** and **Right** to move between items.
- Press **Play/Pause** to start or stop auto-play.
- Press **Menu/Back** to return from detail to grid, then back to the mode selector.

### iPhone

- Uses the mode-selection flow and grid/detail navigation.
- Layout adapts to portrait and landscape.
- Touch is the primary interaction model.

### iPad

- Uses a dedicated split-view learning interface.
- Sidebar navigation shows modes and items.
- Detail views support horizontal swipe navigation between items.
- Sidebar rows include visual previews for shapes and colours.
- Selection styling is tuned for both light and dark mode.

## Auto-play behaviour

Letters and numbers support auto-play.

- **Grid view:** advances every 1 second
- **Detail view:** advances every 4 seconds

Auto-play stops when the user manually navigates or switches views.

## Data and assets

- Letter words are loaded from `Learn Letters/LetterWords.txt` with fallback data in code.
- Colours are centralized in `Learn Letters/Utilities/LearningPalette.swift`.
- App icons and platform artwork live in `Learn Letters/Assets.xcassets/`.

## Project structure

Main source code lives in `Learn Letters/`.

Key folders:

- `Models/`
  - learning data models such as letters, numbers, shapes, and colours
- `Views/`
  - mode selection, grid/detail screens, random prompt, and voice settings
- `Views/Components/`
  - reusable UI pieces including shape rendering
- `Services/`
  - speech synthesis and voice management
- `Utilities/`
  - layout constants, palette helpers, and orientation handling

Important files:

- `Learn Letters/ContentView.swift`
  - main app orchestration and iPad split-view implementation
- `Learn Letters/Services/LetterSpeaker.swift`
  - voice selection, preview, and speech output
- `Learn Letters/Views/ModeSelectionView.swift`
  - starting screen for learning modes and voice settings
- `Learn Letters/Views/RandomPromptView.swift`
  - mixed random practice mode

## Requirements

- Xcode with SwiftUI support
- Apple platform SDKs for iOS and tvOS

The project is configured for:

- **iOS:** 18.0+
- **tvOS:** 26.5+

## Running the project

1. Open `Learning Things.xcodeproj` in Xcode.
2. Select the shared **Learning Things** scheme.
3. Choose an iPhone, iPad, or Apple TV simulator/device.
4. Build and run.

## Notes

- The app uses Apple's SF Display system font for consistent typography across all platforms.
- Voice availability depends on what is installed on the device.
- Some UI behaviour differs intentionally between tvOS and iPad to fit each platform better.
