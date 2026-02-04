# FlashCard

A native macOS application for multi-language vocabulary learning (English-Vietnamese, Chinese) with multiple practice modes.

## Features

- **Traditional Flashcards** - Flip cards with spring animation, showing question/answer/hint
- **Multiple Choice Quiz** - 4 options with instant feedback, score tracking and accuracy rate
- **Reading Comprehension** - Leveled passages (Beginner -> Advanced) with questions and vocabulary support
- **Content Management** - Add/delete custom topics and flashcards
- **Search** - Filter topics quickly by keyword

## Tech Stack

| Component | Technology |
|---|---|
| Framework | SwiftUI |
| Language | Swift |
| Database | SQLite3 |
| Architecture | MVVM |
| State Management | Combine |

## Project Structure

```
flash-card/
├── flash_cardApp.swift          # App entry point
├── Models.swift                 # Data models (Subject, Topic, Flashcard, ReadingPassage...)
├── ContentView.swift            # Main UI - 3-column NavigationSplitView
├── ContentViewModel.swift       # ViewModel - business logic & state
├── FlashcardMainView.swift      # Flashcard learning interface (List/Practice/Reading)
├── DatabaseManager.swift        # SQLite management, CSV data seeding
├── Data/
│   └── flashcards.sqlite        # SQLite database
├── Assets.xcassets/             # Icons and resources
└── LearnMacOS.xcdatamodel       # Core Data schema (legacy)
```

## Data Model

```
Subject (Main category)
  └── Topic (Sub-category)
        ├── Flashcard
        │     └── Exercise Types: EN→VI, VI→EN, Fill in the blank, Choose correct word, Match meaning
        └── ReadingPassage
              ├── ReadingQuestion (Multiple choice)
              └── VocabularyItem (Supporting vocabulary)
```

## Interface

The app uses a **3-column NavigationSplitView**:

1. **Sidebar** - Subject list (Vocabulary, IELTS, Chinese...)
2. **Middle column** - Topic list with search bar
3. **Detail** - 3 display modes:
   - **List** - Browse flashcards and view details
   - **Practice** - Timed quiz with configurable word count (20/40/60/All)
   - **Reading** - Leveled reading comprehension

## Built-in Data

- Basic vocabulary: family, seasons, colors, days, food, fruits, animals, body, clothes, weather...
- Holidays: Christmas, Tet (Vietnamese New Year)
- IELTS: environment, technology, health, education, society, personality
- IT vocabulary
- Chinese: family, colors, radicals, HSK3

## Requirements

- macOS
- Xcode

## Getting Started

```bash
# Clone the repository
git clone <repository-url>

# Open project in Xcode
open flash-card.xcodeproj

# Build and run (Cmd + R)
```

The database is automatically seeded with built-in data on first launch.
