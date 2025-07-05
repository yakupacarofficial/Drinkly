//
//  WaterManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI
import Combine

/// Manages water intake data and business logic
@MainActor
class WaterManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentAmount: Double = 0.0
    @Published var dailyGoal: Double = Constants.defaultDailyGoal
    @Published var todayDrinks: [WaterDrink] = []
    @Published var showingDrinkOptions = false
    @Published var isAnimating = false
    @Published var showingCelebration = false
    @Published var smartGoalEnabled: Bool = true
    @Published var currentTemperature: Double = 22.0
    @Published var userProfile: UserProfile = UserProfile.default
    @Published var showingProfileSetup = false
    
    // MARK: - Private Properties
    private var animationTask: Task<Void, Never>?
    private var progressUpdateTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Dependencies
    private var hydrationHistory: HydrationHistory?
    private var achievementManager: AchievementManager?
    private var smartReminderManager: SmartReminderManager?
    private var weatherManager: WeatherManager?
    
    // MARK: - Computed Properties
    var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(100, max(0, (currentAmount / dailyGoal) * 100))
    }
    
    var progressColor: Color {
        if progressPercentage >= 100 {
            return .green
        } else if progressPercentage >= 75 {
            return .blue
        } else if progressPercentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    var remainingAmount: Double {
        max(0, dailyGoal - currentAmount)
    }
    
    var isGoalMet: Bool {
        currentAmount >= dailyGoal
    }
    
    var goalStatus: GoalStatus {
        if isGoalMet {
            return .completed
        } else if progressPercentage >= 75 {
            return .almostThere
        } else if progressPercentage >= 50 {
            return .halfway
        } else {
            return .gettingStarted
        }
    }
    
    enum GoalStatus {
        case gettingStarted, halfway, almostThere, completed
        
        var message: String {
            switch self {
            case .gettingStarted:
                return "Let's start your hydration journey!"
            case .halfway:
                return "Great progress! Keep going!"
            case .almostThere:
                return "Almost there! You're doing great!"
            case .completed:
                return "Congratulations! Goal achieved!"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        loadData()
        setupPublishers()
        startProgressUpdates()
    }
    
    deinit {
        animationTask?.cancel()
        progressUpdateTask?.cancel()
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Set dependencies for integration with other managers
    func setDependencies(
        hydrationHistory: HydrationHistory,
        achievementManager: AchievementManager,
        smartReminderManager: SmartReminderManager,
        weatherManager: WeatherManager
    ) {
        self.hydrationHistory = hydrationHistory
        self.achievementManager = achievementManager
        self.smartReminderManager = smartReminderManager
        self.weatherManager = weatherManager
        
        // Observe weather changes
        setupWeatherObserver()
    }
    
    /// Add water intake with comprehensive validation
    func addWater(_ amount: Double) {
        // Validate input amount
        guard amount > 0 else {
            print("[WaterManager] Warning: Attempted to add negative or zero water amount: \(amount)")
            return
        }
        
        // Set reasonable upper bound (5L per drink)
        let validatedAmount = min(amount, 5.0)
        
        let drink = WaterDrink(amount: validatedAmount, timestamp: Date())
        todayDrinks.append(drink)
        currentAmount += validatedAmount
        
        // Update hydration history safely
        hydrationHistory?.addDrink(drink)
        
        // Check achievements safely
        checkAchievements()
        
        // Save data with error handling
        saveData()
        
        // Show celebration if goal is met
        if isGoalMet && !showingCelebration {
            showCelebration()
        }
        
        // Trigger animation
        triggerProgressAnimation()
    }
    
    /// Reset today's progress with validation
    func resetToday() {
        currentAmount = 0.0
        todayDrinks.removeAll()
        saveData()
    }
    
    /// Update daily goal based on user profile and temperature with bounds checking
    func updateDailyGoal() {
        let baseGoal = userProfile.calculateDailyGoal()
        
        if smartGoalEnabled {
            // Adjust for temperature with bounds checking
            let temperatureAdjustment = calculateTemperatureAdjustment()
            dailyGoal = baseGoal + temperatureAdjustment
        } else {
            dailyGoal = baseGoal
        }
        
        // Ensure reasonable bounds (1.0L to 5.0L)
        dailyGoal = max(1.0, min(5.0, dailyGoal))
        
        saveData()
    }
    
    /// Update user profile with validation
    func updateUserProfile(_ profile: UserProfile) {
        // Validate profile before updating
        guard profile.isValid else {
            print("[WaterManager] Warning: Invalid profile data received")
            return
        }
        
        userProfile = profile
        
        // Save profile with error handling
        do {
            try userProfile.save()
        } catch {
            print("[WaterManager] Error saving user profile: \(error)")
        }
        
        updateDailyGoal()
    }
    
    /// Update temperature with bounds checking
    func updateTemperature(_ temperature: Double) {
        // Validate temperature range (-50°C to 60°C)
        let validatedTemperature = max(-50.0, min(60.0, temperature))
        currentTemperature = validatedTemperature
        updateDailyGoal()
    }
    
    /// Toggle smart goal feature
    func toggleSmartGoal() {
        smartGoalEnabled.toggle()
        updateDailyGoal()
        userDefaults.set(smartGoalEnabled, forKey: "drinkly_smart_goal_enabled")
    }
    
    // MARK: - Private Methods
    
    private func setupPublishers() {
        // Debounced goal recalculation
        $userProfile
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDailyGoal()
            }
            .store(in: &cancellables)
        
        $currentTemperature
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDailyGoal()
            }
            .store(in: &cancellables)
    }
    
    private func setupWeatherObserver() {
        // Observe weather manager temperature changes
        weatherManager?.$currentTemperature
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] temperature in
                self?.currentTemperature = temperature
                self?.updateDailyGoal()
            }
            .store(in: &cancellables)
    }
    
    private func startProgressUpdates() {
        progressUpdateTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    updateProgressDisplay()
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
        }
    }
    
    private func updateProgressDisplay() {
        // Update progress display without triggering expensive computations
        objectWillChange.send()
    }
    
    private func calculateTemperatureAdjustment() -> Double {
        let baseTemp = 22.0
        let tempDifference = currentTemperature - baseTemp
        
        if tempDifference > 0 {
            // Add 150ml per degree above 22°C
            return tempDifference * 0.15
        } else {
            return 0
        }
    }
    
    private func checkAchievements() {
        guard let achievementManager = achievementManager,
              let hydrationHistory = hydrationHistory else { 
            print("[WaterManager] Warning: Achievement or hydration history manager not available")
            return 
        }
        
        // Safely calculate total intake with bounds checking
        let totalIntake = max(0, hydrationHistory.dailyRecords.reduce(0) { $0 + $1.totalIntake })
        let consecutiveDays = calculateConsecutiveDays()
        let perfectWeek = calculatePerfectWeek()
        let perfectMonth = calculatePerfectMonth()
        
        achievementManager.checkAchievements(
            currentStreak: hydrationHistory.currentStreak,
            totalIntake: totalIntake,
            consecutiveDays: consecutiveDays,
            perfectWeek: perfectWeek,
            perfectMonth: perfectMonth
        )
    }
    
    private func calculateConsecutiveDays() -> Int {
        guard let hydrationHistory = hydrationHistory else { return 0 }
        
        let sortedRecords = hydrationHistory.dailyRecords.sorted { $0.date < $1.date }
        var consecutiveDays = 0
        
        for record in sortedRecords.reversed() {
            if record.isGoalMet {
                consecutiveDays += 1
            } else {
                break
            }
        }
        
        return max(0, consecutiveDays)
    }
    
    private func calculatePerfectWeek() -> Bool {
        guard let hydrationHistory = hydrationHistory else { return false }
        let weekRecords = hydrationHistory.getWeeklyStats(for: 1)
        return weekRecords.first?.goalMetDays == 7
    }
    
    private func calculatePerfectMonth() -> Bool {
        guard let hydrationHistory = hydrationHistory else { return false }
        let monthRecords = hydrationHistory.getMonthlyStats(for: 1)
        return monthRecords.first?.goalMetDays == monthRecords.first?.totalDays
    }
    
    private func triggerProgressAnimation() {
        animationTask?.cancel()
        animationTask = Task {
            await MainActor.run {
                isAnimating = true
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                isAnimating = false
            }
        }
    }
    
    private func showCelebration() {
        showingCelebration = true
        
        // Hide celebration after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showingCelebration = false
            }
        }
    }
    
    private func loadData() {
        // Load user profile with error handling
        userProfile = UserProfile.load()
        
        // Load smart goal setting with validation
        smartGoalEnabled = userDefaults.bool(forKey: "drinkly_smart_goal_enabled")
        if userDefaults.object(forKey: "drinkly_smart_goal_enabled") == nil {
            smartGoalEnabled = true
        }
        
        // Load current temperature with bounds checking
        currentTemperature = userDefaults.double(forKey: "drinkly_current_temperature")
        if currentTemperature == 0.0 || currentTemperature < -50.0 || currentTemperature > 60.0 {
            currentTemperature = 22.0
        }
        
        // Load today's data with error handling
        loadTodayData()
        
        // Update goal based on loaded data
        updateDailyGoal()
    }
    
    private func loadTodayData() {
        let today = Date()
        let todayKey = "drinkly_today_\(today.formatted(date: .numeric, time: .omitted))"
        
        do {
            if let data = userDefaults.data(forKey: todayKey) {
                let todayData = try JSONDecoder().decode(TodayData.self, from: data)
                
                // Validate loaded data
                currentAmount = max(0, todayData.amount)
                todayDrinks = todayData.drinks.filter { $0.amount > 0 }
            }
        } catch {
            print("[WaterManager] Error loading today's data: \(error)")
            // Reset to safe defaults
            currentAmount = 0.0
            todayDrinks = []
        }
    }
    
    func saveData() {
        do {
            let today = Date()
            let todayKey = "drinkly_today_\(today.formatted(date: .numeric, time: .omitted))"
            
            let todayData = TodayData(amount: currentAmount, drinks: todayDrinks)
            let data = try JSONEncoder().encode(todayData)
            userDefaults.set(data, forKey: todayKey)
            
            // Save current temperature
            userDefaults.set(currentTemperature, forKey: "drinkly_current_temperature")
        } catch {
            print("[WaterManager] Error saving data: \(error)")
        }
    }
    

}

// MARK: - Supporting Models

struct TodayData: Codable {
    let amount: Double
    let drinks: [WaterDrink]
}

 