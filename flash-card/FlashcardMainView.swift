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
    
    // Mode selection
    enum ViewMode: String, CaseIterable {
        case list = "Danh sách"
        case practice = "Luyện tập"
        case reading = "Bài đọc"
    }

    enum PracticeType: String, CaseIterable {
        case multipleChoice = "Trắc nghiệm"
        case matching = "Nối cặp"
        case trueFalse = "Đúng/Sai"
        case speedCards = "Thẻ nhớ nhanh"

        var icon: String {
            switch self {
            case .multipleChoice: return "list.bullet.circle.fill"
            case .matching: return "arrow.left.arrow.right"
            case .trueFalse: return "checkmark.circle"
            case .speedCards: return "bolt.fill"
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
                    .font(.headline)
                
                Spacer()

                // Add flashcard button
                Button(action: {
                    viewModel.showAddFlashcardSheet = true
                }) {
                    Label("Thêm từ", systemImage: "plus.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
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
                    HStack(spacing: 8) {
                        Picker("Kiểu", selection: $selectedPracticeType) {
                            ForEach(PracticeType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Menu {
                            Button("20 từ") {
                                selectedWordCount = 20
                                resetPractice()
                            }
                            Button("40 từ") {
                                selectedWordCount = 40
                                resetPractice()
                            }
                            Button("60 từ") {
                                selectedWordCount = 60
                                resetPractice()
                            }
                            Button("Tất cả (\(topic.flashcards.count) từ)") {
                                selectedWordCount = topic.flashcards.count
                                resetPractice()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "number.circle.fill")
                                Text("\(min(selectedWordCount, topic.flashcards.count)) từ")
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        if totalAnswered > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                let percentage = Int((Double(score) / Double(totalAnswered)) * 100)
                                Text("\(score)/\(totalAnswered) (\(percentage)%)")
                                    .font(.subheadline)
                                    .foregroundStyle(percentage >= 70 ? .green : .orange)
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
            case .reading:
                readingView
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
    }
    
    // List mode view
    private var listView: some View {
        HSplitView {
            List(topic.flashcards, selection: $viewModel.selectedFlashcard) { flashcard in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(flashcard.exerciseType.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    
                    Text(flashcard.question)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)

                    if let hint = flashcard.hint {
                        Text("💡 \(hint)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(flashcard)
                .padding(.vertical, 4)
                .contextMenu {
                    Button(role: .destructive, action: {
                        viewModel.deleteFlashcard(flashcard)
                    }) {
                        Label("Xoá từ vựng", systemImage: "trash")
                    }
                }
            }
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            .listStyle(.plain)
            
            if let flashcard = viewModel.selectedFlashcard {
                FlashcardDetailView(flashcard: flashcard, topic: topic, subjectName: viewModel.selectedSubject?.name ?? "", onAnswered: nil)
            } else {
                ContentUnavailableView(
                    "Chọn một flashcard",
                    systemImage: "rectangle.portrait.on.rectangle.portrait",
                    description: Text("Chọn một flashcard để xem chi tiết")
                )
            }
        }
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
                    onComplete: { knownCount, total in
                        score = knownCount
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
                            .font(.headline)

                        Spacer()

                        Text(flashcard.exerciseType.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
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
        
    private func startPractice() {
        let totalAvailable = topic.flashcards.count
        let countToUse = min(selectedWordCount, totalAvailable)

        shuffledFlashcards = Array(topic.flashcards.shuffled().prefix(countToUse))
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
    
    // MARK: - Reading View
    private var readingView: some View {
        Group {
            if topic.readings.isEmpty {
                VStack {
                    Spacer()
                        .frame(height: 60)
                    ContentUnavailableView(
                        "Chưa có bài đọc",
                        systemImage: "book.closed",
                        description: Text("Chủ đề này chưa có bài đọc nào")
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                ReadingPassageListView(readings: topic.readings)
            }
        }
    }
}

// MARK: - Reading Passage Views
struct ReadingPassageListView: View {
    let readings: [ReadingPassage]
    @State private var selectedReading: ReadingPassage?
    
    var body: some View {
        HSplitView {
            // Reading list
            List(readings, selection: $selectedReading) { reading in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Level badge
                        Text(reading.level.rawValue)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(levelColor(for: reading.level).opacity(0.2))
                            .foregroundStyle(levelColor(for: reading.level))
                            .cornerRadius(6)

                        Spacer()

                        // Question count
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.footnote)
                            Text("\(reading.questions.count) câu hỏi")
                                .font(.footnote)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Text(reading.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(reading.content.prefix(100) + "...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 8)
                .tag(reading)
            }
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            .listStyle(.plain)
            
            // Reading detail
            if let reading = selectedReading {
                ReadingPassageDetailView(reading: reading)
            } else {
                ContentUnavailableView(
                    "Chọn một bài đọc",
                    systemImage: "book.fill",
                    description: Text("Chọn bài đọc từ danh sách bên trái")
                )
            }
        }
        .onAppear {
            if selectedReading == nil && !readings.isEmpty {
                selectedReading = readings.first
            }
        }
    }
    
    private func levelColor(for level: ReadingLevel) -> Color {
        switch level {
        case .beginner:
            return .green
        case .elementary:
            return .blue
        case .intermediate:
            return .orange
        case .upperIntermediate:
            return .purple
        case .advanced:
            return .red
        }
    }
}

struct ReadingPassageDetailView: View {
    let reading: ReadingPassage
    @Environment(\.colorScheme) private var colorScheme
    @State private var userAnswers: [Int: String] = [:] // questionId -> selected answer
    @State private var showResults: Bool = false
    @State private var score: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(reading.level.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(levelColor(for: reading.level).opacity(0.2))
                            .foregroundStyle(levelColor(for: reading.level))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        if showResults {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("\(score)/\(reading.questions.count)")
                                    .font(.headline)
                            }
                        }
                    }
                    
                    Text(reading.title)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Divider()
                
                // Vocabulary help (if available)
                if let vocabulary = reading.vocabularyHelp, !vocabulary.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundStyle(.blue)
                            Text("Từ vựng hỗ trợ")
                                .font(.headline)
                        }
                        
                        ForEach(vocabulary) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.word)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                    
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    
                                    Text(item.meaning)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let example = item.example {
                                    Text("📝 \(example)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .italic()
                                        .padding(.leading, 4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .light
                                ? Color(nsColor: .controlBackgroundColor)
                                : Color.blue.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .light ? Color.blue.opacity(0.15) : Color.clear, lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
                
                // Reading content
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(.green)
                        Text("Bài đọc")
                            .font(.headline)
                    }
                    
                    TappableReadingContent(text: reading.content, vocabularyHelp: reading.vocabularyHelp)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .light
                                    ? Color(nsColor: .textBackgroundColor)
                                    : Color.green.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorScheme == .light ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                
                Divider()
                
                // Questions
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Câu hỏi")
                            .font(.headline)
                    }
                    
                    ForEach(Array(reading.questions.enumerated()), id: \.element.id) { index, question in
                        questionView(question: question, index: index + 1)
                    }
                }
                
                // Submit button
                if !showResults {
                    Button(action: checkAnswers) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Nộp bài")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userAnswers.count == reading.questions.count ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(userAnswers.count != reading.questions.count)
                } else {
                    Button(action: resetQuiz) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Làm lại")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }
    
    @ViewBuilder
    private func questionView(question: ReadingQuestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Câu \(index): \(question.question)")
                .font(.body)
                .fontWeight(.semibold)
            
            ForEach(question.options, id: \.self) { option in
                optionButton(option: option, question: question)
            }
            
            // Show explanation if available and results are shown
            if showResults, let explanation = question.explanation {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text(explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light
                    ? Color(nsColor: .controlBackgroundColor)
                    : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .light ? Color.gray.opacity(0.15) : Color.clear, lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func optionButton(option: String, question: ReadingQuestion) -> some View {
        let optionLetter = String(option.prefix(1))
        let isSelected = userAnswers[question.id] == optionLetter
        let isCorrect = question.correctAnswer == optionLetter
        
        Button(action: {
            if !showResults {
                userAnswers[question.id] = optionLetter
            }
        }) {
            HStack {
                Text(option)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showResults {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .background(buttonBackground(isSelected: isSelected, isCorrect: isCorrect))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(buttonBorder(isSelected: isSelected, isCorrect: isCorrect), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(showResults)
    }
    
    private func buttonBackground(isSelected: Bool, isCorrect: Bool) -> Color {
        let isLight = colorScheme == .light
        if !showResults {
            if isSelected {
                return Color.blue.opacity(isLight ? 0.08 : 0.1)
            }
            return isLight ? Color(nsColor: .controlBackgroundColor) : Color.clear
        } else {
            if isCorrect {
                return Color.green.opacity(isLight ? 0.08 : 0.1)
            } else if isSelected && !isCorrect {
                return Color.red.opacity(isLight ? 0.08 : 0.1)
            }
            return isLight ? Color(nsColor: .controlBackgroundColor) : Color.clear
        }
    }

    private func buttonBorder(isSelected: Bool, isCorrect: Bool) -> Color {
        let isLight = colorScheme == .light
        if !showResults {
            return isSelected ? .blue : Color.gray.opacity(isLight ? 0.2 : 0.3)
        } else {
            if isCorrect {
                return .green
            } else if isSelected && !isCorrect {
                return .red
            }
            return Color.gray.opacity(isLight ? 0.2 : 0.3)
        }
    }
    
    private func checkAnswers() {
        var correctCount = 0
        for question in reading.questions {
            if userAnswers[question.id] == question.correctAnswer {
                correctCount += 1
            }
        }
        score = correctCount
        withAnimation {
            showResults = true
        }
    }
    
    private func resetQuiz() {
        withAnimation {
            userAnswers.removeAll()
            showResults = false
            score = 0
        }
    }
    
    private func levelColor(for level: ReadingLevel) -> Color {
        switch level {
        case .beginner:
            return .green
        case .elementary:
            return .blue
        case .intermediate:
            return .orange
        case .upperIntermediate:
            return .purple
        case .advanced:
            return .red
        }
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
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    clearAndClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Topic info
            if let topic = viewModel.selectedTopic {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.blue)
                    Text(topic.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            Divider()

            // Input fields
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Từ gốc")
                        .font(.headline)
                    TextField("Ví dụ: Apple", text: $viewModel.newFlashcardQuestion)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .question)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Nghĩa")
                        .font(.headline)
                    TextField("Ví dụ: Quả táo", text: $viewModel.newFlashcardAnswer)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .answer)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Gợi ý")
                        .font(.headline)
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

// MARK: - Tappable Reading Content (Smart Define)

struct TappableReadingContent: View {
    let text: String
    let vocabularyHelp: [VocabularyItem]?

    @State private var selectedWordIndex: Int? = nil
    @State private var wordResult: (word: String, meaning: String, hint: String?)? = nil

    private var paragraphs: [[String]] {
        text.components(separatedBy: "\n").map { paragraph in
            paragraph.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { pIdx, words in
                if words.joined().trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 4)
                } else {
                    WordFlowLayout(horizontalSpacing: 4, verticalSpacing: 5) {
                        ForEach(Array(words.enumerated()), id: \.offset) { wIdx, word in
                            let globalIndex = globalIndex(paragraph: pIdx, word: wIdx)
                            let isSelected = selectedWordIndex == globalIndex

                            Text(word)
                                .font(.body)
                                .padding(.vertical, 1)
                                .padding(.horizontal, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                                )
                                .onTapGesture {
                                }
                                .popover(isPresented: .constant(isSelected && wordResult != nil), arrowEdge: .bottom) {
                                    if let result = wordResult {
                                        WordDefinitionPopover(result: result) {
                                            selectedWordIndex = nil
                                            wordResult = nil
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    private func globalIndex(paragraph: Int, word: Int) -> Int {
        paragraph * 10000 + word
    }

}

struct WordDefinitionPopover: View {
    let result: (word: String, meaning: String, hint: String?)
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.word)
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(result.meaning)
                .font(.body)
                .foregroundStyle(.blue)

            if let hint = result.hint, !hint.isEmpty {
                Divider()
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(minWidth: 200, maxWidth: 300)
    }
}

// MARK: - Word Flow Layout

struct WordFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + horizontalSpacing
            totalHeight = max(totalHeight, y + rowHeight)
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}

