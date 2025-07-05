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
    @Published var currentTemperature: Double = 0.0
    @Published var userCity: String = ""
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile?
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let todayKey = Constants.UserDefaultsKeys.todayDrinks
    private let goalKey = Constants.UserDefaultsKeys.dailyGoal
    private let smartGoalKey = Constants.UserDefaultsKeys.smartGoalEnabled
    private let temperatureKey = Constants.UserDefaultsKeys.lastTemperature
    private let cityKey = Constants.UserDefaultsKeys.userCity
    
    // Performance optimizations
    private var animationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // Cached computed properties
    private var cachedProgressPercentage: Double = 0.0
    private var cachedRemainingAmount: Double = 0.0
    private var cachedIsGoalReached: Bool = false
    private var lastCalculationTime: Date = Date()
    
    // MARK: - Computed Properties (Optimized)
    var progressPercentage: Double {
        // Cache for 100ms to avoid excessive recalculations
        let now = Date()
        if now.timeIntervalSince(lastCalculationTime) < 0.1 {
            return cachedProgressPercentage
        }
        
        let percentage = dailyGoal > 0 ? min(currentAmount / dailyGoal, 1.0) : 0.0
        cachedProgressPercentage = percentage
        lastCalculationTime = now
        return percentage
    }
    
    var remainingAmount: Double {
        let remaining = max(dailyGoal - currentAmount, 0)
        cachedRemainingAmount = remaining
        return remaining
    }
    
    var isGoalReached: Bool {
        let reached = currentAmount >= dailyGoal
        cachedIsGoalReached = reached
        return reached
    }
    
    var progressColor: Color {
        let percentage = progressPercentage
        switch percentage {
        case 0..<0.33:
            return .gray
        case 0.33..<0.67:
            return .blue
        default:
            return .green
        }
    }
    
    // MARK: - Initialization
    init() {
        loadData()
        setupAnimations()
        setupPublishers()
    }
    
    deinit {
        animationTask?.cancel()
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Adds water intake to today's log
    /// - Parameter amount: Amount in liters
    func addWater(amount: Double) {
        let drink = WaterDrink(amount: amount)
        todayDrinks.append(drink)
        currentAmount += amount
        saveData()
        
        triggerAnimation()
        
        if isGoalReached && !showingCelebration {
            showGoalReachedCelebration()
        }
    }
    
    /// Resets today's progress
    func resetToday() {
        currentAmount = 0
        todayDrinks.removeAll()
        saveData()
    }
    
    /// Sets the daily water goal
    /// - Parameter goal: Goal in liters
    func setDailyGoal(_ goal: Double) {
        dailyGoal = max(Constants.minimumDailyGoal, min(Constants.maximumDailyGoal, goal))
        userDefaults.set(dailyGoal, forKey: goalKey)
    }
    
    /// Updates smart goal based on temperature
    /// - Parameter temperature: Current temperature in Celsius
    func updateSmartGoal(for temperature: Double) {
        currentTemperature = temperature
        userDefaults.set(temperature, forKey: temperatureKey)
        
        if smartGoalEnabled {
            let smartGoal = calculateSmartGoal(for: temperature)
            dailyGoal = smartGoal
            userDefaults.set(smartGoal, forKey: goalKey)
        }
    }
    
    /// Sets the user's city
    /// - Parameter city: City name
    func setUserCity(_ city: String) {
        userCity = city
        userDefaults.set(city, forKey: cityKey)
    }
    
    /// Toggles smart goal feature
    func toggleSmartGoal() {
        smartGoalEnabled.toggle()
        userDefaults.set(smartGoalEnabled, forKey: smartGoalKey)
        
        if smartGoalEnabled {
            updateSmartGoal(for: currentTemperature)
        }
    }
    
    /// Updates user profile and recalculates goal
    /// - Parameter profile: New user profile
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        recalculatePersonalizedGoal()
    }
    
    /// Recalculates personalized goal based on user profile and temperature
    func recalculatePersonalizedGoal() {
        guard let profile = userProfile else { return }
        
        let baseGoal = calculatePersonalizedBaseGoal(for: profile)
        let temperatureAdjustment = calculateTemperatureAdjustment()
        let finalGoal = baseGoal + temperatureAdjustment
        
        dailyGoal = max(Constants.minimumDailyGoal, min(Constants.maximumDailyGoal, finalGoal))
        userDefaults.set(dailyGoal, forKey: goalKey)
    }
    
    // MARK: - Private Methods
    
    private func loadData() {
        // Load user profile
        userProfile = UserProfile.load()
        
        // Load daily goal
        dailyGoal = userDefaults.double(forKey: goalKey)
        if dailyGoal == 0 {
            dailyGoal = Constants.defaultDailyGoal
        }
        
        // Load smart goal settings
        smartGoalEnabled = userDefaults.bool(forKey: smartGoalKey)
        if userDefaults.object(forKey: smartGoalKey) == nil {
            smartGoalEnabled = true
        }
        
        // Load temperature and city
        currentTemperature = userDefaults.double(forKey: temperatureKey)
        userCity = userDefaults.string(forKey: cityKey) ?? ""
        
        // Load today's drinks
        loadTodayDrinks()
        
        // Check if it's a new day
        checkNewDay()
        
        // Recalculate goal if profile exists
        if userProfile != nil {
            recalculatePersonalizedGoal()
        }
    }
    
    private func loadTodayDrinks() {
        guard let data = userDefaults.data(forKey: todayKey),
              let drinks = try? JSONDecoder().decode([WaterDrink].self, from: data) else {
            return
        }
        
        todayDrinks = drinks
        currentAmount = drinks.reduce(0) { $0 + $1.amount }
    }
    
    private func saveData() {
        Task {
            do {
                let data = try JSONEncoder().encode(todayDrinks)
                userDefaults.set(data, forKey: todayKey)
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func checkNewDay() {
        let calendar = Calendar.current
        let today = Date()
        
        if let lastDrink = todayDrinks.last {
            if !calendar.isDate(lastDrink.timestamp, inSameDayAs: today) {
                resetToday()
            }
        }
    }
    
    private func calculateSmartGoal(for temperature: Double) -> Double {
        let baseGoal = Constants.baseWaterGoal
        let threshold = Constants.temperatureThreshold
        let additionalPerDegree = Constants.additionalWaterPerDegree
        
        var goal = baseGoal
        
        if temperature > threshold {
            let additional = (temperature - threshold) * additionalPerDegree
            goal += additional
        }
        
        return max(Constants.minimumDailyGoal, min(Constants.maximumSmartGoal, goal))
    }
    
    /// Calculates personalized base goal based on user profile
    /// - Parameter profile: User profile
    /// - Returns: Base goal in liters
    private func calculatePersonalizedBaseGoal(for profile: UserProfile) -> Double {
        // Base calculation: 30ml per kg of body weight
        let baseWaterPerKg: Double = 0.03
        var baseGoal = profile.weight * baseWaterPerKg
        
        // Activity level adjustments
        let activityMultiplier: Double
        switch profile.activityLevel {
        case .sedentary:
            activityMultiplier = 1.0
        case .moderate:
            activityMultiplier = 1.1
        case .active:
            activityMultiplier = 1.2
        case .veryActive:
            activityMultiplier = 1.3
        }
        
        baseGoal *= activityMultiplier
        
        // Gender adjustments (slight difference)
        let genderMultiplier: Double
        switch profile.gender {
        case .male:
            genderMultiplier = 1.05
        case .female:
            genderMultiplier = 1.0
        case .other:
            genderMultiplier = 1.025
        }
        
        baseGoal *= genderMultiplier
        
        return baseGoal
    }
    
    /// Calculates temperature adjustment for water goal
    /// - Returns: Additional water needed in liters
    private func calculateTemperatureAdjustment() -> Double {
        let threshold = Constants.temperatureThreshold
        let additionalPerDegree = Constants.additionalWaterPerDegree
        
        if currentTemperature > threshold {
            return (currentTemperature - threshold) * additionalPerDegree
        }
        
        return 0.0
    }
    
    // MARK: - Animation Optimizations
    
    private func setupAnimations() {
        // Replace Timer with more efficient animation
        startEfficientAnimation()
    }
    
    private func startEfficientAnimation() {
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if !Task.isCancelled {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            self.isAnimating.toggle()
                        }
                    }
                }
            }
        }
    }
    
    private func triggerAnimation() {
        withAnimation(.easeInOut(duration: Constants.AnimationDuration.standard)) {
            isAnimating = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(Constants.AnimationDuration.standard * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeInOut(duration: Constants.AnimationDuration.standard)) {
                    self.isAnimating = false
                }
            }
        }
    }
    
    private func showGoalReachedCelebration() {
        showingCelebration = true
        
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            await MainActor.run {
                showingCelebration = false
            }
        }
    }
    
    // MARK: - Publisher Setup
    
    private func setupPublishers() {
        // Monitor changes to trigger goal recalculation
        $userProfile
            .combineLatest($currentTemperature, $smartGoalEnabled)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.recalculatePersonalizedGoal()
            }
            .store(in: &cancellables)
    }
}

 