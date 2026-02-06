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
        case trueFalse = "Đúng/Sai"
        case speedCards = "Thẻ nhớ nhanh"
        case speaking = "Luyện nói"
        case fillInTheBlank = "Điền từ"

        var icon: String {
            switch self {
            case .multipleChoice: return "list.bullet.circle.fill"
            case .matching: return "arrow.left.arrow.right"
            case .trueFalse: return "checkmark.circle"
            case .speedCards: return "bolt.fill"
            case .speaking: return "mic.fill"
            case .fillInTheBlank: return "pencil.and.list.clipboard"
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

    enum PracticeSource: String, CaseIterable {
        case all = "Tất cả"
        case notLearned = "Chưa thuộc"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Back button
            HStack {
                Button(action: {
                    viewModel.selectedTopic = nil
                    viewModel.selectedFlashcard = nil
                }) {
                    Label("Quay lại", systemImage: "chevron.left")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(topic.name)
                    .font(.app(.headline))
                
                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.showAddFlashcardSheet = true
                    }) {
                        Label("Thêm từ", systemImage: "plus.circle.fill")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    Button(action: {
                        viewModel.showImportFlashcardSheet = true
                    }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Mode Toggle
            VStack(spacing: 8) {
                Picker("Chế độ", selection: $selectedMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if selectedMode == .practice {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Picker("Kiểu", selection: $selectedPracticeType) {
                                ForEach(PracticeType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        HStack(spacing: 8) {
                            Picker("Nguồn", selection: $practiceSource) {
                                ForEach(PracticeSource.allCases, id: \.self) { src in
                                    Text(src.rawValue).tag(src)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(maxWidth: 120)
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
                                    Text("\(min(selectedWordCount, practicePoolCount)) từ")
                                    Image(systemName: "chevron.down")
                                        .font(.app(.caption))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.gray.opacity(colorScheme == .light ? 0.1 : 0.15))
                                .foregroundStyle(.secondary)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)

                            if topic.flashcards.count > 60 {
                                Text("Nên 20–30 từ/phiên")
                                    .font(.app(.caption2))
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

            Divider()

            // Content based on mode
            switch selectedMode {
            case .list:
                listView
            case .practice:
                practiceView
            }
        }
        .onChange(of: selectedMode) { _, newValue in
            if newValue == .practice {
                startPractice()
            }
        }
        .onChange(of: topic.id) { _, _ in
            // Reset when topic changes
            if selectedMode == .practice {
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
        .confirmationDialog("Xóa từ vựng?", isPresented: Binding(
            get: { viewModel.flashcardToDelete != nil },
            set: { if !$0 { viewModel.flashcardToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Xóa", role: .destructive) {
                if let fc = viewModel.flashcardToDelete {
                    viewModel.flashcardToDelete = nil
                    viewModel.deleteFlashcard(fc)
                }
            }
            Button("Huỷ", role: .cancel) {
                viewModel.flashcardToDelete = nil
            }
        } message: {
            if let fc = viewModel.flashcardToDelete {
                Text("Từ \"\(fc.question)\" sẽ bị xóa. Không thể hoàn tác.")
            }
        }
    }
    
    // List mode view
    private var listView: some View {
        HSplitView {
            List(topic.flashcards, selection: $viewModel.selectedFlashcard) { flashcard in
                ZStack(alignment: .topTrailing) {
                    // Main content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(flashcard.exerciseType.rawValue)
                                .scaledFont(.xs)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(colorScheme == .light ? 0.12 : 0.18))
                                .cornerRadius(4)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        
                        Text(flashcard.question)
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.trailing, 32) // Space for icons

                        if let hint = flashcard.hint, !hint.isEmpty {
                            Text("💡 \(hint)")
                                .font(.app(.footnote))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .padding(.trailing, 32) // Space for icons
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Status Icons - absolute positioned
                    HStack(spacing: 4) {
                        if isFlashcardLearned(flashcard) {
                            Image(systemName: "checkmark.circle.fill")
                                .scaledFont(.xs)
                                .foregroundStyle(.secondary)
                                .help("Đã học")
                                .accessibilityLabel("Đã học")
                        }
                        
                        if needsImprovement(flashcard) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .scaledFont(.xs)
                                .foregroundStyle(.teal)
                                .help("Cần ôn lại")
                                .accessibilityLabel("Cần ôn lại")
                        }
                    }
                    .padding(.top, 2)
                    .padding(.trailing, 4)
                }
                .tag(flashcard)
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
                .contextMenu {
                    Button(action: {
                        viewModel.selectFlashcard(flashcard)
                        showEditFlashcardSheet = true
                    }) {
                        Label("Sửa từ vựng", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: {
                        viewModel.flashcardToDelete = flashcard
                    }) {
                        Label("Xoá từ vựng", systemImage: "trash")
                    }
                }
            }
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            .listStyle(.plain)
            .tint(.green)
            
            if let flashcard = viewModel.selectedFlashcard {
                FlashcardDetailView(flashcard: flashcard, topic: topic, subjectName: viewModel.selectedSubject?.name ?? "", onEdit: { showEditFlashcardSheet = true }, onAnswered: nil)
            } else {
                ContentUnavailableView(
                    "Chọn một flashcard",
                    systemImage: "rectangle.portrait.on.rectangle.portrait",
                    description: Text("Chọn một flashcard để xem chi tiết")
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func isFlashcardLearned(_ flashcard: Flashcard) -> Bool {
        if let progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) {
            return progress.totalReviews > 0
        }
        return false
    }
    
    private func needsImprovement(_ flashcard: Flashcard) -> Bool {
        // Check if flashcard has mistakes in the last 30 days
        let mistakeIds = DatabaseManager.shared.getMistakeFlashcards(days: 30)
        return mistakeIds.contains(flashcard.id)
    }
    
    // Practice mode view
    private var practiceView: some View {
        Group {
            switch selectedPracticeType {
            case .multipleChoice:
                multipleChoicePracticeView
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
            case .trueFalse:
                TrueFalsePracticeView(
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
            }
        }
    }

    // Original multiple choice practice
    private var multipleChoicePracticeView: some View {
        VStack {
            if currentIndex < shuffledFlashcards.count {
                let flashcard = shuffledFlashcards[currentIndex]

                // Progress indicator
                VStack(spacing: 8) {
                    HStack {
                        Text("Câu \(currentIndex + 1)/\(shuffledFlashcards.count)")
                            .font(.app(.headline))

                        Spacer()

                        Text(flashcard.exerciseType.rawValue)
                            .font(.app(.subheadline))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(colorScheme == .light ? 0.14 : 0.2))
                            .cornerRadius(6)
                    }

                    ProgressView(value: Double(currentIndex), total: Double(shuffledFlashcards.count))
                }
                .padding()

                // Flashcard with auto-advance - use id to force view recreation
                FlashcardDetailView(
                    flashcard: flashcard,
                    topic: topic,
                    subjectName: viewModel.selectedSubject?.name ?? "",
                    onEdit: nil,
                    onAnswered: { isCorrect in
                        handleAnswer(isCorrect: isCorrect)
                    }
                )
                .id(flashcard.id)
            } else {
                practiceCompletedView
            }
        }
    }

    private var practiceCompletedView: some View {
        PracticeCompletedView(
            score: score,
            totalAnswered: totalAnswered,
            onContinue: {
                recordPracticeIfNeeded()
                resetPractice()
            }
        )
    }
        
    /// Correct percentage in session (0–100)
    private var practiceScorePercentage: Int {
        totalAnswered > 0 ? Int((Double(score) / Double(totalAnswered)) * 100) : 0
    }

    /// Count of cards to review for selected source
    private var practicePoolCount: Int {
        practicePool().count
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
        let pool = practicePool()
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
    
    private func handleAnswer(isCorrect: Bool) {
        totalAnswered += 1
        if isCorrect {
            score += 1
        }
        
        // Update SRS progress
        if currentIndex < shuffledFlashcards.count {
            let flashcard = shuffledFlashcards[currentIndex]
            var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ?? 
                FlashcardProgress(flashcardId: flashcard.id)
            
            let srsAlgorithm = SRSAlgorithm()
            let quality: Double = isCorrect ? 1.0 : 0.0
            progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
            DatabaseManager.shared.saveFlashcardProgress(progress)
            
            // Record mistake if wrong
            if !isCorrect {
                DatabaseManager.shared.recordMistake(
                    flashcardId: flashcard.id,
                    practiceType: "Multiple Choice",
                    topicId: topic.id
                )
            }
        }

        // Auto advance after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                currentIndex += 1
            }
        }
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

            Divider()

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
                Button("Huỷ") {
                    clearAndClose()
                }
                .keyboardShortcut(.escape)

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
                }
                .keyboardShortcut(.return)
                .disabled(
                    viewModel.newFlashcardQuestion.trimmingCharacters(in: .whitespaces).isEmpty ||
                    viewModel.newFlashcardAnswer.trimmingCharacters(in: .whitespaces).isEmpty
                )
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


