//
//  ImportFlashcardSheet.swift
//  flash-card
//
//  Import flashcards from CSV or JSON into a chosen topic.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ImportFlashcardSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFileURL: URL?
    @State private var selectedTopicId: Int?
    @State private var parsedRows: [(question: String, answer: String, hint: String?)] = []
    @State private var parseError: String?
    @State private var isImporting = false
    @State private var importResult: String?

    private var targetTopic: Topic? {
        guard let sid = viewModel.selectedSubject?.id,
              let tid = selectedTopicId,
              let sub = viewModel.subjects.first(where: { $0.id == sid }) else { return nil }
        return sub.topics.first(where: { $0.id == tid })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Import từ vựng")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }

            Group {
                HStack {
                    Button("Chọn file CSV hoặc JSON...") {
                        openFilePanel()
                    }
                    .buttonStyle(.bordered)
                    if let url = selectedFileURL {
                        Text(url.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                    }
                }

                if let subject = viewModel.selectedSubject {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chủ đề đích")
                            .font(.headline)
                        Picker("", selection: $selectedTopicId) {
                            Text("-- Chọn chủ đề --")
                                .tag(nil as Int?)
                            ForEach(subject.topics) { topic in
                                Text(topic.name).tag(topic.id as Int?)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }

                if !parsedRows.isEmpty {
                    Text("Sẽ thêm \(parsedRows.count) thẻ vào chủ đề đã chọn.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let err = parseError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if let result = importResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Huỷ") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Import") {
                    performImport()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(targetTopic == nil || parsedRows.isEmpty || isImporting)
            }
        }
        .padding(24)
        .frame(width: 440, height: 320)
        .onChange(of: selectedFileURL) { _, url in
            if let url = url {
                parseFile(at: url)
            } else {
                parsedRows = []
                parseError = nil
            }
        }
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .json, .plainText]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                selectedFileURL = url
            }
        }
    }

    private func parseFile(at url: URL) {
        parseError = nil
        parsedRows = []
        do {
            let data = try Data(contentsOf: url)
            let ext = url.pathExtension.lowercased()
            if ext == "json" {
                let decoded = try JSONDecoder().decode([ImportFlashcardRow].self, from: data)
                parsedRows = decoded.map { ($0.question, $0.answer, $0.hint) }
            } else {
                guard let content = String(data: data, encoding: .utf8) else {
                    parseError = "Không đọc được file (encoding)."
                    return
                }
                let lines = content.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty { continue }
                    let parts = trimmed.split(separator: ";", omittingEmptySubsequences: false)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count < 2 {
                        let commaParts = trimmed.split(separator: ",", omittingEmptySubsequences: false)
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                        if commaParts.count >= 2 {
                            let q = String(commaParts[0])
                            let a = String(commaParts[1])
                            let h = commaParts.count > 2 ? String(commaParts[2]) : nil
                            parsedRows.append((q, a, (h?.isEmpty ?? true) ? nil : h))
                        }
                    } else {
                        let q = String(parts[0])
                        let a = String(parts[1])
                        let h = parts.count > 2 ? String(parts[2]) : nil
                        parsedRows.append((q, a, (h?.isEmpty ?? true) ? nil : h))
                    }
                }
            }
            if parsedRows.isEmpty && parseError == nil {
                parseError = "Không tìm thấy dòng nào hợp lệ."
            }
        } catch {
            parseError = "Lỗi: \(error.localizedDescription)"
        }
    }

    private func performImport() {
        guard let topic = targetTopic else { return }
        isImporting = true
        importResult = nil
        var added = 0
        for row in parsedRows {
            let q = row.question.trimmingCharacters(in: .whitespaces)
            let a = row.answer.trimmingCharacters(in: .whitespaces)
            guard !q.isEmpty, !a.isEmpty else { continue }
            let card = Flashcard(
                question: q,
                answer: a,
                hint: row.hint?.isEmpty == false ? row.hint : nil,
                exerciseType: Flashcard.exerciseTypeLabel
            )
            do {
                try DatabaseManager.shared.insertFlashcard(card, topicId: topic.id)
                added += 1
            } catch {
                viewModel.errorMessage = error.localizedDescription
                isImporting = false
                return
            }
        }
        isImporting = false
        importResult = "Đã thêm \(added) thẻ."
        viewModel.loadLearningData()
        if let subId = viewModel.selectedSubject?.id,
           let sub = viewModel.subjects.first(where: { $0.id == subId }),
           let t = sub.topics.first(where: { $0.id == topic.id }) {
            viewModel.selectedSubject = sub
            viewModel.selectedTopic = t
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

private struct ImportFlashcardRow: Codable {
    let question: String
    let answer: String
    let hint: String?
}
