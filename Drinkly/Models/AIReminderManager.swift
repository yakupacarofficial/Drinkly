//
//  AIReminderManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI

/// AI-powered reminder manager that analyzes user behavior and suggests optimal reminder times
@MainActor
class AIReminderManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var suggestedReminders: [AIReminderSuggestion] = []
    @Published var showingSuggestion = false
    @Published var currentSuggestion: AIReminderSuggestion?
    @Published var learningProgress: Double = 0.0
    @Published var isAnalyzing = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let dataKey = "drinkly_ai_reminder_data"
    private let modelKey = "drinkly_ai_reminder_model"
    private var userBehaviorData: [ReminderBehaviorEntry] = []
    private var reminderModel: ReminderPredictionModel?
    
    // MARK: - Initialization
    init() {
        loadBehaviorData()
        initializeModel()
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    /// Analyze user drinking patterns and generate reminder suggestions
    func analyzeAndSuggestReminders() {
        guard !userBehaviorData.isEmpty else { return }
        
        isAnalyzing = true
        learningProgress = 0.0
        
        Task {
            // Analyze drinking patterns
            let patterns = analyzeDrinkingPatterns()
            
            // Generate optimal reminder times
            let optimalTimes = generateOptimalReminderTimes(from: patterns)
            
            // Create suggestions
            let suggestions = createReminderSuggestions(for: optimalTimes)
            
            await MainActor.run {
                suggestedReminders = suggestions
                isAnalyzing = false
                learningProgress = 1.0
            }
        }
    }
    
    /// Accept an AI reminder suggestion
    func acceptSuggestion(_ suggestion: AIReminderSuggestion) async {
        // Add to user's reminder list
        addReminderToUserList(suggestion)
        
        // Record positive behavior
        await recordUserBehavior(for: suggestion, wasAccepted: true)
        
        // Remove from suggestions
        suggestedReminders.removeAll { $0.id == suggestion.id }
        
        // Retrain model
        retrainModel()
    }
    
    /// Dismiss an AI reminder suggestion
    func dismissSuggestion(_ suggestion: AIReminderSuggestion) async {
        // Record negative behavior
        await recordUserBehavior(for: suggestion, wasAccepted: false)
        
        // Remove from suggestions
        suggestedReminders.removeAll { $0.id == suggestion.id }
        
        // Retrain model
        retrainModel()
    }
    
    /// Record when user skips or misses a reminder
    func recordReminderSkipped(_ reminder: SmartReminder) async {
        let entry = ReminderBehaviorEntry(
            timestamp: Date(),
            reminderTime: reminder.time,
            wasSkipped: true,
            wasAccepted: false,
            context: await createCurrentContext()
        )
        
        await addBehaviorData(entry)
    }
    
    /// Record when user completes a reminder
    func recordReminderCompleted(_ reminder: SmartReminder) async {
        let entry = ReminderBehaviorEntry(
            timestamp: Date(),
            reminderTime: reminder.time,
            wasSkipped: false,
            wasAccepted: true,
            context: await createCurrentContext()
        )
        
        await addBehaviorData(entry)
    }
    
    /// Get AI insights about reminder effectiveness
    func getReminderInsights() -> ReminderInsights {
        let patterns = analyzeDrinkingPatterns()
        let effectiveness = calculateReminderEffectiveness()
        let optimalTimes = findOptimalReminderTimes(patterns)
        
        return ReminderInsights(
            totalReminders: userBehaviorData.count,
            acceptanceRate: calculateAcceptanceRate(),
            optimalTimes: optimalTimes,
            effectiveness: effectiveness,
            suggestions: generateInsights(patterns)
        )
    }
    
    // MARK: - Private Methods
    
    private func loadBehaviorData() {
        if let data = userDefaults.data(forKey: dataKey),
           let savedData = try? JSONDecoder().decode([ReminderBehaviorEntry].self, from: data) {
            userBehaviorData = savedData
        }
    }
    
    private func saveBehaviorData() {
        if let data = try? JSONEncoder().encode(userBehaviorData) {
            userDefaults.set(data, forKey: dataKey)
        }
    }
    
    private func initializeModel() {
        reminderModel = ReminderPredictionModel()
    }
    
    private func addBehaviorData(_ entry: ReminderBehaviorEntry) async {
        userBehaviorData.append(entry)
        saveBehaviorData()
        
        // Retrain model if we have enough data
        if userBehaviorData.count >= 5 {
            retrainModel()
        }
    }
    
    private func retrainModel() {
        guard userBehaviorData.count >= 5 else { return }
        
        learningProgress = 0.0
        
        Task {
            // Simulate training process
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await MainActor.run {
                    learningProgress = Double(i) / 10.0
                }
            }
            
            await MainActor.run {
                reminderModel?.train(with: userBehaviorData)
                learningProgress = 1.0
            }
        }
    }
    
    private func analyzeDrinkingPatterns() -> [DrinkingPattern] {
        let patternsDict = Dictionary(grouping: userBehaviorData) { entry in
            Calendar.current.component(.hour, from: entry.reminderTime)
        }
        var patterns: [DrinkingPattern] = []
        for (hour, entries) in patternsDict {
            let frequency = Double(entries.count) / Double(userBehaviorData.count)
            let acceptanceRate = Double(entries.filter { $0.wasAccepted }.count) / Double(entries.count)
            patterns.append(DrinkingPattern(
                timeSlot: getTimeSlotName(hour),
                frequency: frequency,
                averageAmount: 0.0,
                acceptanceRate: acceptanceRate
            ))
        }
        return patterns.sorted { $0.frequency > $1.frequency }
    }
    
    private func generateOptimalReminderTimes(from patterns: [DrinkingPattern]) -> [Date] {
        var optimalTimes: [Date] = []
        let calendar = Calendar.current
        // Find time slots with high acceptance rates
        let goodTimeSlots = patterns.filter { $0.acceptanceRate > 0.6 }
        for pattern in goodTimeSlots {
            let hour: Int
            switch pattern.timeSlot {
            case "Morning": hour = 8
            case "Mid-morning": hour = 10
            case "Lunch": hour = 12
            case "Afternoon": hour = 15
            case "Evening": hour = 18
            case "Night": hour = 20
            default: hour = 12
            }
            if let time = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) {
                optimalTimes.append(time)
            }
        }
        // Fill gaps if we don't have enough suggestions
        if optimalTimes.count < 3 {
            let defaultTimes = [8, 12, 18] // Morning, Lunch, Evening
            for hour in defaultTimes {
                if !optimalTimes.contains(where: { Calendar.current.component(.hour, from: $0) == hour }) {
                    if let time = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) {
                        optimalTimes.append(time)
                    }
                }
            }
        }
        return optimalTimes.sorted()
    }
    
    private func createReminderSuggestions(for times: [Date]) -> [AIReminderSuggestion] {
        let messages = [
            "Time to hydrate! 💧",
            "Stay refreshed with water",
            "Hydration reminder",
            "Don't forget to drink water",
            "Water break time!",
            "Keep yourself hydrated"
        ]
        
        return times.enumerated().map { index, time in
            let message = messages[index % messages.count]
            let confidence = calculateConfidence(for: time)
            
            return AIReminderSuggestion(
                time: time,
                message: message,
                confidence: confidence,
                reason: generateReason(for: time)
            )
        }
    }
    
    private func addReminderToUserList(_ suggestion: AIReminderSuggestion) {
        // This would integrate with SmartReminderManager
        // For now, we'll just log the action
        print("AI Reminder accepted: \(suggestion.time) - \(suggestion.message)")
    }
    
    private func recordUserBehavior(for suggestion: AIReminderSuggestion, wasAccepted: Bool) async {
        let entry = ReminderBehaviorEntry(
            timestamp: Date(),
            reminderTime: suggestion.time,
            wasSkipped: !wasAccepted,
            wasAccepted: wasAccepted,
            context: await createCurrentContext()
        )
        
        await addBehaviorData(entry)
    }
    
    private func createCurrentContext() async -> ReminderContext {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        return ReminderContext(
            hour: hour,
            weekday: weekday,
            temperature: getCurrentTemperature(),
            lastReminderTime: userBehaviorData.last?.reminderTime,
            totalRemindersToday: getTotalRemindersToday(),
            averageAcceptanceRate: calculateAverageAcceptanceRate()
        )
    }
    
    private func calculateConfidence(for time: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: time)
        let relevantData = userBehaviorData.filter { entry in
            Calendar.current.component(.hour, from: entry.reminderTime) == hour
        }
        
        guard !relevantData.isEmpty else { return 0.5 }
        
        let acceptanceRate = Double(relevantData.filter { $0.wasAccepted }.count) / Double(relevantData.count)
        return max(0.1, min(1.0, acceptanceRate))
    }
    
    private func generateReason(for time: Date) -> String {
        let hour = Calendar.current.component(.hour, from: time)
        
        switch hour {
        case 6..<12:
            return "Based on your morning hydration patterns"
        case 12..<17:
            return "Optimal time for afternoon hydration"
        case 17..<21:
            return "Evening hydration to meet daily goals"
        default:
            return "Based on your drinking preferences"
        }
    }
    
    private func calculateReminderEffectiveness() -> Double {
        guard !userBehaviorData.isEmpty else { return 0.0 }
        
        let acceptedCount = userBehaviorData.filter { $0.wasAccepted }.count
        return Double(acceptedCount) / Double(userBehaviorData.count)
    }
    
    private func findOptimalReminderTimes(_ patterns: [DrinkingPattern]) -> [String] {
        return patterns
            .filter { $0.acceptanceRate > 0.7 }
            .map { $0.timeSlot }
    }
    
    private func calculateAcceptanceRate() -> Double {
        guard !userBehaviorData.isEmpty else { return 0.0 }
        
        let acceptedCount = userBehaviorData.filter { $0.wasAccepted }.count
        return Double(acceptedCount) / Double(userBehaviorData.count)
    }
    
    private func calculateAverageAcceptanceRate() -> Double {
        guard !userBehaviorData.isEmpty else { return 0.0 }
        
        let totalRate = userBehaviorData.reduce(0.0) { sum, entry in
            sum + (entry.wasAccepted ? 1.0 : 0.0)
        }
        
        return totalRate / Double(userBehaviorData.count)
    }
    
    private func getTotalRemindersToday() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return userBehaviorData.filter { entry in
            Calendar.current.isDate(entry.timestamp, inSameDayAs: today)
        }.count
    }
    
    private func getCurrentTemperature() -> Double {
        // This would get from WeatherManager
        return 22.0
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .reminderSkipped,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let reminder = notification.userInfo?["reminder"] as? SmartReminder {
                Task { await self?.recordReminderSkipped(reminder) }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .reminderCompleted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let reminder = notification.userInfo?["reminder"] as? SmartReminder {
                Task { await self?.recordReminderCompleted(reminder) }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .suggestionAccepted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let suggestion = notification.userInfo?["suggestion"] as? SmartReminder {
                Task {
                    // Record positive behavior for accepted suggestions
                    let context = await self?.createCurrentContext() ?? ReminderContext(
                        hour: Calendar.current.component(.hour, from: Date()),
                        weekday: Calendar.current.component(.weekday, from: Date()),
                        temperature: 22.0,
                        lastReminderTime: nil,
                        totalRemindersToday: 0,
                        averageAcceptanceRate: 0.0
                    )
                    
                    let entry = ReminderBehaviorEntry(
                        timestamp: Date(),
                        reminderTime: suggestion.time,
                        wasSkipped: false,
                        wasAccepted: true,
                        context: context
                    )
                    await self?.addBehaviorData(entry)
                }
            }
        }
    }
    
    private func getTimeSlotName(_ hour: Int) -> String {
        switch hour {
        case 6..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
    
    private func generateInsights(_ patterns: [DrinkingPattern]) -> [ReminderInsight] {
        var insights: [ReminderInsight] = []
        
        // Most effective reminder time
        if let mostEffective = patterns.first(where: { $0.acceptanceRate > 0.8 }) {
            insights.append(ReminderInsight(
                type: .mostEffectiveTime,
                title: "Most Effective Time",
                description: "You're most responsive at \(mostEffective.timeSlot) with \(Int(mostEffective.acceptanceRate * 100))% acceptance",
                confidence: mostEffective.acceptanceRate
            ))
        }
        
        // Overall effectiveness
        let effectiveness = calculateReminderEffectiveness()
        insights.append(ReminderInsight(
            type: .effectiveness,
            title: "Reminder Effectiveness",
            description: "Your overall reminder acceptance rate is \(Int(effectiveness * 100))%",
            confidence: effectiveness
        ))
        
        return insights
    }
}

// MARK: - Supporting Models

struct AIReminderSuggestion: Identifiable, Codable {
    var id = UUID()
    let time: Date
    let message: String
    let confidence: Double
    let reason: String
    
    var formattedTime: String {
        time.formatted(date: .omitted, time: .shortened)
    }
}

struct ReminderBehaviorEntry: Codable {
    let timestamp: Date
    let reminderTime: Date
    let wasSkipped: Bool
    let wasAccepted: Bool
    let context: ReminderContext
}

struct ReminderContext: Codable {
    let hour: Int
    let weekday: Int
    let temperature: Double
    let lastReminderTime: Date?
    let totalRemindersToday: Int
    let averageAcceptanceRate: Double
}

struct ReminderInsights {
    let totalReminders: Int
    let acceptanceRate: Double
    let optimalTimes: [String]
    let effectiveness: Double
    let suggestions: [ReminderInsight]
}

struct ReminderInsight {
    let type: ReminderInsightType
    let title: String
    let description: String
    let confidence: Double
}

enum ReminderInsightType {
    case mostEffectiveTime, effectiveness, improvement, gap
} 

// MARK: - Reminder Prediction Model

class ReminderPredictionModel {
    private var weights: [Double] = []
    private var bias: Double = 0.0
    
    init() {
        // Initialize with random weights
        weights = (0..<6).map { _ in Double.random(in: -1...1) }
        bias = Double.random(in: -1...1)
    }
    
    func predict(context: ReminderContext) -> Double {
        let features = extractFeatures(context)
        return predictValue(features)
    }
    
    func train(with data: [ReminderBehaviorEntry]) {
        guard data.count >= 5 else { return }
        
        let learningRate = 0.01
        let epochs = 50
        
        for _ in 0..<epochs {
            for entry in data {
                let features = extractFeatures(entry.context)
                let target = entry.wasAccepted ? 1.0 : 0.0
                let prediction = predictValue(features)
                
                let error = target - prediction
                
                // Update weights
                for i in 0..<weights.count {
                    weights[i] += learningRate * error * features[i]
                }
                bias += learningRate * error
            }
        }
    }
    
    private func extractFeatures(_ context: ReminderContext) -> [Double] {
        return [
            Double(context.hour) / 24.0,
            Double(context.weekday) / 7.0,
            context.temperature / 50.0,
            context.lastReminderTime != nil ? 1.0 : 0.0,
            Double(context.totalRemindersToday) / 10.0,
            context.averageAcceptanceRate
        ]
    }
    
    private func predictValue(_ features: [Double]) -> Double {
        var sum = bias
        for i in 0..<min(weights.count, features.count) {
            sum += weights[i] * features[i]
        }
        return max(0, min(1, sum)) // Clamp between 0 and 1
    }
} 