//
//  StatisticsView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var hydrationHistory: HydrationHistory
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with streak information
                    streakHeader
                    
                    // Time range selector
                    timeRangeSelector
                    
                    // Main statistics content
                    statisticsContent
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportData()
                    }
                }
            }
        }
    }
    
    // MARK: - Streak Header
    private var streakHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(hydrationHistory.currentStreak) days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Longest Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(hydrationHistory.longestStreak) days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            // Progress bar for current streak
            if hydrationHistory.currentStreak > 0 {
                ProgressView(value: Double(hydrationHistory.currentStreak), total: Double(max(hydrationHistory.currentStreak, 7)))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    // MARK: - Statistics Content
    private var statisticsContent: some View {
        VStack(spacing: 20) {
            switch selectedTimeRange {
            case .week:
                weeklyStatistics
            case .month:
                monthlyStatistics
            case .year:
                yearlyStatistics
            }
        }
    }
    
    // MARK: - Weekly Statistics
    private var weeklyStatistics: some View {
        VStack(spacing: 16) {
            // Weekly chart
            weeklyChart
            
            // Weekly summary cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Total Intake",
                    value: String(format: "%.1fL", weeklyTotalIntake),
                    subtitle: "This week",
                    color: .blue
                )
                
                StatCard(
                    title: "Average Daily",
                    value: String(format: "%.1fL", weeklyAverageIntake),
                    subtitle: "Per day",
                    color: .green
                )
                
                StatCard(
                    title: "Goal Met",
                    value: "\(weeklyGoalMetDays)/7",
                    subtitle: "Days this week",
                    color: .orange
                )
                
                StatCard(
                    title: "Success Rate",
                    value: String(format: "%.0f%%", weeklySuccessRate),
                    subtitle: "Goal achievement",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Monthly Statistics
    private var monthlyStatistics: some View {
        VStack(spacing: 16) {
            // Monthly chart
            monthlyChart
            
            // Monthly summary cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Total Intake",
                    value: String(format: "%.1fL", monthlyTotalIntake),
                    subtitle: "This month",
                    color: .blue
                )
                
                StatCard(
                    title: "Average Daily",
                    value: String(format: "%.1fL", monthlyAverageIntake),
                    subtitle: "Per day",
                    color: .green
                )
                
                StatCard(
                    title: "Goal Met",
                    value: "\(monthlyGoalMetDays)/\(monthlyTotalDays)",
                    subtitle: "Days this month",
                    color: .orange
                )
                
                StatCard(
                    title: "Longest Streak",
                    value: "\(monthlyLongestStreak) days",
                    subtitle: "This month",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Yearly Statistics
    private var yearlyStatistics: some View {
        VStack(spacing: 16) {
            // Yearly chart
            yearlyChart
            
            // Yearly summary
            yearlySummary
        }
    }
    
    // MARK: - Charts
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Progress")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(weeklyData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Intake", data.intake)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    
                    RuleMark(y: .value("Goal", 2.5))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for iOS 15
                Text("Charts available in iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Progress")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(monthlyData) { data in
                    LineMark(
                        x: .value("Week", data.week),
                        y: .value("Average", data.average)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .symbol(Circle())
                    
                    AreaMark(
                        x: .value("Week", data.week),
                        y: .value("Average", data.average)
                    )
                    .foregroundStyle(Color.green.opacity(0.1))
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for iOS 15
                Text("Charts available in iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var yearlyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Yearly Overview")
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart(yearlyData) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Total", data.total)
                    )
                    .foregroundStyle(Color.purple.gradient)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for iOS 15
                Text("Charts available in iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Yearly Summary
    private var yearlySummary: some View {
        VStack(spacing: 16) {
            Text("Yearly Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Total Intake",
                    value: String(format: "%.0fL", yearlyTotalIntake),
                    subtitle: "This year",
                    color: .blue
                )
                
                StatCard(
                    title: "Average Daily",
                    value: String(format: "%.1fL", yearlyAverageIntake),
                    subtitle: "Per day",
                    color: .green
                )
                
                StatCard(
                    title: "Goal Met",
                    value: "\(yearlyGoalMetDays) days",
                    subtitle: "This year",
                    color: .orange
                )
                
                StatCard(
                    title: "Success Rate",
                    value: String(format: "%.0f%%", yearlySuccessRate),
                    subtitle: "Goal achievement",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    private var weeklyData: [ChartData] {
        let weekRecords = hydrationHistory.getWeeklyStats(for: 1)
        return weekRecords.enumerated().map { index, stat in
            ChartData(
                day: "Week \(index + 1)",
                intake: stat.averageIntake,
                week: "Week \(index + 1)",
                average: stat.averageIntake,
                month: "Month \(index + 1)",
                total: stat.totalIntake
            )
        }
    }
    
    private var monthlyData: [ChartData] {
        let monthStats = hydrationHistory.getMonthlyStats(for: 6)
        return monthStats.enumerated().map { index, stat in
            ChartData(
                day: "Month \(index + 1)",
                intake: stat.averageIntake,
                week: "Month \(index + 1)",
                average: stat.averageIntake,
                month: "Month \(index + 1)",
                total: stat.totalIntake
            )
        }
    }
    
    private var yearlyData: [ChartData] {
        let yearStats = hydrationHistory.getMonthlyStats(for: 12)
        return yearStats.enumerated().map { index, stat in
            ChartData(
                day: "Month \(index + 1)",
                intake: stat.totalIntake,
                week: "Month \(index + 1)",
                average: stat.averageIntake,
                month: "Month \(index + 1)",
                total: stat.totalIntake
            )
        }
    }
    
    private var weeklyTotalIntake: Double {
        hydrationHistory.getWeeklyStats(for: 1).first?.totalIntake ?? 0
    }
    
    private var weeklyAverageIntake: Double {
        hydrationHistory.getWeeklyStats(for: 1).first?.averageIntake ?? 0
    }
    
    private var weeklyGoalMetDays: Int {
        hydrationHistory.getWeeklyStats(for: 1).first?.goalMetDays ?? 0
    }
    
    private var weeklySuccessRate: Double {
        hydrationHistory.getWeeklyStats(for: 1).first?.goalMetPercentage ?? 0
    }
    
    private var monthlyTotalIntake: Double {
        hydrationHistory.getMonthlyStats(for: 1).first?.totalIntake ?? 0
    }
    
    private var monthlyAverageIntake: Double {
        hydrationHistory.getMonthlyStats(for: 1).first?.averageIntake ?? 0
    }
    
    private var monthlyGoalMetDays: Int {
        hydrationHistory.getMonthlyStats(for: 1).first?.goalMetDays ?? 0
    }
    
    private var monthlyTotalDays: Int {
        hydrationHistory.getMonthlyStats(for: 1).first?.totalDays ?? 0
    }
    
    private var monthlyLongestStreak: Int {
        hydrationHistory.getMonthlyStats(for: 1).first?.longestStreak ?? 0
    }
    
    private var yearlyTotalIntake: Double {
        hydrationHistory.getMonthlyStats(for: 12).reduce(0) { $0 + $1.totalIntake }
    }
    
    private var yearlyAverageIntake: Double {
        let totalDays = hydrationHistory.getMonthlyStats(for: 12).reduce(0) { $0 + $1.totalDays }
        return totalDays > 0 ? yearlyTotalIntake / Double(totalDays) : 0
    }
    
    private var yearlyGoalMetDays: Int {
        hydrationHistory.getMonthlyStats(for: 12).reduce(0) { $0 + $1.goalMetDays }
    }
    
    private var yearlySuccessRate: Double {
        let totalDays = hydrationHistory.getMonthlyStats(for: 12).reduce(0) { $0 + $1.totalDays }
        return totalDays > 0 ? (Double(yearlyGoalMetDays) / Double(totalDays)) * 100 : 0
    }
    
    // MARK: - Helper Methods
    private func exportData() {
        // Data export functionality placeholder
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Chart Data Model
struct ChartData: Identifiable {
    let id = UUID()
    let day: String
    let intake: Double
    let week: String
    let average: Double
    let month: String
    let total: Double
}

// MARK: - Preview
#Preview {
    StatisticsView()
        .environmentObject(WaterManager())
        .environmentObject(LocationManager())
        .environmentObject(WeatherManager())
        .environmentObject(NotificationManager.shared)
        .environmentObject(PerformanceMonitor.shared)
        .environmentObject(HydrationHistory())
        .environmentObject(AchievementManager())
        .environmentObject(SmartReminderManager())
} 