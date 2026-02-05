//
//  StatisticsDashboardView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import AppKit

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
    
    // Design tokens – consistent across all sections
    private let cardRadius: CGFloat = 12
    private let sectionPadding: CGFloat = 24
    private let contentMinHeight: CGFloat = 200
    private let rowHeight: CGFloat = 44
    private let barHeight: CGFloat = 10
    
    private var sectionBorder: Color {
        Color(nsColor: .separatorColor).opacity(colorScheme == .dark ? 0.4 : 0.6)
    }
    
    private var cardBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }
    
    private var mutedBackground: Color {
        Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.08)
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
                            progressChart(stats: stats)
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
            .padding(.bottom, 32)
        }
        .background(cardBackground)
        .onAppear { loadStatistics() }
        .onChange(of: selectedTimeRange) { _, _ in loadStatistics() }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Thống kê học tập")
                .scaledFont(24)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
        .padding(sectionPadding)
        .background(Color(nsColor: .controlBackgroundColor))
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
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Đang tải thống kê...")
                .scaledFont(14)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 360)
        .padding(.top, 48)
    }
    
    // MARK: - Overview Cards
    private func overviewCards(stats: LearningStatistics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            StatCard(title: "Tổng từ", value: "\(stats.totalFlashcards)", icon: "book.fill", color: .blue)
            StatCard(title: "Đã học", value: "\(stats.learnedFlashcards)", icon: "checkmark.circle.fill", color: .green)
            StatCard(title: "Đã thuộc", value: "\(stats.masteredFlashcards)", icon: "star.fill", color: .orange)
            StatCard(title: "Cần ôn", value: "\(stats.dueFlashcards)", icon: "clock.fill", color: .red)
        }
        .padding(sectionPadding)
    }
    
    // MARK: - Progress Chart
    private func progressChart(stats: LearningStatistics) -> some View {
        let filteredHistory = filterHistory(stats.practiceHistory)
        
        return Group {
            if filteredHistory.isEmpty {
                emptyState(
                    title: "Chưa có dữ liệu",
                    icon: "chart.bar.doc.horizontal",
                    message: "Luyện tập theo thời gian đã chọn để xem biểu đồ"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredHistory.prefix(12).enumerated()), id: \.element.id) { index, day in
                        progressRow(date: day.date, accuracy: day.accuracy)
                        if index < min(11, filteredHistory.count - 1) {
                            Divider().padding(.leading, 120)
                        }
                    }
                }
                .padding(sectionPadding)
            }
        }
        .frame(minHeight: contentMinHeight)
    }
    
    private func progressRow(date: Date, accuracy: Double) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(date, style: .date)
                .scaledFont(13)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(mutedBackground)
                        .frame(height: barHeight)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.85), Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * CGFloat(accuracy)), height: barHeight)
                }
            }
            .frame(height: barHeight)
            Text("\(Int(accuracy * 100))%")
                .scaledFont(12)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.blue))
                .fixedSize(horizontal: true, vertical: true)
        }
        .frame(height: rowHeight)
    }
    
    // MARK: - Accuracy by Topic
    private func accuracyByTopic(stats: LearningStatistics) -> some View {
        Group {
            if stats.accuracyByTopic.isEmpty {
                emptyState(
                    title: "Chưa có dữ liệu",
                    icon: "book.closed",
                    message: "Bắt đầu luyện tập để xem độ chính xác theo chủ đề"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Array(stats.accuracyByTopic.sorted(by: { $0.value > $1.value }).prefix(12)), id: \.key) { topicId, accuracy in
                            if let topic = findTopic(id: topicId) {
                                topicAccuracyCard(topicName: topic.name, accuracy: accuracy)
                            }
                        }
                    }
                    .padding(.horizontal, sectionPadding - 4)
                    .padding(.vertical, 4)
                }
                .padding(.vertical, 8)
            }
        }
        .frame(minHeight: contentMinHeight)
    }
    
    private func topicAccuracyCard(topicName: String, accuracy: Double) -> some View {
        let accent = accuracy >= 0.7 ? Color.green : accuracy >= 0.5 ? Color.orange : Color.red
        return VStack(alignment: .leading, spacing: 12) {
            Text(topicName)
                .scaledFont(13)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 10) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(mutedBackground).frame(height: 8)
                        Capsule().fill(accent).frame(width: max(0, g.size.width * accuracy), height: 8)
                    }
                }
                .frame(height: 8)
                Text("\(Int(accuracy * 100))%")
                    .scaledFont(11)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(accent))
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
        .padding(16)
        .frame(width: 148)
        .frame(minHeight: 88)
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
        let accent = accuracy >= 0.7 ? Color.green : accuracy >= 0.5 ? Color.orange : Color.red
        return HStack(spacing: 16) {
            Image(systemName: subject.icon)
                .scaledFont(16)
                .foregroundStyle(accent)
                .frame(width: 28, alignment: .center)
            Text(subject.name)
                .scaledFont(14)
                .fontWeight(.medium)
            Spacer(minLength: 12)
            Text("\(Int(accuracy * 100))%")
                .scaledFont(12)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(accent))
                .fixedSize(horizontal: true, vertical: true)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(mutedBackground).frame(height: 8)
                    Capsule().fill(accent).frame(width: max(0, geometry.size.width * CGFloat(accuracy)), height: 8)
                }
            }
            .frame(width: 110, height: 8)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(height: 56)
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
    
    private var borderColor: Color {
        Color(nsColor: .separatorColor).opacity(colorScheme == .dark ? 0.4 : 0.6)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .scaledFont(14)
                    .foregroundStyle(.secondary)
                Text(title)
                    .scaledFont(17)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: minHeight ?? 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @Environment(\.colorScheme) private var colorScheme
    
    private var borderColor: Color {
        Color(nsColor: .separatorColor).opacity(colorScheme == .dark ? 0.4 : 0.6)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .scaledFont(20)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .scaledFont(26)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(title)
                .scaledFont(13)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 118)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
    }
}
