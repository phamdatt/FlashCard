# FlashCard

Native macOS app for multilingual vocabulary learning (English–Vietnamese, Chinese) with multiple practice modes.

## Features

- **Flashcards** – Flip cards, show question / answer / hint
- **Multiple choice** – 4 options, instant feedback, score and accuracy rate
- **Reading** – Passages by level (Beginner → Advanced), with vocabulary support
- **Content management** – Add / delete topics and custom flashcards
- **Search** – Filter topics by keyword
- **SRS review** – Spaced repetition, scheduled review
- **Review mistakes** – Practice previously missed words by topic
- **Statistics** – Learning overview, streak, accuracy
- **Scalable font** – Adjust content font size in settings

## Tech Stack

| Component  | Technology |
|-----------|------------|
| Framework | SwiftUI    |
| Language  | Swift      |
| Database  | SQLite3    |
| Architecture | MVVM    |
| State     | Combine    |

## Project structure

```
flash-card/
├── flash-card.xcodeproj/
├── flash-card/
│   ├── flash_cardApp.swift              # Entry point, AppearanceManager, font size
│   ├── Data/
│   │   └── flashcards.sqlite            # Database seed (subjects, topics, vocabularies)
│   ├── Features/
│   │   ├── Learning/
│   │   │   ├── Models/
│   │   │   │   └── LearningModels.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── ContentViewModel.swift
│   │   │   └── Views/
│   │   │       ├── ContentView.swift    # 3 columns: Sidebar, Topics, Detail
│   │   │       └── FlashcardMainView.swift
│   │   ├── Practice/
│   │   │   └── Views/
│   │   │       ├── MatchingPracticeView.swift
│   │   │       ├── PracticeCompletedView.swift
│   │   │       ├── SpeedCardsPracticeView.swift
│   │   │       └── TrueFalsePracticeView.swift
│   │   ├── FillInTheBlank/
│   │   │   └── Views/
│   │   │       └── FillInTheBlankView.swift
│   │   ├── Speaking/
│   │   │   └── Views/
│   │   │       └── SpeakingPracticeView.swift
│   │   ├── SRS/
│   │   │   ├── Models/
│   │   │   │   └── SRSModels.swift
│   │   │   └── Views/
│   │   │       ├── ReviewModeView.swift
│   │   │       └── ReviewMistakesView.swift
│   │   └── Statistics/
│   │       ├── Models/
│   │       │   └── StatisticsModels.swift
│   │       └── Views/
│   │           └── StatisticsDashboardView.swift
│   ├── Shared/
│   │   ├── Components/
│   │   │   ├── ScaleButtonStyle.swift
│   │   │   ├── SmartCopyDefineView.swift
│   │   │   └── StreakMascotView.swift
│   │   ├── Models/
│   │   │   └── SharedModels.swift
│   │   ├── Resources/
│   │   └── Utilities/
│   │       ├── DatabaseManager.swift
│   │       ├── FontSizeApplier.swift
│   │       ├── FontSizeManager.swift
│   │       ├── FontSizeModifier.swift
│   │       ├── SoundManager.swift
│   │       └── ThemeColors.swift
│   ├── Assets.xcassets/
│   └── LearnMacOS.xcdatamodeld/         # (legacy Core Data, not used as primary)
├── flash-cardTests/
├── flash-cardUITests/
└── README.md
```

## Data model

```
Subject
  └── Topic
        ├── Flashcard (vocabularies)
        │     └── exercise_type: English→Vietnamese, Vietnamese→English, Chinese→Vietnamese, ...
        └── ReadingPassage
              └── title, content
```

SRS: `flashcard_progress`, `mistake_records` (DatabaseManager).

## UI layout

- **Column 1 (Sidebar)** – Subjects, SRS review, Review mistakes, Statistics; bottom: streak, theme, font size.
- **Column 2** – Topic list and search.
- **Column 3** – Detail: list / practice / reading per topic, or Review / Statistics screen.

## Default data

- English: family, seasons, colors, food, IELTS topics, IT, …
- Chinese: Family, Colors, HSK1, Radicals, HSK2, HSK3.1

## Requirements

- macOS
- Xcode

## Run the project

```bash
git clone <repo-url>
cd flash-card
open flash-card.xcodeproj
# Cmd + R to build and run
```

The database is copied from the bundle to Application Support on first launch (or when `currentSeedVersion` is increased).
