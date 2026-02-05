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
    
    private var sectionBorder: Color {
        Color(nsColor: .separatorColor).opacity(colorScheme == .dark ? 0.6 : 0.8)
    }
    
    private var sectionBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Header Section
                VStack(spacing: 16) {
                    HStack {
                        Text("Thống kê học tập")
                            .scaledFont(26)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Spacer()
                        Picker("", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionBackground)
                .overlay(alignment: .bottom) {
                    Divider()
                        .background(sectionBorder)
                }
                
                if let stats = statistics {
                    VStack(spacing: 0) {
                        // MARK: - Section 1: Overview Cards
                        StatisticsSection(title: "Tổng quan", icon: "chart.pie.fill") {
                            overviewCards(stats: stats)
                        }
                        
                        Divider()
                            .background(sectionBorder)
                            .padding(.horizontal, 24)
                        
                        // MARK: - Section 2: Progress Chart
                        StatisticsSection(title: "Tiến độ theo thời gian", icon: "chart.bar.fill") {
                            progressChart(stats: stats)
                        }
                        
                        Divider()
                            .background(sectionBorder)
                            .padding(.horizontal, 24)
                        
                        // MARK: - Section 3: Accuracy by Topic
                        StatisticsSection(title: "Độ chính xác theo chủ đề", icon: "book.fill") {
                            accuracyByTopic(stats: stats)
                        }
                        
                        Divider()
                            .background(sectionBorder)
                            .padding(.horizontal, 24)
                        
                        // MARK: - Section 4: Accuracy by Subject
                        StatisticsSection(title: "Độ chính xác theo môn học", icon: "folder.fill") {
                            accuracyBySubject(stats: stats)
                        }
                    }
                    .background(Color(nsColor: .windowBackgroundColor))
                } else {
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Đang tải thống kê...")
                            .scaledFont(14)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                    .padding(.top, 40)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { loadStatistics() }
        .onChange(of: selectedTimeRange) { _, _ in loadStatistics() }
    }
    
    // MARK: - Overview Cards
    private func overviewCards(stats: LearningStatistics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            StatCard(
                title: "Tổng từ",
                value: "\(stats.totalFlashcards)",
                icon: "book.fill",
                color: .blue
            )
            StatCard(
                title: "Đã học",
                value: "\(stats.learnedFlashcards)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            StatCard(
                title: "Đã thuộc",
                value: "\(stats.masteredFlashcards)",
                icon: "star.fill",
                color: .orange
            )
            StatCard(
                title: "Cần ôn",
                value: "\(stats.dueFlashcards)",
                icon: "clock.fill",
                color: .red
            )
        }
        .padding(20)
    }
    
    // MARK: - Progress Chart
    private func progressChart(stats: LearningStatistics) -> some View {
        let filteredHistory = filterHistory(stats.practiceHistory)
        
        return Group {
            if filteredHistory.isEmpty {
                ContentUnavailableView(
                    "Chưa có dữ liệu",
                    systemImage: "chart.bar.doc.horizontal",
                    description: Text("Luyện tập theo thời gian đã chọn để xem biểu đồ")
                )
                .frame(minHeight: 200)
                .padding(20)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(filteredHistory.prefix(12)) { day in
                        HStack(spacing: 16) {
                            Text(day.date, style: .date)
                                .scaledFont(13)
                                .foregroundStyle(.secondary)
                                .frame(width: 100, alignment: .leading)
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 10)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.gradient)
                                        .frame(width: max(0, geometry.size.width * CGFloat(day.accuracy)), height: 10)
                                }
                            }
                            .frame(height: 10)
                            Text("\(Int(day.accuracy * 100))%")
                                .scaledFont(13)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .frame(width: 44, alignment: .trailing)
                        }
                        if day.id != filteredHistory.prefix(12).last?.id {
                            Divider()
                                .padding(.leading, 116)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Accuracy by Topic
    private func accuracyByTopic(stats: LearningStatistics) -> some View {
        Group {
            if stats.accuracyByTopic.isEmpty {
                ContentUnavailableView(
                    "Chưa có dữ liệu",
                    systemImage: "book.closed",
                    description: Text("Bắt đầu luyện tập để xem độ chính xác theo chủ đề")
                )
                .frame(minHeight: 180)
                .padding(20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(Array(stats.accuracyByTopic.sorted(by: { $0.value > $1.value }).prefix(12)), id: \.key) { topicId, accuracy in
                            if let topic = findTopic(id: topicId) {
                                VStack(spacing: 12) {
                                    Text(topic.name)
                                        .scaledFont(12)
                                        .fontWeight(.medium)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 100)
                                    ZStack {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                                            .frame(width: 56, height: 56)
                                        Circle()
                                            .trim(from: 0, to: accuracy)
                                            .stroke(
                                                accuracy >= 0.7 ? Color.green : accuracy >= 0.5 ? Color.orange : Color.red,
                                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                            )
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 56, height: 56)
                                        Text("\(Int(accuracy * 100))%")
                                            .scaledFont(13)
                                            .fontWeight(.bold)
                                    }
                                }
                                .padding(14)
                                .frame(width: 130)
                                .background(Color(nsColor: .windowBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(sectionBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Accuracy by Subject
    private func accuracyBySubject(stats: LearningStatistics) -> some View {
        Group {
            if stats.accuracyBySubject.isEmpty {
                ContentUnavailableView(
                    "Chưa có dữ liệu",
                    systemImage: "folder",
                    description: Text("Bắt đầu luyện tập để xem độ chính xác theo môn học")
                )
                .frame(minHeight: 180)
                .padding(20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(stats.accuracyBySubject.sorted(by: { $0.value > $1.value })), id: \.key) { subjectId, accuracy in
                        if let subject = viewModel.subjects.first(where: { $0.id == subjectId }) {
                            HStack(spacing: 16) {
                                Image(systemName: subject.icon)
                                    .scaledFont(18)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, alignment: .center)
                                Text(subject.name)
                                    .scaledFont(14)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(Int(accuracy * 100))%")
                                    .scaledFont(14)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(accuracy >= 0.7 ? .green : accuracy >= 0.5 ? .orange : .red)
                                    .frame(width: 44, alignment: .trailing)
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(height: 6)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(accuracy >= 0.7 ? Color.green : accuracy >= 0.5 ? Color.orange : Color.red)
                                            .frame(width: geometry.size.width * CGFloat(accuracy), height: 6)
                                    }
                                }
                                .frame(width: 80, height: 6)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(nsColor: .windowBackgroundColor))
                            
                            if subjectId != Array(stats.accuracyBySubject.sorted(by: { $0.value > $1.value })).last?.key {
                                Divider()
                                    .background(sectionBorder)
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
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
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme
    
    private var borderColor: Color {
        Color(nsColor: .separatorColor).opacity(colorScheme == .dark ? 0.5 : 0.7)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .scaledFont(14)
                    .foregroundStyle(.secondary)
                Text(title)
                    .scaledFont(18)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            content()
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: icon)
                    .scaledFont(22)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .scaledFont(28)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(title)
                .scaledFont(13)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}
