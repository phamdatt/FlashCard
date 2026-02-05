//
//  ContentView.swift
//  learn-macos
//
//  Created by Dat Pham on 29/1/26.
//

import SwiftUI
import AppKit

// MARK: - Views

// Unified Sidebar View
struct SidebarView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var fontSizeManager: FontSizeManager

    var body: some View {
        List(selection: $viewModel.selectedSubject) {
            learningSection
            reviewSection
            statisticsSection
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        .navigationTitle("Menu")
        .safeAreaInset(edge: .bottom) {
            bottomSection
        }
    }
    
    // MARK: - Sections
    
    private var learningSection: some View {
        Section("Học tập") {
            ForEach(viewModel.subjects) { subject in
                Button(action: {
                    // Use transaction to batch updates
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.selectSubject(subject)
                        viewModel.switchToLearningMode()
                    }
                }) {
                    Label(subject.name, systemImage: subject.icon)
                        .scaledFont(14)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var reviewSection: some View {
        Section("Ôn tập") {
            Button(action: {
                viewModel.switchToReviewMode()
            }) {
                Label("Ôn tập SRS", systemImage: "repeat.circle.fill")
                    .scaledFont(14)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                viewModel.switchToReviewMistakes()
            }) {
                Label("Ôn lại từ sai", systemImage: "xmark.circle.fill")
                    .scaledFont(14)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var statisticsSection: some View {
        Section("Thống kê") {
            Button(action: {
                viewModel.switchToStatistics()
            }) {
                Label("Thống kê", systemImage: "chart.line.uptrend.xyaxis")
                    .scaledFont(14)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var bottomSection: some View {
        VStack(spacing: 8) {
            VStack(spacing: 8) {
                // Streak indicator
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .scaledFont(22)
                        .foregroundStyle(viewModel.streakInfo.currentStreak > 0 ? .orange : .gray)
                        .frame(minWidth: 22 * fontSizeManager.fontSizeMultiplier)
                        // .symbolEffect(.pulse, isActive: viewModel.streakInfo.didPracticeToday)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(viewModel.streakInfo.currentStreak)")
                                .scaledFont(18)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            Text("ngày")
                                .scaledFont(14)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        if viewModel.streakInfo.longestStreak > 0 {
                            Text("Kỷ lục: \(viewModel.streakInfo.longestStreak) ngày")
                                .scaledFont(11)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    if viewModel.streakInfo.didPracticeToday {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .scaledFont(16)
                            .frame(minWidth: 16 * fontSizeManager.fontSizeMultiplier)
                    } else {
                        Text("Chưa học")
                            .scaledFont(11)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .lineLimit(1)
                            .background(Capsule().fill(.orange))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 50 * fontSizeManager.fontSizeMultiplier)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )

                // Theme toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appearanceManager.cycleMode()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: appearanceManager.mode.icon)
                            .scaledFont(22)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(minWidth: 22 * fontSizeManager.fontSizeMultiplier)

                        Text(appearanceManager.mode.rawValue)
                            .scaledFont(14)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .scaledFont(10)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                            .frame(minWidth: 10 * fontSizeManager.fontSizeMultiplier)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 50 * fontSizeManager.fontSizeMultiplier)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear {
            // Auto-select first subject if none selected
            if viewModel.selectedSubject == nil, let firstSubject = viewModel.subjects.first {
                viewModel.selectSubject(firstSubject)
            }
        }
        .onChange(of: viewModel.selectedSubject) { _, newSubject in
            if let subject = newSubject {
                viewModel.selectSubject(subject)
            }
        }
    }
}

// Topics List View (shows topics for selected subject)
struct TopicsListView: View {
    @ObservedObject var viewModel: ContentViewModel
    let subject: Subject
    @FocusState private var isSearchFocused: Bool
    @State private var lastSelectedTopicId: Int? = nil
    
    var filteredTopics: [Topic] {
        viewModel.filteredTopics(for: subject)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Search Bar
            HStack(spacing: 12) {
                // Search Icon
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .scaledFont(16)
                    .fontWeight(.medium)
                
                // Search TextField
                TextField("Tìm kiếm chủ đề...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .scaledFont(15)
                    .focused($isSearchFocused)
                
                // Clear Button
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .scaledFont(16)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSearchFocused ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSearchFocused ? 2 : 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
            
            // Search Results Info
            if !viewModel.searchText.isEmpty {
                HStack {
                    Text("\(filteredTopics.count) kết quả")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Topics List
            if filteredTopics.isEmpty {
                ContentUnavailableView {
                    Label("Không tìm thấy kết quả", systemImage: "magnifyingglass")
                } description: {
                    Text("Thử tìm kiếm với từ khóa khác")
                }
            } else {
                List(filteredTopics, selection: $viewModel.selectedTopic) { topic in
                    HStack(spacing: 12) {
                        // Topic Icon
                        Image(systemName: "book.fill")
                            .scaledFont(18)
                            .foregroundColor(.accentColor)
                            .frame(width: 32)

                        // Topic Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(topic.name)
                                .scaledFont(14)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)

                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.stack.fill")
                                    .scaledFont(12)
                                Text("\(topic.flashcards.count) flashcards")
                                    .scaledFont(14)
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Chevron
                        Image(systemName: "chevron.right")
                            .scaledFont(12)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .tag(topic)
                    .contextMenu {
                        Button(role: .destructive, action: {
                            viewModel.deleteTopic(topic)
                        }) {
                            Label("Xoá chủ đề", systemImage: "trash")
                        }
                    }
                }
                .listStyle(.plain)
                .onChange(of: viewModel.selectedTopic) { oldValue, newValue in
                    // Lưu lại ID của topic được chọn
                    if let newTopic = newValue {
                        lastSelectedTopicId = newTopic.id
                    }
                    
                    // Nếu click vào vùng trống làm selectedTopic thành nil, restore lại topic trước đó
                    if newValue == nil && lastSelectedTopicId != nil && !filteredTopics.isEmpty {
                        // Chỉ restore nếu topic cũ vẫn còn trong danh sách
                        if let topic = filteredTopics.first(where: { $0.id == lastSelectedTopicId }) {
                            DispatchQueue.main.async {
                                viewModel.selectedTopic = topic
                            }
                        } else {
                            // Nếu topic cũ không còn trong danh sách (có thể do filter), chọn topic đầu tiên
                            if let firstTopic = filteredTopics.first {
                                DispatchQueue.main.async {
                                    viewModel.selectedTopic = firstTopic
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    // Lưu lại topic hiện tại khi view xuất hiện
                    if let currentTopic = viewModel.selectedTopic {
                        lastSelectedTopicId = currentTopic.id
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Add Topic Button - Sticky at bottom
            HStack {
                Spacer()
                Button(action: {
                    viewModel.showAddTopicSheet = true
                }) {
                    Label("Thêm chủ đề", systemImage: "plus.circle.fill")
                        .scaledFont(13)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                // Gradient fade để tạo hiệu ứng mượt
                LinearGradient(
                    colors: [Color(nsColor: .windowBackgroundColor).opacity(0), Color(nsColor: .windowBackgroundColor)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .allowsHitTesting(false)
            )
        }
        .navigationTitle(subject.name)
        .animation(.easeInOut(duration: 0.3), value: viewModel.searchText)
        .sheet(isPresented: $viewModel.showAddTopicSheet) {
            AddTopicSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Add Topic Sheet
struct AddTopicSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Tạo chủ đề mới")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    viewModel.newTopicName = ""
                    viewModel.showAddTopicSheet = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Subject info
            if let subject = viewModel.selectedSubject {
                HStack(spacing: 8) {
                    Image(systemName: subject.icon)
                        .foregroundStyle(.blue)
                    Text(subject.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            Divider()

            // Topic name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Tên chủ đề")
                    .font(.headline)
                TextField("Ví dụ: Sports (Thể thao)", text: $viewModel.newTopicName)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .focused($isFocused)
            }

            Spacer()

            // Action buttons
            HStack {
                Button("Huỷ") {
                    viewModel.newTopicName = ""
                    viewModel.showAddTopicSheet = false
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button(action: {
                    viewModel.addTopic(name: viewModel.newTopicName)
                }) {
                    Text("Tạo chủ đề")
                        .fontWeight(.semibold)
                }
                .keyboardShortcut(.return)
                .disabled(viewModel.newTopicName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400, height: 280)
        .onAppear { isFocused = true }
    }
}

// Flashcard Detail View
struct FlashcardDetailView: View {
    let flashcard: Flashcard
    let topic: Topic
    let subjectName: String
    let onAnswered: ((Bool) -> Void)?  // Callback for practice mode

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var isFlipped = false
    @State private var selectedAnswer: String? = nil
    @State private var showResult = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subjectName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(topic.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                if flashcard.isMultipleChoice {
                    // Multiple Choice Question
                    multipleChoiceView
                } else {
                    // Traditional Flashcard
                    traditionalFlashcardView
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 500)
    }
    
    // Traditional flip card view
    private var traditionalFlashcardView: some View {
        VStack(spacing: 20) {
            // Card
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFlipped
                        ? Color.green.opacity(colorScheme == .light ? 0.06 : 0.1)
                        : Color.blue.opacity(colorScheme == .light ? 0.06 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isFlipped
                                    ? Color.green.opacity(colorScheme == .light ? 0.6 : 1)
                                    : Color.blue.opacity(colorScheme == .light ? 0.6 : 1),
                                lineWidth: 2)
                    )
                
                VStack(spacing: 16) {
                    Text(isFlipped ? "Đáp án" : "Câu hỏi")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    SmartCopyDefineText(text: isFlipped ? flashcard.answer : flashcard.question, flashcards: topic.flashcards)
                        .scaledFont(28)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .environmentObject(fontSizeManager)
                }
                .padding()
            }
            .frame(minHeight: 250)
            .padding()
            
            // Flip button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFlipped.toggle()
                }
            }) {
                Label(isFlipped ? "Xem câu hỏi" : "Xem đáp án", systemImage: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            
            // Hint section
            if let hint = flashcard.hint {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Gợi ý", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    
                    SmartCopyDefineText(text: hint, flashcards: topic.flashcards)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // Multiple choice question view
    private var multipleChoiceView: some View {
        VStack(spacing: 25) {
            // Question card
            VStack(spacing: 16) {
                Text("Câu hỏi")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                SmartCopyDefineText(text: flashcard.question, flashcards: topic.flashcards)
                    .scaledFont(28) // title size
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                    .environmentObject(fontSizeManager)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(colorScheme == .light ? 0.05 : 0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(colorScheme == .light ? 0.4 : 1), lineWidth: 2)
            )
            .cornerRadius(16)
            
            // Hint section
            if let hint = flashcard.hint, !showResult {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.orange)
                    SmartCopyDefineText(text: hint, flashcards: topic.flashcards)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Options
            VStack(spacing: 12) {
                ForEach(flashcard.options ?? [], id: \.self) { option in
                    multipleChoiceButton(option: option)
                }
            }
            
            // Result feedback
            if showResult {
                resultView
            }
        }
    }
    
    private func multipleChoiceButton(option: String) -> some View {
        let optionLetter = String(option.prefix(1))
        let isSelected = selectedAnswer == optionLetter
        let isCorrect = flashcard.correctAnswer == optionLetter
        let shortcutKey = KeyEquivalent(Character(optionLetter.lowercased()))
        
        @State var isPressed = false
        
        let isLight = colorScheme == .light

        var backgroundColor: Color {
            if !showResult {
                if isSelected {
                    return Color.blue.opacity(isLight ? 0.1 : 0.15)
                }
                return isLight ? Color(nsColor: .controlBackgroundColor) : Color.gray.opacity(0.08)
            } else {
                if isCorrect {
                    return Color.green.opacity(isLight ? 0.18 : 0.2)
                } else if isSelected && !isCorrect {
                    return Color.red.opacity(isLight ? 0.18 : 0.2)
                }
                return isLight ? Color(nsColor: .controlBackgroundColor) : Color.gray.opacity(0.08)
            }
        }

        var borderColor: Color {
            if !showResult {
                return isSelected ? .blue : Color.gray.opacity(isLight ? 0.25 : 0.5)
            } else {
                if isCorrect {
                    return .green
                } else if isSelected && !isCorrect {
                    return .red
                }
                return Color.gray.opacity(isLight ? 0.25 : 0.5)
            }
        }

        var shadowColor: Color {
            if !showResult {
                return isSelected
                    ? Color.blue.opacity(isLight ? 0.2 : 0.4)
                    : Color.gray.opacity(isLight ? 0.15 : 0.4)
            } else {
                if isCorrect {
                    return Color.green.opacity(isLight ? 0.35 : 0.5)
                } else if isSelected && !isCorrect {
                    return Color.red.opacity(isLight ? 0.35 : 0.5)
                }
                return Color.gray.opacity(isLight ? 0.15 : 0.4)
            }
        }
        
        return Button(action: {
            if !showResult {
                let isCorrect = optionLetter == flashcard.correctAnswer
                
                // Improved sound and haptic feedback
                if isCorrect {
                    SoundManager.shared.playCorrectWithHaptic()
                } else {
                    SoundManager.shared.playIncorrectWithHaptic()
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.15)) {
                    selectedAnswer = optionLetter
                    showResult = true
                    onAnswered?(isCorrect)
                }
            }
        }) {
            HStack {
                Text(option)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showResult {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce.up, value: showResult)
                            .shadow(color: .green.opacity(0.5), radius: 4)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                            .symbolEffect(.bounce.down, value: showResult)
                            .shadow(color: .red.opacity(0.5), radius: 4)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    // Bottom shadow layer (depth effect)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(shadowColor)
                        .offset(y: isPressed ? 2 : 4)
                    
                    // Main button layer
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(borderColor, lineWidth: 3)
                        )
                }
            )
            .offset(y: isPressed ? 2 : 0)
        }
        .buttonStyle(CoreButtonStyle(isPressed: $isPressed, isDisabled: showResult))
        .keyboardShortcut(shortcutKey, modifiers: [])
        // Sử dụng opacity và border thay vì scale để tránh tràn
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    showResult && isCorrect ? Color.green.opacity(0.6) : 
                    (showResult && isSelected && !isCorrect ? Color.red.opacity(0.6) : Color.clear),
                    lineWidth: showResult ? 3 : 0
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showResult)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
    
    private var resultView: some View {
        VStack(spacing: 12) {
            let isCorrect = selectedAnswer == flashcard.correctAnswer
            
            HStack(spacing: 16) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(isCorrect ? .green : .red)
                    .symbolEffect(.bounce.up, value: showResult)
                    .scaleEffect(showResult ? 1.15 : 1.0)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(isCorrect ? "Chính xác! 🎉" : "Chưa đúng")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(isCorrect ? .green : .red)
                    
                    SmartCopyDefineText(text: flashcard.answer, flashcards: topic.flashcards)
                        .scaledFont(17) // body size
                        .foregroundStyle(.secondary)
                        .environmentObject(fontSizeManager)
                }
                
                Spacer()
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isCorrect
                        ? Color.green.opacity(colorScheme == .light ? 0.12 : 0.15)
                        : Color.red.opacity(colorScheme == .light ? 0.12 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showResult)
    }
}

struct CoreButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                if !isDisabled {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = newValue
                    }
                }
            }
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @EnvironmentObject var fontSizeManager: FontSizeManager
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
        } content: {
            middleColumn
        } detail: {
            detailColumn
        }
        .applyFontSizeScaling(multiplier: fontSizeManager.fontSizeMultiplier)
        .onChange(of: viewModel.isInSpecialMode) { oldValue, newValue in
            // Only update if actually changed to avoid unnecessary animations
            if oldValue != newValue {
                updateColumnVisibility(animated: true)
            }
        }
    }
    
    // MARK: - Columns
    
    @ViewBuilder
    private var middleColumn: some View {
        if viewModel.isInSpecialMode {
            // Empty view when in special mode
            Color.clear
                .frame(width: 0)
                .navigationSplitViewColumnWidth(min: 0, ideal: 0, max: 0)
        } else if let subject = viewModel.selectedSubject {
            TopicsListView(viewModel: viewModel, subject: subject)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } else {
            ContentUnavailableView(
                "Chọn môn học",
                systemImage: "book.fill",
                description: Text("Chọn một môn học từ sidebar")
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        }
    }
    
    @ViewBuilder
    private var detailColumn: some View {
        Group {
            if viewModel.showReviewMode {
                ReviewModeView(viewModel: viewModel)
                    .id("review-mode")
            } else if viewModel.showReviewMistakes {
                ReviewMistakesView(viewModel: viewModel)
                    .id("review-mistakes")
            } else if viewModel.showStatistics {
                StatisticsDashboardView(viewModel: viewModel)
                    .id("statistics")
            } else if let topic = viewModel.selectedTopic {
                FlashcardMainView(viewModel: viewModel, topic: topic)
                    .id("topic-\(topic.id)")
            } else {
                ContentUnavailableView(
                    "Chọn chủ đề",
                    systemImage: "text.book.closed.fill",
                    description: Text("Chọn một chủ đề để xem flashcards")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Helpers
    
    private func updateColumnVisibility(animated: Bool) {
        let newVisibility: NavigationSplitViewVisibility = viewModel.isInSpecialMode ? .doubleColumn : .all
        
        // Use transaction for smoother animation
        if animated {
            var transaction = Transaction(animation: .easeInOut(duration: 0.3))
            transaction.disablesAnimations = false
            withTransaction(transaction) {
                columnVisibility = newVisibility
            }
        } else {
            columnVisibility = newVisibility
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 600)
}
