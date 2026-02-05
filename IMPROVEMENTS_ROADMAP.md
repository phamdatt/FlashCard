# Cải tiến ứng dụng – Lộ trình & Lịch append

Tài liệu liệt kê các hạng mục cải tiến đề xuất và lịch triển khai (append) theo phase. Có thể cập nhật file này khi hoàn thành hoặc đổi thứ tự ưu tiên.

---

## Danh sách cải tiến đề xuất

### A. UX & An toàn dữ liệu

| # | Hạng mục | Mô tả ngắn | Độ ưu tiên |
|---|----------|------------|------------|
| A1 | **Xác nhận trước khi xóa** | Khi xóa chủ đề / flashcard / bài đọc: hiện alert xác nhận ("Bạn có chắc muốn xóa …?") thay vì xóa ngay. Tránh xóa nhầm. | Cao |
| A2 | **Undo xóa (hoặc thùng rác)** | Sau khi xóa chủ đề hoặc thẻ: cho phép "Hoàn tác" trong vài giây, hoặc lưu vào thùng rác có thể khôi phục. | Trung bình |
| A3 | **Báo lỗi khi ghi DB thất bại** | Nếu `DatabaseManager` insert/update/delete lỗi: hiện alert hoặc banner thay vì fail im lặng; log lỗi để debug. | Cao |
| A4 | **Onboarding / Hướng dẫn lần đầu** | Lần đầu mở app: 1–2 màn hình ngắn giới thiệu (chọn môn → chọn chủ đề → xem thẻ / luyện tập). Có nút "Bỏ qua". | Thấp |
| A5 | **Phím tắt trong app** | Trang Help hoặc tooltip: liệt kê phím tắt (Cmd+/, Cmd+-, Cmd+0, Space/Return trong ôn SRS). | Thấp |

### B. Tính năng mới

| # | Hạng mục | Mô tả ngắn | Độ ưu tiên |
|---|----------|------------|------------|
| B1 | **Sao lưu / Phục hồi dữ liệu** | Export toàn bộ dữ liệu user (topics, flashcards, bài đọc) ra file (JSON hoặc SQLite). Import từ file để khôi phục hoặc chuyển máy. | Cao |
| B2 | **Tìm kiếm toàn cục** | Ô tìm không chỉ lọc chủ đề mà tìm cả nội dung flashcard (question/answer) trong toàn bộ môn hoặc toàn app; hiện kết quả theo chủ đề. | Trung bình |
| B3 | **Hiển thị ngày ôn SRS** | Trong danh sách thẻ hoặc chi tiết thẻ: hiện "Ôn lại vào: DD/MM" (next review date) cho từ đã có progress. Giúp user biết khi nào nên ôn. | Trung bình |
| B4 | **Import flashcard từ file** | Cho phép import CSV/JSON (ví dụ: cột 1 = từ, cột 2 = nghĩa) vào một chủ đề đã chọn. | Trung bình |
| B5 | **TTS / Phát âm** | Nút phát âm (speaker) bên cạnh từ (question/answer); dùng AVSpeechSynthesizer hoặc API TTS. Hữu ích cho Luyện nói và từ vựng. | Trung bình |
| B6 | **iCloud sync (tùy chọn)** | Đồng bộ dữ liệu user (topics, cards, readings) qua iCloud để dùng nhiều thiết bị. Có thể làm sau khi đã có export/import ổn định. | Thấp |
| B7 | **Widget / Menu bar** | Widget macOS hoặc menu bar: hiện streak, số từ cần ôn hôm nay; click mở app. | Thấp |

### C. Chất lượng & Hiệu năng

| # | Hạng mục | Mô tả ngắn | Độ ưu tiên |
|---|----------|------------|------------|
| C1 | **Unit test ViewModel** | Test `ContentViewModel`: `filteredTopics`, `selectSubject`/`selectTopic`, `addTopic`/`deleteTopic`, `addFlashcard`/`updateFlashcard` (mock DB hoặc in-memory). | Trung bình |
| C2 | **Unit test DatabaseManager** | Test CRUD cơ bản: insert topic, insert/update flashcard, load subjects (dùng DB tạm hoặc in-memory SQLite). | Trung bình |
| C3 | **Loading state rõ ràng** | Khi `loadLearningData()` hoặc load thống kê lâu: hiện indicator (ProgressView / skeleton) thay vì màn trống. | Trung bình |
| C4 | **Accessibility** | Kiểm tra VoiceOver (label cho nút, list), giữ/chuẩn hóa Dynamic Type (đã có font scale). | Thấp |

### D. Code & Kiến trúc

| # | Hạng mục | Mô tả ngắn | Độ ưu tiên |
|---|----------|------------|------------|
| D1 | **Tách router / navigation state** | Nếu ContentView tiếp tục phình: tách logic "hiện màn nào" (Review/Mistakes/Statistics/Reading/Flashcard) ra một object (e.g. Router) để dễ test và mở rộng. | Thấp |
| D2 | **Document API DatabaseManager** | Comment hoặc doc cho các hàm public của `DatabaseManager` (ý nghĩa tham số, side effect, throw nếu có). | Thấp |
| D3 | **Chuẩn hóa error type** | Định nghĩa enum lỗi (e.g. `DBError`) thay vì in print; ViewModel nhận Result/throw và map sang message cho user. | Thấp |

---

## Lịch append (triển khai theo phase)

Lịch dưới đây gợi ý **thứ tự append** theo từng phase. Mỗi phase nên hoàn thành trước khi chuyển phase tiếp (hoặc điều chỉnh tùy thời gian).

### Phase 1 – Quick wins (ưu tiên cao, ít thay đổi) ✅ Đã làm

| Thứ tự | Hạng mục | Trạng thái |
|--------|----------|------------|
| 1 | A1 – Xác nhận trước khi xóa | ✅ Done: `topicToDelete` / `flashcardToDelete` / `passageToDelete` + `confirmationDialog` trong TopicsListView, ReadingMainView, FlashcardMainView. |
| 2 | A3 – Báo lỗi khi ghi DB thất bại | ✅ Done: `DatabaseManager.deleteTopic/deleteFlashcard/deleteReadingPassage` trả về `Bool`; ViewModel set `errorMessage` khi false; ContentView `.alert("Lỗi")` khi `errorMessage != nil`. |
| 3 | C3 – Loading state | ✅ Done: `ContentViewModel.isLoading` = true trong init, loadLearningData + loadStreakInfo chạy trong `DispatchQueue.main.async` rồi set `isLoading = false`; middleColumn hiện ProgressView + "Đang tải..." khi `isLoading && subjects.isEmpty`. |

**Kết thúc Phase 1:** User ít bị xóa nhầm, thấy lỗi khi DB fail, không thấy màn trống khi đang load.

---

### Phase 2 – UX & An toàn (tiếp) ✅ Đã làm

| Thứ tự | Hạng mục | Trạng thái |
|--------|----------|------------|
| 4 | A2 – Undo xóa | ✅ Done: `UndoableItem` + banner "Đã xóa. Hoàn tác" 5s; restore topic/flashcard/passage. |
| 5 | A4 – Onboarding | ✅ Done: `OnboardingView` (Chọn môn → Chọn chủ đề → Xem thẻ); `@AppStorage("hasCompletedOnboarding")`. |
| 6 | A5 – Phím tắt trong app | ✅ Done: `KeyboardShortcutsView`; mở từ sidebar và menu Help → "Phím tắt". |

---

### Phase 3 – Tính năng (Features) ✅ Đã làm

| Thứ tự | Hạng mục | Trạng thái |
|--------|----------|------------|
| 7 | B1 – Sao lưu / Phục hồi | ✅ Done: `BackupPayload` + `DatabaseManager.exportUserData`/`importUserData`; `BackupRestoreView` (Sao lưu ra file, Phục hồi với xác nhận); nút sidebar "Sao lưu / Phục hồi". |
| 8 | B2 – Tìm kiếm toàn cục | ✅ Done: `flashcardSearchResults(for:)`; section "Kết quả trong flashcard" trong TopicsListView, tap chọn topic + flashcard. |
| 9 | B3 – Ngày ôn SRS | ✅ Done: `FlashcardDetailView` hiện "Ôn lại vào: dd/MM" từ `getFlashcardProgress(flashcardId:)` khi đã có progress. |
| 10 | B4 – Import CSV/JSON | ✅ Done: `ImportFlashcardSheet` (chọn file CSV/JSON, chọn chủ đề, parse); nút "Import" trong FlashcardMainView. |
| 11 | B5 – TTS | ✅ Done: `SpeakButton` (AVSpeechSynthesizer, ngôn ngữ vi/zh theo nội dung); gắn vào FlashcardDetailView và context menu "Phát âm" trong SmartCopyDefineText. |

---

### Phase 4 – Chất lượng & Polish

| Thứ tự | Hạng mục | Công việc gợi ý |
|--------|----------|------------------|
| 12 | C1 – Unit test ViewModel | Target test: `ContentViewModel` với mock hoặc DB in-memory; test `filteredTopics`, `selectSubject`, `addTopic`, `addFlashcard`, `updateFlashcard`. |
| 13 | C2 – Unit test DatabaseManager | Target test: tạo SQLite in-memory, gọi insert topic, insert flashcard, load subjects; assert count và nội dung. |
| 14 | C4 – Accessibility | Rà soát label, hint cho Button/Image/List; test VoiceOver. |
| 15 | D1 – Tách router | Tạo `AppRouter` hoặc `NavigationState`: enum màn detail (learning(topic), reading(topic), review, mistakes, statistics); ContentView đọc state này để render detailColumn. |
| 16 | D2 – Document DatabaseManager | Thêm comment hoặc DocC cho các hàm public. |
| 17 | D3 – Error type chuẩn | Enum `DBError`; DatabaseManager throw thay vì print; ViewModel catch và set errorMessage. |

---

## Cập nhật file này

- Khi **bắt đầu** một hạng mục: có thể đánh dấu trong bảng (e.g. thêm cột "Trạng thái: Chưa làm / Đang làm / Xong").
- Khi **hoàn thành**: ghi ngắn vào mục tương ứng (ví dụ: "A1 done: confirmationDialog cho deleteTopic/deleteFlashcard/deleteReadingPassage").
- Khi **đổi ưu tiên**: đổi thứ tự trong "Lịch append" hoặc chuyển hạng mục giữa các phase.

File này có thể append thêm ý tưởng mới vào "Danh sách cải tiến" và bổ sung vào lịch phase tương ứng.
