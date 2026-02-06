# FlashCard

Native macOS app for multilingual vocabulary learning (English–Vietnamese, Chinese) with multiple practice modes.

## Features

- **Vocabulary list** – Browse flashcards by topic; select a card to see detail (question, answer, hint, radicals, notes). Add, edit, delete words; multi-select to delete in bulk.
- **Practice modes** – Multiple choice, matching pairs, speed cards, speaking (type answer), fill-in-the-blank, and fill-in-pinyin (Chinese only).
- **Reading** – Passages by level (Beginner → Advanced) with copy and “look up in vocabulary.”
- **Content management** – Subjects, topics, flashcards; CSV import (word, meaning, hint, notes, radical).
- **Search** – Filter topics by keyword.
- **SRS** – Spaced repetition; review due cards and track progress.
- **Review mistakes** – Practice previously missed words by subject/topic.
- **Statistics** – Overview, streak, accuracy.
- **Scalable font** – Adjust content font size in settings.

## Tech stack

| Component    | Technology  |
|-------------|-------------|
| Framework   | SwiftUI     |
| Language    | Swift       |
| Database    | SQLite3     |
| Architecture| MVVM        |
| State       | Combine     |

## App flow

1. **Sidebar** – Choose a **subject** (e.g. Tiếng Anh, Tiếng Trung) under “Học tập,” or switch to **Ôn tập SRS**, **Ôn lại từ sai**, or **Thống kê.** Bottom: streak, theme (light/dark/auto), font size.
2. **Middle column** – Topic list for the selected subject; search bar and “Thêm chủ đề.” Selecting a topic loads its content in the detail column.
3. **Detail column** – Depends on selection:
   - **Flashcard subject + topic** → **FlashcardMainView**: header (topic name, “Thêm từ”, “Import”), then a **mode toggle**: **Danh sách** (vocabulary list) or **Luyện tập** (practice).
     - **Danh sách** → **VocabularyListView**: list of flashcards on the left; detail or empty state on the right. Empty topic shows “Chưa có từ vựng” and points to Thêm từ / Import.
     - **Luyện tập** → Choose practice type (Trắc nghiệm, Nối cặp, Thẻ nhớ nhanh, Luyện nói, Điền từ; **Điền pinyin** only for Tiếng Trung), source (Tất cả / Chưa thuộc), and session size → run session; completion screen then reset.
   - **Bài đọc subject** → Reading: list of passages, passage content, add/delete passages.
   - **Ôn tập SRS / Ôn lại từ sai / Thống kê** → Their dedicated full-screen views.

## Project structure

```
flash-card/
├── flash-card.xcodeproj/
├── flash-card/
│   ├── flash_cardApp.swift                 # Entry point, appearance, font size
│   ├── Data/
│   │   └── flashcards.sqlite               # Seed DB (subjects, topics, vocabularies)
│   ├── Features/
│   │   ├── Learning/
│   │   │   ├── Models/
│   │   │   │   └── LearningModels.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── ContentViewModel.swift
│   │   │   └── Views/
│   │   │       ├── ContentView.swift       # 3 columns: Sidebar, Topics, Detail
│   │   │       ├── FlashcardMainView.swift # Topic header + List/Practice toggle
│   │   │       ├── AddFlashcardSheet, EditFlashcardSheet, ImportFlashcardSheet
│   │   │       ├── BackupRestoreView, KeyboardShortcutsView, OnboardingView
│   │   │       └── (FlashcardDetailView, ReadingMainView, etc. in ContentView)
│   │   ├── VocabularyList/
│   │   │   └── Views/
│   │   │       └── VocabularyListView.swift   # List + detail for a topic
│   │   ├── Practice/
│   │   │   └── Views/
│   │   │       ├── MultipleChoicePracticeView.swift
│   │   │       ├── MatchingPracticeView.swift
│   │   │       ├── SpeedCardsPracticeView.swift
│   │   │       ├── PinyinPracticeView.swift   # Fill-in pinyin (Chinese only)
│   │   │       └── PracticeCompletedView.swift
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
│   │       ├── FontSizeManager.swift
│   │       ├── FontSizeModifier.swift
│   │       ├── SoundManager.swift
│   │       └── ThemeColors.swift
│   └── Assets.xcassets/
├── flash-cardTests/
├── flash-cardUITests/
└── README.md
```

## Data model

- **Subject** → **Topic** → **Flashcard** (vocabularies: question, answer, hint, notes, radical); **Topic** → **ReadingPassage** (title, content).
- SRS: `flashcard_progress`, `mistake_records` (see `DatabaseManager`).
- Chinese: question often stored as `汉字 (pinyin)`; pinyin is used for “Fill-in pinyin” practice.

## Default data

- **English** – Family, seasons, colors, food, IELTS topics, IT, etc.; seed adds words to topics with few cards (min 25 per topic).
- **Chinese** – Family, colors, HSK1, radicals, HSK2, HSK3.x; “Điền pinyin” uses pinyin in parentheses from the question field.

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

The database is copied from the bundle to Application Support on first launch (or when the seed version is bumped in `DatabaseManager`).
