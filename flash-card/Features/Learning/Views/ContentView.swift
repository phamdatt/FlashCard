//
//  ContentView.swift
//  learn-macos
//
//  Created by Dat Pham on 29/1/26.
//

import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

extension Notification.Name {
    static let openKeyboardShortcuts = Notification.Name("OpenKeyboardShortcuts")
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
            .cursor(.pointingHand)
            .tint(.green)
            .scaledFont(.sm)
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .scaledFont(.lg)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
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
    @EnvironmentObject var appearanceManager: AppearanceManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
        } content: {
            middleColumn
        } detail: {
            detailColumn
        }
        .background(colorScheme == .dark ? Color.appDarkBackground : Color.clear)
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
        .alert("Import", isPresented: Binding(
            get: { viewModel.importResultMessage != nil },
            set: { if !$0 { viewModel.importResultMessage = nil } }
        )) {
            Button("OK") { viewModel.importResultMessage = nil }
        } message: {
            if let msg = viewModel.importResultMessage {
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
        .overlay {
            ConfirmActionOverlay(
                title: "Kết thúc luyện tập?",
                message: viewModel.pendingTopicSwitch.map { "Chuyển sang \"\($0.name)\" sẽ kết thúc phiên luyện tập hiện tại." } ?? "",
                destructiveTitle: "Chuyển",
                cancelTitle: "Ở lại",
                isPresented: Binding(
                    get: { viewModel.pendingTopicSwitch != nil },
                    set: { if !$0 { viewModel.pendingTopicSwitch = nil } }
                ),
                onConfirm: {
                    if let t = viewModel.pendingTopicSwitch {
                        viewModel.applyTopicSwitch(to: t)
                    }
                }
            )
        }
        .overlay {
            ConfirmActionOverlay(
                title: "Kết thúc luyện tập?",
                message: "Bạn có chắc muốn thoát? Phiên luyện tập sẽ kết thúc.",
                destructiveTitle: "Kết thúc",
                cancelTitle: "Tiếp tục",
                isPresented: Binding(
                    get: { viewModel.pendingSidebarAction != .none },
                    set: { if !$0 { viewModel.pendingSidebarAction = .none } }
                ),
                onConfirm: {
                    if viewModel.pendingSidebarAction == .cycleTheme {
                        withAnimation(.easeInOut(duration: 0.2)) { appearanceManager.cycleMode() }
                    }
                    viewModel.applyPendingSidebarAction()
                }
            )
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
        .onReceive(NotificationCenter.default.publisher(for: .openReviewFromNotification)) { _ in
            ReviewReminderManager.pendingOpenReviewFromNotification = false
            viewModel.switchToReviewMode()
        }
        .onAppear {
            if ReviewReminderManager.pendingOpenReviewFromNotification {
                ReviewReminderManager.pendingOpenReviewFromNotification = false
                viewModel.switchToReviewMode()
            }
        }
        .onChange(of: viewModel.showReviewMode) { _, isReview in
            if !isReview { viewModel.loadStreakInfo() }
        }
    }
    
    // MARK: - Columns
    
    @ViewBuilder
    private var middleColumn: some View {
        if viewModel.isInSpecialMode || viewModel.isInPracticeMode {
            Color.clear
                .frame(width: 0)
                .navigationSplitViewColumnWidth(min: 0, ideal: 0, max: 0)
        } else if viewModel.isLoading && viewModel.subjects.isEmpty {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.secondary)
                Text("Đang tải...")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 420)
        } else if let subject = viewModel.selectedSubject {
            TopicsListView(viewModel: viewModel, subject: subject)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 420)
        } else {
            ContentUnavailableView {
                Label("Chọn môn học", systemImage: "book.fill")
            } description: {
                Text("Chọn một môn học từ sidebar")
                    .font(.app(.subheadline))
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 420)
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
                    ContentUnavailableView {
                        Label("Chọn chủ đề", systemImage: "text.book.closed.fill")
                    } description: {
                        Text("Chọn một chủ đề để xem flashcards")
                            .font(.app(.subheadline))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 400)
        .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: .infinity)
        .background(Color.appBackgroundPage(isLight: colorScheme == .light))
    }
    
    // MARK: - Helpers
    
    private func updateColumnVisibility(animated: Bool) {
        let newVisibility: NavigationSplitViewVisibility = viewModel.isInSpecialMode ? .doubleColumn : .all
        if animated {
            var transaction = Transaction(animation: .easeInOut(duration: 0.15))
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
