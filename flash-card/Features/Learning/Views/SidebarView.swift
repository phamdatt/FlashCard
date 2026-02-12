//
//  SidebarView.swift
//  flash-card
//
//  Sidebar: môn học, ôn từ sai, thống kê, streak, mục tiêu ôn, cài đặt.
//

import SwiftUI
import AppKit

struct SidebarView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var practiceSoundEnabled: Bool = SoundManager.practiceSoundEnabled
    @State private var reviewReminderEnabled: Bool = ReviewReminderManager.isEnabled
    @State private var reminderHour: Int = ReviewReminderManager.reminderHour
    @State private var reminderMinute: Int = ReviewReminderManager.reminderMinute

    var body: some View {
        List {
            wordOfTheDaySection
            learningSection
            reviewSection
            statisticsSection
        }
        .environment(\.fontSizeMultiplier, fontSizeManager.fontSizeMultiplier)
        .scrollContentBackground(colorScheme == .dark ? .hidden : .visible)
        .background(colorScheme == .dark ? Color.appDarkBackground : Color.clear)
        .navigationSplitViewColumnWidth(min: 240, ideal: 250, max: 300)
        .navigationTitle("Menu")
        .tint(.green)
        .safeAreaInset(edge: .bottom) {
            bottomSection
        }
    }

    private func sidebarRowContent(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.appFixed(14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .center)
            Text(title)
                .font(.appFixed(14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.appFixed(12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .trailing)
        }
        .padding(AppLayout.sidebarPadding)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusMedium)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
        )
    }

    /// Từ theo ngày: mỗi môn (Tiếng Anh, Tiếng Trung) 5–10 từ. Bấm vào → mở flow luyện tập.
    @ViewBuilder
    private var wordOfTheDaySection: some View {
        let items = viewModel.wordOfTheDayBySubject
        if !items.isEmpty {
            Section {
                ForEach(items, id: \.subject.id) { item in
                    Button(action: {
                        if viewModel.isPracticeSessionActive {
                            viewModel.pendingSidebarAction = .switchToWordOfDay(subjectId: item.subject.id, topicId: item.topic.id, flashcardIds: item.flashcards.map(\.id))
                        } else {
                            var t = Transaction()
                            t.disablesAnimations = true
                            withTransaction(t) {
                                viewModel.selectSubject(item.subject)
                                viewModel.selectTopic(item.topic)
                                viewModel.switchToLearningMode()
                                if let first = item.flashcards.first { viewModel.selectFlashcard(first) }
                                viewModel.wordOfDayToPractice = (item.topic, item.flashcards, item.subject)
                            }
                        }
                    }) {
                        sidebarRowContent(
                            icon: item.subject.displayIcon,
                            title: "\(item.flashcards.count) từ · \(item.subject.name)"
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .cursor(.pointingHand)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: AppLayout.sidebarPadding, leading: AppLayout.sidebarPadding, bottom: AppLayout.sidebarPadding, trailing: AppLayout.sidebarPadding))
                }
            } header: {
                Text("Từ của ngày")
                    .font(.appFixed(12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .padding(.horizontal, AppLayout.sidebarPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var learningSection: some View {
        Section {
            ForEach(viewModel.subjects) { subject in
                Button(action: {
                    if viewModel.isPracticeSessionActive {
                        viewModel.pendingSidebarAction = .switchToSubject(id: subject.id)
                    } else {
                        var t = Transaction()
                        t.disablesAnimations = true
                        withTransaction(t) {
                            viewModel.selectSubject(subject)
                            viewModel.switchToLearningMode()
                        }
                    }
                }) {
                    sidebarRowContent(icon: subject.displayIcon, title: subject.name)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: AppLayout.sidebarPadding, leading: AppLayout.sidebarPadding, bottom: AppLayout.sidebarPadding, trailing: AppLayout.sidebarPadding))
            }
        } header: {
            Text("Học tập")
                .font(.appFixed(12, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.horizontal, AppLayout.sidebarPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var reviewSection: some View {
        Section {
            Button(action: {
                if viewModel.isPracticeSessionActive {
                    viewModel.pendingSidebarAction = .switchToReviewMistakes
                } else {
                    viewModel.switchToReviewMistakes()
                }
            }) {
                sidebarRowContent(icon: "xmark.circle.fill", title: "Ôn lại từ sai")
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
            .accessibilityLabel("Ôn lại từ sai")
            .accessibilityHint("Mở danh sách từ đã trả lời sai để ôn lại")
            .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: AppLayout.sidebarPadding, leading: AppLayout.sidebarPadding, bottom: AppLayout.sidebarPadding, trailing: AppLayout.sidebarPadding))
        } header: {
            Text("Ôn tập")
                .font(.appFixed(12, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.horizontal, AppLayout.sidebarPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statisticsSection: some View {
        Section {
            Button(action: {
                if viewModel.isPracticeSessionActive {
                    viewModel.pendingSidebarAction = .switchToStatistics
                } else {
                    viewModel.switchToStatistics()
                }
            }) {
                sidebarRowContent(icon: "chart.line.uptrend.xyaxis", title: "Thống kê")
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .cursor(.pointingHand)
            .accessibilityLabel("Thống kê")
            .accessibilityHint("Xem thống kê học tập và streak")
            .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: AppLayout.sidebarPadding, leading: AppLayout.sidebarPadding, bottom: AppLayout.sidebarPadding, trailing: AppLayout.sidebarPadding))
        } header: {
            Text("Thống kê")
                .font(.appFixed(12, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.horizontal, AppLayout.sidebarPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 0) {
            ThemeDivider()
                .padding(.bottom, AppLayout.sidebarPadding)
            VStack(spacing: AppLayout.sidebarPadding) {
                streakBlock
                dailyGoalBlock
                if viewModel.dueFlashcardsCount > 0 {
                    dueNowBlock
                }
                themeButton
                reviewReminderRow
                practiceSoundRow
                keyboardShortcutsButton
                speechAccentButton
                strokeDrawButton
                backupRestoreButton
            }
            .padding(AppLayout.sidebarPadding)
        }
        .onAppear {
            viewModel.loadStreakInfo()
            if viewModel.selectedSubject == nil, let firstSubject = viewModel.subjects.first {
                viewModel.selectSubject(firstSubject)
            }
        }
    }

    private var streakBlock: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundStyle(viewModel.streakInfo.currentStreak > 0 ? .orange : .secondary)
                .font(.appFixed(14))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(viewModel.streakInfo.currentStreak)")
                        .font(.appFixed(14, weight: .bold))
                        .lineLimit(1)
                    Text("ngày")
                        .font(.appFixed(14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if viewModel.streakInfo.longestStreak > 0 {
                    Text("Kỷ lục: \(viewModel.streakInfo.longestStreak) ngày")
                        .font(.appFixed(12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Spacer()
            if viewModel.streakInfo.didPracticeToday {
                Group {
                    if viewModel.streakInfo.currentStreak > 0 {
                        GreenCheckmarkView(size: 20)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.appFixed(14))
                    }
                }
                .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .trailing)
            } else {
                Text("Chưa học")
                    .font(.appFixed(12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .lineLimit(1)
                    .background(Capsule().fill(.orange))
            }
        }
        .padding(AppLayout.sidebarPadding)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusMedium)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
        )
    }

    private var dueNowBlock: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark")
                .font(.appFixed(14))
                .foregroundStyle(.secondary)
            Text("Nên ôn: \(viewModel.dueFlashcardsCount) từ")
                .font(.appFixed(14))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            Button("Bắt đầu") {
                viewModel.switchToReviewMode()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.green)
        }
        .padding(AppLayout.sidebarPadding)
        .frame(minHeight: 40)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusMedium)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
        )
    }

    private var dailyGoalBlock: some View {
        HStack(spacing: 8) {
            Image(systemName: "target")
                .font(.appFixed(14))
                .foregroundStyle(.secondary)
            if viewModel.dailyReviewGoal > 0 {
                Text("Đã ôn: \(viewModel.wordsPracticedToday)/\(viewModel.dailyReviewGoal) từ hôm nay")
                    .font(.appFixed(14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text("Mục tiêu ôn mỗi ngày")
                    .font(.appFixed(14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Menu {
                Button("Tắt") { viewModel.dailyReviewGoal = 0 }
                Button("5 từ") { viewModel.dailyReviewGoal = 5 }
                Button("10 từ") { viewModel.dailyReviewGoal = 10 }
                Button("20 từ") { viewModel.dailyReviewGoal = 20 }
                Button("50 từ") { viewModel.dailyReviewGoal = 50 }
            } label: {
                Text(viewModel.dailyReviewGoal > 0 ? "\(viewModel.dailyReviewGoal)" : "Đặt")
                    .font(.appFixed(14, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(colorScheme == .light ? 0.15 : 0.25))
                    .cornerRadius(6)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(AppLayout.sidebarPadding)
        .frame(minHeight: 40)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusMedium)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
        )
    }

    @ViewBuilder
    private func compactRow<Trailing: View>(icon: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.appFixed(14))
                .foregroundStyle(.secondary)
                .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .center)
            Text(title)
                .font(.appFixed(14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .padding(AppLayout.sidebarPadding)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadiusMedium)
                .fill(Color.appBackgroundControl(isLight: colorScheme == .light))
        )
    }

    private var themeButton: some View {
        Button(action: {
            if viewModel.isPracticeSessionActive {
                viewModel.pendingSidebarAction = .cycleTheme
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appearanceManager.cycleMode()
                }
            }
        }) {
            compactRow(icon: appearanceManager.mode.icon, title: appearanceManager.mode.rawValue) {
                Image(systemName: "chevron.right")
                    .font(.appFixed(12))
                    .foregroundStyle(.tertiary)
                    .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }

    private var reviewReminderRow: some View {
        compactRow(icon: "bell.badge.fill", title: "Nhắc ôn") {
            HStack(spacing: 6) {
                Menu {
                    ForEach(0..<24, id: \.self) { h in
                        Section {
                            ForEach([0, 15, 30, 45], id: \.self) { m in
                                Button(String(format: "%d:%02d", h, m)) {
                                    reminderHour = h
                                    reminderMinute = m
                                    ReviewReminderManager.reminderHour = h
                                    ReviewReminderManager.reminderMinute = m
                                    if ReviewReminderManager.isEnabled {
                                        ReviewReminderManager.scheduleReminder()
                                    }
                                }
                            }
                        } header: { Text("\(h) giờ") }
                    }
                } label: {
                    Text(String(format: "%d:%02d", reminderHour, reminderMinute))
                        .font(.appFixed(14))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                Toggle("", isOn: $reviewReminderEnabled)
                    .labelsHidden()
                    .onChange(of: reviewReminderEnabled) { _, new in
                        ReviewReminderManager.isEnabled = new
                    }
            }
        }
        .accessibilityLabel("Nhắc ôn tập")
        .onAppear {
            reminderHour = ReviewReminderManager.reminderHour
            reminderMinute = ReviewReminderManager.reminderMinute
        }
    }

    private var practiceSoundRow: some View {
        compactRow(icon: "speaker.wave.2.fill", title: "Âm thanh ôn") {
            Toggle("", isOn: $practiceSoundEnabled)
                .labelsHidden()
                .onChange(of: practiceSoundEnabled) { _, new in
                    SoundManager.practiceSoundEnabled = new
                }
        }
        .accessibilityLabel("Âm thanh luyện tập")
    }

    private var keyboardShortcutsButton: some View {
        Button(action: {
            if viewModel.isPracticeSessionActive { viewModel.pendingSidebarAction = .showKeyboardShortcuts }
            else { viewModel.showKeyboardShortcutsSheet = true }
        }) {
            compactRow(icon: "keyboard", title: "Phím tắt") {
                Image(systemName: "chevron.right")
                    .font(.appFixed(12))
                    .foregroundStyle(.tertiary)
                    .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }

    private var speechAccentButton: some View {
        Button(action: {
            if viewModel.isPracticeSessionActive { viewModel.pendingSidebarAction = .showSpeechAccent }
            else { viewModel.showSpeechAccentSheet = true }
        }) {
            compactRow(icon: "speaker.wave.2", title: "Giọng đọc (EN)") {
                Image(systemName: "chevron.right")
                    .font(.appFixed(12))
                    .foregroundStyle(.tertiary)
                    .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }

    private var strokeDrawButton: some View {
        Button(action: {
            if viewModel.isPracticeSessionActive { viewModel.pendingSidebarAction = .showStrokeDraw }
            else { viewModel.showStrokeDrawSuggestSheet = true }
        }) {
            compactRow(icon: "pencil.and.outline", title: "Vẽ nét → từ") {
                Image(systemName: "chevron.right")
                    .font(.appFixed(12))
                    .foregroundStyle(.tertiary)
                    .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }

    private var backupRestoreButton: some View {
        Button(action: {
            if viewModel.isPracticeSessionActive { viewModel.pendingSidebarAction = .showBackupRestore }
            else { viewModel.showBackupRestoreSheet = true }
        }) {
            compactRow(icon: "externaldrive.fill", title: "Sao lưu") {
                Image(systemName: "chevron.right")
                    .font(.appFixed(12))
                    .foregroundStyle(.tertiary)
                    .frame(width: AppLayout.sidebarIconAreaWidth, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .cursor(.pointingHand)
    }
}

