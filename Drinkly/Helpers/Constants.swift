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
        static let progressCircleSize: CGFloat = 140
        static let progressStrokeWidth: CGFloat = 20
    }
    
    // MARK: - Performance
    
    /// Performance optimization constants
    enum Performance {
        static let debounceDelay: TimeInterval = 0.3
        static let progressUpdateInterval: TimeInterval = 2.0
        static let animationDuration: TimeInterval = 0.5
        static let celebrationDuration: TimeInterval = 3.0
        static let cacheTimeout: TimeInterval = 3600 // 1 hour
        static let locationCacheTimeout: TimeInterval = 300 // 5 minutes
    }
    
    // MARK: - Validation
    
    /// Input validation constants
    enum Validation {
        static let minWaterAmount: Double = 0.1
        static let maxWaterAmount: Double = 5.0
        static let minTemperature: Double = -50.0
        static let maxTemperature: Double = 60.0
        static let minAge: Int = 1
        static let maxAge: Int = 120
        static let minWeight: Double = 10.0
        static let maxWeight: Double = 300.0
    }
    
    // MARK: - Weather API
    
    /// OpenWeatherMap API configuration
    enum WeatherAPI {
        static let baseURL = "https://api.openweathermap.org/data/2.5"
        static let apiKey = "00ddac1192baf9f196b79a6dbabffa9d"
        static let cacheTimeout: TimeInterval = 3600 // 1 hour cache
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
        static let weatherFetchError = "Failed to fetch weather data"
        static let networkError = "Network error. Please check your connection."
        static let invalidInput = "Please enter a valid amount"
        static let profileUpdateSuccess = "Profile updated successfully"
        static let reminderAdded = "Reminder added successfully"
        static let reminderDeleted = "Reminder deleted successfully"
    }
    
    // MARK: - Error Codes
    
    /// Error codes for better error handling
    enum ErrorCodes {
        static let networkError = 1001
        static let locationError = 1002
        static let weatherError = 1003
        static let dataSaveError = 1004
        static let validationError = 1005
        static let permissionError = 1006
    }
} 