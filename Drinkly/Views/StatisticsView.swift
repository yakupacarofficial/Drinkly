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
    @State private var selectedTimeRange: TimeRange = .daily
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    enum TimeRange: String, CaseIterable {
        case daily = "Daily"
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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
        .cornerRadius(16)
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Statistics Content
    private var statisticsContent: some View {
        VStack(spacing: 20) {
            switch selectedTimeRange {
            case .daily:
                dailyStatistics
            case .week:
                weeklyStatistics
            case .month:
                monthlyStatistics
            case .year:
                yearlyStatistics
            }
        }
    }
    
    // MARK: - Daily Statistics
    private var dailyStatistics: some View {
        VStack(spacing: 20) {
            // Daily chart
            dailyChart
            
            // Daily summary cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Total Intake",
                    value: String(format: "%.1fL", dailyTotalIntake),
                    subtitle: "Today",
                    color: .blue
                )
                
                StatCard(
                    title: "Goal Progress",
                    value: String(format: "%.0f%%", dailyGoalProgress),
                    subtitle: "Target: 2.5L",
                    color: .green
                )
                
                StatCard(
                    title: "Drinks Today",
                    value: "\(dailyDrinkCount)",
                    subtitle: "Total drinks",
                    color: .orange
                )
                
                StatCard(
                    title: "Average per Drink",
                    value: String(format: "%.0fml", dailyAveragePerDrink),
                    subtitle: "Per drink",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Weekly Statistics
    private var weeklyStatistics: some View {
        VStack(spacing: 20) {
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
        VStack(spacing: 20) {
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
        VStack(spacing: 20) {
            // Yearly chart
            yearlyChart
            
            // Yearly summary
            yearlySummary
        }
    }
    
    // MARK: - Charts
    private var dailyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Water Intake")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(dailyData) { data in
                    BarMark(
                        x: .value("Hour", data.hour),
                        y: .value("Intake", data.intake)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                    
                    RuleMark(y: .value("Goal", 2.5))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            Text("\(value.as(Double.self)?.formatted(.number.precision(.fractionLength(1))) ?? "")L")
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)h")
                        }
                    }
                }
            } else {
                // Fallback for iOS 15
                Text("Charts available in iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Water Intake")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(weeklyData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Intake", data.intake)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .cornerRadius(4)
                    
                    RuleMark(y: .value("Goal", 2.5))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            Text("\(value.as(Double.self)?.formatted(.number.precision(.fractionLength(1))) ?? "")L")
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
            } else {
                // Fallback for iOS 15
                Text("Charts available in iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Water Intake")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(monthlyData) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Intake", data.intake)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            Text("\(value.as(Double.self)?.formatted(.number.precision(.fractionLength(0))) ?? "")L")
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
            } else {
                // Fallback for iOS 15
                Text("Charts available in iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var yearlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yearly Water Intake")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(yearlyData) { data in
                    BarMark(
                        x: .value("Year", data.year),
                        y: .value("Intake", data.intake)
                    )
                    .foregroundStyle(Color.purple.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            Text("\(value.as(Double.self)?.formatted(.number.precision(.fractionLength(0))) ?? "")L")
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                    }
                }
            } else {
                // Fallback for iOS 15
                Text("Charts available in iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
    private var dailyData: [HourlyChartData] {
        let today = Date()
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: today)
        
        var hourlyData: [HourlyChartData] = []
        
        for hour in 0..<24 {
            let hourDate = calendar.date(byAdding: .hour, value: hour, to: dayStart) ?? today
            let nextHourDate = calendar.date(byAdding: .hour, value: 1, to: hourDate) ?? today
            
            let hourRecords = hydrationHistory.getRecords(for: DateInterval(start: hourDate, end: nextHourDate))
            let totalIntake = hourRecords.reduce(0) { $0 + $1.totalIntake }
            
            hourlyData.append(HourlyChartData(
                hour: hour,
                intake: totalIntake
            ))
        }
        
        return hourlyData
    }
    
    private var weeklyData: [DailyChartData] {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return []
        }
        
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? today
        let weekRecords = hydrationHistory.getRecords(for: DateInterval(start: weekStart, end: weekEnd))
        
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var chartData: [DailyChartData] = []
        
        for (index, dayName) in dayNames.enumerated() {
            let dayDate = calendar.date(byAdding: .day, value: index, to: weekStart) ?? today
            let dayRecord = weekRecords.first { Calendar.current.isDate($0.date, inSameDayAs: dayDate) }
            let intake = dayRecord?.totalIntake ?? 0
            
            chartData.append(DailyChartData(
                day: dayName,
                intake: intake
            ))
        }
        
        return chartData
    }
    
    private var monthlyData: [MonthlyChartData] {
        let calendar = Calendar.current
        let today = Date()
        let yearStart = calendar.dateInterval(of: .year, for: today)?.start ?? today
        
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        var chartData: [MonthlyChartData] = []
        
        for monthIndex in 0..<12 {
            guard let monthStart = calendar.date(byAdding: .month, value: monthIndex, to: yearStart),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                continue
            }
            
            let monthRecords = hydrationHistory.getRecords(for: DateInterval(start: monthStart, end: monthEnd))
            let totalIntake = monthRecords.reduce(0) { $0 + $1.totalIntake }
            
            chartData.append(MonthlyChartData(
                month: monthNames[monthIndex],
                intake: totalIntake
            ))
        }
        
        return chartData
    }
    
    private var yearlyData: [YearlyChartData] {
        let calendar = Calendar.current
        let today = Date()
        var chartData: [YearlyChartData] = []
        
        // Get data for last 5 years
        for yearOffset in 0..<5 {
            guard let yearStart = calendar.date(byAdding: .year, value: -yearOffset, to: today),
                  let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart) else {
                continue
            }
            
            let yearRecords = hydrationHistory.getRecords(for: DateInterval(start: yearStart, end: yearEnd))
            let totalIntake = yearRecords.reduce(0) { $0 + $1.totalIntake }
            let year = calendar.component(.year, from: yearStart)
            
            chartData.append(YearlyChartData(
                year: year,
                intake: totalIntake
            ))
        }
        
        return chartData.reversed()
    }
    
    // MARK: - Daily Statistics
    private var dailyTotalIntake: Double {
        dailyData.reduce(0) { $0 + $1.intake }
    }
    
    private var dailyGoalProgress: Double {
        let goal = 2.5
        return min(100, (dailyTotalIntake / goal) * 100)
    }
    
    private var dailyDrinkCount: Int {
        let today = Date()
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: today)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? today
        
        let dayRecords = hydrationHistory.getRecords(for: DateInterval(start: dayStart, end: dayEnd))
        return dayRecords.reduce(0) { $0 + $1.drinks.count }
    }
    
    private var dailyAveragePerDrink: Double {
        let totalDrinks = dailyDrinkCount
        return totalDrinks > 0 ? (dailyTotalIntake * 1000) / Double(totalDrinks) : 0
    }
    
    // MARK: - Weekly Statistics
    private var weeklyTotalIntake: Double {
        weeklyData.reduce(0) { $0 + $1.intake }
    }
    
    private var weeklyAverageIntake: Double {
        let daysWithData = weeklyData.filter { $0.intake > 0 }.count
        return daysWithData > 0 ? weeklyTotalIntake / Double(daysWithData) : 0
    }
    
    private var weeklyGoalMetDays: Int {
        weeklyData.filter { $0.intake >= 2.5 }.count
    }
    
    private var weeklySuccessRate: Double {
        let totalDays = weeklyData.count
        return totalDays > 0 ? (Double(weeklyGoalMetDays) / Double(totalDays)) * 100 : 0
    }
    
    // MARK: - Monthly Statistics
    private var monthlyTotalIntake: Double {
        monthlyData.reduce(0) { $0 + $1.intake }
    }
    
    private var monthlyAverageIntake: Double {
        let monthsWithData = monthlyData.filter { $0.intake > 0 }.count
        return monthsWithData > 0 ? monthlyTotalIntake / Double(monthsWithData) : 0
    }
    
    private var monthlyGoalMetDays: Int {
        // This would need to be calculated from daily records
        return 0 // Placeholder
    }
    
    private var monthlyTotalDays: Int {
        // This would need to be calculated from daily records
        return 0 // Placeholder
    }
    
    private var monthlyLongestStreak: Int {
        // This would need to be calculated from daily records
        return 0 // Placeholder
    }
    
    // MARK: - Yearly Statistics
    private var yearlyTotalIntake: Double {
        yearlyData.reduce(0) { $0 + $1.intake }
    }
    
    private var yearlyAverageIntake: Double {
        let yearsWithData = yearlyData.filter { $0.intake > 0 }.count
        return yearsWithData > 0 ? yearlyTotalIntake / Double(yearsWithData) : 0
    }
    
    private var yearlyGoalMetDays: Int {
        // This would need to be calculated from daily records
        return 0 // Placeholder
    }
    
    private var yearlySuccessRate: Double {
        // This would need to be calculated from daily records
        return 0 // Placeholder
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
        .cornerRadius(16)
    }
}

// MARK: - Chart Data Models
struct HourlyChartData: Identifiable {
    let id = UUID()
    let hour: Int
    let intake: Double
}

struct DailyChartData: Identifiable {
    let id = UUID()
    let day: String
    let intake: Double
}

struct MonthlyChartData: Identifiable {
    let id = UUID()
    let month: String
    let intake: Double
}

struct YearlyChartData: Identifiable {
    let id = UUID()
    let year: Int
    let intake: Double
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
