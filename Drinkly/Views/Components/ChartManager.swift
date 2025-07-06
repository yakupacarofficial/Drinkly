//
//  ChartManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI
import Charts

/// Manages chart data and visualizations for analytics
@MainActor
class ChartManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var weeklyChartData: [ChartDataPoint] = []
    @Published var monthlyChartData: [ChartDataPoint] = []
    @Published var goalAchievementData: [GoalAchievementPoint] = []
    @Published var trendData: [TrendDataPoint] = []
    
    // MARK: - Private Properties
    private var analyticsManager: AnalyticsManager?
    
    // MARK: - Initialization
    init() {
        setupChartData()
    }
    
    // MARK: - Public Methods
    
    /// Set analytics manager for chart data
    func setAnalyticsManager(_ manager: AnalyticsManager) {
        analyticsManager = manager
        updateChartData()
    }
    
    /// Update all chart data
    func updateChartData() {
        guard let analytics = analyticsManager else { return }
        
        generateWeeklyChartData(from: analytics)
        generateMonthlyChartData(from: analytics)
        generateGoalAchievementData(from: analytics)
        generateTrendData(from: analytics)
    }
    
    /// Get chart data for specific type
    func getChartData(for type: ChartType) -> [ChartDataPoint] {
        switch type {
        case .weekly:
            return weeklyChartData
        case .monthly:
            return monthlyChartData
        case .goalAchievement:
            return goalAchievementData.map { $0.toChartDataPoint() }
        case .trend:
            return trendData.map { $0.toChartDataPoint() }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupChartData() {
        // Initialize with empty data
        weeklyChartData = []
        monthlyChartData = []
        goalAchievementData = []
        trendData = []
    }
    
    private func generateWeeklyChartData(from analytics: AnalyticsManager) {
        weeklyChartData = analytics.weeklyStats.enumerated().map { index, stat in
            ChartDataPoint(
                date: stat.weekStart,
                value: stat.averageDailyIntake,
                label: "Week \(index + 1)",
                color: getColorForValue(stat.averageDailyIntake),
                secondaryValue: Double(stat.goalMetDays),
                secondaryLabel: "Goal Met: \(stat.goalMetDays)/\(stat.totalDays)"
            )
        }
    }
    
    private func generateMonthlyChartData(from analytics: AnalyticsManager) {
        monthlyChartData = analytics.monthlyStats.enumerated().map { index, stat in
            ChartDataPoint(
                date: stat.monthStart,
                value: stat.averageDailyIntake,
                label: getMonthName(from: stat.monthStart),
                color: getColorForValue(stat.averageDailyIntake),
                secondaryValue: Double(stat.goalMetDays),
                secondaryLabel: "Goal Met: \(stat.goalMetDays)/\(stat.totalDays)"
            )
        }
    }
    
    private func generateGoalAchievementData(from analytics: AnalyticsManager) {
        goalAchievementData = analytics.weeklyStats.enumerated().map { index, stat in
            let achievementRate = stat.totalDays > 0 ? Double(stat.goalMetDays) / Double(stat.totalDays) : 0.0
            
            return GoalAchievementPoint(
                date: stat.weekStart,
                achievementRate: achievementRate,
                label: "Week \(index + 1)",
                color: getColorForAchievementRate(achievementRate)
            )
        }
    }
    
    private func generateTrendData(from analytics: AnalyticsManager) {
        let trendAnalysis = analytics.getTrendAnalysis()
        
        trendData = [
            TrendDataPoint(
                date: Date().addingTimeInterval(-7 * 24 * 3600), // 1 week ago
                value: trendAnalysis.olderAverage,
                label: "Previous",
                color: .blue
            ),
            TrendDataPoint(
                date: Date(),
                value: trendAnalysis.recentAverage,
                label: "Current",
                color: getColorForTrend(trendAnalysis.trendDirection)
            )
        ]
    }
    
    private func getColorForValue(_ value: Double) -> Color {
        if value >= 2.5 {
            return .green
        } else if value >= 2.0 {
            return .blue
        } else if value >= 1.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func getColorForAchievementRate(_ rate: Double) -> Color {
        if rate >= 0.8 {
            return .green
        } else if rate >= 0.6 {
            return .blue
        } else if rate >= 0.4 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func getColorForTrend(_ direction: TrendDirection) -> Color {
        switch direction {
        case .improving:
            return .green
        case .declining:
            return .red
        case .stable:
            return .blue
        }
    }
    
    private func getMonthName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Models

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
    let color: Color
    let secondaryValue: Double?
    let secondaryLabel: String?
    
    init(date: Date, value: Double, label: String, color: Color, secondaryValue: Double? = nil, secondaryLabel: String? = nil) {
        self.date = date
        self.value = value
        self.label = label
        self.color = color
        self.secondaryValue = secondaryValue
        self.secondaryLabel = secondaryLabel
    }
}

struct GoalAchievementPoint: Identifiable {
    let id = UUID()
    let date: Date
    let achievementRate: Double
    let label: String
    let color: Color
    
    func toChartDataPoint() -> ChartDataPoint {
        return ChartDataPoint(
            date: date,
            value: achievementRate * 100, // Convert to percentage
            label: label,
            color: color,
            secondaryValue: achievementRate,
            secondaryLabel: "\(Int(achievementRate * 100))%"
        )
    }
}

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
    let color: Color
    
    func toChartDataPoint() -> ChartDataPoint {
        return ChartDataPoint(
            date: date,
            value: value,
            label: label,
            color: color
        )
    }
}

enum ChartType {
    case weekly, monthly, goalAchievement, trend
}

// MARK: - Chart Views

struct WeeklyChartView: View {
    @ObservedObject var chartManager: ChartManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(chartManager.weeklyChartData) { dataPoint in
                BarMark(
                    x: .value("Week", dataPoint.label),
                    y: .value("Intake", dataPoint.value)
                )
                .foregroundStyle(dataPoint.color)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MonthlyChartView: View {
    @ObservedObject var chartManager: ChartManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(chartManager.monthlyChartData) { dataPoint in
                LineMark(
                    x: .value("Month", dataPoint.label),
                    y: .value("Intake", dataPoint.value)
                )
                .foregroundStyle(dataPoint.color)
                .symbol(Circle())
                .symbolSize(50)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GoalAchievementChartView: View {
    @ObservedObject var chartManager: ChartManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Achievement Rate")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(chartManager.goalAchievementData) { dataPoint in
                BarMark(
                    x: .value("Week", dataPoint.label),
                    y: .value("Achievement", dataPoint.achievementRate * 100)
                )
                .foregroundStyle(dataPoint.color)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(value.as(Double.self)?.formatted(.number) ?? "")%")
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TrendChartView: View {
    @ObservedObject var chartManager: ChartManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Improvement Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(chartManager.trendData) { dataPoint in
                BarMark(
                    x: .value("Period", dataPoint.label),
                    y: .value("Average", dataPoint.value)
                )
                .foregroundStyle(dataPoint.color)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 