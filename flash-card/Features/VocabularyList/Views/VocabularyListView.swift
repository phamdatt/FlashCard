//
//  VocabularyListView.swift
//  flash-card
//
//  Danh sách từ vựng: list bên trái + chi tiết / empty state bên phải.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Sort options for vocabulary list
enum VocabularySortOption: String, CaseIterable {
    case orderInDB = "Thứ tự trong DB"
    case wordAZ = "Từ gốc A–Z"
    case meaningAZ = "Nghĩa A–Z"
    case learnedFirst = "Đã học trước"
    case mistakeFirst = "Từ sai trước"
}

// Filter options for vocabulary list
enum VocabularyFilterOption: String, CaseIterable {
    case all = "Tất cả"
    case learnedOnly = "Chỉ đã học"
    case unlearnedOnly = "Chỉ chưa học"
    case mistakesOnly = "Chỉ từ sai"
}

struct VocabularyListView: View {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @Binding var showEditFlashcardSheet: Bool
    @Binding var showDeleteMultipleFlashcardsConfirmation: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var sortOption: VocabularySortOption = .orderInDB
    @State private var filterOption: VocabularyFilterOption = .all
    /// Index trong displayedFlashcards của item được bấm lần trước (không giữ Shift) — dùng cho chọn theo vùng Shift+click.
    @State private var selectionAnchorIndex: Int? = nil
    @State private var isExportingCSV = false
    /// Khi set: mở sheet rồi gắn NSSavePanel vào cửa sổ sheet để user chọn nơi lưu.
    @State private var pendingCSVExport: (filename: String, data: Data)? = nil
    /// Id các thẻ đến hạn ôn (hiển thị icon "Cần ôn"); cập nhật onAppear / khi topic đổi.
    @State private var dueFlashcardIds: Set<Int> = []

    private var isLight: Bool { colorScheme == .light }

    /// Filtered and sorted list for display (uses topic.flashcards + progress/mistake from DB).
    private var displayedFlashcards: [Flashcard] {
        let learnedIds = Set(DatabaseManager.shared.getLearnedFlashcardIds())
        let mistakeIds = Set(DatabaseManager.shared.getMistakeFlashcards(days: 30))
        var list = topic.flashcards
        switch filterOption {
        case .all: break
        case .learnedOnly: list = list.filter { learnedIds.contains($0.id) }
        case .unlearnedOnly: list = list.filter { !learnedIds.contains($0.id) }
        case .mistakesOnly: list = list.filter { mistakeIds.contains($0.id) }
        }
        switch sortOption {
        case .orderInDB: break
        case .wordAZ: list.sort { $0.questionDisplayText.localizedStandardCompare($1.questionDisplayText) == .orderedAscending }
        case .meaningAZ: list.sort { $0.answer.localizedStandardCompare($1.answer) == .orderedAscending }
        case .learnedFirst: list.sort { learnedIds.contains($0.id) && !learnedIds.contains($1.id) }
        case .mistakeFirst: list.sort { mistakeIds.contains($0.id) && !mistakeIds.contains($1.id) }
        }
        return list
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                vocabularySortFilterBar
                List(displayedFlashcards) { flashcard in
                vocabularyRow(flashcard: flashcard)
                    .contentShape(Rectangle())
                    .listRowBackground(
                        viewModel.selectedFlashcardIds.contains(flashcard.id)
                        ? Color.gray.opacity(isLight ? 0.2 : 0.25)
                        : Color.clear
                    )
                    .onTapGesture {
                        let shiftPressed = NSEvent.modifierFlags.contains(.shift)
                        guard let clickedIndex = displayedFlashcards.firstIndex(where: { $0.id == flashcard.id }) else { return }
                        var t = Transaction()
                        t.disablesAnimations = true
                        withTransaction(t) {
                            if shiftPressed {
                                let anchor = selectionAnchorIndex ?? clickedIndex
                                let low = min(anchor, clickedIndex)
                                let high = max(anchor, clickedIndex)
                                let rangeSelection = Array(displayedFlashcards[low...high])
                                viewModel.setSelectedFlashcards(Set(rangeSelection))
                            } else {
                                selectionAnchorIndex = clickedIndex
                                viewModel.setSelectedFlashcards([flashcard])
                            }
                        }
                    }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            }
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            .background(Color.appBackgroundPage(isLight: isLight))

            VStack(spacing: 0) {
                if !viewModel.selectedFlashcardIds.isEmpty {
                    HStack {
                        Text("\(viewModel.selectedFlashcardIds.count) thẻ đã chọn")
                            .scaledFont(.sm)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(role: .destructive) {
                            showDeleteMultipleFlashcardsConfirmation = true
                        } label: {
                            Label("Xóa \(viewModel.selectedFlashcardIds.count) thẻ", systemImage: "trash")
                                .scaledFont(.sm)
                        }
                        .buttonStyle(.bordered)
                        .cursor(.pointingHand)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.appCardBackground(isLight: colorScheme == .light))
                    ThemeDivider()
                }
                detailContent
            }
            .frame(minWidth: 400)
        }
        .sheet(isPresented: Binding(
            get: { pendingCSVExport != nil },
            set: { if !$0 { pendingCSVExport = nil } }
        )) {
            csvExportSheetContent
        }
        .onAppear { loadDueFlashcardIds() }
        .onChange(of: topic.id) { _, _ in loadDueFlashcardIds() }
        .onChange(of: scenePhase) { _, new in
            if new == .active { loadDueFlashcardIds() }
        }
    }

    @ViewBuilder
    private var csvExportSheetContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Đang mở hộp thoại lưu file...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 280, minHeight: 120)
        .onAppear {
            guard let pending = pendingCSVExport else { return }
            let filename = pending.filename
            let data = pending.data
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                let panel = NSSavePanel()
                panel.canCreateDirectories = true
                panel.nameFieldStringValue = filename
                panel.title = "Lưu file CSV"
                panel.prompt = "Lưu"
                panel.message = "Chọn nơi lưu file CSV."
                panel.allowedContentTypes = [UTType(filenameExtension: "csv", conformingTo: .plainText) ?? .plainText]
                let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible })
                if let win = window {
                    panel.beginSheetModal(for: win) { response in
                        pendingCSVExport = nil
                        isExportingCSV = false
                        guard response == .OK, let url = panel.url else { return }
                        do {
                            try data.write(to: url)
                            viewModel.backupSaveResultMessage = "Đã lưu CSV: \(url.lastPathComponent)"
                        } catch {
                            viewModel.errorMessage = "Không ghi được file: \(error.localizedDescription)"
                        }
                    }
                } else {
                    let response = panel.runModal()
                    pendingCSVExport = nil
                    isExportingCSV = false
                    guard response == .OK, let url = panel.url else { return }
                    do {
                        try data.write(to: url)
                        viewModel.backupSaveResultMessage = "Đã lưu CSV: \(url.lastPathComponent)"
                    } catch {
                        viewModel.errorMessage = "Không ghi được file: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private var vocabularySortFilterBar: some View {
        HStack(spacing: 12) {
            Picker("Sắp xếp", selection: $sortOption) {
                ForEach(VocabularySortOption.allCases, id: \.self) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .scaledFont(.sm)
            Picker("Lọc", selection: $filterOption) {
                ForEach(VocabularyFilterOption.allCases, id: \.self) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .scaledFont(.sm)
            Spacer()
            Text("\(displayedFlashcards.count) từ")
                .scaledFont(.xs)
                .foregroundStyle(.secondary)
            Button(action: exportVocabularyCSV) {
                Label("Xuất CSV", systemImage: "square.and.arrow.up")
                    .scaledFont(.sm)
            }
            .buttonStyle(.bordered)
            .disabled(displayedFlashcards.isEmpty || isExportingCSV)
            .cursor(.pointingHand)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appBackgroundControl(isLight: isLight))
    }

    private func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    private func exportVocabularyCSV() {
        let items = displayedFlashcards
        guard !items.isEmpty else { return }
        let csvContent = buildCSVContent(flashcards: items)
        let filename = "tu-vung-\(topic.name.replacingOccurrences(of: " ", with: "-"))-\(dateStringForExport()).csv"
        guard let data = csvContent.data(using: .utf8) else { return }
        isExportingCSV = true
        pendingCSVExport = (filename, data)
    }

    private func buildCSVContent(flashcards: [Flashcard]) -> String {
        let isChinese = viewModel.selectedSubject?.name == "Tiếng Trung"
        if isChinese {
            let header = "Từ Hán,Nghĩa,Loại từ,Ghi chú,Bộ Thủ,Phiên âm"
            let rows = flashcards.map { fc in
                [
                    csvEscape(fc.questionDisplayText),
                    csvEscape(fc.answer),
                    csvEscape(""), // Loại từ — chưa có trong model, để trống
                    csvEscape(fc.notes ?? ""),
                    csvEscape(fc.radical ?? ""),
                    csvEscape(fc.displayPhonetic ?? "")
                ].joined(separator: ",")
            }
            return ([header] + rows).joined(separator: "\n")
        } else {
            let header = "Từ gốc,Nghĩa,Phiên âm,Gợi ý,Ghi chú"
            let rows = flashcards.map { fc in
                [
                    csvEscape(fc.questionDisplayText),
                    csvEscape(fc.answer),
                    csvEscape(fc.displayPhonetic ?? ""),
                    csvEscape(fc.hint ?? ""),
                    csvEscape(fc.notes ?? "")
                ].joined(separator: ",")
            }
            return ([header] + rows).joined(separator: "\n")
        }
    }

    private func dateStringForExport() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f.string(from: Date())
    }

    private func vocabularyRow(flashcard: Flashcard) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(Flashcard.exerciseTypeLabel)
                        .scaledFont(.sm)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(colorScheme == .light ? 0.12 : 0.18))
                        .cornerRadius(4)
                        .lineLimit(1)
                    Spacer()
                }
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Từ gốc")
                            .scaledFont(.sm)
                            .foregroundStyle(.tertiary)
                        Text(flashcard.question)
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Image(systemName: "arrow.right")
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    if let phonetic = flashcard.displayPhonetic, !phonetic.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Phiên âm")
                                .scaledFont(.sm)
                                .foregroundStyle(.tertiary)
                            Text(phonetic)
                                .scaledFont(.sm)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Image(systemName: "arrow.right")
                            .scaledFont(.sm)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ý nghĩa")
                            .scaledFont(.sm)
                            .foregroundStyle(.tertiary)
                        Text(flashcard.answer)
                            .scaledFont(.sm)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 32)

                if let hint = flashcard.hint, !hint.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .scaledFont(.sm)
                                .foregroundStyle(.white)
                            Text("Gợi ý")
                                .scaledFont(.sm)
                                .foregroundStyle(.secondary)
                        }
                        Text(hint)
                            .scaledFont(.sm)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 32)
                }
                if viewModel.selectedSubject?.name == "Tiếng Trung", let radical = flashcard.radical, !radical.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("Bộ thủ")
                                .scaledFont(.sm)
                                .foregroundStyle(.secondary)
                        }
                        Text(radical)
                            .scaledFont(.sm)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 32)
                }
                if let notes = flashcard.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("Ghi chú")
                                .scaledFont(.sm)
                                .foregroundStyle(.secondary)
                        }
                        Text(notes)
                            .scaledFont(.sm)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 32)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                if isFlashcardLearned(flashcard) {
                    GreenCheckmarkView(size: 18)
                        .help("Đã học")
                        .accessibilityLabel("Đã học")
                }
                if isDueForReview(flashcard) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.orange)
                        .help("Đến hạn ôn")
                        .accessibilityLabel("Đến hạn ôn")
                }
            }
            .padding(.top, 2)
            .padding(.trailing, 4)
        }
        .cursor(.pointingHand)
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

    @ViewBuilder
    private var detailContent: some View {
        if topic.flashcards.isEmpty {
            ContentUnavailableView(
                "Chưa có từ vựng",
                systemImage: "text.badge.plus",
                description: Text("Nhấn \"Thêm từ\" hoặc \"Import\" ở góc phải để thêm từ vựng vào chủ đề này.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if displayedFlashcards.isEmpty {
            ContentUnavailableView(
                "Không có từ nào theo bộ lọc",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("Thử đổi bộ lọc hoặc cách sắp xếp ở trên.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let flashcard = viewModel.selectedFlashcard {
            let radicalText: String? = viewModel.selectedSubject?.name == "Tiếng Trung"
                ? (flashcard.radical.flatMap { $0.isEmpty ? nil : $0 } ?? viewModel.radicalForCharacter(flashcard.questionDisplayText))
                : nil
            FlashcardDetailView(
                flashcard: flashcard,
                topic: topic,
                subjectName: viewModel.selectedSubject?.name ?? "",
                subjectIcon: viewModel.selectedSubject?.displayIcon,
                radicalText: radicalText,
                onEdit: { showEditFlashcardSheet = true },
                onAnswered: nil
            )
        } else {
            ContentUnavailableView(
                "Chọn một flashcard",
                systemImage: "rectangle.portrait.on.rectangle.portrait",
                description: Text("Chọn một hoặc nhiều flashcard để xem chi tiết hoặc xóa")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func isFlashcardLearned(_ flashcard: Flashcard) -> Bool {
        if let progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) {
            return progress.totalReviews > 0
        }
        return false
    }

    /// Thẻ đến hạn ôn (trong danh sách cần ôn hôm nay). Ôn xong thì icon biến mất.
    private func isDueForReview(_ flashcard: Flashcard) -> Bool {
        dueFlashcardIds.contains(flashcard.id)
    }

    private func loadDueFlashcardIds() {
        dueFlashcardIds = Set(DatabaseManager.shared.getDueFlashcards())
    }
}
