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
    @State private var parsedRows: [(question: String, answer: String, hint: String?, notes: String?, radical: String?, phonetic: String?)] = []
    @State private var parseError: String?

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
                .cursor(.pointingHand)
            }

            Group {
                HStack {
                    Button(action: { openFilePanel() }) {
                        Text("Chọn file CSV hoặc JSON...")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.bordered)
                    .cursor(.pointingHand)
                    .controlSize(.large)
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
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Text("Huỷ")
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .cursor(.pointingHand)
                .controlSize(.large)
                Button(action: { performImportAndClose() }) {
                    Text("Import")
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderedProminent)
                .cursor(.pointingHand)
                .tint(.green)
                .controlSize(.large)
                .disabled(targetTopic == nil || parsedRows.isEmpty)
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
                parsedRows = decoded.map { ($0.question, $0.answer, $0.hint, $0.notes, $0.radical, $0.phonetic) }
            } else {
                guard let content = String(data: data, encoding: .utf8) else {
                    parseError = "Không đọc được file (encoding)."
                    return
                }
                let lines = content.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty { continue }
                    let commaParts = trimmed.split(separator: ",", omittingEmptySubsequences: false)
                        .map { String($0).trimmingCharacters(in: .whitespaces) }
                    guard commaParts.count >= 2 else { continue }
                    let q = commaParts[0]
                    let a = commaParts[1]
                    let h = commaParts.count > 2 && !commaParts[2].isEmpty ? commaParts[2] : nil
                    let notes = commaParts.count > 3 && !commaParts[3].isEmpty ? commaParts[3] : nil
                    let radical = commaParts.count > 4 && !commaParts[4].isEmpty ? commaParts[4] : nil
                    let phonetic = commaParts.count > 5 && !commaParts[5].isEmpty ? commaParts[5] : nil  // Cột 6 = phiên âm
                    parsedRows.append((q, a, h, notes, radical, phonetic))
                }
            }
            if parsedRows.isEmpty && parseError == nil {
                parseError = "Không tìm thấy dòng nào hợp lệ."
            }
        } catch {
            parseError = "Lỗi: \(error.localizedDescription)"
        }
    }

    private func performImportAndClose() {
        guard let topic = targetTopic else { return }
        let rows = parsedRows
        dismiss()
        viewModel.importFlashcardsFromRows(topicId: topic.id, subjectId: topic.subjectId, rows: rows)
    }
}

private struct ImportFlashcardRow: Codable {
    let question: String
    let answer: String
    let hint: String?
    let notes: String?
    let radical: String?
    let phonetic: String?  // Pinyin (Tiếng Trung) hoặc phiên âm (Tiếng Anh, vd IPA)
}
