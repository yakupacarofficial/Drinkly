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
    @Published var personalizedGoalEnabled: Bool = true
    @Published var currentTemperature: Double = 22.0
    @Published var userProfile: UserProfile = UserProfile.default
    @Published var showingProfileSetup = false
    @Published var aiPrediction: WaterPrediction?
    
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
    private var aiWaterPredictor: AIWaterPredictor?
    
    // MARK: - Computed Properties
    var progressPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        let percentage = (currentAmount / dailyGoal) * 100.0
        
        if currentAmount >= dailyGoal || percentage >= 99.5 {
            return 100.0
        }
        
        return min(100.0, max(0.0, round(percentage * 10) / 10))
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
    
    func setDependencies(
        hydrationHistory: HydrationHistory,
        achievementManager: AchievementManager,
        smartReminderManager: SmartReminderManager,
        weatherManager: WeatherManager,
        aiWaterPredictor: AIWaterPredictor
    ) {
        self.hydrationHistory = hydrationHistory
        self.achievementManager = achievementManager
        self.smartReminderManager = smartReminderManager
        self.weatherManager = weatherManager
        self.aiWaterPredictor = aiWaterPredictor
        
        setupWeatherObserver()
    }
    
    func addWater(_ amount: Double) {
        guard amount > 0 else { return }
        
        let validatedAmount = min(amount, 5.0)
        let drink = WaterDrink(amount: validatedAmount, timestamp: Date())
        
        todayDrinks.append(drink)
        currentAmount += validatedAmount
        
        hydrationHistory?.addDrink(drink)
        addBehaviorDataToAI(amount: validatedAmount)
        checkAchievements()
        saveData()
        
        if isGoalMet && !showingCelebration {
            showCelebration()
        }
        
        triggerProgressAnimation()
    }
    
    func resetToday() {
        currentAmount = 0.0
        todayDrinks.removeAll()
        saveData()
    }
    
    func updateDailyGoal() {
        let baseGoal: Double
        
        if personalizedGoalEnabled && userProfile.isValid {
            baseGoal = userProfile.calculateDailyGoal()
        } else {
            baseGoal = Constants.defaultDailyGoal
        }
        
        if personalizedGoalEnabled && smartGoalEnabled {
            let temperatureAdjustment = calculateTemperatureAdjustment()
            dailyGoal = baseGoal + temperatureAdjustment
        } else {
            dailyGoal = baseGoal
        }
        
        dailyGoal = max(1.0, min(5.0, dailyGoal))
        saveData()
    }
    
    func updateUserProfile(_ profile: UserProfile) {
        guard profile.isValid else { return }
        
        userProfile = profile
        
        do {
            try userProfile.save()
        } catch {
            // Error saving user profile
        }
        
        updateDailyGoal()
    }
    
    func updateTemperature(_ temperature: Double) {
        let validatedTemperature = max(-50.0, min(60.0, temperature))
        currentTemperature = validatedTemperature
        updateDailyGoal()
    }
    
    func toggleSmartGoal() {
        smartGoalEnabled.toggle()
        updateDailyGoal()
        userDefaults.set(smartGoalEnabled, forKey: "drinkly_smart_goal_enabled")
    }
    
    func togglePersonalizedGoal() {
        personalizedGoalEnabled.toggle()
        updateDailyGoal()
        userDefaults.set(personalizedGoalEnabled, forKey: "drinkly_personalized_goal_enabled")
    }
    
    // MARK: - Private Methods
    
    private func setupPublishers() {
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
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
    
    private func updateProgressDisplay() {
        objectWillChange.send()
    }
    
    private func calculateTemperatureAdjustment() -> Double {
        let baseTemp = 22.0
        let tempDifference = currentTemperature - baseTemp
        
        if tempDifference > 0 {
            return tempDifference * 0.15
        } else {
            return 0
        }
    }
    
    private func addBehaviorDataToAI(amount: Double) {
        guard let aiWaterPredictor = aiWaterPredictor else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let month = calendar.component(.month, from: now)
        
        let context = PredictionContext(
            hour: hour,
            weekday: weekday,
            month: month,
            temperature: currentTemperature,
            humidity: nil,
            weatherCondition: nil,
            activityLevel: nil,
            lastDrinkTime: nil,
            totalDrinksToday: 0,
            averageDrinkSize: 0.0
        )
        
        _ = UserBehaviorEntry(
            timestamp: Date(),
            amount: amount,
            context: context,
            wasSuccessful: true
        )
        
        aiWaterPredictor.recordUserBehavior(amount: amount, wasSuccessful: true)
        aiWaterPredictor.updatePredictions()
        aiPrediction = aiWaterPredictor.currentPrediction
    }
    
    private func checkAchievements() {
        guard let achievementManager = achievementManager,
              let hydrationHistory = hydrationHistory else { 
            return 
        }
        
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
    
    func checkAchievementsWithData() {
        guard let achievementManager = achievementManager,
              let hydrationHistory = hydrationHistory else { return }
        
        let totalIntake = hydrationHistory.dailyRecords.reduce(0) { $0 + $1.totalIntake }
        let currentStreak = hydrationHistory.currentStreak
        let consecutiveDays = calculateConsecutiveDays()
        let perfectWeek = calculatePerfectWeek()
        let perfectMonth = calculatePerfectMonth()
        
        achievementManager.checkAchievements(
            currentStreak: currentStreak,
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
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                isAnimating = false
            }
        }
    }
    
    private func showCelebration() {
        showingCelebration = true
        scheduleDailySummaryNotification()
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showingCelebration = false
            }
        }
    }
    
    private func scheduleDailySummaryNotification() {
        guard let hydrationHistory = hydrationHistory else { return }
        
        let todayRecord = hydrationHistory.getTodayRecord()
        
        let summary = """
        Today's Progress: \(String(format: "%.1f", todayRecord.totalIntake))L / \(String(format: "%.1f", dailyGoal))L
        Goal Achievement: \(Int(todayRecord.totalIntake / dailyGoal * 100))%
        Drinks Today: \(todayDrinks.count)
        """
        
        NotificationManager.shared.scheduleDailySummaryNotification(summary: summary)
    }
    
    private func loadData() {
        userProfile = UserProfile.load()
        
        smartGoalEnabled = userDefaults.bool(forKey: "drinkly_smart_goal_enabled")
        if userDefaults.object(forKey: "drinkly_smart_goal_enabled") == nil {
            smartGoalEnabled = true
        }
        
        personalizedGoalEnabled = userDefaults.bool(forKey: "drinkly_personalized_goal_enabled")
        if userDefaults.object(forKey: "drinkly_personalized_goal_enabled") == nil {
            personalizedGoalEnabled = true
        }
        
        currentTemperature = userDefaults.double(forKey: "drinkly_current_temperature")
        if currentTemperature == 0.0 || currentTemperature < -50.0 || currentTemperature > 60.0 {
            currentTemperature = 22.0
        }
        
        loadTodayData()
        updateDailyGoal()
        checkAchievementsWithData()
    }
    
    private func loadTodayData() {
        let today = Date()
        let todayKey = "drinkly_today_\(today.formatted(date: .numeric, time: .omitted))"
        
        do {
            if let data = userDefaults.data(forKey: todayKey) {
                let todayData = try JSONDecoder().decode(TodayData.self, from: data)
                
                currentAmount = max(0, todayData.amount)
                todayDrinks = todayData.drinks.filter { $0.amount > 0 }
            }
        } catch {
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
            
            userDefaults.set(currentTemperature, forKey: "drinkly_current_temperature")
        } catch {
            // Error saving data
        }
    }
}

// MARK: - Supporting Models
struct TodayData: Codable {
    let amount: Double
    let drinks: [WaterDrink]
}

 