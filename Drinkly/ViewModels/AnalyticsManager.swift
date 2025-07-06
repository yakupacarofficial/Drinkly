//
//  AnalyticsManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 7.07.2025.
//

import Foundation
import SwiftUI

/// Advanced analytics and statistics manager for hydration data
@MainActor
class AnalyticsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var goalAchievementRate: Double = 0.0
    @Published var averageDailyIntake: Double = 0.0
    @Published var bestDrinkingTime: String = ""
    @Published var consistencyScore: Double = 0.0
    @Published var improvementTrend: Double = 0.0
    
    @Published var weeklyStats: [WeeklyStat] = []
    @Published var monthlyStats: [MonthlyStat] = []
    @Published var yearlyStats: [YearlyStat] = []
    
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    
    // MARK: - Private Properties
    private var hydrationHistory: HydrationHistory?
    private let userDefaults = UserDefaults.standard
    private let analyticsKey = "Drinkly_Analytics_Cache"
    
    // MARK: - Initialization
    init() {
        loadAnalyticsData()
    }
    
    // MARK: - Public Methods
    
    /// Update analytics with current hydration history
    func updateAnalytics(with history: HydrationHistory) {
        isAnalyzing = true
        hydrationHistory = history
        
        Task {
            await performAnalysis()
            
            await MainActor.run {
                self.isAnalyzing = false
                self.lastAnalysisDate = Date()
                self.saveAnalyticsData()
            }
        }
    }
    
    /// Get analytics data for a specific date range
    func getAnalyticsData(for dateRange: DateRange) -> AnalyticsData {
        guard let history = hydrationHistory else { return AnalyticsData.empty }
        
        let filteredRecords = history.dailyRecords.filter { record in
            dateRange.contains(record.date)
        }
        
        return AnalyticsData(
            totalIntake: filteredRecords.reduce(0) { $0 + $1.totalIntake },
            averageDailyIntake: filteredRecords.isEmpty ? 0 : filteredRecords.reduce(0) { $0 + $1.totalIntake } / Double(filteredRecords.count),
            goalMetDays: filteredRecords.filter { $0.isGoalMet }.count,
            totalDays: filteredRecords.count,
            goalAchievementRate: filteredRecords.isEmpty ? 0 : Double(filteredRecords.filter { $0.isGoalMet }.count) / Double(filteredRecords.count),
            bestDrinkingTime: findBestDrinkingTimeInRecords(filteredRecords),
            consistencyScore: calculateConsistencyForRecords(filteredRecords)
        )
    }
    
    /// Get trend analysis
    func getTrendAnalysis() -> TrendAnalysis {
        guard let history = hydrationHistory else { return TrendAnalysis.empty }
        
        let recentRecords = Array(history.dailyRecords.suffix(30))
        let olderRecords = Array(history.dailyRecords.prefix(max(0, history.dailyRecords.count - 30)))
        
        let recentAverage = recentRecords.isEmpty ? 0 : recentRecords.reduce(0) { $0 + $1.totalIntake } / Double(recentRecords.count)
        let olderAverage = olderRecords.isEmpty ? 0 : olderRecords.reduce(0) { $0 + $1.totalIntake } / Double(olderRecords.count)
        
        let trend = recentAverage - olderAverage
        let trendDirection: TrendDirection = trend > 0 ? .improving : trend < 0 ? .declining : .stable
        
        return TrendAnalysis(
            trendDirection: trendDirection,
            trendValue: abs(trend),
            recentAverage: recentAverage,
            olderAverage: olderAverage,
            confidence: calculateTrendConfidence(recentRecords, olderRecords)
        )
    }
    
    /// Get insights for user
    func getInsights() -> [AnalyticsInsight] {
        var insights: [AnalyticsInsight] = []
        
        // Goal achievement insight
        if goalAchievementRate < 0.5 {
            insights.append(AnalyticsInsight(
                type: .goalAchievement,
                title: "Goal Achievement",
                description: "You're meeting your goal \(Int(goalAchievementRate * 100))% of the time. Try setting smaller, more achievable goals.",
                priority: .high,
                confidence: goalAchievementRate
            ))
        }
        
        // Consistency insight
        if consistencyScore < 0.6 {
            insights.append(AnalyticsInsight(
                type: .consistency,
                title: "Drinking Consistency",
                description: "Your drinking pattern could be more consistent. Try drinking at the same times each day.",
                priority: .medium,
                confidence: consistencyScore
            ))
        }
        
        // Best time insight
        if !bestDrinkingTime.isEmpty {
            insights.append(AnalyticsInsight(
                type: .bestTime,
                title: "Peak Hydration Time",
                description: "You're most active at \(bestDrinkingTime). Consider setting reminders for this time.",
                priority: .low,
                confidence: 0.8
            ))
        }
        
        return insights
    }
    
    // MARK: - Private Methods
    
    private func performAnalysis() async {
        guard let history = hydrationHistory else { return }
        
        calculateGoalAchievementRate(from: history)
        calculateAverageDailyIntake(from: history)
        findBestDrinkingTime(from: history)
        calculateConsistencyScore(from: history)
        calculateImprovementTrend(from: history)
        
        calculateWeeklyStats(from: history)
        calculateMonthlyStats(from: history)
        calculateYearlyStats(from: history)
    }
    
    private func calculateWeeklyStats(from history: HydrationHistory) {
        let calendar = Calendar.current
        let now = Date()
        
        weeklyStats = (0..<4).map { weekOffset in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            let weekRecords = history.dailyRecords.filter { record in
                calendar.isDate(record.date, equalTo: weekStart, toGranularity: .weekOfYear)
            }
            
            return WeeklyStat(
                weekStart: weekStart,
                totalIntake: weekRecords.reduce(0) { $0 + $1.totalIntake },
                averageDailyIntake: weekRecords.isEmpty ? 0 : weekRecords.reduce(0) { $0 + $1.totalIntake } / Double(weekRecords.count),
                goalMetDays: weekRecords.filter { $0.isGoalMet }.count,
                totalDays: weekRecords.count
            )
        }
    }
    
    private func calculateMonthlyStats(from history: HydrationHistory) {
        let calendar = Calendar.current
        let now = Date()
        
        monthlyStats = (0..<6).map { monthOffset in
            let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now) ?? now
            let monthRecords = history.dailyRecords.filter { record in
                calendar.isDate(record.date, equalTo: monthStart, toGranularity: .month)
            }
            
            return MonthlyStat(
                monthStart: monthStart,
                totalIntake: monthRecords.reduce(0) { $0 + $1.totalIntake },
                averageDailyIntake: monthRecords.isEmpty ? 0 : monthRecords.reduce(0) { $0 + $1.totalIntake } / Double(monthRecords.count),
                goalMetDays: monthRecords.filter { $0.isGoalMet }.count,
                totalDays: monthRecords.count
            )
        }
    }
    
    private func calculateYearlyStats(from history: HydrationHistory) {
        let calendar = Calendar.current
        let now = Date()
        
        yearlyStats = (0..<2).map { yearOffset in
            let yearStart = calendar.date(byAdding: .year, value: -yearOffset, to: now) ?? now
            let yearRecords = history.dailyRecords.filter { record in
                calendar.isDate(record.date, equalTo: yearStart, toGranularity: .year)
            }
            
            return YearlyStat(
                yearStart: yearStart,
                totalIntake: yearRecords.reduce(0) { $0 + $1.totalIntake },
                averageDailyIntake: yearRecords.isEmpty ? 0 : yearRecords.reduce(0) { $0 + $1.totalIntake } / Double(yearRecords.count),
                goalMetDays: yearRecords.filter { $0.isGoalMet }.count,
                totalDays: yearRecords.count
            )
        }
    }
    
    private func calculateGoalAchievementRate(from history: HydrationHistory) {
        let totalDays = history.dailyRecords.count
        let goalMetDays = history.dailyRecords.filter { $0.isGoalMet }.count
        
        goalAchievementRate = totalDays > 0 ? Double(goalMetDays) / Double(totalDays) : 0.0
    }
    
    private func calculateAverageDailyIntake(from history: HydrationHistory) {
        let totalIntake = history.dailyRecords.reduce(0) { $0 + $1.totalIntake }
        let totalDays = history.dailyRecords.count
        
        averageDailyIntake = totalDays > 0 ? totalIntake / Double(totalDays) : 0.0
    }
    
    private func findBestDrinkingTime(from history: HydrationHistory) {
        // Analyze drinking patterns by hour
        let hourPatterns = Dictionary(grouping: history.dailyRecords) { record in
            Calendar.current.component(.hour, from: record.date)
        }
        
        let bestHour = hourPatterns.max { first, second in
            first.value.reduce(0) { $0 + $1.totalIntake } < second.value.reduce(0) { $0 + $1.totalIntake }
        }?.key ?? 8
        
        bestDrinkingTime = getTimeSlotName(bestHour)
    }
    
    private func calculateConsistencyScore(from history: HydrationHistory) {
        let records = history.dailyRecords.sorted { $0.date < $1.date }
        guard records.count > 1 else {
            consistencyScore = 1.0
            return
        }
        
        let intakes = records.map { $0.totalIntake }
        let mean = intakes.reduce(0, +) / Double(intakes.count)
        let variance = intakes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intakes.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation means more consistency
        consistencyScore = max(0, 1 - (standardDeviation / mean))
    }
    
    private func calculateImprovementTrend(from history: HydrationHistory) {
        let records = history.dailyRecords.sorted { $0.date < $1.date }
        guard records.count >= 10 else {
            improvementTrend = 0.0
            return
        }
        
        let half = records.count / 2
        let firstHalf = Array(records.prefix(half))
        let secondHalf = Array(records.suffix(half))
        
        let firstAverage = firstHalf.reduce(0) { $0 + $1.totalIntake } / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0) { $0 + $1.totalIntake } / Double(secondHalf.count)
        
        improvementTrend = secondAverage - firstAverage
    }
    
    private func getTimeSlotName(_ hour: Int) -> String {
        switch hour {
        case 6..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
    
    private func findBestDrinkingTimeInRecords(_ records: [DailyHydration]) -> String {
        let hourPatterns = Dictionary(grouping: records) { record in
            Calendar.current.component(.hour, from: record.date)
        }
        
        let bestHour = hourPatterns.max { first, second in
            first.value.reduce(0) { $0 + $1.totalIntake } < second.value.reduce(0) { $0 + $1.totalIntake }
        }?.key ?? 8
        
        return getTimeSlotName(bestHour)
    }
    
    private func calculateConsistencyForRecords(_ records: [DailyHydration]) -> Double {
        guard records.count > 1 else { return 1.0 }
        
        let intakes = records.map { $0.totalIntake }
        let mean = intakes.reduce(0, +) / Double(intakes.count)
        let variance = intakes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intakes.count)
        let standardDeviation = sqrt(variance)
        
        return max(0, 1 - (standardDeviation / mean))
    }
    
    private func calculateTrendConfidence(_ recentRecords: [DailyHydration], _ olderRecords: [DailyHydration]) -> Double {
        let recentCount = recentRecords.count
        let olderCount = olderRecords.count
        
        // More data points = higher confidence
        let dataConfidence = min(1.0, Double(min(recentCount, olderCount)) / 10.0)
        
        // Less variance = higher confidence
        let recentVariance = calculateVariance(recentRecords)
        let olderVariance = calculateVariance(olderRecords)
        let varianceConfidence = max(0, 1 - ((recentVariance + olderVariance) / 2))
        
        return (dataConfidence + varianceConfidence) / 2
    }
    
    private func calculateVariance(_ records: [DailyHydration]) -> Double {
        guard records.count > 1 else { return 0 }
        
        let intakes = records.map { $0.totalIntake }
        let mean = intakes.reduce(0, +) / Double(intakes.count)
        let variance = intakes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intakes.count)
        
        return variance
    }
    
    private func loadAnalyticsData() {
        // Load cached analytics data if available
        if let data = userDefaults.data(forKey: analyticsKey),
           let analytics = try? JSONDecoder().decode(AnalyticsCache.self, from: data) {
            goalAchievementRate = analytics.goalAchievementRate
            averageDailyIntake = analytics.averageDailyIntake
            bestDrinkingTime = analytics.bestDrinkingTime
            consistencyScore = analytics.consistencyScore
            improvementTrend = analytics.improvementTrend
        }
    }
    
    private func saveAnalyticsData() {
        let cache = AnalyticsCache(
            goalAchievementRate: goalAchievementRate,
            averageDailyIntake: averageDailyIntake,
            bestDrinkingTime: bestDrinkingTime,
            consistencyScore: consistencyScore,
            improvementTrend: improvementTrend
        )
        
        if let data = try? JSONEncoder().encode(cache) {
            userDefaults.set(data, forKey: analyticsKey)
        }
    }
}

// MARK: - Supporting Models

struct WeeklyStat: Codable, Identifiable {
    var id = UUID()
    let weekStart: Date
    let totalIntake: Double
    let averageDailyIntake: Double
    let goalMetDays: Int
    let totalDays: Int
}

struct MonthlyStat: Codable, Identifiable {
    var id = UUID()
    let monthStart: Date
    let totalIntake: Double
    let averageDailyIntake: Double
    let goalMetDays: Int
    let totalDays: Int
}

struct YearlyStat: Codable, Identifiable {
    var id = UUID()
    let yearStart: Date
    let totalIntake: Double
    let averageDailyIntake: Double
    let goalMetDays: Int
    let totalDays: Int
}

struct AnalyticsData {
    let totalIntake: Double
    let averageDailyIntake: Double
    let goalMetDays: Int
    let totalDays: Int
    let goalAchievementRate: Double
    let bestDrinkingTime: String
    let consistencyScore: Double
    
    static let empty = AnalyticsData(
        totalIntake: 0,
        averageDailyIntake: 0,
        goalMetDays: 0,
        totalDays: 0,
        goalAchievementRate: 0,
        bestDrinkingTime: "",
        consistencyScore: 0
    )
}

struct TrendAnalysis {
    let trendDirection: TrendDirection
    let trendValue: Double
    let recentAverage: Double
    let olderAverage: Double
    let confidence: Double
    
    static let empty = TrendAnalysis(
        trendDirection: .stable,
        trendValue: 0,
        recentAverage: 0,
        olderAverage: 0,
        confidence: 0
    )
}

enum TrendDirection {
    case improving, declining, stable
}

struct AnalyticsInsight {
    let type: InsightType
    let title: String
    let description: String
    let priority: InsightPriority
    let confidence: Double
}

enum InsightType {
    case goalAchievement, consistency, bestTime, improvement
}

enum InsightPriority {
    case low, medium, high
}

struct DateRange {
    let startDate: Date
    let endDate: Date
    
    func contains(_ date: Date) -> Bool {
        return date >= startDate && date <= endDate
    }
}

struct AnalyticsCache: Codable {
    let goalAchievementRate: Double
    let averageDailyIntake: Double
    let bestDrinkingTime: String
    let consistencyScore: Double
    let improvementTrend: Double
} 