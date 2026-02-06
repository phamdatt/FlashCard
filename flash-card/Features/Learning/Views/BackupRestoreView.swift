//
//  BackupRestoreView.swift
//  flash-card
//
//  Backup (export SQL database or JSON) / Restore (import JSON with confirmation).
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BackupRestoreView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showImportConfirmation = false
    @State private var pendingImportURL: URL?
    @State private var showImportSQLConfirmation = false
    @State private var pendingImportSQLURL: URL?
    @State private var statusMessage: String?
    @State private var isExporting = false
    @State private var isExportingSQL = false
    @State private var isImporting = false
    @State private var isImportingSQL = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Sao lưu & Phục hồi")
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
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            Divider()

            VStack(alignment: .leading, spacing: 20) {
                Text("Sao lưu: copy database ra file .sqlite (khuyến nghị) hoặc ra JSON.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Button(action: runExportSQL) {
                        Label("Sao lưu SQL...", systemImage: "internaldrive")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(isExportingSQL)
                    Button(action: runExport) {
                        Label("Sao lưu JSON...", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isExporting)
                }
                Divider()
                    .padding(.vertical, 4)
                Text("Phục hồi: thay toàn bộ dữ liệu bằng file đã chọn. Chỉ dùng khi bạn chắc chắn.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Button(action: runImportSQL) {
                        Label("Phục hồi từ file SQL...", systemImage: "internaldrive")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isImportingSQL)
                    Button(action: runImport) {
                        Label("Phục hồi từ JSON...", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isImporting)
                }
            }
            .padding(24)

            if let msg = statusMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 420, height: 380)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay {
            ConfirmActionOverlay(
                title: "Phục hồi từ JSON?",
                message: "Toàn bộ dữ liệu do bạn tạo sẽ bị thay thế bằng nội dung từ file JSON. Tiếp tục?",
                destructiveTitle: "Phục hồi",
                cancelTitle: "Huỷ",
                isPresented: $showImportConfirmation,
                onConfirm: {
                    if let url = pendingImportURL {
                        performImport(from: url)
                    }
                    pendingImportURL = nil
                }
            )
        }
        .overlay {
            ConfirmActionOverlay(
                title: "Phục hồi từ file SQL?",
                message: "Database hiện tại sẽ bị thay bằng file .sqlite bạn chọn. Toàn bộ dữ liệu trong app sẽ là dữ liệu từ file đó. Tiếp tục?",
                destructiveTitle: "Phục hồi",
                cancelTitle: "Huỷ",
                isPresented: $showImportSQLConfirmation,
                onConfirm: {
                    if let url = pendingImportSQLURL {
                        performImportSQL(from: url)
                    }
                    pendingImportSQLURL = nil
                }
            )
        }
    }

    private func runExportSQL() {
        isExportingSQL = true
        statusMessage = "Đang mở hộp thoại lưu file..."
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "sqlite", conformingTo: .data) ?? .data]
        panel.nameFieldStringValue = "flashcards-\(dateString()).sqlite"
        panel.title = "Lưu file SQL (database)"
        panel.message = "Chọn vị trí lưu file sao lưu database."
        guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }) else {
            statusMessage = nil
            isExportingSQL = false
            viewModel.errorMessage = "Không tìm thấy cửa sổ để hiển thị hộp thoại."
            return
        }
        panel.beginSheetModal(for: window) { response in
            statusMessage = nil
            isExportingSQL = false
            guard response == .OK, let destURL = panel.url else { return }
            statusMessage = "Đang sao lưu database..."
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try DatabaseManager.shared.exportDatabase(to: destURL)
                    DispatchQueue.main.async {
                        statusMessage = nil
                        viewModel.backupSaveResultMessage = "Đã lưu file SQL: \(destURL.lastPathComponent)"
                        dismiss()
                    }
                } catch {
                    DispatchQueue.main.async {
                        statusMessage = nil
                        viewModel.errorMessage = "Không thể sao lưu database: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func runExport() {
        isExporting = true
        statusMessage = "Đang tạo dữ liệu JSON..."
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = DatabaseManager.shared.exportUserData() else {
                DispatchQueue.main.async {
                    viewModel.errorMessage = "Không thể tạo bản sao lưu JSON."
                    isExporting = false
                    statusMessage = nil
                }
                return
            }
            DispatchQueue.main.async {
                statusMessage = nil
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "flashcard-backup-\(dateString()).json"
                panel.title = "Lưu bản sao lưu JSON"
                let response = panel.runModal()
                isExporting = false
                guard response == .OK, let url = panel.url else { return }
                do {
                    try data.write(to: url)
                    viewModel.backupSaveResultMessage = "Đã lưu: \(url.lastPathComponent)"
                    dismiss()
                } catch {
                    viewModel.errorMessage = "Không thể ghi file: \(error.localizedDescription)"
                }
            }
        }
    }

    private func runImportSQL() {
        guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }) else {
            viewModel.errorMessage = "Không tìm thấy cửa sổ."
            return
        }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "sqlite", conformingTo: .data) ?? .data]
        panel.allowsMultipleSelection = false
        panel.title = "Chọn file SQL (database) để phục hồi"
        panel.message = "Chọn file .sqlite đã sao lưu trước đó."
        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            pendingImportSQLURL = url
            showImportSQLConfirmation = true
        }
    }

    private func performImportSQL(from url: URL) {
        isImportingSQL = true
        statusMessage = "Đang phục hồi database..."
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try DatabaseManager.shared.replaceDatabase(withFileAt: url)
                DispatchQueue.main.async {
                    statusMessage = nil
                    isImportingSQL = false
                    viewModel.loadLearningData()
                    viewModel.backupSaveResultMessage = "Đã phục hồi từ file SQL."
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    statusMessage = nil
                    isImportingSQL = false
                    viewModel.errorMessage = "Không thể phục hồi: \(error.localizedDescription)"
                }
            }
        }
    }

    private func runImport() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Chọn file JSON để phục hồi"
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }
        pendingImportURL = url
        showImportConfirmation = true
    }

    private func performImport(from url: URL) {
        isImporting = true
        statusMessage = nil
        defer { isImporting = false }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(BackupPayload.self, from: data)
            try DatabaseManager.shared.importUserData(payload)
            viewModel.loadLearningData()
            statusMessage = "Đã phục hồi xong."
            dismiss()
        } catch {
            viewModel.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
