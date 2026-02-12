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
        case flipCard = "Thẻ lật"
        case matching = "Nối cặp"
        case speaking = "Luyện nói"
        case fillInTheBlank = "Điền từ"
        case listening = "Nghe → chọn"
        case fillInPinyin = "Điền pinyin"
        case meaningToHanzi = "Nghĩa → Hán tự"

        /// Tiếng Anh & Tiếng Trung: Trắc nghiệm, Thẻ lật, Nối, Nói, Điền từ, Nghe→chọn. Chỉ Tiếng Trung thêm: Điền pinyin, Nghĩa→Hán tự.
        static func availableTypes(subjectName: String?) -> [PracticeType] {
            let all: [PracticeType] = [.multipleChoice, .flipCard, .matching, .speaking, .fillInTheBlank, .listening]
            guard subjectName == "Tiếng Trung" else { return all }
            return all + [.fillInPinyin, .meaningToHanzi]
        }

        var icon: String {
            switch self {
            case .multipleChoice: return "list.bullet.circle.fill"
            case .flipCard: return "rectangle.portrait.on.rectangle.portrait.angled"
            case .matching: return "arrow.left.arrow.right"
            case .speaking: return "mic.fill"
            case .fillInTheBlank: return "pencil.and.list.clipboard"
            case .listening: return "speaker.wave.2.fill"
            case .fillInPinyin: return "character.bubble"
            case .meaningToHanzi: return "character.cursor.ibeam"
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
    /// Đang trong flow Từ của ngày (Lật thẻ → Trắc nghiệm → Nối từ → Nghĩa→Hán tự).
    @State private var isWordOfDayFlow: Bool = false

    enum PracticeSource: String, CaseIterable {
        case all = "Tất cả"
        case notLearned = "Chưa thuộc"
        case mistakes = "Đã sai"
        case weak = "Từ yếu"
    }
    
    var body: some View {
        mainContent
            .modifier(FlashcardMainModifier(
                viewModel: viewModel,
                topic: topic,
                selectedMode: $selectedMode,
                practiceStarted: $practiceStarted,
                selectedPracticeType: $selectedPracticeType,
                showEditFlashcardSheet: $showEditFlashcardSheet,
                showDeleteMultipleFlashcardsConfirmation: $showDeleteMultipleFlashcardsConfirmation,
                showEndPracticeConfirmation: $showEndPracticeConfirmation,
                openWordOfDayPracticeIfNeeded: openWordOfDayPracticeIfNeeded,
                resetPractice: resetPractice
            ))
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            ThemeDivider()
            modeToggleSection
            modeContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerSection: some View {
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
                Button(action: { viewModel.showAddFlashcardSheet = true }) {
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

                Button(action: { viewModel.showImportFlashcardSheet = true }) {
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
    }

    @ViewBuilder
    private var modeToggleSection: some View {
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
                    practiceSettingsView
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ThemeDivider()
        }
    }

    private var practiceSettingsView: some View {
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

    @ViewBuilder
    private var modeContent: some View {
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
            if isWordOfDayFlow, !shuffledFlashcards.isEmpty {
                WordOfDayPracticeFlowView(
                    flashcards: shuffledFlashcards,
                    topic: topic,
                    subjectName: viewModel.selectedSubject?.name ?? "",
                    subjectIcon: viewModel.selectedSubject?.displayIcon,
                    radicalForCharacter: viewModel.radicalForCharacter,
                    topicId: topic.id,
                    onComplete: {
                        isWordOfDayFlow = false
                        practiceStarted = false
                        viewModel.isPracticeSessionActive = false
                        viewModel.loadStreakInfo()
                        resetPractice()
                    }
                )
            } else {
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
            case .flipCard:
                FlipCardPracticeView(
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
            case .meaningToHanzi:
                MeaningToHanziPracticeView(
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
            case .listening:
                ListeningPracticeView(
                    flashcards: shuffledFlashcards,
                    topic: topic,
                    topicId: topic.id,
                    subjectName: viewModel.selectedSubject?.name ?? "",
                    subjectIcon: viewModel.selectedSubject?.displayIcon,
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

    /// Card pool by source: all, unlearned, mistake, or weak
    private func practicePool() -> [Flashcard] {
        let all = topic.flashcards
        switch practiceSource {
        case .all:
            return all
        case .notLearned:
            let notLearned = all.filter { (DatabaseManager.shared.getFlashcardProgress(flashcardId: $0.id)?.totalReviews ?? 0) == 0 }
            return notLearned.isEmpty ? all : notLearned
        case .mistakes:
            let ids = DatabaseManager.shared.getFlashcardIdsWithMistakes(topicId: topic.id)
            return all.filter { ids.contains($0.id) }
        case .weak:
            let ids = DatabaseManager.shared.getWeakFlashcardIds(topicId: topic.id)
            return all.filter { ids.contains($0.id) }
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

    /// Mở mode Luyện tập với flow Từ của ngày (Lật thẻ → Trắc nghiệm → Nối từ → Nghĩa→Hán tự) khi viewModel.wordOfDayToPractice khớp topic.
    private func openWordOfDayPracticeIfNeeded() {
        guard let pending = viewModel.wordOfDayToPractice, pending.topic.id == topic.id else { return }
        viewModel.wordOfDayToPractice = nil
        selectedMode = .practice
        shuffledFlashcards = pending.flashcards
        currentIndex = 0
        score = 0
        totalAnswered = 0
        practiceRecorded = false
        isWordOfDayFlow = true
        practiceStarted = true
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

// MARK: - Modifier tách biệt để tránh compiler type-check timeout
private struct FlashcardMainModifier: ViewModifier {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @Binding var selectedMode: FlashcardMainView.ViewMode
    @Binding var practiceStarted: Bool
    @Binding var selectedPracticeType: FlashcardMainView.PracticeType
    @Binding var showEditFlashcardSheet: Bool
    @Binding var showDeleteMultipleFlashcardsConfirmation: Bool
    @Binding var showEndPracticeConfirmation: Bool
    let openWordOfDayPracticeIfNeeded: () -> Void
    let resetPractice: () -> Void

    func body(content: Content) -> some View {
        content
            .modifier(FlashcardMainModifierLifecycle(
                viewModel: viewModel,
                topic: topic,
                selectedMode: $selectedMode,
                practiceStarted: $practiceStarted,
                selectedPracticeType: $selectedPracticeType,
                openWordOfDayPracticeIfNeeded: openWordOfDayPracticeIfNeeded,
                resetPractice: resetPractice
            ))
            .modifier(FlashcardMainModifierSheets(
                viewModel: viewModel,
                showEditFlashcardSheet: $showEditFlashcardSheet
            ))
            .modifier(FlashcardMainModifierOverlays(
                viewModel: viewModel,
                topic: topic,
                practiceStarted: $practiceStarted,
                showDeleteMultipleFlashcardsConfirmation: $showDeleteMultipleFlashcardsConfirmation,
                showEndPracticeConfirmation: $showEndPracticeConfirmation
            ))
    }
}

private struct FlashcardMainModifierLifecycle: ViewModifier {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @Binding var selectedMode: FlashcardMainView.ViewMode
    @Binding var practiceStarted: Bool
    @Binding var selectedPracticeType: FlashcardMainView.PracticeType
    let openWordOfDayPracticeIfNeeded: () -> Void
    let resetPractice: () -> Void

    func body(content: Content) -> some View {
        content
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
                openWordOfDayPracticeIfNeeded()
            }
            .onChange(of: viewModel.wordOfDayToPractice?.topic.id) { _, newId in
                if newId == topic.id { openWordOfDayPracticeIfNeeded() }
            }
            .onDisappear { viewModel.isInPracticeMode = false }
            .onChange(of: topic.id) { _, _ in
                if selectedMode == .practice {
                    let available = FlashcardMainView.PracticeType.availableTypes(subjectName: viewModel.selectedSubject?.name)
                    if !available.contains(selectedPracticeType) {
                        selectedPracticeType = .multipleChoice
                    }
                    resetPractice()
                }
            }
    }
}

private struct FlashcardMainModifierSheets: ViewModifier {
    @ObservedObject var viewModel: ContentViewModel
    @Binding var showEditFlashcardSheet: Bool

    func body(content: Content) -> some View {
        content
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
    }
}

private struct FlashcardMainModifierOverlays: ViewModifier {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @Binding var practiceStarted: Bool
    @Binding var showDeleteMultipleFlashcardsConfirmation: Bool
    @Binding var showEndPracticeConfirmation: Bool

    func body(content: Content) -> some View {
        content
            .overlay { deleteFlashcardOverlay }
            .overlay { deleteMultipleOverlay }
            .overlay { endPracticeOverlay }
    }

    private var deleteFlashcardOverlay: some View {
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

    private var deleteMultipleOverlay: some View {
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

    private var endPracticeOverlay: some View {
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


