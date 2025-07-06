//
//  HydrationHistory.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation

/// Represents a single day's hydration data
struct DailyHydration: Codable, Identifiable {
    var id = UUID()
    let date: Date
    var totalIntake: Double // in liters
    let goal: Double
    var drinks: [WaterDrink]
    
    var progressPercentage: Double {
        guard goal > 0 else { return 0 }
        return min(100, (totalIntake / goal) * 100)
    }
    
    var isGoalMet: Bool {
        totalIntake >= goal
    }
    
    init(date: Date, totalIntake: Double, goal: Double, drinks: [WaterDrink]) {
        self.date = date
        self.totalIntake = totalIntake
        self.goal = goal
        self.drinks = drinks
    }
}

/// Represents weekly hydration statistics
struct WeeklyStats: Codable {
    let weekStartDate: Date
    let totalIntake: Double
    let averageIntake: Double
    let goalMetDays: Int
    let totalDays: Int
    
    var goalMetPercentage: Double {
        guard totalDays > 0 else { return 0 }
        return (Double(goalMetDays) / Double(totalDays)) * 100
    }
}

/// Represents monthly hydration statistics
struct MonthlyStats: Codable {
    let month: Date
    let totalIntake: Double
    let averageIntake: Double
    let goalMetDays: Int
    let totalDays: Int
    let longestStreak: Int
    
    var goalMetPercentage: Double {
        guard totalDays > 0 else { return 0 }
        return (Double(goalMetDays) / Double(totalDays)) * 100
    }
}

/// Manages hydration history and statistics
@MainActor
class HydrationHistory: ObservableObject {
    
    // MARK: - Published Properties
    @Published var dailyRecords: [DailyHydration] = []
    @Published var weeklyStats: [WeeklyStats] = []
    @Published var monthlyStats: [MonthlyStats] = []
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let historyKey = "drinkly_hydration_history"
    
    // MARK: - Initialization
    init() {
        loadHistory()
        calculateStreaks()
    }
    
    // MARK: - Public Methods
    
    /// Add a new drink to today's record with validation
    func addDrink(_ drink: WaterDrink) {
        // Validate drink amount
        guard drink.amount > 0 else {
            print("[HydrationHistory] Warning: Attempted to add drink with invalid amount: \(drink.amount)")
            return
        }
        
        var todayRecord = getTodayRecord()
        todayRecord.drinks.append(drink)
        todayRecord.totalIntake += drink.amount
        
        updateDailyRecord(todayRecord)
        saveHistory()
        calculateStreaks()
    }
    
    /// Get today's hydration record with validation
    func getTodayRecord() -> DailyHydration {
        let today = Date()
        
        if let existingRecord = dailyRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return existingRecord
        }
        
        // Create new record for today with validation
        let newRecord = DailyHydration(
            date: today,
            totalIntake: 0,
            goal: max(1.0, UserProfile.load().calculateDailyGoal()),
            drinks: []
        )
        
        dailyRecords.append(newRecord)
        return newRecord
    }
    
    /// Get hydration data for a specific date range
    func getRecords(for dateRange: DateInterval) -> [DailyHydration] {
        return dailyRecords.filter { record in
            dateRange.contains(record.date)
        }.sorted { $0.date < $1.date }
    }
    
    /// Get weekly statistics
    func getWeeklyStats(for weeks: Int = 4) -> [WeeklyStats] {
        let calendar = Calendar.current
        let today = Date()
        var stats: [WeeklyStats] = []
        
        for weekOffset in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            
            let weekRecords = getRecords(for: DateInterval(start: weekStart, end: weekEnd))
            let totalIntake = weekRecords.reduce(0) { $0 + $1.totalIntake }
            let goalMetDays = weekRecords.filter { $0.isGoalMet }.count
            
            let weeklyStat = WeeklyStats(
                weekStartDate: weekStart,
                totalIntake: totalIntake,
                averageIntake: weekRecords.isEmpty ? 0 : totalIntake / Double(weekRecords.count),
                goalMetDays: goalMetDays,
                totalDays: weekRecords.count
            )
            
            stats.append(weeklyStat)
        }
        
        return stats.reversed()
    }
    
    /// Get monthly statistics
    func getMonthlyStats(for months: Int = 6) -> [MonthlyStats] {
        let calendar = Calendar.current
        let today = Date()
        var stats: [MonthlyStats] = []
        
        for monthOffset in 0..<months {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: today),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            
            let monthRecords = getRecords(for: DateInterval(start: monthStart, end: monthEnd))
            let totalIntake = monthRecords.reduce(0) { $0 + $1.totalIntake }
            let goalMetDays = monthRecords.filter { $0.isGoalMet }.count
            
            let monthlyStat = MonthlyStats(
                month: monthStart,
                totalIntake: totalIntake,
                averageIntake: monthRecords.isEmpty ? 0 : totalIntake / Double(monthRecords.count),
                goalMetDays: goalMetDays,
                totalDays: monthRecords.count,
                longestStreak: calculateLongestStreak(for: monthRecords)
            )
            
            stats.append(monthlyStat)
        }
        
        return stats.reversed()
    }
    
    // MARK: - Private Methods
    
    private func updateDailyRecord(_ record: DailyHydration) {
        if let index = dailyRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: record.date) }) {
            dailyRecords[index] = record
        } else {
            dailyRecords.append(record)
        }
    }
    
    func calculateStreaks() {
        let sortedRecords = dailyRecords.sorted { $0.date < $1.date }
        var currentStreakCount = 0
        var longestStreakCount = 0
        var tempStreak = 0
        
        for record in sortedRecords.reversed() {
            if record.isGoalMet {
                tempStreak += 1
                currentStreakCount = max(currentStreakCount, tempStreak)
            } else {
                tempStreak = 0
            }
        }
        
        longestStreakCount = dailyRecords.map { record in
            var streak = 0
            var currentDate = record.date
            
            while let existingRecord = dailyRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: currentDate) }),
                  existingRecord.isGoalMet {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            return streak
        }.max() ?? 0
        
        currentStreak = currentStreakCount
        longestStreak = longestStreakCount
    }
    
    private func calculateLongestStreak(for records: [DailyHydration]) -> Int {
        let sortedRecords = records.sorted { $0.date < $1.date }
        var longestStreak = 0
        var currentStreak = 0
        
        for record in sortedRecords {
            if record.isGoalMet {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return longestStreak
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func loadHistory() {
        do {
            if let data = userDefaults.data(forKey: historyKey) {
                let records = try JSONDecoder().decode([DailyHydration].self, from: data)
                
                // Validate and sanitize loaded records
                dailyRecords = records.filter { record in
                    record.totalIntake >= 0 && 
                    record.goal > 0 && 
                    record.drinks.allSatisfy { $0.amount > 0 }
                }
            }
        } catch {
            print("[HydrationHistory] Error loading history: \(error)")
            dailyRecords = []
        }
    }
    
    func saveHistory() {
        do {
            let data = try JSONEncoder().encode(dailyRecords)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            print("[HydrationHistory] Error saving history: \(error)")
        }
    }
    
    /// Reset all hydration data
    func resetAllData() {
        dailyRecords.removeAll()
        weeklyStats.removeAll()
        monthlyStats.removeAll()
        currentStreak = 0
        longestStreak = 0
        saveHistory()
    }
}

// MARK: - UserProfile Extension for Goal Calculation
extension UserProfile {
    func calculateDailyGoal() -> Double {
        // Enhanced formula based on scientific recommendations
        // Base: 35ml per kg of body weight
        var baseGoal = weight * 0.035
        
        // Height adjustment: +200ml for every 10cm above 160cm
        let heightAdjustment = max(0, (height - 160) / 10) * 0.2
        baseGoal += heightAdjustment
        
        // Activity level adjustments
        switch activityLevel {
        case .sedentary:
            baseGoal *= 1.0
        case .moderate:
            baseGoal *= 1.1
        case .active:
            baseGoal *= 1.2
        case .veryActive:
            baseGoal *= 1.3
        }
        
        // Gender adjustments
        switch gender {
        case .male:
            baseGoal *= 1.1
        case .female:
            baseGoal *= 1.0
        case .other:
            baseGoal *= 1.05
        }
        
        // Age adjustments
        if age < 18 {
            baseGoal *= 0.9
        } else if age > 65 {
            baseGoal *= 0.95
        }
        
        // Ensure minimum and maximum values (1.5L to 5.0L)
        return max(1.5, min(5.0, baseGoal))
    }
    
    /// Calculate temperature-adjusted daily goal
    /// - Parameter temperature: Current temperature in Celsius
    /// - Returns: Adjusted daily water goal in liters
    func calculateDailyGoal(with temperature: Double) -> Double {
        let baseGoal = calculateDailyGoal()
        
        // Temperature adjustment: +150ml per degree above 25°C
        let temperatureAdjustment = max(0, (temperature - 25)) * 0.15
        
        return min(5.0, baseGoal + temperatureAdjustment)
    }
} 