# Learn Letters - File Structure

## Project Organization

The app has been refactored into a clean, modular structure for better maintainability:

### Models/
- **LetterCard.swift** - Data model for letter cards with loading logic from text files, color parsing, and fallback data

### Views/
- **ContentView.swift** - Main app container handling state and orchestration
- **GridView.swift** - The alphabet grid view with tile layout and navigation
- **DetailView.swift** - Letter detail view with word display

### Views/Components/
- **LetterPairLabel.swift** - Custom UIViewRepresentable for displaying styled letter pairs

### Services/
- **LetterSpeaker.swift** - Audio synthesis and speech management

### Utilities/
- **Layout.swift** - Shared layout constants
- **FocusTarget.swift** - Focus state enum for TV remote navigation

## Architecture

**ContentView** acts as the main orchestrator:
- Manages auto-play state and timer
- Coordinates between grid and detail views
- Handles TV remote input (play/pause, arrows, menu)
- Manages focus transitions

**GridView** and **DetailView** are pure view components that:
- Accept bindings for state
- Call back to ContentView for user interactions
- Have no direct dependencies on business logic

**LetterSpeaker** is an isolated service:
- Handles all audio syntheis
- Can be easily tested or replaced
- Self-contained voice selection logic

This structure makes it easy to:
- Find code related to each feature
- Test components in isolation
- Modify one concern without affecting others
- Add new features without cluttering existing files
