//
//  FlashcardMainView.swift
//  learn-macos
//
//  Created by Dat Pham on 31/1/26.
//

import SwiftUI

// Combined Flashcard List and Detail View with Practice Mode
struct FlashcardMainView: View {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme
    
    // Mode selection
    enum ViewMode: String, CaseIterable {
        case list = "Danh sách"
        case practice = "Luyện tập"
    }

    enum PracticeType: String, CaseIterable {
        case multipleChoice = "Trắc nghiệm"
        case matching = "Nối cặp"
        case speedCards = "Thẻ nhớ nhanh"
        case speaking = "Luyện nói"
        case fillInTheBlank = "Điền từ"
        case fillInPinyin = "Điền pinyin"

        /// Chỉ Tiếng Trung mới có mode Điền pinyin
        static func availableTypes(subjectName: String?) -> [PracticeType] {
            let all: [PracticeType] = [.multipleChoice, .matching, .speedCards, .speaking, .fillInTheBlank]
            guard subjectName == "Tiếng Trung" else { return all }
            return all + [.fillInPinyin]
        }

        var icon: String {
            switch self {
            case .multipleChoice: return "list.bullet.circle.fill"
            case .matching: return "arrow.left.arrow.right"
            case .speedCards: return "bolt.fill"
            case .speaking: return "mic.fill"
            case .fillInTheBlank: return "pencil.and.list.clipboard"
            case .fillInPinyin: return "character.bubble"
            }
        }
    }

    @State private var selectedMode: ViewMode = .list
    @State private var selectedPracticeType: PracticeType = .multipleChoice
    @State private var shuffledFlashcards: [Flashcard] = []
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var selectedWordCount: Int = 20
    @State private var showingWordCountPicker: Bool = false
    @State private var practiceRecorded: Bool = false
    /// Source: all cards or only unlearned (for large topics)
    @State private var practiceSource: PracticeSource = .all
    @State private var showEditFlashcardSheet: Bool = false
    @State private var showDeleteMultipleFlashcardsConfirmation: Bool = false
    /// Đã bấm Bắt đầu → đang trong phiên luyện tập (bấm Back sẽ confirm).
    @State private var practiceStarted: Bool = false
    @State private var showEndPracticeConfirmation: Bool = false

    enum PracticeSource: String, CaseIterable {
        case all = "Tất cả"
        case notLearned = "Chưa thuộc"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Back button
            HStack {
                Button(action: {
                    if selectedMode == .practice && practiceStarted {
                        showEndPracticeConfirmation = true
                    } else {
                        viewModel.selectedTopic = nil
                        viewModel.selectedFlashcard = nil
                    }
                }) {
                    Label("Quay lại", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
                
                Spacer()

                Text(topic.name)
                    .font(.app(.headline))
                
                Spacer()

                HStack(alignment: .center, spacing: 12) {
                    Button(action: {
                        viewModel.showAddFlashcardSheet = true
                    }) {
                        Label("Thêm từ", systemImage: "plus.circle.fill")
                            .font(.app(.body))
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .cursor(.pointingHand)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44, alignment: .center)
                    Button(action: {
                        viewModel.showImportFlashcardSheet = true
                    }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .font(.app(.body))
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .cursor(.pointingHand)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44, alignment: .center)
                }
            }
            .padding()

            ThemeDivider()

            // Mode Toggle + cài đặt: chỉ hiện khi chưa bắt đầu phiên (đã vào session thì ẩn để gọn UI)
            if selectedMode == .list || !practiceStarted {
                VStack(spacing: 8) {
                    Picker("Chế độ", selection: $selectedMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                                .font(.app(.body))
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.large)

                    if selectedMode == .practice {
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Picker("Kiểu", selection: $selectedPracticeType) {
                                    ForEach(PracticeType.availableTypes(subjectName: viewModel.selectedSubject?.name), id: \.self) { type in
                                        Text(type.rawValue)
                                            .font(.app(.body))
                                            .tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                                .controlSize(.large)
                                .onChange(of: viewModel.selectedSubject?.name) { _, _ in
                                    let available = PracticeType.availableTypes(subjectName: viewModel.selectedSubject?.name)
                                    if !available.contains(selectedPracticeType) {
                                        selectedPracticeType = .multipleChoice
                                        resetPractice()
                                    }
                                }
                            }

                            HStack(alignment: .center, spacing: 8) {
                                Picker("Nguồn", selection: $practiceSource) {
                                    ForEach(PracticeSource.allCases, id: \.self) { src in
                                        Text(src.rawValue)
                                            .font(.app(.body))
                                            .tag(src)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .frame(maxWidth: 120)
                                .controlSize(.large)
                                .onChange(of: practiceSource) { _, _ in resetPractice() }

                                Menu {
                                    ForEach(practiceSessionSizes, id: \.self) { count in
                                        Button(sessionSizeLabel(count) + (count >= topic.flashcards.count ? " (\(topic.flashcards.count))" : "")) {
                                            selectedWordCount = count
                                            resetPractice()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "number.circle.fill")
                                            .font(.app(.body))
                                        Text("\(min(selectedWordCount, practicePoolCount)) từ")
                                            .font(.app(.body))
                                        Image(systemName: "chevron.down")
                                            .font(.app(.subheadline))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.appBackgroundControl(isLight: colorScheme == .light).opacity(0.8))
                                    .foregroundStyle(.secondary)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)

                                if topic.flashcards.count > 60 {
                                    Text("Nên 20–30 từ/phiên")
                                        .font(.app(.subheadline))
                                        .foregroundStyle(.secondary)
                                }

                                if totalAnswered > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                        Text("\(score)/\(totalAnswered) (\(practiceScorePercentage)%)")
                                            .font(.app(.subheadline))
                                            .foregroundStyle(practiceScorePercentage >= 70 ? .green : .orange)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                ThemeDivider()
            }

            // Content based on mode
            switch selectedMode {
            case .list:
                VocabularyListView(
                    viewModel: viewModel,
                    topic: topic,
                    showEditFlashcardSheet: $showEditFlashcardSheet,
                    showDeleteMultipleFlashcardsConfirmation: $showDeleteMultipleFlashcardsConfirmation
                )
            case .practice:
                if practiceStarted {
                    practiceView
                } else {
                    practiceStartView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: selectedMode) { _, newValue in
            viewModel.isInPracticeMode = (newValue == .practice)
            if newValue == .list {
                practiceStarted = false
                viewModel.isPracticeSessionActive = false
            }
        }
        .onChange(of: practiceStarted) { _, started in
            viewModel.isPracticeSessionActive = started
        }
        .onChange(of: viewModel.isPracticeSessionActive) { _, active in
            if !active { practiceStarted = false }
        }
        .onAppear {
            viewModel.isInPracticeMode = (selectedMode == .practice)
        }
        .onDisappear {
            viewModel.isInPracticeMode = false
        }
        .onChange(of: topic.id) { _, _ in
            // Reset when topic changes; nếu không phải Tiếng Trung thì bỏ chọn Điền pinyin
            if selectedMode == .practice {
                let available = PracticeType.availableTypes(subjectName: viewModel.selectedSubject?.name)
                if !available.contains(selectedPracticeType) {
                    selectedPracticeType = .multipleChoice
                }
                resetPractice()
            }
        }
        .sheet(isPresented: $viewModel.showAddFlashcardSheet) {
            AddFlashcardSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showImportFlashcardSheet) {
            ImportFlashcardSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showEditFlashcardSheet) {
            if let flashcard = viewModel.selectedFlashcard, let topic = viewModel.selectedTopic {
                EditFlashcardSheet(flashcard: flashcard, topic: topic, viewModel: viewModel, onDismiss: { showEditFlashcardSheet = false })
            }
        }
        .overlay {
            ConfirmActionOverlay(
                title: "Xóa từ vựng?",
                message: viewModel.flashcardToDelete.map { "Từ \"\($0.question)\" sẽ bị xóa. Không thể hoàn tác." } ?? "",
                destructiveTitle: "Xóa",
                cancelTitle: "Huỷ",
                isPresented: Binding(
                    get: { viewModel.flashcardToDelete != nil },
                    set: { if !$0 { viewModel.flashcardToDelete = nil } }
                ),
                onConfirm: {
                    if let fc = viewModel.flashcardToDelete {
                        viewModel.flashcardToDelete = nil
                        viewModel.deleteFlashcard(fc)
                    }
                }
            )
        }
        .overlay {
            ConfirmActionOverlay(
                title: "Xóa từ vựng đã chọn?",
                message: "\(viewModel.selectedFlashcardIds.count) từ vựng sẽ bị xóa. Không thể hoàn tác.",
                destructiveTitle: "Xóa",
                cancelTitle: "Huỷ",
                isPresented: $showDeleteMultipleFlashcardsConfirmation,
                onConfirm: {
                    viewModel.deleteSelectedFlashcards(topicId: topic.id)
                    showDeleteMultipleFlashcardsConfirmation = false
                }
            )
        }
        .overlay {
            ConfirmActionOverlay(
                title: "Kết thúc luyện tập?",
                message: "Bạn có chắc muốn thoát? Phiên luyện tập sẽ kết thúc.",
                destructiveTitle: "Kết thúc",
                cancelTitle: "Tiếp tục",
                isPresented: $showEndPracticeConfirmation,
                onConfirm: {
                    showEndPracticeConfirmation = false
                    practiceStarted = false
                    viewModel.isPracticeSessionActive = false
                    viewModel.selectedTopic = nil
                    viewModel.selectedFlashcard = nil
                }
            )
        }
    }
    
    /// Màn trước khi vào luyện tập: nút "Bắt đầu".
    private var practiceStartView: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: selectedPracticeType.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(selectedPracticeType.rawValue)
                    .font(.app(.title2))
                    .fontWeight(.semibold)
                Text("\(min(selectedWordCount, practicePoolCount)) từ · \(practiceSource.rawValue)")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: {
                practiceStarted = true
                startPractice()
            }) {
                Text("Bắt đầu")
                    .font(.app(.title3))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
            .frame(maxWidth: 320)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Practice mode view
    private var practiceView: some View {
        Group {
            switch selectedPracticeType {
            case .multipleChoice:
                MultipleChoicePracticeView(
                    flashcards: shuffledFlashcards,
                    topic: topic,
                    topicId: topic.id,
                    subjectName: viewModel.selectedSubject?.name ?? "",
                    subjectIcon: viewModel.selectedSubject?.displayIcon,
                    radicalForCharacter: viewModel.radicalForCharacter,
                    onComplete: { correctCount, total in
                        score = correctCount
                        totalAnswered = total
                    },
                    onReset: {
                        recordPracticeIfNeeded()
                        resetPractice()
                    }
                )
            case .matching:
                MatchingPracticeView(
                    flashcards: shuffledFlashcards,
                    topicId: topic.id,
                    onComplete: { correctCount, total in
                        score = correctCount
                        totalAnswered = total
                    },
                    onReset: {
                        recordPracticeIfNeeded()
                        resetPractice()
                    }
                )
            case .speedCards:
                SpeedCardsPracticeView(
                    flashcards: shuffledFlashcards,
                    topicId: topic.id,
                    onComplete: { knownCount, total in
                        score = knownCount
                        totalAnswered = total
                    },
                    onReset: {
                        recordPracticeIfNeeded()
                        resetPractice()
                    }
                )
            case .speaking:
                SpeakingPracticeView(
                    flashcards: shuffledFlashcards,
                    topicId: topic.id,
                    onComplete: { correctCount, total in
                        score = correctCount
                        totalAnswered = total
                    },
                    onReset: {
                        recordPracticeIfNeeded()
                        resetPractice()
                    }
                )
            case .fillInTheBlank:
                FillInTheBlankView(
                    flashcards: shuffledFlashcards,
                    topicId: topic.id,
                    onComplete: { correctCount, total in
                        score = correctCount
                        totalAnswered = total
                    },
                    onReset: {
                        recordPracticeIfNeeded()
                        resetPractice()
                    }
                )
            case .fillInPinyin:
                PinyinPracticeView(
                    flashcards: shuffledFlashcards,
                    topicId: topic.id,
                    onComplete: { correctCount, total in
                        score = correctCount
                        totalAnswered = total
                    },
                    onReset: {
                        recordPracticeIfNeeded()
                        resetPractice()
                    }
                )
            }
        }
    }

    /// Correct percentage in session (0–100)
    private var practiceScorePercentage: Int {
        totalAnswered > 0 ? Int((Double(score) / Double(totalAnswered)) * 100) : 0
    }

    /// Count of cards to review for selected source (for Điền pinyin: only cards that have pinyin)
    private var practicePoolCount: Int {
        let pool = practicePool()
        if selectedPracticeType == .fillInPinyin {
            return pool.filter(\.hasPinyin).count
        }
        return pool.count
    }

    /// Suggested review counts by topic size
    private var practiceSessionSizes: [Int] {
        let total = topic.flashcards.count
        let candidates: [Int]
        if total <= 30 { candidates = [10, 20, total] }
        else if total <= 80 { candidates = [15, 20, 25, 30, 50, total] }
        else { candidates = [15, 20, 25, 30, 50, 100, total] }
        return Array(Set(candidates)).sorted()
    }

    private func sessionSizeLabel(_ count: Int) -> String {
        if count >= topic.flashcards.count { return "Tất cả" }
        return "\(count) từ"
    }

    /// Card pool by source: all or only unlearned (totalReviews == 0)
    private func practicePool() -> [Flashcard] {
        switch practiceSource {
        case .all:
            return topic.flashcards
        case .notLearned:
            let notLearned = topic.flashcards.filter { card in
                (DatabaseManager.shared.getFlashcardProgress(flashcardId: card.id)?.totalReviews ?? 0) == 0
            }
            return notLearned.isEmpty ? topic.flashcards : notLearned
        }
    }

    private func startPractice() {
        var pool = practicePool()
        if selectedPracticeType == .fillInPinyin {
            pool = pool.filter(\.hasPinyin)
        }
        let countToUse = min(selectedWordCount, pool.count)

        shuffledFlashcards = Array(pool.shuffled().prefix(countToUse))
        currentIndex = 0
        score = 0
        totalAnswered = 0
        practiceRecorded = false
    }
    
    private func resetPractice() {
        startPractice()
    }
    
    private func recordPracticeIfNeeded() {
        guard totalAnswered > 0, !practiceRecorded else { return }
        practiceRecorded = true
        viewModel.recordPractice(
            practiceType: selectedPracticeType.rawValue,
            topicId: topic.id,
            correct: score,
            total: totalAnswered
        )
    }
    
}

// MARK: - Add Flashcard Sheet
struct AddFlashcardSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case question, answer, hint
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Thêm từ vựng mới")
                    .font(.app(.title2))
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    clearAndClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.app(.title2))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
            }

            // Topic info
            if let topic = viewModel.selectedTopic {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.secondary)
                    Text(topic.name)
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            ThemeDivider()

            // Input fields
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Từ gốc")
                        .font(.app(.headline))
                    TextField("Ví dụ: Apple", text: $viewModel.newFlashcardQuestion)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .question)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Nghĩa")
                        .font(.app(.headline))
                    TextField("Ví dụ: Quả táo", text: $viewModel.newFlashcardAnswer)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .answer)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Gợi ý")
                        .font(.app(.headline))
                    TextField("Ví dụ: A common red fruit (không bắt buộc)", text: $viewModel.newFlashcardHint)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .hint)
                }
            }

            Spacer()

            // Action buttons
            HStack {
                Button(action: { clearAndClose() }) {
                    Text("Huỷ")
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)
                .cursor(.pointingHand)
                .controlSize(.large)

                Spacer()

                Button(action: {
                    viewModel.addFlashcard(
                        question: viewModel.newFlashcardQuestion,
                        answer: viewModel.newFlashcardAnswer,
                        hint: viewModel.newFlashcardHint
                    )
                }) {
                    Text("Thêm từ vựng")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .keyboardShortcut(.return)
                .disabled(
                    viewModel.newFlashcardQuestion.trimmingCharacters(in: .whitespaces).isEmpty ||
                    viewModel.newFlashcardAnswer.trimmingCharacters(in: .whitespaces).isEmpty
                )
                .buttonStyle(.borderedProminent)
                .cursor(.pointingHand)
                .tint(.accentColor)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 450, height: 400)
        .onAppear { focusedField = .question }
    }

    private func clearAndClose() {
        viewModel.newFlashcardQuestion = ""
        viewModel.newFlashcardAnswer = ""
        viewModel.newFlashcardHint = ""
        viewModel.showAddFlashcardSheet = false
    }
}


