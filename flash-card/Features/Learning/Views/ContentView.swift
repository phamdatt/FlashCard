//
//  ContentView.swift
//  learn-macos
//
//  Created by Dat Pham on 29/1/26.
//

import SwiftUI
import AppKit

extension Notification.Name {
    static let openKeyboardShortcuts = Notification.Name("OpenKeyboardShortcuts")
}

// MARK: - Views

// Unified Sidebar View
struct SidebarView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List(selection: $viewModel.selectedSubject) {
            learningSection
            reviewSection
            statisticsSection
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        .navigationTitle("Menu")
        .tint(.green)
        .safeAreaInset(edge: .bottom) {
            bottomSection
        }
    }
    
    // MARK: - Sections
    
    private var learningSection: some View {
        Section("Học tập") {
            ForEach(viewModel.subjects) { subject in
                Button(action: {
                    viewModel.selectSubject(subject)
                    viewModel.switchToLearningMode()
                }) {
                    Label(subject.name, systemImage: subject.icon)
                        .scaledFont(.sm)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
            }
        }
    }
    
    private var reviewSection: some View {
        Section("Ôn tập") {
            // Button(action: {
            //     viewModel.switchToReviewMode()
            // }) {
            //     Label("Ôn tập SRS", systemImage: "repeat.circle.fill")
            //         .scaledFont(.sm)
            //         .padding(.vertical, 6)
            //         .padding(.horizontal, 8)
            //         .frame(maxWidth: .infinity, alignment: .leading)
            // }
            // .buttonStyle(.plain)
            // .cursor(.pointingHand)
            // .accessibilityLabel("Ôn tập SRS")
            // .accessibilityHint("Mở màn ôn từ theo thuật toán lặp lại ngắt quãng")

            Button(action: {
                viewModel.switchToReviewMistakes()
            }) {
                Label("Ôn lại từ sai", systemImage: "xmark.circle.fill")
                    .scaledFont(.sm)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
            .accessibilityLabel("Ôn lại từ sai")
            .accessibilityHint("Mở danh sách từ đã trả lời sai để ôn lại")
        }
    }
    
    private var statisticsSection: some View {
        Section("Thống kê") {
            Button(action: {
                viewModel.switchToStatistics()
            }) {
                Label("Thống kê", systemImage: "chart.line.uptrend.xyaxis")
                    .scaledFont(.sm)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
            .accessibilityLabel("Thống kê")
            .accessibilityHint("Xem thống kê học tập và streak")
        }
    }
    
    private var bottomSection: some View {
        VStack(spacing: 8) {
            VStack(spacing: 8) {
                // Streak indicator
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(viewModel.streakInfo.currentStreak > 0 ? .orange : .secondary)
                        .scaledFont(.xl2)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(viewModel.streakInfo.currentStreak)")
                                .scaledFont(.lg)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            Text("ngày")
                                .scaledFont(.sm)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        if viewModel.streakInfo.longestStreak > 0 {
                            Text("Kỷ lục: \(viewModel.streakInfo.longestStreak) ngày")
                                .scaledFont(.xs)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    if viewModel.streakInfo.didPracticeToday {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(viewModel.streakInfo.currentStreak > 0 ? .green : .secondary)
                            .scaledFont(.sm)
                            .frame(minWidth: 16 * fontSizeManager.fontSizeMultiplier)
                    } else {
                        Text("Chưa học")
                            .scaledFont(.xs)
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
.scaledFont(.xl2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(minWidth: 22 * fontSizeManager.fontSizeMultiplier)

                        Text(appearanceManager.mode.rawValue)
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .scaledFont(.xs)
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

                // Keyboard shortcuts
                Button(action: {
                    viewModel.showKeyboardShortcutsSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "keyboard")
                            .scaledFont(.xl2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 22 * fontSizeManager.fontSizeMultiplier)
                        Text("Phím tắt")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .scaledFont(.xs)
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

                // English TTS accent
                Button(action: {
                    viewModel.showSpeechAccentSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2.fill")
                            .scaledFont(.xl2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 22 * fontSizeManager.fontSizeMultiplier)
                        Text("Giọng đọc tiếng Anh")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .scaledFont(.xs)
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
                .accessibilityLabel("Giọng đọc tiếng Anh")
                .accessibilityHint("Chọn accent cho phát âm tiếng Anh (US, UK, Úc, …)")

                // Vẽ nét → Gợi ý từ
                Button(action: {
                    viewModel.showStrokeDrawSuggestSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.and.outline")
                            .scaledFont(.xl2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 22 * fontSizeManager.fontSizeMultiplier)
                        Text("Vẽ nét → Gợi ý từ")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .scaledFont(.xs)
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
                .accessibilityLabel("Vẽ nét gợi ý từ")
                .accessibilityHint("Vẽ nét chữ lên canvas, gợi ý từ theo số nét (Tiếng Trung)")

                // Backup / Restore
                Button(action: {
                    viewModel.showBackupRestoreSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "externaldrive.fill")
                            .scaledFont(.xl2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 22 * fontSizeManager.fontSizeMultiplier)
                        Text("Sao lưu / Phục hồi")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .scaledFont(.xs)
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
                .accessibilityLabel("Sao lưu và Phục hồi")
                .accessibilityHint("Mở màn sao lưu dữ liệu ra file JSON hoặc phục hồi từ file")
            }
            
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
    @Environment(\.colorScheme) private var colorScheme
    
    var filteredTopics: [Topic] {
        viewModel.filteredTopics(for: subject)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .scaledFont(.sm)
                .fontWeight(.medium)
            TextField("Tìm kiếm chủ đề...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .scaledFont(.sm)
                .focused($isSearchFocused)
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .scaledFont(.sm)
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
                            .stroke(isSearchFocused ? Color.green : Color(nsColor: .separatorColor).opacity(0.8), lineWidth: isSearchFocused ? 2 : 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }
    
    @ViewBuilder
    private var searchResultsInfo: some View {
        if !viewModel.searchText.isEmpty {
            HStack {
                Text("\(filteredTopics.count) chủ đề")
                    .font(.app(.caption))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var flashcardSearchSection: some View {
        let results = viewModel.flashcardSearchResults(for: subject)
        return Group {
            if !viewModel.searchText.isEmpty && !results.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kết quả trong flashcard")
                        .font(.app(.caption))
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                    List {
                        ForEach(Array(results.enumerated()), id: \.offset) { _, pair in
                            Button(action: {
                                viewModel.selectedTopic = pair.topic
                                viewModel.selectedFlashcard = pair.flashcard
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pair.topic.name)
                                        .scaledFont(.xs)
                                        .foregroundStyle(.secondary)
                                    Text(pair.flashcard.questionDisplayText)
                                        .scaledFont(.sm)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(maxHeight: 180)
                }
                .padding(.bottom, 8)
            }
        }
    }
    
    @ViewBuilder
    private var topicsListContent: some View {
        if filteredTopics.isEmpty {
            ContentUnavailableView {
                Label(emptyStateTitle, systemImage: emptyStateIcon)
            } description: {
                Text(emptyStateDescription)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(filteredTopics, selection: Binding(
                get: { viewModel.selectedTopic },
                set: { viewModel.setSelectedTopic($0) }
            )) { topic in
                TopicRowView(topic: topic, subject: subject, practiceCount: viewModel.topicPracticeCounts[topic.id] ?? 0, isSelected: viewModel.selectedTopic?.id == topic.id, isLight: colorScheme == .light, onDelete: { viewModel.topicToDelete = topic }, onRename: { viewModel.startRenameTopic(topic) })
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.setSelectedTopic(topic)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .tint(.green)
        }
    }

    private var emptyStateTitle: String {
        viewModel.searchText.isEmpty ? "Chưa có chủ đề nào" : "Không tìm thấy kết quả"
    }

    private var emptyStateIcon: String {
        viewModel.searchText.isEmpty ? "folder.badge.plus" : "magnifyingglass"
    }

    private var emptyStateDescription: String {
        viewModel.searchText.isEmpty ? "Nhấn \"Thêm chủ đề\" bên dưới để tạo chủ đề mới" : "Thử tìm kiếm với từ khóa khác"
    }
    
    private var addTopicBottomBar: some View {
        HStack {
            Spacer()
            Button(action: {
                viewModel.showAddTopicSheet = true
            }) {
Label("Thêm chủ đề", systemImage: "plus.circle.fill")
                        .scaledFont(.sm)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color(nsColor: .windowBackgroundColor).opacity(0), Color(nsColor: .windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)
            .allowsHitTesting(false)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            searchResultsInfo
            flashcardSearchSection
            topicsListContent
        }
        .safeAreaInset(edge: .bottom) {
            addTopicBottomBar
        }
        .navigationTitle(subject.name)
        .animation(.easeInOut(duration: 0.2), value: viewModel.searchText)
        .sheet(isPresented: $viewModel.showAddTopicSheet) {
            AddTopicSheet(viewModel: viewModel)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.topicToRename != nil },
            set: { if !$0 { viewModel.topicToRename = nil; viewModel.renameTopicName = "" } }
        )) {
            RenameTopicSheet(viewModel: viewModel)
        }
        .overlay {
            ConfirmActionOverlay(
                title: "Xóa chủ đề?",
                message: viewModel.topicToDelete.map { "Chủ đề \"\($0.name)\" và mọi flashcard, bài đọc trong đó sẽ bị xóa. Không thể hoàn tác." } ?? "",
                destructiveTitle: "Xóa",
                cancelTitle: "Huỷ",
                isPresented: Binding(
                    get: { viewModel.topicToDelete != nil },
                    set: { if !$0 { viewModel.topicToDelete = nil } }
                ),
                onConfirm: {
                    if let t = viewModel.topicToDelete {
                        viewModel.topicToDelete = nil
                        viewModel.deleteTopic(t)
                    }
                }
            )
        }
    }
}

// Topic row – content only; selection background is handled by listRowBackground
private struct TopicRowView: View {
    let topic: Topic
    let subject: Subject
    let practiceCount: Int
    let isSelected: Bool
    let isLight: Bool
    let onDelete: () -> Void
    let onRename: () -> Void

    private var isReadingSubject: Bool { subject.name == "Bài đọc" }
    private var hasPracticed: Bool { practiceCount > 0 }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.gray.opacity(isLight ? 0.2 : 0.25) : Color.gray.opacity(isLight ? 0.1 : 0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: isReadingSubject ? "doc.text.fill" : "book.fill")
                    .scaledFont(.lg)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.name)
                    .scaledFont(.sm)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Image(systemName: isReadingSubject ? "doc.richtext" : "rectangle.stack.fill")
                        .scaledFont(.xs)
                    Text(isReadingSubject ? "\(topic.readings.count) bài đọc" : "\(topic.flashcards.count) flashcards")
                        .scaledFont(.sm)
                    Text("•")
                        .scaledFont(.xs)
                        .foregroundStyle(.secondary)
                    Text(hasPracticed ? "Đã làm" : "Chưa làm")
                        .scaledFont(.xs)
                        .foregroundStyle(hasPracticed ? .green : .secondary)
                }
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .scaledFont(.xs)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .tag(topic)
        .contextMenu {
            Button(action: onRename) {
                Label("Sửa tên", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Xoá chủ đề", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Topic Sheet
struct AddTopicSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Tạo chủ đề mới")
                    .font(.app(.title2))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    viewModel.newTopicName = ""
                    viewModel.showAddTopicSheet = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.app(.title2))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }

            if let subject = viewModel.selectedSubject {
                HStack(spacing: 8) {
                    Image(systemName: subject.icon)
                        .foregroundStyle(.secondary)
                    Text(subject.name)
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            Divider()
                .background(Color(nsColor: .separatorColor))

            VStack(alignment: .leading, spacing: 8) {
                Text("Tên chủ đề")
                    .font(.app(.headline))
                    .foregroundStyle(.primary)
                TextField("Ví dụ: Sports (Thể thao)", text: $viewModel.newTopicName)
                    .textFieldStyle(.roundedBorder)
                    .font(.app(.body))
                    .focused($isFocused)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Huỷ") {
                    viewModel.newTopicName = ""
                    viewModel.showAddTopicSheet = false
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)

                Spacer()

                Button(action: {
                    viewModel.addTopic(name: viewModel.newTopicName)
                }) {
                    Text("Tạo chủ đề")
                        .fontWeight(.semibold)
                }
                .keyboardShortcut(.return)
                .disabled(viewModel.newTopicName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
        .padding(24)
        .frame(width: 400, height: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { isFocused = true }
    }
}

// MARK: - Rename Topic Sheet
struct RenameTopicSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Sửa tên chủ đề")
                    .font(.app(.title2))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    viewModel.topicToRename = nil
                    viewModel.renameTopicName = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.app(.title2))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tên chủ đề")
                    .font(.app(.headline))
                    .foregroundStyle(.primary)
                TextField("Tên chủ đề", text: $viewModel.renameTopicName)
                    .textFieldStyle(.roundedBorder)
                    .font(.app(.body))
                    .focused($isFocused)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Huỷ") {
                    viewModel.topicToRename = nil
                    viewModel.renameTopicName = ""
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)

                Spacer()
                Button(action: { viewModel.renameTopic() }) {
                    Text("Lưu")
                        .fontWeight(.semibold)
                }
                .keyboardShortcut(.return)
                .disabled(viewModel.renameTopicName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }
        }
        .padding(24)
        .frame(width: 400, height: 240)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { isFocused = true }
    }
}

// MARK: - Reading Main View
struct ReadingMainView: View {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPassage: ReadingPassage?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    viewModel.selectedTopic = nil
                    viewModel.selectedFlashcard = nil
                }) {
                    Label("Quay lại", systemImage: "chevron.left")
                        .scaledFont(.sm)
                }
                .buttonStyle(.plain)

                Spacer()
                Text(topic.name)
                    .scaledFont(.sm)
                    .fontWeight(.semibold)
                Spacer()

                Button(action: {
                    viewModel.newReadingTitle = ""
                    viewModel.newReadingContent = ""
                    viewModel.showAddReadingSheet = true
                }) {
                    Label("Tạo bài đọc", systemImage: "plus.circle.fill")
                        .scaledFont(.sm)
                        .fontWeight(.medium)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            if topic.readings.isEmpty {
                ContentUnavailableView {
                    Label("Chưa có bài đọc", systemImage: "doc.richtext")
                } description: {
                    Text("Nhấn \"Tạo bài đọc\" để thêm bài đọc mới")
                        .scaledFont(.sm)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    // Reading list
                    List(topic.readings, selection: $selectedPassage) { passage in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(passage.title)
                                .scaledFont(.sm)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            Text(passage.content)
                                .scaledFont(.xs)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .tag(passage)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                viewModel.passageToDelete = passage
                            }) {
                                Label("Xoá bài đọc", systemImage: "trash")
                            }
                        }
                    }
                    .frame(minWidth: 260, idealWidth: 320, maxWidth: 400)
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    // Reading content
                    if let passage = selectedPassage {
                        ReadingDetailView(passage: passage, topicName: topic.name)
                    } else {
                        ContentUnavailableView(
                            "Chọn một bài đọc",
                            systemImage: "doc.text.fill",
                            description: Text("Chọn bài đọc từ danh sách bên trái")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .onAppear {
                    if selectedPassage == nil, let first = topic.readings.first {
                        selectedPassage = first
                    }
                }
                .onChange(of: topic.readings.count) { _, _ in
                    if selectedPassage == nil, let first = topic.readings.first {
                        selectedPassage = first
                    } else if let sel = selectedPassage, !topic.readings.contains(where: { $0.id == sel.id }) {
                        selectedPassage = topic.readings.first
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddReadingSheet) {
            AddReadingSheet(viewModel: viewModel, topic: topic)
        }
        .overlay {
            ConfirmActionOverlay(
                title: "Xóa bài đọc?",
                message: viewModel.passageToDelete.map { "Bài đọc \"\($0.title)\" sẽ bị xóa. Không thể hoàn tác." } ?? "",
                destructiveTitle: "Xóa",
                cancelTitle: "Huỷ",
                isPresented: Binding(
                    get: { viewModel.passageToDelete != nil },
                    set: { if !$0 { viewModel.passageToDelete = nil } }
                ),
                onConfirm: {
                    if let p = viewModel.passageToDelete {
                        viewModel.passageToDelete = nil
                        viewModel.deleteReadingPassage(p)
                        if selectedPassage?.id == p.id {
                            selectedPassage = topic.readings.first(where: { $0.id != p.id })
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Reading Detail View
struct ReadingDetailView: View {
    let passage: ReadingPassage
    let topicName: String
    @ObservedObject private var speechManager = SpeechManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Toolbar: Đọc + Ngắt đọc + Sao chép
                HStack {
                    Text(topicName)
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: {
                        speechManager.speak(text: passage.content)
                    }) {
                        Label("Đọc", systemImage: "speaker.wave.2.fill")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .disabled(passage.content.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(action: { speechManager.stop() }) {
                        Label("Ngắt đọc", systemImage: "stop.fill")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!speechManager.isSpeaking)
                    Button(action: copyFullContent) {
                        Label("Sao chép", systemImage: "doc.on.doc")
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                }

                Text(passage.title)
                    .scaledFont(.xl2)
                    .fontWeight(.bold)

                Divider()

                SmartCopyDefineText(text: passage.content, flashcards: nil)
                    .scaledFont(.xl3)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func copyFullContent() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(passage.content, forType: .string)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
    }
}

// MARK: - Add Reading Sheet
struct AddReadingSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @FocusState private var focusedField: Field?

    enum Field {
        case title, content
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Tạo bài đọc")
                    .scaledFont(.xl2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    viewModel.newReadingTitle = ""
                    viewModel.newReadingContent = ""
                    viewModel.showAddReadingSheet = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .scaledFont(.xl2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .scaledFont(.sm)
                    .foregroundStyle(.secondary)
                Text(topic.name)
                    .scaledFont(.sm)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Tiêu đề")
                    .scaledFont(.sm)
                    .fontWeight(.semibold)
                TextField("Nhập tiêu đề bài đọc", text: $viewModel.newReadingTitle)
                    .textFieldStyle(.roundedBorder)
                    .scaledFont(.sm)
                    .focused($focusedField, equals: .title)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Nội dung")
                    .scaledFont(.sm)
                    .fontWeight(.semibold)
                TextEditor(text: $viewModel.newReadingContent)
                    .scaledFont(.sm)
                    .frame(minHeight: 200, maxHeight: 360)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .content)
            }

            Spacer(minLength: 0)

            HStack {
                Button("Huỷ") {
                    viewModel.newReadingTitle = ""
                    viewModel.newReadingContent = ""
                    viewModel.showAddReadingSheet = false
                }
                .scaledFont(.sm)
                .keyboardShortcut(.escape)

                Spacer()

                Button(action: {
                    viewModel.addReadingPassage(topicId: topic.id, title: viewModel.newReadingTitle, content: viewModel.newReadingContent)
                }) {
                    Text("Lưu bài đọc")
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                }
                .keyboardShortcut(.return)
                .disabled(viewModel.newReadingTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 500, height: 520)
        .onAppear { focusedField = .title }
    }
}

// MARK: - Edit Flashcard Sheet
struct EditFlashcardSheet: View {
    let flashcard: Flashcard
    let topic: Topic
    @ObservedObject var viewModel: ContentViewModel
    let onDismiss: () -> Void

    @State private var editQuestion: String = ""
    @State private var editAnswer: String = ""
    @State private var editHint: String = ""
    @State private var editNotes: String = ""
    @State private var editRadical: String = ""
    @FocusState private var focusedField: Field?

    private var isChineseSubject: Bool { viewModel.selectedSubject?.name == "Tiếng Trung" }

    enum Field {
        case question, answer, hint, notes, radical
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Sửa từ vựng")
                        .scaledFont(.xl2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .scaledFont(.xl2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Từ gốc")
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    TextField("Từ gốc", text: $editQuestion)
                        .textFieldStyle(.roundedBorder)
                        .scaledFont(.sm)
                        .focused($focusedField, equals: .question)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nghĩa")
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    TextField("Nghĩa", text: $editAnswer)
                        .textFieldStyle(.roundedBorder)
                        .scaledFont(.sm)
                        .focused($focusedField, equals: .answer)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Gợi ý (không bắt buộc)")
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    TextField("Gợi ý", text: $editHint)
                        .textFieldStyle(.roundedBorder)
                        .scaledFont(.sm)
                        .focused($focusedField, equals: .hint)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Ghi chú (notes)")
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    TextField("Ghi chú", text: $editNotes)
                        .textFieldStyle(.roundedBorder)
                        .scaledFont(.sm)
                        .focused($focusedField, equals: .notes)
                }

                if isChineseSubject {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bộ thủ (部首)")
                            .scaledFont(.sm)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        TextField("Bộ thủ", text: $editRadical)
                            .textFieldStyle(.roundedBorder)
                            .scaledFont(.sm)
                            .focused($focusedField, equals: .radical)
                    }
                }

                HStack {
                    Button("Huỷ") {
                        onDismiss()
                    }
                    .scaledFont(.sm)
                    .keyboardShortcut(.escape)

                    Spacer()

                    Button(action: save) {
                        Text("Lưu")
                            .scaledFont(.sm)
                            .fontWeight(.semibold)
                    }
                    .keyboardShortcut(.return)
                    .disabled(editQuestion.trimmingCharacters(in: .whitespaces).isEmpty || editAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(24)
        }
        .frame(width: 440, height: 520)
        .onAppear {
            editQuestion = flashcard.question
            editAnswer = flashcard.answer
            editHint = flashcard.hint ?? ""
            editNotes = flashcard.notes ?? ""
            editRadical = flashcard.radical ?? ""
            focusedField = .question
        }
    }

    private func save() {
        viewModel.updateFlashcard(
            id: flashcard.id,
            question: editQuestion,
            answer: editAnswer,
            hint: editHint.isEmpty ? nil : editHint,
            notes: editNotes.isEmpty ? nil : editNotes,
            radical: isChineseSubject ? (editRadical.isEmpty ? nil : editRadical) : nil
        )
        onDismiss()
    }
}

// Hint box: tap box to expand/collapse, no disclosure button. Shows từ gốc + bộ thủ + gợi ý + ghi chú when expanded.
struct HintExpandableBox: View {
    @Binding var expanded: Bool
    let fromGoc: String
    let hint: String
    let flashcards: [Flashcard]
    var radicalText: String? = nil
    var notesText: String? = nil
    var compact: Bool = false
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isLight = colorScheme == .light
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
        }) {
            VStack(alignment: .leading, spacing: expanded ? 12 : 0) {
                if expanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Từ gốc")
                            .font(.app(.subheadline))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        SmartCopyDefineText(text: fromGoc, flashcards: flashcards)
                            .font(.app(.callout))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environmentObject(fontSizeManager)
                        if let radical = radicalText, !radical.isEmpty {
                            Text("Bộ thủ")
                                .font(.app(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(radical)
                                .font(.app(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if !hint.isEmpty {
                            Text("Gợi ý")
                                .font(.app(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                            SmartCopyDefineText(text: hint, flashcards: flashcards)
                                .font(.app(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environmentObject(fontSizeManager)
                        }
                        if let notes = notesText, !notes.isEmpty {
                            Text("Ghi chú")
                                .font(.app(.subheadline))
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            SmartCopyDefineText(text: notes, flashcards: flashcards)
                                .font(.app(.callout))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environmentObject(fontSizeManager)
                        }
                    }
                    .padding()
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.green)
                        Text("Gợi ý")
                            .font(.app(.headline))
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(isLight ? 0.1 : 0.15))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }
}

// Flashcard Detail View
struct FlashcardDetailView: View {
    let flashcard: Flashcard
    let topic: Topic
    let subjectName: String
    var radicalText: String? = nil
    var onEdit: (() -> Void)? = nil
    let onAnswered: ((Bool) -> Void)?  // Callback for practice mode
    var onContinueToNext: (() -> Void)? = nil  // Callback to advance to next card (practice mode)

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var isFlipped = false
    @State private var selectedAnswer: String? = nil
    @State private var showResult = false
    @State private var nextReviewDateString: String? = nil
    @State private var hintExpanded = false

    private static var nextReviewFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM"
        f.locale = Locale(identifier: "vi_VN")
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .font(.app(.title))
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subjectName)
                            .font(.app(.headline))
                            .foregroundStyle(.secondary)
                        Text(topic.name)
                            .font(.app(.title2))
                            .fontWeight(.semibold)
                        if let dateStr = nextReviewDateString {
                            Text("Ôn lại vào: \(dateStr)")
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()

                    if onEdit != nil {
                        Button(action: { onEdit?() }) {
                            Label("Sửa", systemImage: "pencil")
                                .scaledFont(.sm)
                        }
                        .buttonStyle(.bordered)
                    }
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
        .onAppear {
            if let progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id), progress.totalReviews > 0 {
                nextReviewDateString = Self.nextReviewFormatter.string(from: progress.nextReviewDate)
            } else {
                nextReviewDateString = nil
            }
        }
    }
    
    // Traditional flip card view
    private var traditionalFlashcardView: some View {
        let isLight = colorScheme == .light
        return VStack(spacing: 20) {
            // Card
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isLight ? Color.appCardBackground(isLight: true) : Color(nsColor: .textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(isLight ? 0.5 : 0.7), lineWidth: 2)
                    )
                
                VStack(spacing: 16) {
                    HStack {
                        Text(isFlipped ? "Đáp án" : "Câu hỏi")
                            .font(.app(.body))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        SpeakButton(text: isFlipped ? flashcard.answer : flashcard.question, fontSize: 18)
                    }

                    SmartCopyDefineText(text: isFlipped ? flashcard.answer : flashcard.questionDisplayText, flashcards: topic.flashcards)
                        .scaledFont(.xl3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .environmentObject(fontSizeManager)
                }
                .padding()
            }
            .frame(minHeight: 250)
            .padding()
            
            // Hint box: tap to expand/collapse (từ gốc + bộ thủ + gợi ý + ghi chú). Hiện khi có hint, bộ thủ hoặc ghi chú.
            if (flashcard.hint != nil && !(flashcard.hint?.isEmpty ?? true)) || (radicalText != nil && !(radicalText?.isEmpty ?? true)) || (flashcard.notes != nil && !(flashcard.notes?.isEmpty ?? true)) {
                HintExpandableBox(expanded: $hintExpanded, fromGoc: flashcard.question, hint: flashcard.hint ?? "", flashcards: topic.flashcards, radicalText: radicalText, notesText: flashcard.notes)
            }
            
            // Flip button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isFlipped.toggle()
                }
            }) {
                Label(isFlipped ? "Xem câu hỏi" : "Xem đáp án", systemImage: "arrow.triangle.2.circlepath")
                    .font(.app(.headline))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
            .padding(.horizontal)
            .accessibilityHint(isFlipped ? "Lật thẻ để xem lại câu hỏi" : "Lật thẻ để xem đáp án")

            if isFlipped, let onNext = onContinueToNext {
                Button(action: onNext) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .scaledFont(.xl2)
                        Text("Tiếp tục")
                            .scaledFont(.lg)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .cursor(.pointingHand)
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
    
    // Multiple choice question view
    private var multipleChoiceView: some View {
        VStack(spacing: 25) {
            // Question card
            VStack(spacing: 16) {
                HStack {
                    Text("Câu hỏi")
                        .scaledFont(.xl)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    SpeakButton(text: flashcard.question, fontSize: 24)
                }

                SmartCopyDefineText(text: flashcard.questionDisplayText, flashcards: topic.flashcards)
                    .scaledFont(.display)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                    .environmentObject(fontSizeManager)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(colorScheme == .light ? Color.appCardBackground(isLight: true) : Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appBorder(isLight: colorScheme == .light), lineWidth: 1.5)
            )
            .cornerRadius(16)
            
            // Hint box: tap to expand/collapse (từ gốc + bộ thủ + gợi ý + ghi chú). Hiện khi có hint, bộ thủ hoặc ghi chú.
            if ((flashcard.hint != nil && !(flashcard.hint?.isEmpty ?? true)) || (radicalText != nil && !(radicalText?.isEmpty ?? true)) || (flashcard.notes != nil && !(flashcard.notes?.isEmpty ?? true))) && !showResult {
                HintExpandableBox(expanded: $hintExpanded, fromGoc: flashcard.question, hint: flashcard.hint ?? "", flashcards: topic.flashcards, radicalText: radicalText, notesText: flashcard.notes, compact: true)
            }
            
            // Options
            VStack(spacing: 16) {
                ForEach(flashcard.options ?? [], id: \.self) { option in
                    multipleChoiceButton(option: option)
                }
            }
            
            // Result feedback
            if showResult {
                resultView
                if onContinueToNext != nil {
                    Button(action: { onContinueToNext?() }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .scaledFont(.xl2)
                            Text("Tiếp tục")
                                .scaledFont(.lg)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .cursor(.pointingHand)
                    .padding(.top, 8)
                }
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
                    return Color.green.opacity(isLight ? 0.1 : 0.15)
                }
                return Color(nsColor: .controlBackgroundColor)
            } else {
                if isCorrect {
                    return Color.green.opacity(isLight ? 0.18 : 0.2)
                } else if isSelected && !isCorrect {
                    return Color.red.opacity(isLight ? 0.18 : 0.2)
                }
                return Color(nsColor: .controlBackgroundColor)
            }
        }

        var borderColor: Color {
            if !showResult {
                return isSelected ? .green : Color.appBorder(isLight: isLight)
            } else {
                if isCorrect {
                    return .green
                } else if isSelected && !isCorrect {
                    return .red
                }
                return Color.appBorder(isLight: isLight)
            }
        }

        var shadowColor: Color {
            if !showResult {
                return isSelected
                    ? Color.green.opacity(isLight ? 0.2 : 0.4)
                    : Color.appBorder(isLight: isLight).opacity(0.8)
            } else {
                if isCorrect {
                    return Color.green.opacity(isLight ? 0.35 : 0.5)
                } else if isSelected && !isCorrect {
                    return Color.red.opacity(isLight ? 0.35 : 0.5)
                }
                return Color.appBorder(isLight: isLight).opacity(0.6)
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
                    .scaledFont(.base)
                    .fontWeight(.regular)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showResult {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .scaledFont(.lg)
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce.up, value: showResult)
                            .shadow(color: .green.opacity(0.5), radius: 4)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .scaledFont(.lg)
                            .foregroundStyle(.red)
                            .symbolEffect(.bounce.down, value: showResult)
                            .shadow(color: .red.opacity(0.5), radius: 4)
                    }
                }
            }
            .padding(16)
            .background(
                ZStack {
                    // Bottom shadow layer (depth effect)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(shadowColor)
                        .offset(y: isPressed ? 2 : 4)
                    
                    // Main button layer
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(borderColor, lineWidth: 2)
                        )
                }
            )
            .offset(y: isPressed ? 2 : 0)
        }
        .buttonStyle(CoreButtonStyle(isPressed: $isPressed, isDisabled: showResult))
        .cursor(.pointingHand)
        .keyboardShortcut(shortcutKey, modifiers: [])
        // Use opacity and border to avoid overflow
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
        let isCorrect = selectedAnswer == flashcard.correctAnswer
        let accent = isCorrect ? Color.green : Color.red
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(accent)
                    .symbolEffect(.bounce.up, value: showResult)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isCorrect ? "Chính xác!" : "Chưa đúng")
                        .scaledFont(.xl)
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)
                    SmartCopyDefineText(text: flashcard.answer, flashcards: topic.flashcards)
                        .scaledFont(.base)
                        .foregroundStyle(.secondary)
                        .environmentObject(fontSizeManager)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 14)
            
            if (flashcard.hint != nil && !(flashcard.hint?.isEmpty ?? true)) || (radicalText != nil && !(radicalText?.isEmpty ?? true)) || (flashcard.notes != nil && !(flashcard.notes?.isEmpty ?? true)) {
                VStack(alignment: .leading, spacing: 8) {
                    resultDetailRow(label: "Từ gốc", value: flashcard.question)
                    if let radical = radicalText, !radical.isEmpty {
                        resultDetailRow(label: "Bộ thủ", value: radical)
                    }
                    if let hint = flashcard.hint, !hint.isEmpty {
                        resultDetailRow(label: "Gợi ý", value: hint)
                    }
                    if let notes = flashcard.notes, !notes.isEmpty {
                        resultDetailRow(label: "Ghi chú", value: notes)
                    }
                }
                .padding(.top, 12)
                .padding(.leading, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .light ? Color(.controlBackgroundColor).opacity(0.6) : Color(.windowBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accent.opacity(colorScheme == .light ? 0.25 : 0.4), lineWidth: 1)
                )
        )
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showResult)
    }
    
    private func resultDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .scaledFont(.xs)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
            Text(value)
                .scaledFont(.base)
                .foregroundStyle(.secondary)
        }
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

// MARK: - Undo Banner
private struct UndoBannerView: View {
    let onUndo: () -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash.slash")
                .scaledFont(.base)
                .foregroundStyle(.secondary)
            Text("Đã xóa.")
                .scaledFont(.sm)
                .fontWeight(.medium)
            Spacer()
            Button("Hoàn tác") {
                onUndo()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .scaledFont(.sm)
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .scaledFont(.lg)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 8, y: 4)
        )
        .frame(maxWidth: 420)
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @ObservedObject private var speechManager = SpeechManager.shared
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
                // Delay slightly to prevent jerky animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    updateColumnVisibility(animated: true)
                }
            }
        }
        .onChange(of: columnVisibility) { oldValue, newValue in
            // Don't auto-switch when user toggles columns in special mode
            // Let user manually control column visibility
        }
        .alert("Lỗi", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let msg = viewModel.errorMessage {
                Text(msg)
            }
        }
        .alert("Sao lưu", isPresented: Binding(
            get: { viewModel.backupSaveResultMessage != nil },
            set: { if !$0 { viewModel.backupSaveResultMessage = nil } }
        )) {
            Button("OK") { viewModel.backupSaveResultMessage = nil }
        } message: {
            if let msg = viewModel.backupSaveResultMessage {
                Text(msg)
            }
        }
        .alert("Không thể phát âm", isPresented: Binding(
            get: { speechManager.ttsUnavailableMessage != nil },
            set: { if !$0 { speechManager.ttsUnavailableMessage = nil } }
        )) {
            Button("Mở Cài đặt") {
                speechManager.openSpeechSettings()
                speechManager.ttsUnavailableMessage = nil
            }
            Button("Đóng", role: .cancel) {
                speechManager.ttsUnavailableMessage = nil
            }
        } message: {
            if let msg = speechManager.ttsUnavailableMessage {
                Text(msg)
            }
        }
        .overlay(alignment: .top) {
            if viewModel.undoableItem != nil {
                UndoBannerView(
                    onUndo: { viewModel.restoreUndo() },
                    onDismiss: { viewModel.dismissUndoBanner() }
                )
                .padding(.top, 12)
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: viewModel.undoableItem != nil)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $viewModel.showKeyboardShortcutsSheet) {
            KeyboardShortcutsView()
        }
        .sheet(isPresented: $viewModel.showBackupRestoreSheet) {
            BackupRestoreView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showStrokeDrawSuggestSheet) {
            StrokeDrawSuggestView(viewModel: viewModel, onDismiss: { viewModel.showStrokeDrawSuggestSheet = false })
        }
        .sheet(isPresented: $viewModel.showSpeechAccentSheet) {
            SpeechAccentSheetView(onDismiss: { viewModel.showSpeechAccentSheet = false })
        }
        .onReceive(NotificationCenter.default.publisher(for: .openKeyboardShortcuts)) { _ in
            viewModel.showKeyboardShortcutsSheet = true
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
        } else if viewModel.isLoading && viewModel.subjects.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Đang tải...")
                    .scaledFont(.sm)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationSplitViewColumnWidth(min: 420, ideal: 320, max: 420)
        } else if let subject = viewModel.selectedSubject {
            TopicsListView(viewModel: viewModel, subject: subject)
                .navigationSplitViewColumnWidth(min: 420, ideal: 320, max: 420)
        } else {
            ContentUnavailableView(
                "Chọn môn học",
                systemImage: "book.fill",
                description: Text("Chọn một môn học từ sidebar")
            )
            .navigationSplitViewColumnWidth(min: 420, ideal: 320, max: 420)
        }
    }
    
    @ViewBuilder
    private var detailColumn: some View {
        Group {
            switch viewModel.detailRoute {
            case .review:
                ReviewModeView(viewModel: viewModel)
                    .id("review-mode")
            case .reviewMistakes:
                ReviewMistakesView(viewModel: viewModel)
                    .id("review-mistakes")
            case .statistics:
                StatisticsDashboardView(viewModel: viewModel)
                    .id("statistics")
            case .reading(let topic):
                ReadingMainView(viewModel: viewModel, topic: topic)
                    .id("reading-\(topic.id)")
            case .learning(let topic):
                if let topic = topic {
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

// MARK: - Speech Accent Sheet
struct SpeechAccentSheetView: View {
    var onDismiss: () -> Void
    @ObservedObject private var speechManager = SpeechManager.shared
    @State private var selectedAccent: EnglishAccent = .gb

    var body: some View {
        VStack(spacing: 24) {
            Text("Giọng đọc tiếng Anh")
                .font(.app(.title2))
                .fontWeight(.semibold)
            Text("Chọn accent cho phát âm (TTS) khi nội dung là tiếng Anh.")
                .font(.app(.subheadline))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Accent", selection: $selectedAccent) {
                ForEach(EnglishAccent.allCases) { accent in
                    Text(accent.displayName).tag(accent)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            .onChange(of: selectedAccent) { _, newValue in
                speechManager.preferredEnglishAccent = newValue
            }

            HStack {
                Spacer()
                Button("Xong", action: onDismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(minWidth: 320)
        .onAppear {
            selectedAccent = speechManager.preferredEnglishAccent
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppearanceManager())
            .environmentObject(FontSizeManager())
            .frame(width: 1000, height: 600)
    }
}
