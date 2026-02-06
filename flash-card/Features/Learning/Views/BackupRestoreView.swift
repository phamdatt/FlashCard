//
//  BackupRestoreView.swift
//  flash-card
//
//  Sao lưu (export JSON) / Phục hồi (import với xác nhận).
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BackupRestoreView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showImportConfirmation = false
    @State private var pendingImportURL: URL?
    @State private var statusMessage: String?
    @State private var isExporting = false
    @State private var isImporting = false

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
                Text("Sao lưu dữ liệu (chủ đề, từ vựng, bài đọc do bạn tạo) ra file JSON để lưu trữ hoặc chuyển máy.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: runExport) {
                    Label("Sao lưu ra file...", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isExporting)

                Divider()
                    .padding(.vertical, 8)

                Text("Phục hồi sẽ thay thế toàn bộ dữ liệu hiện tại bằng bản sao lưu. Chỉ nên dùng khi bạn chắc chắn.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: runImport) {
                    Label("Chọn file để phục hồi...", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isImporting)
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
        .frame(width: 420, height: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .confirmationDialog("Phục hồi dữ liệu?", isPresented: $showImportConfirmation, titleVisibility: .visible) {
            Button("Phục hồi", role: .destructive) {
                if let url = pendingImportURL {
                    performImport(from: url)
                }
                pendingImportURL = nil
            }
            Button("Huỷ", role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text("Toàn bộ chủ đề và từ vựng do bạn tạo sẽ bị thay thế bằng nội dung từ file đã chọn. Tiếp tục?")
        }
    }

    private func runExport() {
        isExporting = true
        statusMessage = "Đang tạo dữ liệu..."
        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = DatabaseManager.shared.exportUserData() else {
                DispatchQueue.main.async {
                    viewModel.errorMessage = "Không thể tạo bản sao lưu."
                    isExporting = false
                    statusMessage = nil
                }
                return
            }
            DispatchQueue.main.async {
                statusMessage = nil
                // Đóng sheet trước, sau đó mới mở hộp thoại lưu (tránh runModal() từ trong sheet bị trả về Cancel).
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showSavePanelAfterDismiss(data: data)
                }
            }
        }
    }

    private func showSavePanelAfterDismiss(data: Data) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "flashcard-backup-\(dateString()).json"
        panel.title = "Lưu bản sao lưu"
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url)
            viewModel.backupSaveResultMessage = "Đã lưu: \(url.lastPathComponent)"
        } catch {
            viewModel.errorMessage = "Không thể ghi file: \(error.localizedDescription)"
        }
    }

    private func runImport() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Chọn file sao lưu"
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
            if DatabaseManager.shared.importUserData(payload) {
                viewModel.loadLearningData()
                statusMessage = "Đã phục hồi xong."
                dismiss()
            } else {
                viewModel.errorMessage = "Phục hồi thất bại."
            }
        } catch {
            viewModel.errorMessage = "File không hợp lệ: \(error.localizedDescription)"
        }
    }

    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
