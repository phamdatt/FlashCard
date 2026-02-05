# FlashCard

Native macOS app học từ vựng đa ngôn ngữ (Anh–Việt, Trung) với nhiều chế độ luyện tập.

## Tính năng

- **Flashcard** – Lật thẻ, hiển thị câu hỏi / đáp án / gợi ý
- **Trắc nghiệm** – 4 đáp án, phản hồi tức thì, điểm và tỷ lệ đúng
- **Đọc hiểu** – Bài đọc theo cấp độ (Beginner → Advanced), câu hỏi và từ vựng hỗ trợ
- **Quản lý nội dung** – Thêm / xóa chủ đề và flashcard tùy chỉnh
- **Tìm kiếm** – Lọc chủ đề theo từ khóa
- **Ôn tập SRS** – Spaced repetition, ôn theo lịch
- **Ôn lại từ sai** – Ôn tập từ đã sai theo chủ đề
- **Thống kê** – Tổng quan học tập, streak, độ chính xác
- **Đa ngôn ngữ UI** – Tiếng Việt, English, 中文 (đổi ngay không cần tắt app)

## Tech Stack

| Thành phần   | Công nghệ   |
|-------------|-------------|
| Framework   | SwiftUI     |
| Ngôn ngữ    | Swift       |
| Database    | SQLite3     |
| Kiến trúc   | MVVM        |
| State       | Combine     |

## Cấu trúc project

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
│   │   │       ├── ContentView.swift    # 3 cột: Sidebar, Topics, Detail
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
│   │   ├── Reading/
│   │   │   └── Models/
│   │   │       └── ReadingModels.swift
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
│   │   │   └── SmartCopyDefineView.swift
│   │   ├── Models/
│   │   │   └── SharedModels.swift
│   │   ├── Resources/
│   │   │   ├── en.lproj/
│   │   │   ├── vi.lproj/
│   │   │   └── zh.lproj/
│   │   │       └── Localizable.strings
│   │   └── Utilities/
│   │       ├── DatabaseManager.swift
│   │       ├── FontSizeApplier.swift
│   │       ├── FontSizeManager.swift
│   │       ├── FontSizeModifier.swift
│   │       ├── LocalizationManager.swift
│   │       ├── SoundManager.swift
│   │       └── ThemeColors.swift
│   ├── Assets.xcassets/
│   └── LearnMacOS.xcdatamodeld/         # (legacy Core Data, không dùng chính)
├── flash-cardTests/
├── flash-cardUITests/
└── README.md
```

## Data model

```
Subject (môn học)
  └── Topic (chủ đề)
        ├── Flashcard (vocabularies)
        │     └── exercise_type: Anh→Việt, Việt→Anh, Trung→Việt, ...
        └── ReadingPassage (bài đọc)
              ├── ReadingQuestion
              └── VocabularyItem (từ vựng hỗ trợ)
```

SRS: `flashcard_progress`, `mistake_records` (DatabaseManager).

## Giao diện

- **Cột 1 (Sidebar)** – Môn học, Ôn tập SRS, Ôn từ sai, Thống kê; dưới có streak, theme, ngôn ngữ.
- **Cột 2** – Danh sách chủ đề + tìm kiếm.
- **Cột 3** – Chi tiết: List / Practice / Reading theo chủ đề, hoặc màn Review/Statistics.

## Dữ liệu mặc định

- Tiếng Anh: family, seasons, colors, food, IELTS topics, IT, …
- Tiếng Trung: Family, Colors, HSK1, Radicals, HSK2, HSK3.1

## Yêu cầu

- macOS
- Xcode

## Chạy project

```bash
git clone <repo-url>
cd flash-card
open flash-card.xcodeproj
# Cmd + R để build và chạy
```

Database được copy từ bundle vào Application Support khi lần đầu chạy (hoặc khi tăng `currentSeedVersion`).
