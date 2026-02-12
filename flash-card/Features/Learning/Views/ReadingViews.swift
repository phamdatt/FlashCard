//
//  ReadingViews.swift
//  flash-card
//
//  Reading: danh sách bài đọc, chi tiết bài đọc, tạo bài đọc.
//

import SwiftUI
import AppKit

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
                .cursor(.pointingHand)

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
                .cursor(.pointingHand)
                .foregroundStyle(.secondary)
            }
            .padding()

            ThemeDivider()

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
                    List(topic.readings, selection: $selectedPassage) { passage in
                        ReadingPassageRow(topicName: topic.name, passage: passage, isSelected: selectedPassage?.id == passage.id)
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

// MARK: - Reading passage list row (card + level tag)
struct ReadingPassageRow: View {
    let topicName: String
    let passage: ReadingPassage
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var levelTag: (text: String, color: Color)? {
        let lower = topicName.lowercased()
        if lower.contains("hsk1") || lower.contains("hsk 1") { return ("HSK 1", Color(red: 0.2, green: 0.7, blue: 0.45)) }
        if lower.contains("hsk2") || lower.contains("hsk 2") { return ("HSK 2", Color(red: 0.25, green: 0.5, blue: 1.0)) }
        if lower.contains("hsk3") || lower.contains("hsk 3") { return ("HSK 3", Color(red: 0.95, green: 0.6, blue: 0.2)) }
        if lower.contains("hsk4") || lower.contains("hsk 4") { return ("HSK 4", Color(red: 0.9, green: 0.4, blue: 0.5)) }
        if lower.contains("hsk5") || lower.contains("hsk 5") { return ("HSK 5", Color(red: 0.6, green: 0.35, blue: 0.85)) }
        if lower.contains("hsk6") || lower.contains("hsk 6") { return ("HSK 6", Color(red: 0.5, green: 0.3, blue: 0.6)) }
        if lower.contains("hsk") { return ("HSK", Color.gray) }
        return nil
    }

    private var rowBackground: Color {
        if isSelected {
            return colorScheme == .dark ? Color.white.opacity(0.12) : Color.accentColor.opacity(0.12)
        }
        return colorScheme == .dark ? Color.white.opacity(0.04) : Color.primary.opacity(0.04)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let tag = levelTag {
                Text(tag.text)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(tag.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(tag.color.opacity(0.2)))
            }
            Text(passage.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(2)
                .foregroundStyle(.primary)
            Text(passage.content)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(rowBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? (colorScheme == .dark ? Color.white.opacity(0.2) : Color.accentColor.opacity(0.5)) : Color.clear, lineWidth: 1.5)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

private let readingContentMaxWidth: CGFloat = 720
private let readingHorizontalPadding: CGFloat = 40

// MARK: - Reading Detail View
struct ReadingDetailView: View {
    let passage: ReadingPassage
    let topicName: String
    @ObservedObject private var speechManager = SpeechManager.shared
    @Environment(\.colorScheme) private var colorScheme

    private var readingBackground: Color {
        Color.appBackgroundText(isLight: colorScheme == .light)
    }

    private var readingTitleColor: Color {
        colorScheme == .dark ? Color(white: 0.95) : Color.primary
    }

    private var readingBodyColor: Color {
        colorScheme == .dark ? Color(white: 0.88) : Color.primary
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Text(topicName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 16)
                    Button(action: {
                        speechManager.speak(text: passage.content)
                    }) {
                        Label("Đọc", systemImage: "speaker.wave.2.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .buttonStyle(.bordered)
                    .cursor(.pointingHand)
                    .controlSize(.regular)
                    .disabled(passage.content.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(action: { speechManager.stop() }) {
                        Label("Ngắt đọc", systemImage: "stop.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .buttonStyle(.bordered)
                    .cursor(.pointingHand)
                    .controlSize(.regular)
                    .disabled(!speechManager.isSpeaking)
                    Button(action: copyFullContent) {
                        Label("Sao chép", systemImage: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .buttonStyle(.bordered)
                    .cursor(.pointingHand)
                    .controlSize(.regular)
                }
                .padding(.bottom, 20)

                Text(passage.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(readingTitleColor)
                    .lineSpacing(4)
                    .padding(.bottom, 16)

                ThemeDivider()
                    .padding(.bottom, 24)

                SmartCopyDefineText(
                    text: passage.content,
                    flashcards: nil,
                    defineTextFont: .system(size: 19, weight: .regular, design: .rounded),
                    defineTextColor: readingBodyColor
                )
                    .frame(maxWidth: .infinity, minHeight: 400, alignment: .leading)
            }
            .frame(maxWidth: readingContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(24)
            .padding(.horizontal, readingHorizontalPadding)
        }
        .scrollIndicators(.hidden, axes: .horizontal)
        .background(readingBackground)
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
    @Environment(\.colorScheme) private var colorScheme

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
                .cursor(.pointingHand)
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

            ThemeDivider()

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
                    .background(Color.appBackgroundText(isLight: colorScheme == .light))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appBorder(isLight: colorScheme == .light), lineWidth: 1)
                    )
                    .focused($focusedField, equals: .content)
            }

            Spacer(minLength: 0)

            HStack {
                Button(action: {
                    viewModel.newReadingTitle = ""
                    viewModel.newReadingContent = ""
                    viewModel.showAddReadingSheet = false
                }) {
                    Text("Huỷ")
                        .scaledFont(.sm)
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
                    viewModel.addReadingPassage(topicId: topic.id, title: viewModel.newReadingTitle, content: viewModel.newReadingContent)
                }) {
                    Text("Lưu bài đọc")
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .keyboardShortcut(.return)
                .disabled(viewModel.newReadingTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .cursor(.pointingHand)
                .tint(.accentColor)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 500, height: 520)
        .onAppear { focusedField = .title }
    }
}
