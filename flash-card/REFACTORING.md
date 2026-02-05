# Refactoring Guide - Feature-Based Structure

## Cấu trúc mới

Code đã được tổ chức lại theo cấu trúc features với Model, ViewModel, View:

```
flash-card/
├── Features/
│   ├── Learning/
│   │   ├── Models/
│   │   │   └── LearningModels.swift (Subject, Topic, Flashcard, ExerciseType)
│   │   ├── ViewModels/
│   │   │   └── ContentViewModel.swift
│   │   └── Views/
│   │       ├── ContentView.swift
│   │       └── FlashcardMainView.swift
│   ├── SRS/
│   │   ├── Models/
│   │   │   └── SRSModels.swift (FlashcardProgress, MistakeRecord, SRSAlgorithm)
│   │   └── Views/
│   │       ├── ReviewModeView.swift
│   │       └── ReviewMistakesView.swift
│   ├── Statistics/
│   │   ├── Models/
│   │   │   └── StatisticsModels.swift (LearningStatistics, DailyPractice)
│   │   └── Views/
│   │       └── StatisticsDashboardView.swift
│   ├── Practice/
│   │   └── Views/
│   │       ├── MatchingPracticeView.swift
│   │       ├── TrueFalsePracticeView.swift
│   │       ├── SpeedCardsPracticeView.swift
│   │       └── PracticeCompletedView.swift
│   └── Reading/
│       └── Models/
│           └── ReadingModels.swift (ReadingPassage, ReadingQuestion, VocabularyItem, ReadingLevel)
└── Shared/
    ├── Models/
    │   └── SharedModels.swift (StreakInfo)
    ├── Utilities/
    │   ├── DatabaseManager.swift
    │   ├── SoundManager.swift
    │   ├── FontSizeManager.swift
    │   ├── FontSizeModifier.swift
    │   └── FontSizeApplier.swift
    └── Components/
        ├── SmartCopyDefineView.swift
        └── ScaleButtonStyle.swift
```

## Cần làm trong Xcode

1. **Xóa các file cũ khỏi project:**
   - `Models.swift`
   - `SRSModels.swift`

2. **Thêm các file mới vào project:**
   - Tất cả files trong `Features/` folders
   - Tất cả files trong `Shared/` folders

3. **Kiểm tra imports:**
   - Các file có thể cần update imports nếu có references đến models cũ
   - SwiftUI và Foundation imports vẫn giữ nguyên

4. **Build và test:**
   - Clean build folder (Cmd + Shift + K)
   - Build project (Cmd + B)
   - Fix any import errors nếu có

## Lợi ích

- ✅ Code được tổ chức rõ ràng theo features
- ✅ Dễ maintain và mở rộng
- ✅ Tách biệt concerns (Model, ViewModel, View)
- ✅ Dễ tìm và sửa code
- ✅ Có thể test từng feature độc lập
