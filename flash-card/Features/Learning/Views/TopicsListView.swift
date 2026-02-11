//
//  TopicsListView.swift
//  flash-card
//
//  Danh sách chủ đề (topics) của môn đã chọn, tìm kiếm, thêm/sửa/xóa chủ đề.
//

import SwiftUI
import UniformTypeIdentifiers

struct TopicsListView: View {
    @ObservedObject var viewModel: ContentViewModel
    let subject: Subject
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var reorderSourceTopicId: Int? = nil

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
                .lineLimit(1)
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
                .cursor(.pointingHand)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSearchFocused ? Color.blue : Color.appBorder(isLight: colorScheme == .light), lineWidth: isSearchFocused ? 2 : 1)
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
                        .lineLimit(1)
                        .truncationMode(.tail)
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
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Text(pair.flashcard.questionDisplayText)
                                        .scaledFont(.sm)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .cursor(.pointingHand)
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
            List(selection: Binding(
                get: { viewModel.selectedTopic },
                set: { newTopic in
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) {
                        viewModel.setSelectedTopic(newTopic)
                    }
                }
            )) {
                ForEach(Array(filteredTopics.enumerated()), id: \.element.id) { index, topic in
                    TopicRowView(
                        topic: topic,
                        subject: subject,
                        practiceCount: viewModel.topicPracticeCounts[topic.id] ?? 0,
                        isSelected: viewModel.selectedTopic?.id == topic.id,
                        isLight: colorScheme == .light,
                        onDelete: { viewModel.topicToDelete = topic },
                        onRename: { viewModel.startRenameTopic(topic) },
                        showReorderHandle: viewModel.searchText.isEmpty,
                        rowIndex: index,
                        reorderSourceTopicId: $reorderSourceTopicId,
                        onReorderDrop: { draggedTopicId, dropIndex in
                            guard let srcIndex = filteredTopics.firstIndex(where: { $0.id == draggedTopicId }), srcIndex != dropIndex else { return }
                            viewModel.reorderTopics(subject: subject, from: IndexSet(integer: srcIndex), to: dropIndex)
                            reorderSourceTopicId = nil
                        }
                    )
                    .listRowBackground(viewModel.selectedTopic?.id == topic.id ? Color.gray.opacity(colorScheme == .light ? 0.2 : 0.25) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        var t = Transaction()
                        t.disablesAnimations = true
                        withTransaction(t) {
                            viewModel.setSelectedTopic(topic)
                        }
                    }
                }
                .onMove { source, dest in
                    if viewModel.searchText.isEmpty {
                        viewModel.reorderTopics(subject: subject, from: source, to: dest)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
                    .lineLimit(1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.appBackgroundPage(isLight: colorScheme == .light).opacity(0), Color.appBackgroundPage(isLight: colorScheme == .light)],
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
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
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
struct TopicRowView: View {
    let topic: Topic
    let subject: Subject
    let practiceCount: Int
    let isSelected: Bool
    let isLight: Bool
    let onDelete: () -> Void
    let onRename: () -> Void
    var showReorderHandle: Bool = false
    var rowIndex: Int = 0
    @Binding var reorderSourceTopicId: Int?
    var onReorderDrop: ((Int, Int) -> Void)? = nil

    private var isReadingSubject: Bool { subject.name == "Bài đọc" }
    private var hasPracticed: Bool { practiceCount > 0 }
    private var isPracticedALot: Bool { practiceCount >= 5 }

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
                HStack(spacing: 6) {
                    Text(topic.name)
                        .scaledFont(.sm)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if isPracticedALot {
                        Text("\(practiceCount)")
                            .scaledFont(.xs)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green))
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: isReadingSubject ? "doc.richtext" : "rectangle.stack.fill")
                        .scaledFont(.xs)
                        .foregroundStyle(.secondary)
                    Text(isReadingSubject ? "\(topic.readings.count) bài đọc" : "\(topic.flashcards.count) flashcards")
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("•")
                        .scaledFont(.xs)
                        .foregroundStyle(.secondary)
                    Text(hasPracticed ? "Đã làm" : "Chưa làm")
                        .scaledFont(.sm)
                        .foregroundStyle(hasPracticed ? .green : .secondary)
                        .lineLimit(1)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .scaledFont(.xs)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .clipped()
        .contentShape(Rectangle())
        .tag(topic)
        .onDrop(of: showReorderHandle ? [.plainText] : [], isTargeted: nil) { providers in
            guard showReorderHandle, let onReorderDrop = onReorderDrop, let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { obj, _ in
                DispatchQueue.main.async {
                    guard let str = (obj as? String)?.trimmingCharacters(in: .whitespaces), !str.isEmpty, let draggedId = Int(str) else { return }
                    onReorderDrop(draggedId, rowIndex)
                }
            }
            return true
        }
        .contextMenu {
            Button(action: onRename) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Sửa tên")
                }
                .foregroundStyle(.primary)
            }
            Button(role: .destructive, action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                    Text("Xoá chủ đề")
                }
            }
        }
    }
}
