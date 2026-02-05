//
//  StatisticsDashboardView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI

struct StatisticsDashboardView: View {
    @ObservedObject var viewModel: ContentViewModel
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var statistics: LearningStatistics?
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "Tuần"
        case month = "Tháng"
        case all = "Tất cả"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Thống kê học tập")
                        .scaledFont(28)
                        .fontWeight(.bold)
                    Spacer()
                    Picker("", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                if let stats = statistics {
                    // Overview Cards
                    overviewCards(stats: stats)
                    
                    // Progress Chart
                    progressChart(stats: stats)
                    
                    // Accuracy by Topic
                    accuracyByTopic(stats: stats)
                    
                    // Accuracy by Subject
                    accuracyBySubject(stats: stats)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 400)
                }
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            loadStatistics()
        }
        .onChange(of: selectedTimeRange) { _, _ in
            loadStatistics()
        }
    }
    
    private func overviewCards(stats: LearningStatistics) -> some View {
        HStack(spacing: 16) {
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
                color: .yellow
            )
            
            StatCard(
                title: "Cần ôn",
                value: "\(stats.dueFlashcards)",
                icon: "clock.fill",
                color: .orange
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func progressChart(stats: LearningStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tiến độ theo thời gian")
                .scaledFont(20)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            let filteredHistory = filterHistory(stats.practiceHistory)
            
            // Simple bar chart using SwiftUI
            VStack(alignment: .leading, spacing: 8) {
                ForEach(filteredHistory.prefix(10)) { day in
                    HStack(spacing: 12) {
                        Text(day.date, style: .date)
                            .scaledFont(12)
                            .frame(width: 100, alignment: .leading)
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * CGFloat(day.accuracy), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        Text("\(Int(day.accuracy * 100))%")
                            .scaledFont(12)
                            .fontWeight(.medium)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }
    
    private func accuracyByTopic(stats: LearningStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Độ chính xác theo chủ đề")
                .scaledFont(20)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            if stats.accuracyByTopic.isEmpty {
                ContentUnavailableView(
                    "Chưa có dữ liệu",
                    systemImage: "chart.bar",
                    description: Text("Bắt đầu luyện tập để xem thống kê")
                )
                .frame(height: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(stats.accuracyByTopic.sorted(by: { $0.value > $1.value }).prefix(10)), id: \.key) { topicId, accuracy in
                            if let topic = findTopic(id: topicId) {
                                VStack(spacing: 8) {
                                    Text(topic.name)
                                        .scaledFont(12)
                                        .lineLimit(1)
                                        .frame(maxWidth: 120)
                                    
                                    ZStack {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                            .frame(width: 60, height: 60)
                                        Circle()
                                            .trim(from: 0, to: accuracy)
                                            .stroke(
                                                accuracy >= 0.7 ? Color.green : accuracy >= 0.5 ? Color.orange : Color.red,
                                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                            )
                                            .rotationEffect(.degrees(-90))
                                            .frame(width: 60, height: 60)
                                        
                                        Text("\(Int(accuracy * 100))%")
                                            .scaledFont(14)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding()
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private func accuracyBySubject(stats: LearningStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Độ chính xác theo môn học")
                .scaledFont(20)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            if stats.accuracyBySubject.isEmpty {
                ContentUnavailableView(
                    "Chưa có dữ liệu",
                    systemImage: "chart.bar",
                    description: Text("Bắt đầu luyện tập để xem thống kê")
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(stats.accuracyBySubject.sorted(by: { $0.value > $1.value })), id: \.key) { subjectId, accuracy in
                        if let subject = viewModel.subjects.first(where: { $0.id == subjectId }) {
                            HStack {
                                Image(systemName: subject.icon)
                                    .scaledFont(20)
                                    .frame(width: 30)
                                Text(subject.name)
                                    .scaledFont(16)
                                Spacer()
                                Text("\(Int(accuracy * 100))%")
                                    .scaledFont(16)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(accuracy >= 0.7 ? .green : accuracy >= 0.5 ? .orange : .red)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 8)
                                        Rectangle()
                                            .fill(accuracy >= 0.7 ? Color.green : accuracy >= 0.5 ? Color.orange : Color.red)
                                            .frame(width: geometry.size.width * CGFloat(accuracy), height: 8)
                                    }
                                }
                                .frame(width: 100, height: 8)
                            }
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func filterHistory(_ history: [DailyPractice]) -> [DailyPractice] {
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate: Date
        
        switch selectedTimeRange {
        case .week:
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            cutoffDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .all:
            return history
        }
        
        return history.filter { $0.date >= cutoffDate }
    }
    
    private func findTopic(id: Int) -> Topic? {
        for subject in viewModel.subjects {
            if let topic = subject.topics.first(where: { $0.id == id }) {
                return topic
            }
        }
        return nil
    }
    
    private func loadStatistics() {
        statistics = DatabaseManager.shared.getLearningStatistics()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var fontSizeManager: FontSizeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .scaledFont(24)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .scaledFont(32)
                .fontWeight(.bold)
            
            Text(title)
                .scaledFont(14)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}
