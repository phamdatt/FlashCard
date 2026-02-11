//
//  EditFlashcardSheet.swift
//  flash-card
//
//  Sheet sửa từ vựng (question, answer, hint, notes, radical, phonetic).
//

import SwiftUI

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
    @State private var editPhonetic: String = ""
    @FocusState private var focusedField: Field?

    private var isChineseSubject: Bool { viewModel.selectedSubject?.name == "Tiếng Trung" }

    enum Field {
        case question, answer, hint, notes, radical, phonetic
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
                    .cursor(.pointingHand)
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

                VStack(alignment: .leading, spacing: 8) {
                    Text(isChineseSubject ? "Phiên âm (pinyin)" : "Phiên âm (IPA, không bắt buộc)")
                        .scaledFont(.sm)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    TextField(isChineseSubject ? "vd: nǐ hǎo" : "vd: /ˈhɛloʊ/", text: $editPhonetic)
                        .textFieldStyle(.roundedBorder)
                        .scaledFont(.sm)
                        .focused($focusedField, equals: .phonetic)
                }

                HStack {
                    Button(action: { onDismiss() }) {
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

                    Button(action: save) {
                        Text("Lưu")
                            .scaledFont(.sm)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                    }
                    .keyboardShortcut(.return)
                    .disabled(editQuestion.trimmingCharacters(in: .whitespaces).isEmpty || editAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
                    .cursor(.pointingHand)
                    .tint(.accentColor)
                    .controlSize(.large)
                }
            }
            .padding(24)
        }
        .frame(width: 440, height: 560)
        .onAppear {
            editQuestion = flashcard.question
            editAnswer = flashcard.answer
            editHint = flashcard.hint ?? ""
            editNotes = flashcard.notes ?? ""
            editRadical = flashcard.radical ?? ""
            editPhonetic = flashcard.phonetic ?? ""
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
            radical: isChineseSubject ? (editRadical.isEmpty ? nil : editRadical) : nil,
            phonetic: editPhonetic.isEmpty ? nil : editPhonetic
        )
        onDismiss()
    }
}
