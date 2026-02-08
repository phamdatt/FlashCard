//
//  StatisticsDashboardView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import AppKit

// MARK: - Dashboard palette (dùng ThemeColors + gradient accents)
private extension Color {
    static var statsBackgroundDark: Color { .appDarkBackground }
    static var statsCardDark: Color { .appCardBackgroundDark }
    static let statsMutedDark = Color.white.opacity(0.06)
    static var statsBorderDark: Color { .appBorderDark }
    static let progressGradientStart = Color(red: 0.25, green: 0.47, blue: 1.0)     // soft blue
    static let progressGradientEnd = Color(red: 0.35, green: 0.65, blue: 1.0)       // cyan-blue
    static let accuracyGradientHigh = Color(red: 0.2, green: 0.75, blue: 0.55)      // mint
    static let accuracyGradientLow = Color(red: 0.15, green: 0.55, blue: 0.45)     // teal
    static let accuracyGradientMid = Color(red: 0.95, green: 0.7, blue: 0.2)       // amber
    static let accuracyGradientNeeds = Color(red: 0.95, green: 0.4, blue: 0.35)   // soft red
}

struct StatisticsDashboardView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var statistics: LearningStatistics?
    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "Tuần"
        case month = "Tháng"
        case all = "Tất cả"
    }

    private let cardRadius: CGFloat = 16
    private let sectionPadding: CGFloat = 28
    private let contentMinHeight: CGFloat = 220
    private let barChartHeight: CGFloat = 200
    private let topicCardFixedHeight: CGFloat = 100

    private var isDark: Bool { colorScheme == .dark }
    private var sectionBorder: Color {
        Color.appBorder(isLight: !isDark)
    }
    private var cardBackground: Color {
        isDark ? .statsCardDark : Color.appCardBackground(isLight: true)
    }
    private var pageBackground: Color {
        Color.appBackgroundPage(isLight: !isDark)
    }
    private var mutedBackground: Color {
        isDark ? .statsMutedDark : Color.gray.opacity(0.08)
    }
    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [.progressGradientStart, .progressGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    private func accuracyGradient(for value: Double) -> LinearGradient {
        let (start, end) = value >= 0.7
            ? (Color.accuracyGradientHigh, Color.accuracyGradientLow)
            : value >= 0.5
                ? (Color.accuracyGradientMid, Color.accuracyGradientMid.opacity(0.85))
                : (Color.accuracyGradientNeeds, Color.accuracyGradientNeeds.opacity(0.85))
        return LinearGradient(colors: [start, end], startPoint: .leading, endPoint: .trailing)
    }

    private func accentColor(for accuracy: Double) -> Color {
        if accuracy >= 0.7 { return .accuracyGradientHigh }
        if accuracy >= 0.5 { return .accuracyGradientMid }
        return .accuracyGradientNeeds
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                if let stats = statistics {
                    VStack(spacing: 0) {
                        StatisticsSection(title: "Tổng quan", icon: "chart.pie.fill", minHeight: nil) {
                            overviewCards(stats: stats)
                        }
                        sectionDivider
                        StatisticsSection(title: "Tiến độ theo thời gian", icon: "chart.bar.fill", minHeight: contentMinHeight) {
                            progressBarChart(stats: stats)
                        }
                        sectionDivider
                        StatisticsSection(title: "Độ chính xác theo chủ đề", icon: "book.fill", minHeight: contentMinHeight) {
                            accuracyByTopic(stats: stats)
                        }
                        sectionDivider
                        StatisticsSection(title: "Độ chính xác theo môn học", icon: "folder.fill", minHeight: contentMinHeight) {
                            accuracyBySubject(stats: stats)
                        }
                    }
                    .background(cardBackground)
                } else {
                    loadingPlaceholder
                }
            }
            .padding(.bottom, 36)
        }
        .background(pageBackground)
        .onAppear { loadStatistics() }
        .onChange(of: selectedTimeRange) { _, _ in loadStatistics() }
    }

    private var headerSection: some View {
        HStack {
            Text("Thống kê học tập")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
            .frame(width: 220)
        }
        .padding(sectionPadding)
        .background(Color.appBackgroundControl(isLight: !isDark))
        .overlay(alignment: .bottom) {
            Rectangle().fill(sectionBorder).frame(height: 1)
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(sectionBorder)
            .frame(height: 1)
            .padding(.horizontal, sectionPadding)
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.2)
            Text("Đang tải thống kê...")
                .scaledFont(.sm)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 360)
        .padding(.top, 48)
    }

    // MARK: - Overview Cards (larger, 2x2 grid)
    private func overviewCards(stats: LearningStatistics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ], spacing: 20) {
            StatCard(title: "Tổng từ", value: "\(stats.totalFlashcards)", icon: "book.fill", gradient: [.progressGradientStart, .progressGradientEnd])
            StatCard(title: "Đã học", value: "\(stats.learnedFlashcards)", icon: "checkmark.circle.fill", gradient: [.accuracyGradientHigh, .accuracyGradientLow])
            StatCard(title: "Đã thuộc", value: "\(stats.masteredFlashcards)", icon: "star.fill", gradient: [.accuracyGradientMid, .accuracyGradientMid.opacity(0.8)])
            StatCard(title: "Cần ôn", value: "\(stats.dueFlashcards)", icon: "clock.fill", gradient: [.accuracyGradientNeeds, .accuracyGradientNeeds.opacity(0.8)])
        }
        .padding(sectionPadding)
    }

    // MARK: - Bar Chart (vertical bars by day – gradient, rounded top, consistent spacing)
    private func progressBarChart(stats: LearningStatistics) -> some View {
        let filtered = filterHistory(stats.practiceHistory)
        let displayData = Array(filtered.prefix(14))
        let maxAcc = displayData.map(\.accuracy).max() ?? 1.0
        let barVerticalGradient = LinearGradient(
            colors: [.progressGradientEnd, .progressGradientStart],
            startPoint: .bottom,
            endPoint: .top
        )

        return Group {
            if displayData.isEmpty {
                emptyState(
                    title: "Chưa có dữ liệu",
                    icon: "chart.bar.doc.horizontal",
                    message: "Luyện tập theo thời gian đã chọn để xem biểu đồ"
                )
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    // Y-axis hint
                    HStack(alignment: .bottom, spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("100%").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                            Text("0%").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                        }
                        .frame(height: barChartHeight + 22)
                        .padding(.trailing, 8)
                        // Bars with fixed max width so chart doesn’t look stretched
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(displayData) { day in
                                VStack(spacing: 6) {
                                    Text("\(Int(day.accuracy * 100))%")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(barVerticalGradient)
                                        .frame(height: max(6, barChartHeight * CGFloat(day.accuracy / max(0.01, maxAcc))))
                                        .frame(maxWidth: .infinity)
                                        .shadow(color: .progressGradientStart.opacity(0.35), radius: 4, x: 0, y: 2)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minWidth: 36)
                            }
                        }
                        .frame(height: barChartHeight + 26)
                    }
                    // X-axis labels
                    HStack(spacing: 12) {
                        ForEach(displayData) { day in
                            Text(day.date, format: .dateTime.day().month(.abbreviated))
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                                .frame(minWidth: 36)
                        }
                    }
                }
                .padding(sectionPadding)
            }
        }
        .frame(minHeight: contentMinHeight)
    }

    // MARK: - Accuracy by Topic (grid)
    private func accuracyByTopic(stats: LearningStatistics) -> some View {
        let sorted = stats.accuracyByTopic.sorted(by: { $0.value > $1.value })
        return Group {
            if sorted.isEmpty {
                emptyState(
                    title: "Chưa có dữ liệu",
                    icon: "book.closed",
                    message: "Bắt đầu luyện tập để xem độ chính xác theo chủ đề"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 180), spacing: 14),
                    GridItem(.adaptive(minimum: 180), spacing: 14),
                    GridItem(.adaptive(minimum: 180), spacing: 14)
                ], spacing: 14) {
                    ForEach(sorted, id: \.key) { topicId, accuracy in
                        if let topic = findTopic(id: topicId) {
                            topicAccuracyCard(topicName: topic.name, accuracy: accuracy)
                        }
                    }
                }
                .padding(sectionPadding)
            }
        }
        .frame(minHeight: contentMinHeight)
    }

    private func topicAccuracyCard(topicName: String, accuracy: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(topicName)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .lineLimit(2)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 40)
            HStack(spacing: 10) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(mutedBackground).frame(height: 8)
                        Capsule()
                            .fill(accuracyGradient(for: accuracy))
                            .frame(width: max(0, g.size.width * accuracy), height: 8)
                    }
                }
                .frame(height: 8)
                Text("\(Int(accuracy * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accentColor(for: accuracy)))
                    .clipShape(Capsule())
            }
        }
        .padding(18)
        .frame(height: topicCardFixedHeight)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
        .overlay(RoundedRectangle(cornerRadius: cardRadius).stroke(sectionBorder, lineWidth: 1))
    }

    // MARK: - Accuracy by Subject
    private func accuracyBySubject(stats: LearningStatistics) -> some View {
        Group {
            if stats.accuracyBySubject.isEmpty {
                emptyState(
                    title: "Chưa có dữ liệu",
                    icon: "folder",
                    message: "Bắt đầu luyện tập để xem độ chính xác theo môn học"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(stats.accuracyBySubject.sorted(by: { $0.value > $1.value })), id: \.key) { subjectId, accuracy in
                        if let subject = viewModel.subjects.first(where: { $0.id == subjectId }) {
                            subjectAccuracyRow(subject: subject, accuracy: accuracy)
                        }
                    }
                }
                .padding(sectionPadding)
            }
        }
        .frame(minHeight: contentMinHeight)
    }

    private func subjectAccuracyRow(subject: Subject, accuracy: Double) -> some View {
        HStack(spacing: 16) {
            Image(systemName: subject.icon)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(accentColor(for: accuracy))
                .frame(width: 32, alignment: .center)
            Text(subject.name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
            Spacer(minLength: 12)
            Text("\(Int(accuracy * 100))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(accentColor(for: accuracy)))
                .clipShape(Capsule())
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(mutedBackground).frame(height: 8)
                    Capsule()
                        .fill(accuracyGradient(for: accuracy))
                        .frame(width: max(0, geometry.size.width * CGFloat(accuracy)), height: 8)
                }
            }
            .frame(width: 120, height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(height: 58)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cardRadius))
        .overlay(RoundedRectangle(cornerRadius: cardRadius).stroke(sectionBorder, lineWidth: 1))
    }

    private func emptyState(title: String, icon: String, message: String) -> some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(message))
            .frame(minHeight: contentMinHeight)
            .padding(sectionPadding)
    }

    private func filterHistory(_ history: [DailyPractice]) -> [DailyPractice] {
        let calendar = Calendar.current
        let now = Date()
        switch selectedTimeRange {
        case .week:
            let cutoff = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return history.filter { $0.date >= cutoff }
        case .month:
            let cutoff = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return history.filter { $0.date >= cutoff }
        case .all:
            return history
        }
    }

    private func findTopic(id: Int) -> Topic? {
        for subject in viewModel.subjects {
            if let topic = subject.topics.first(where: { $0.id == id }) { return topic }
        }
        return nil
    }

    private func loadStatistics() {
        statistics = DatabaseManager.shared.getLearningStatistics()
    }
}

// MARK: - Section Container
private struct StatisticsSection<Content: View>: View {
    let title: String
    let icon: String
    let minHeight: CGFloat?
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    private var sectionBg: Color {
        Color.appBackgroundControl(isLight: colorScheme == .light)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 18)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: minHeight ?? 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionBg)
    }
}

// MARK: - Stat Card (large overview cards with gradient accent)
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme

    private var borderColor: Color {
        Color.appBorder(isLight: colorScheme == .light)
    }
    private var cardBg: Color {
        Color.appCardBackground(isLight: colorScheme == .light)
    }
    private var iconGradient: LinearGradient {
        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(iconGradient)
                Spacer()
            }
            Text(value)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 140)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(borderColor, lineWidth: 1))
    }
}
