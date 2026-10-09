# Learning Things

Learning Things is a SwiftUI learning app for young children across Apple TV, iPhone, and iPad. It uses large visuals, simple navigation, and spoken prompts to support early learning across letters, numbers, shapes, colours, and mixed practice.

## Features

### Learning modes

- **Letters**
  - Browse A–Z.
  - See large uppercase and lowercase letters with a matching word.
  - Hear the letter name and a spoken phrase.

- **Numbers**
  - Browse 0–10.
  - See the number word and matching quantity dots.
  - Hear the number name and spoken phrase.

- **Shapes**
  - Explore 15 shapes including circle, oval, triangle, square, rectangle, diamond, arrow, heart, crescent, star, cloud, pentagon, hexagon, octagon, and rhombus.
  - Uses custom SwiftUI shape rendering rather than SF Symbols for the learning content.

- **Colours**
  - Browse named colours with contrast-aware labels.
  - Colour detail fills the content area with the selected colour.

- **Random**
  - Generates a random coloured letter, number, or shape.
  - Reveal the answer on tap/select.
  - Advance to the next prompt with another tap/select.
  - Excludes grey, black, and white from the random colour pool for visibility.

### Voice and speech

Speech is powered by `AVSpeechSynthesizer`.

- Voices can be turned on or off.
- A voice can be selected from the voices available on the current device.
- Voice selection persists across launches.
- Voice previews are available in the voice picker.
- All speech is suppressed when voices are turned off.

Speech is used throughout the app for:

- letters
- numbers
- shapes
- colours
- voice previews

## Platform behaviour

### Apple TV

The tvOS experience is designed for the Apple TV remote.

- Move with the directional controls.
- Press **Select** to open an item.
- In detail view, use **Left** and **Right** to move between items.
- Press **Play/Pause** to start or stop auto-play where supported.
- Press **Menu/Back** to return from detail to grid, then back to the mode selector.

### iPhone

- Uses the mode-selection flow and grid/detail navigation.
- Uses touch as the primary interaction model.
- Shares the legacy grid/detail structure with tvOS-style content flows.

### iPad

- Uses a dedicated split-view interface built with `NavigationSplitView`.
- Shows learning modes in the sidebar, then the items for the selected mode.
- Uses larger sidebar rows, icons, and labels sized for easier child interaction.
- Shows poster-style placeholder pages for **Letters**, **Numbers**, **Shapes**, and **Colours** before an individual item is selected.
- Poster items can be tapped directly to open the matching detail view and sync the sidebar selection.
- Detail views support horizontal swipe navigation.
- Detail views also support left/right tap zones for previous/next navigation.
- Sidebar rows include visual previews for shapes and colours.
- Selection styling is tuned for both light and dark mode.

## Navigation behaviour

### Auto-play

Letters and numbers support auto-play.

- **Grid view:** advances every 1 second
- **Detail view:** advances every 4 seconds

Auto-play stops when the user manually navigates or switches views.

### Tap and swipe navigation

- On iPad detail views, swiping left/right moves between adjacent items.
- On iPad detail views, tapping the left side moves to the previous item and tapping the right side moves to the next item.
- In the random prompt mode, tapping reveals the answer first and then advances to another prompt.

## Data and assets

- Letter words are loaded from `Learn Letters/LetterWords.txt` with fallback data in code.
- Colours are centralized in `Learn Letters/Utilities/LearningPalette.swift`.
- App icons and platform artwork live in `Learn Letters/Assets.xcassets/`.
- Poster reference artwork lives in `Posters/`.

## Project structure

Main source code lives in `Learn Letters/`.

### Key folders

- `Models/`
  - learning data models for letters, numbers, shapes, and colours
- `Views/`
  - mode selection, grid/detail screens, random prompt, and voice settings
- `Views/Components/`
  - reusable UI pieces including shape rendering and styled letter labels
- `Services/`
  - speech synthesis and voice management
- `Utilities/`
  - layout constants, palette helpers, and orientation handling

### Important files

- `Learn Letters/ContentView.swift`
  - main app orchestration and the iPad split-view implementation
- `Learn Letters/Services/LetterSpeaker.swift`
  - voice selection, preview, persistence, and speech output
- `Learn Letters/Views/ModeSelectionView.swift`
  - starting screen for learning modes and voice settings
- `Learn Letters/Views/RandomPromptView.swift`
  - mixed random practice mode

## Requirements

- Xcode with SwiftUI support
- Apple platform SDKs for iOS and tvOS

The project is currently configured for:

- **iOS:** 26.0+
- **tvOS:** 26.5+

## Running the project

1. Open `Learning Things.xcodeproj` in Xcode.
2. Select the shared **Learning Things** scheme.
3. Choose an iPhone, iPad, or Apple TV simulator/device.
4. Build and run.

## Notes

- The app uses Apple system typography rather than bundled custom fonts.
- Voice availability depends on what is installed on the device.
- Some UI behaviour differs intentionally between tvOS, iPhone, and iPad to better fit each platform.
- The iPad experience is landscape-only and uses a distinct interface from the legacy iPhone/tvOS flow.
