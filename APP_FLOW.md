# Application Flow – Flash Card (macOS)

Tài liệu mô tả flow ứng dụng bằng **ngôn ngữ tự nhiên** (user làm gì, hệ thống phản hồi thế nào) và **code tương ứng** (file, struct, logic) đi song song.

---

## 1. Khởi động ứng dụng

### Ngôn ngữ tự nhiên
- User mở app → cửa sổ chính hiện ra với 3 cột: Menu (sidebar), danh sách chủ đề (giữa), nội dung chi tiết (phải).
- App đọc dữ liệu từ database (môn học, chủ đề, flashcard, bài đọc) và hiển thị. Nếu chưa có database ở thư mục Application Support thì copy từ bundle (file seed `flashcards.sqlite`) sang.
- Giao diện áp dụng theme (sáng/tối/tự động) và cỡ chữ đã lưu (UserDefaults).

### Code tương ứng
- **Entry point**: `flash_cardApp.swift` – `@main struct flash_cardApp: App`.
  - Tạo `AppearanceManager` và `FontSizeManager` (ObservableObject), inject vào environment.
  - `WindowGroup { ContentView() ... .applyGlobalFontSize(fontSizeManager:) }` – toàn bộ app dùng multiplier cỡ chữ từ đây.
- **Root view**: `ContentView` (ContentView.swift) – `NavigationSplitView` với 3 cột: sidebar → content (giữa) → detail (phải).
- **Data load**: `ContentViewModel.init()` gọi `loadLearningData()` và `loadStreakInfo()`.
  - `loadLearningData()` → `DatabaseManager.shared.loadAllSubjects()` → đọc SQLite, trả về `[Subject]` (mỗi Subject có `topics`, mỗi Topic có `flashcards`, `readings`).
- **Database lần đầu**: `DatabaseManager.init()` gọi `copyDatabaseIfNeeded()`:
  - So sánh `UserDefaults db_seed_version` với `currentSeedVersion`; nếu DB chưa tồn tại hoặc version cũ thì copy `Data/flashcards.sqlite` từ bundle vào `Application Support`, lưu version mới. Nếu đã có DB cũ thì backup topics/flashcards do user tạo rồi migrate.

---

## 2. Sidebar (Menu) – Chọn mục và cài đặt

### Ngôn ngữ tự nhiên
- User thấy 3 nhóm: **Học tập** (các môn: Tiếng Anh, Tiếng Trung, Bài đọc), **Ôn tập** (Ôn tập SRS, Ôn lại từ sai), **Thống kê**.
- Chọn một môn trong Học tập → môn đó được chọn, cột giữa hiện danh sách chủ đề của môn đó.
- Chọn "Ôn tập SRS" → chuyển sang màn ôn SRS (cột giữa ẩn, cột phải full màn ôn).
- Chọn "Ôn lại từ sai" → màn ôn từ sai tương tự.
- Chọn "Thống kê" → màn thống kê.
- Dưới cùng: streak (số ngày, kỷ lục, trạng thái đã học hôm nay), nút đổi theme (Sáng/Tối/Tự động).

### Code tương ứng
- **Sidebar**: `SidebarView(viewModel:)` – `List(selection: $viewModel.selectedSubject)` với 3 `Section`: learningSection, reviewSection, statisticsSection.
- **Học tập**: `ForEach(viewModel.subjects)` – mỗi item gọi `viewModel.selectSubject(subject)` và `viewModel.switchToLearningMode()`. `selectSubject` cập nhật `selectedSubject`, `selectedTopic`, `selectedFlashcard` (giữ topic nếu cùng subject, không thì chọn topic đầu hoặc nil).
- **Ôn tập / Thống kê**: Nút gọi `viewModel.switchToReviewMode()`, `switchToReviewMistakes()`, `switchToStatistics()` – set `showReviewMode` / `showReviewMistakes` / `showStatistics` = true, `selectedTopic` = nil, dùng animation.
- **Streak**: Hiển thị `viewModel.streakInfo` (currentStreak, longestStreak, didPracticeToday); dữ liệu từ `DatabaseManager.shared.getStreakInfo()`.
- **Theme**: Nút gọi `appearanceManager.cycleMode()` – đổi enum (auto → light → dark), lưu UserDefaults, `applyAppearance()` set `NSApp.appearance`.

---

## 3. Cột giữa – Danh sách chủ đề (Topics)

### Ngôn ngữ tự nhiên
- Khi đã chọn môn (Học tập), cột giữa hiện danh sách chủ đề của môn đó.
- User có thể tìm kiếm chủ đề theo tên; danh sách lọc theo từ khóa.
- Chọn một chủ đề → cột phải hiện nội dung: với môn thường thì là **Flashcard** (danh sách + chi tiết hoặc luyện tập), với môn "Bài đọc" thì là **Bài đọc** (danh sách bài + nội dung bài).
- Có nút "Thêm chủ đề" → mở sheet nhập tên chủ đề mới, tạo xong thì danh sách cập nhật. Chuột phải chủ đề → Xóa chủ đề.

### Code tương ứng
- **Middle column**: `ContentView.middleColumn` – nếu `viewModel.isInSpecialMode` (Review/Statistics) thì render `Color.clear` (ẩn cột); nếu có `selectedSubject` thì `TopicsListView(viewModel:, subject:)`, không thì `ContentUnavailableView("Chọn môn học")`.
- **TopicsListView**: `filteredTopics` = `viewModel.filteredTopics(for: subject)` – filter theo `viewModel.searchText` (case insensitive). `List(filteredTopics, selection: $viewModel.selectedTopic)` – chọn topic gọi `viewModel.selectTopic(topic)` (chỉ set khi topic thực sự đổi).
- **Thêm chủ đề**: `viewModel.showAddTopicSheet = true` → sheet `AddTopicSheet`. Submit gọi `viewModel.addTopic(name:)` → `DatabaseManager.shared.insertTopic(...)`, `loadLearningData()`, restore selection, đóng sheet.
- **Xóa chủ đề**: Context menu gọi `viewModel.deleteTopic(topic)` → DB delete, `loadLearningData()`, clear selection nếu đang chọn topic bị xóa.

---

## 4. Cột phải – Nội dung chi tiết (Detail)

### Ngôn ngữ tự nhiên
- Nếu đang chế độ **Ôn tập SRS**: cột phải hiện màn ôn SRS (từ cần ôn, lật thẻ, chọn mức độ nhớ).
- Nếu **Ôn lại từ sai**: màn ôn từ đã sai.
- Nếu **Thống kê**: màn thống kê (tổng quan, tiến độ, độ chính xác theo chủ đề/môn).
- Nếu đang **Học tập** và đã chọn chủ đề:
  - Môn **Bài đọc**: danh sách bài đọc bên trái, nội dung bài bên phải; có "Tạo bài đọc", xóa bài, sao chép/tìm nghĩa trong bài.
  - Môn khác (flashcard): màn **Danh sách / Luyện tập** – danh sách thẻ bên trái, chi tiết thẻ hoặc giao diện luyện (trắc nghiệm, nối cặp, đúng/sai, thẻ nhanh, v.v.) bên phải. Có "Thêm từ", sửa/xóa từ.

### Code tương ứng
- **Detail column**: `ContentView.detailColumn` – `Group` phân nhánh:
  - `viewModel.showReviewMode` → `ReviewModeView(viewModel:)`
  - `viewModel.showReviewMistakes` → `ReviewMistakesView(viewModel:)`
  - `viewModel.showStatistics` → `StatisticsDashboardView(viewModel:)`
  - Có `selectedTopic` và subject là "Bài đọc" → `ReadingMainView(viewModel:, topic:)`
  - Có `selectedTopic` (môn khác) → `FlashcardMainView(viewModel:, topic:)`
  - Còn lại → `ContentUnavailableView("Chọn chủ đề")`

---

## 5. Flow Flashcard (môn không phải Bài đọc)

### Ngôn ngữ tự nhiên
- User đã chọn môn + chủ đề → vào FlashcardMainView.
- Toggle **Danh sách / Luyện tập**. Ở **Danh sách**: list flashcard bên trái, chọn một thẻ thì bên phải xem chi tiết (câu hỏi/đáp án/gợi ý, nút Lật, nút Sửa). Context menu thẻ: Sửa từ vựng, Xóa. Nút "Thêm từ" mở sheet nhập Từ gốc / Nghĩa / Gợi ý.
- Ở **Luyện tập**: chọn kiểu (Trắc nghiệm, Nối cặp, Đúng–Sai, Thẻ nhanh, Luyện nói, Điền từ), chọn nguồn (Tất cả / Chưa thuộc), chọn số từ → bắt đầu. Mỗi câu trả lời xong có phản hồi đúng/sai, sau khi hết lượt có màn hoàn thành (điểm, nút tiếp). Kết quả được ghi để tính streak và thống kê.

### Code tương ứng
- **FlashcardMainView**: Nhận `viewModel`, `topic`. State: `selectedMode` (list/practice), `selectedPracticeType`, `shuffledFlashcards`, `currentIndex`, `score`, `totalAnswered`, v.v.
- **List mode**: `listView` – `HSplitView` với `List(topic.flashcards, selection: $viewModel.selectedFlashcard)` và `FlashcardDetailView` (hoặc ContentUnavailable). Context menu: `viewModel.selectFlashcard(flashcard)` + `showEditFlashcardSheet = true`, hoặc `viewModel.deleteFlashcard(flashcard)`. Sheet sửa: `EditFlashcardSheet` gọi `viewModel.updateFlashcard(id:question:answer:hint:)`.
- **Practice mode**: `practiceView` – lấy pool từ `practicePool()` (all hoặc chưa thuộc), shuffle, lấy `selectedWordCount` từ; hiển thị `FlashcardDetailView` (hoặc view trắc nghiệm/nối/đúng-sai/…) với `onAnswered: { handleAnswer(isCorrect:) }`. Khi hết thẻ → `PracticeCompletedView`; `recordPracticeIfNeeded()` gọi `viewModel.recordPractice(practiceType:topicId:correct:total:)` → DB + `loadStreakInfo()`.
- **Thêm từ**: Sheet `AddFlashcardSheet` bind `viewModel.newFlashcardQuestion/Answer/Hint`, submit gọi `viewModel.addFlashcard(question:answer:hint:)` → `DatabaseManager.shared.insertFlashcard(...)`, `loadLearningData()`, chọn thẻ vừa tạo.

---

## 6. Flow Bài đọc (môn Bài đọc)

### Ngôn ngữ tự nhiên
- User chọn môn "Bài đọc" và một chủ đề → màn bài đọc: list bài bên trái, nội dung bài bên phải.
- Chọn một bài → xem tiêu đề + nội dung; có nút Sao chép toàn bộ. Trong bài có thể bôi đen đoạn → context menu Sao chép / Tìm nghĩa (tra trong flashcard hoặc hiện "Không tìm thấy").
- "Tạo bài đọc" → sheet nhập Tiêu đề + Nội dung → lưu thì bài mới xuất hiện trong list. Chuột phải bài → Xóa bài đọc.

### Code tương ứng
- **ReadingMainView**: Nhận `viewModel`, `topic`. State `selectedPassage`. Nếu `topic.readings.isEmpty` → ContentUnavailable; không thì `HSplitView`: `List(topic.readings, selection: $selectedPassage)` và `ReadingDetailView(passage:, topicName:)` hoặc placeholder. Sheet `AddReadingSheet` gọi `viewModel.addReadingPassage(topicId:title:content:)`. Xóa: `viewModel.deleteReadingPassage(passage)`.
- **ReadingDetailView**: Hiển thị `passage.title`, `SmartCopyDefineText(text: passage.content, flashcards: nil)` (copy + tìm nghĩa). Copy full: NSPasteboard + nội dung.
- **SmartCopyDefineView**: Text có context menu (Sao chép, Tìm nghĩa); nếu truyền `flashcards` thì tìm nghĩa trong list flashcard, không thì vẫn có thể hiện "Không tìm thấy".

---

## 7. Flow ôn tập SRS

### Ngôn ngữ tự nhiên
- User chọn "Ôn tập SRS" → màn ôn: lấy danh sách từ cần ôn (theo thuật toán SRS). Với mỗi thẻ: xem câu hỏi, bấm Space hoặc nút để lật xem đáp án, chọn mức độ nhớ (Hoàn hảo / Đúng / Sai…) → thẻ tiếp theo. Hết thẻ thì màn hoàn thành.

### Code tương ứng
- **ReviewModeView**: `onAppear` gọi `loadDueFlashcards()` – lấy từ `DatabaseManager` (flashcard_progress, due date). State: `dueFlashcards`, `currentIndex`, `showAnswer`, `quality`, `srsAlgorithm`. View: empty state / thẻ ôn / completion. Space → `showAnswer = true`; Return hoặc nút chất lượng → `submitQuality(...)` cập nhật SRS và `currentIndex`. Ghi kết quả vào DB (progress, mistake nếu sai).

---

## 8. Flow ôn từ sai & thống kê

### Ngôn ngữ tự nhiên
- **Ôn từ sai**: Danh sách từ đã sai (từ mistake_records), ôn lần lượt, đánh dấu đúng/sai.
- **Thống kê**: Chọn Tuần / Tháng / Tất cả; hiển thị tổng quan (tổng từ, đã học, đã thuộc, cần ôn), tiến độ theo thời gian, độ chính xác theo chủ đề, độ chính xác theo môn học.

### Code tương ứng
- **ReviewMistakesView**: Load từ sai từ DB, hiển thị từng thẻ, ghi lại kết quả.
- **StatisticsDashboardView**: `viewModel.selectedTimeRange` (week/month/all); `statistics = DatabaseManager.shared.getLearningStatistics()`. Hiển thị StatCard, progress chart (filter history theo range), accuracy by topic/subject (từ `statistics.accuracyByTopic`, `accuracyBySubject`).

---

## 9. Dữ liệu và persistence

### Ngôn ngữ tự nhiên
- Môn học, chủ đề, flashcard, bài đọc: lưu SQLite (bảng subjects, topics, vocabularies, reading_passages). Thêm/sửa/xóa đều ghi DB rồi load lại danh sách từ DB để UI cập nhật.
- Streak và thống kê: đọc từ DB (practice_sessions, flashcard_progress, mistake_records). Cỡ chữ và theme: UserDefaults.

### Code tương ứng
- **DatabaseManager** (singleton): `openDatabase()` mở SQLite tại Application Support. `loadAllSubjects()` JOIN subjects + topics + vocabularies + reading_passages, build `[Subject]`. Insert/update/delete: `insertTopic`, `insertFlashcard`, `updateFlashcard`, `deleteFlashcard`, `insertReadingPassage`, `deleteReadingPassage`, `deleteTopic`, v.v.
- **ContentViewModel**: Mọi thao tác CRUD gọi DB rồi `loadLearningData()` (và có thể `loadStreakInfo()`). Selection (subject/topic/flashcard) giữ trong @Published, sau load lại data thì restore selection theo id.
- **FontSizeManager**: multiplier lưu UserDefaults, áp dụng qua `applyFontSizeScaling(multiplier:)` và modifier `ScaledFont` (FontSizeModifier.swift).

---

## 10. Tóm tắt luồng điều khiển

| Bước người dùng | View / ViewModel | Điều kiện / Hàm chính |
|-----------------|------------------|------------------------|
| Mở app | `flash_cardApp` → `ContentView` | `viewModel = ContentViewModel()` → `loadLearningData()`, `loadStreakInfo()` |
| Chọn môn (sidebar) | `SidebarView` | `selectSubject(_:)`, `switchToLearningMode()` |
| Chọn Ôn SRS / Từ sai / Thống kê | `SidebarView` | `switchToReviewMode()` / `switchToReviewMistakes()` / `switchToStatistics()` |
| Cột giữa: danh sách chủ đề | `TopicsListView` | `filteredTopics(for:)`, `selectedTopic` binding |
| Chọn chủ đề | `TopicsListView` | `selectTopic(_:)` |
| Cột phải: flashcard vs bài đọc | `ContentView.detailColumn` | `selectedSubject?.name == "Bài đọc"` → ReadingMainView, else FlashcardMainView |
| Danh sách thẻ / Chi tiết thẻ / Sửa thẻ | `FlashcardMainView` | `selectedFlashcard`, `showEditFlashcardSheet`, `updateFlashcard` |
| Luyện tập (trắc nghiệm, nối, …) | `FlashcardMainView.practiceView` | `practicePool()`, `handleAnswer`, `recordPracticeIfNeeded` |
| Bài đọc: list + nội dung | `ReadingMainView`, `ReadingDetailView` | `selectedPassage`, `SmartCopyDefineText` |
| Ôn SRS | `ReviewModeView` | `loadDueFlashcards()`, `submitQuality`, SRS DB |
| Thống kê | `StatisticsDashboardView` | `getLearningStatistics()`, `selectedTimeRange` |

File này dùng làm tài liệu tham chiếu: mỗi flow ngôn ngữ tự nhiên đều có phần "Code tương ứng" giải thích logic và vị trí code.
