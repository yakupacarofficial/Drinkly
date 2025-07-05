//
//  Constants.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation

/// App-wide constants
enum Constants {
    
    // MARK: - Water Intake
    
    /// Default daily water goal in liters
    static let defaultDailyGoal: Double = 2.5
    
    /// Minimum daily water goal in liters
    static let minimumDailyGoal: Double = 1.0
    
    /// Maximum daily water goal in liters
    static let maximumDailyGoal: Double = 5.0
    
    /// Quick drink amounts in liters
    static let quickDrinkAmounts: [Double] = [0.2, 0.3, 0.5, 0.75, 1.0]
    
    // MARK: - Smart Goal
    
    /// Base water goal for smart calculation
    static let baseWaterGoal: Double = 2.0
    
    /// Temperature threshold for smart goal adjustment
    static let temperatureThreshold: Double = 25.0
    
    /// Additional water per degree above threshold
    static let additionalWaterPerDegree: Double = 0.15
    
    /// Maximum smart goal in liters
    static let maximumSmartGoal: Double = 5.0
    
    // MARK: - UserDefaults Keys
    
    /// UserDefaults keys
    enum UserDefaultsKeys {
        static let todayDrinks = "today_drinks"
        static let dailyGoal = "daily_goal"
        static let smartGoalEnabled = "smart_goal_enabled"
        static let lastTemperature = "last_temperature"
        static let userCity = "user_city"
        static let reminderTime = "drinkly_reminder_time"
        static let savedCity = "drinkly_user_city"
    }
    
    // MARK: - Animation
    
    /// Animation durations
    enum AnimationDuration {
        static let quick: Double = 0.2
        static let standard: Double = 0.3
        static let slow: Double = 0.8
        static let celebration: Double = 1.5
    }
    
    // MARK: - UI
    
    /// UI constants
    enum UI {
        static let cornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 50
        static let progressCircleSize: CGFloat = 200
        static let progressStrokeWidth: CGFloat = 20
    }
    
    // MARK: - Messages
    
    /// App messages
    enum Messages {
        static let goalReached = "🎉 Congratulations! You've reached your daily water goal!"
        static let locationPermissionDenied = "Location access denied. Please enable in Settings."
        static let notificationPermissionDenied = "Please enable notifications in Settings to receive daily reminders."
        static let dataSaveError = "Failed to save data"
        static let locationError = "Failed to get city"
        static let cityNotFound = "Could not determine city name"
    }
} 