//
//  VocabularyListView.swift
//  flash-card
//
//  Danh sách từ vựng: list bên trái + chi tiết / empty state bên phải.
//

import SwiftUI
import AppKit

struct VocabularyListView: View {
    @ObservedObject var viewModel: ContentViewModel
    let topic: Topic
    @Binding var showEditFlashcardSheet: Bool
    @Binding var showDeleteMultipleFlashcardsConfirmation: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        HSplitView {
            List(topic.flashcards) { flashcard in
                vocabularyRow(flashcard: flashcard)
                    .contentShape(Rectangle())
                    .listRowBackground(
                        viewModel.selectedFlashcardIds.contains(flashcard.id)
                        ? Color.gray.opacity(isLight ? 0.2 : 0.25)
                        : Color.clear
                    )
                    .onTapGesture {
                        let shiftPressed = NSEvent.modifierFlags.contains(.shift)
                        if shiftPressed {
                            let ids = viewModel.selectedFlashcardIds
                            let newIds = ids.contains(flashcard.id)
                                ? ids.filter { $0 != flashcard.id }
                                : ids.union([flashcard.id])
                            let newSet = Set(topic.flashcards.filter { newIds.contains($0.id) })
                            viewModel.setSelectedFlashcards(newSet)
                        } else {
                            viewModel.setSelectedFlashcards([flashcard])
                        }
                    }
            }
            .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
    }

    private func vocabularyRow(flashcard: Flashcard) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(Flashcard.exerciseTypeLabel)
                        .font(.app(.caption))
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
                            .font(.app(.caption2))
                            .foregroundStyle(.tertiary)
                        Text(flashcard.question)
                            .scaledFont(.sm)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Image(systemName: "arrow.right")
                        .font(.app(.caption))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    if let phonetic = flashcard.displayPhonetic, !phonetic.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Phiên âm")
                                .font(.app(.caption2))
                                .foregroundStyle(.tertiary)
                            Text(phonetic)
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Image(systemName: "arrow.right")
                            .font(.app(.caption))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ý nghĩa")
                            .font(.app(.caption2))
                            .foregroundStyle(.tertiary)
                        Text(flashcard.answer)
                            .font(.app(.subheadline))
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
                                .font(.app(.subheadline))
                                .foregroundStyle(.green)
                            Text("Gợi ý")
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                        }
                        Text(hint)
                            .font(.app(.subheadline))
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
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                        }
                        Text(radical)
                            .font(.app(.callout))
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
                                .font(.app(.subheadline))
                                .foregroundStyle(.secondary)
                        }
                        Text(notes)
                            .font(.app(.callout))
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
                    Image(systemName: "checkmark.circle.fill")
                        .scaledFont(.sm)
                        .foregroundStyle(.secondary)
                        .help("Đã học")
                        .accessibilityLabel("Đã học")
                }
                if needsImprovement(flashcard) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .scaledFont(.sm)
                        .foregroundStyle(.teal)
                        .help("Cần ôn lại")
                        .accessibilityLabel("Cần ôn lại")
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

    private func needsImprovement(_ flashcard: Flashcard) -> Bool {
        let mistakeIds = DatabaseManager.shared.getMistakeFlashcards(days: 30)
        return mistakeIds.contains(flashcard.id)
    }
}
