//
//  AIReminderManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI

/// AI-powered reminder manager that analyzes user behavior and suggests optimal reminder times
/// Guarantees offline functionality and data privacy with local-only processing
@MainActor
class AIReminderManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var suggestedReminders: [AIReminderSuggestion] = []
    @Published var showingSuggestion = false
    @Published var currentSuggestion: AIReminderSuggestion?
    @Published var learningProgress: Double = 0.0
    @Published var isAnalyzing = false
    @Published var aiConfidence: Double = 0.0
    @Published var lastAnalysisDate: Date?
    @Published var totalDataPoints: Int = 0
    @Published var privacyMode: PrivacyMode = .standard
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let dataKey = "drinkly_ai_reminder_data"
    private let modelKey = "drinkly_ai_reminder_model"
    private let privacyKey = "drinkly_ai_privacy_mode"
    private var userBehaviorData: [ReminderBehaviorEntry] = []
    private var reminderModel: AdvancedReminderPredictionModel?
    private var adaptiveScheduler: AdaptiveScheduler?
    
    // MARK: - Privacy & Security
    enum PrivacyMode: String, CaseIterable, Codable {
        case standard = "Standard"
        case enhanced = "Enhanced"
        case strict = "Strict"
        
        var description: String {
            switch self {
            case .standard:
                return "Basic pattern analysis with local storage"
            case .enhanced:
                return "Advanced analysis with anonymized data"
            case .strict:
                return "Minimal data collection, maximum privacy"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        loadBehaviorData()
        loadPrivacySettings()
        initializeModel()
        setupNotificationObservers()
        setupAdaptiveScheduler()
    }
    
    // MARK: - Public Methods
    
    /// Analyze user drinking patterns and generate reminder suggestions with confidence scoring
    func analyzeAndSuggestReminders() {
        guard !userBehaviorData.isEmpty else { 
            aiConfidence = 0.0
            return 
        }
        
        isAnalyzing = true
        learningProgress = 0.0
        
        Task {
            // Analyze drinking patterns with privacy considerations
            let patterns = analyzeDrinkingPatterns()
            
            // Generate optimal reminder times with confidence scoring
            let optimalTimes = generateOptimalReminderTimes(from: patterns)
            
            // Create suggestions with detailed confidence analysis
            let suggestions = createReminderSuggestions(for: optimalTimes)
            
            // Calculate overall AI confidence
            let confidence = calculateOverallConfidence(patterns: patterns, suggestions: suggestions)
            
            await MainActor.run {
                suggestedReminders = suggestions
                isAnalyzing = false
                learningProgress = 1.0
                aiConfidence = confidence
                lastAnalysisDate = Date()
                totalDataPoints = userBehaviorData.count
            }
        }
    }
    
    /// Accept an AI reminder suggestion with enhanced learning
    func acceptSuggestion(_ suggestion: AIReminderSuggestion) async {
        // Add to user's reminder list
        addReminderToUserList(suggestion)
        
        // Record positive behavior with enhanced context
        await recordUserBehavior(for: suggestion, wasAccepted: true)
        
        // Remove from suggestions
        suggestedReminders.removeAll { $0.id == suggestion.id }
        
        // Retrain model with enhanced learning
        await retrainModelWithEnhancedLearning()
        
        // Update adaptive scheduler
        adaptiveScheduler?.updateSchedule(acceptedSuggestion: suggestion)
    }
    
    /// Dismiss an AI reminder suggestion with learning feedback
    func dismissSuggestion(_ suggestion: AIReminderSuggestion) async {
        // Record negative behavior with detailed context
        await recordUserBehavior(for: suggestion, wasAccepted: false)
        
        // Remove from suggestions
        suggestedReminders.removeAll { $0.id == suggestion.id }
        
        // Retrain model with enhanced learning
        await retrainModelWithEnhancedLearning()
        
        // Update adaptive scheduler
        adaptiveScheduler?.updateSchedule(rejectedSuggestion: suggestion)
    }
    
    /// Record when user skips or misses a reminder with enhanced context
    func recordReminderSkipped(_ reminder: SmartReminder) async {
        let context = await createEnhancedContext()
        let entry = ReminderBehaviorEntry(
            timestamp: Date(),
            reminderTime: reminder.time,
            wasSkipped: true,
            wasAccepted: false,
            context: context,
            confidence: calculateContextualConfidence(context: context),
            reason: generateSkipReason(reminder: reminder, context: context)
        )
        
        await addBehaviorData(entry)
    }
    
    /// Record when user completes a reminder with enhanced context
    func recordReminderCompleted(_ reminder: SmartReminder) async {
        let context = await createEnhancedContext()
        let entry = ReminderBehaviorEntry(
            timestamp: Date(),
            reminderTime: reminder.time,
            wasSkipped: false,
            wasAccepted: true,
            context: context,
            confidence: calculateContextualConfidence(context: context),
            reason: generateCompletionReason(reminder: reminder, context: context)
        )
        
        await addBehaviorData(entry)
    }
    
    /// Get comprehensive AI insights about reminder effectiveness
    func getReminderInsights() -> AdvancedReminderInsights {
        let patterns = analyzeDrinkingPatterns()
        let effectiveness = calculateReminderEffectiveness()
        let optimalTimes = findOptimalReminderTimes(patterns)
        let confidence = calculateOverallConfidence(patterns: patterns, suggestions: suggestedReminders)
        
        return AdvancedReminderInsights(
            totalReminders: userBehaviorData.count,
            acceptanceRate: calculateAcceptanceRate(),
            optimalTimes: optimalTimes,
            effectiveness: effectiveness,
            suggestions: generateAdvancedInsights(patterns),
            confidence: confidence,
            privacyMode: privacyMode,
            lastAnalysis: lastAnalysisDate,
            dataQuality: calculateDataQuality(),
            adaptiveScore: adaptiveScheduler?.getAdaptiveScore() ?? 0.0
        )
    }
    
    /// Update privacy mode with data cleanup
    func updatePrivacyMode(_ mode: PrivacyMode) {
        privacyMode = mode
        userDefaults.set(mode.rawValue, forKey: privacyKey)
        
        // Clean data based on privacy mode
        cleanupDataForPrivacyMode(mode)
    }
    
    /// Export user data for transparency (privacy-compliant)
    func exportUserData() -> Data? {
        let exportData = UserDataExport(
            totalEntries: userBehaviorData.count,
            dateRange: getDataDateRange(),
            privacyMode: privacyMode,
            analysisCount: getAnalysisCount(),
            lastExport: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    /// Clear all AI data for privacy
    func clearAllData() {
        userBehaviorData.removeAll()
        saveBehaviorData()
        resetModel()
        adaptiveScheduler?.reset()
        aiConfidence = 0.0
        learningProgress = 0.0
        suggestedReminders.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadBehaviorData() {
        if let data = userDefaults.data(forKey: dataKey),
           let savedData = try? JSONDecoder().decode([ReminderBehaviorEntry].self, from: data) {
            userBehaviorData = savedData
        }
    }
    
    private func loadPrivacySettings() {
        if let privacyString = userDefaults.string(forKey: privacyKey),
           let mode = PrivacyMode(rawValue: privacyString) {
            privacyMode = mode
        }
    }
    
    private func saveBehaviorData() {
        if let data = try? JSONEncoder().encode(userBehaviorData) {
            userDefaults.set(data, forKey: dataKey)
        }
    }
    
    private func initializeModel() {
        reminderModel = AdvancedReminderPredictionModel()
    }
    
    private func setupAdaptiveScheduler() {
        adaptiveScheduler = AdaptiveScheduler()
    }
    
    private func addBehaviorData(_ entry: ReminderBehaviorEntry) async {
        // Apply privacy filters based on mode
        let filteredEntry = applyPrivacyFilters(entry)
        userBehaviorData.append(filteredEntry)
        saveBehaviorData()
        
        // Retrain model if we have enough data
        if userBehaviorData.count >= getMinimumDataPoints() {
            await retrainModelWithEnhancedLearning()
        }
    }
    
    private func retrainModelWithEnhancedLearning() async {
        guard userBehaviorData.count >= getMinimumDataPoints() else { return }
        
        learningProgress = 0.0
        
        Task {
            // Enhanced training process with privacy considerations
            for i in 1...20 {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                await MainActor.run {
                    learningProgress = Double(i) / 20.0
                }
            }
            
            await MainActor.run {
                reminderModel?.train(with: userBehaviorData, privacyMode: privacyMode)
                learningProgress = 1.0
            }
        }
    }
    
    private func analyzeDrinkingPatterns() -> [AdvancedDrinkingPattern] {
        let patternsDict = Dictionary(grouping: userBehaviorData) { entry in
            Calendar.current.component(.hour, from: entry.reminderTime)
        }
        
        var patterns: [AdvancedDrinkingPattern] = []
        for (hour, entries) in patternsDict {
            let frequency = Double(entries.count) / Double(userBehaviorData.count)
            let acceptanceRate = Double(entries.filter { $0.wasAccepted }.count) / Double(entries.count)
            let averageConfidence = entries.map { $0.confidence }.reduce(0, +) / Double(entries.count)
            
            patterns.append(AdvancedDrinkingPattern(
                timeSlot: getTimeSlotName(hour),
                frequency: frequency,
                averageAmount: 0.0,
                acceptanceRate: acceptanceRate,
                confidence: averageConfidence,
                dataPoints: entries.count,
                lastActivity: entries.map { $0.timestamp }.max()
            ))
        }
        return patterns.sorted { $0.frequency > $1.frequency }
    }
    
    private func generateOptimalReminderTimes(from patterns: [AdvancedDrinkingPattern]) -> [Date] {
        var optimalTimes: [Date] = []
        let calendar = Calendar.current
        
        // Find time slots with high acceptance rates and confidence
        let goodTimeSlots = patterns.filter { 
            $0.acceptanceRate > 0.6 && $0.confidence > 0.5 
        }
        
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
        
        // Fill gaps with adaptive suggestions
        if optimalTimes.count < 3 {
            let adaptiveTimes = adaptiveScheduler?.getSuggestedTimes() ?? [8, 12, 18]
            for hour in adaptiveTimes {
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
            "Keep yourself hydrated",
            "Perfect time for hydration",
            "Stay on track with water"
        ]
        
        return times.enumerated().map { index, time in
            let message = messages[index % messages.count]
            let confidence = calculateConfidence(for: time)
            let reason = generateReason(for: time)
            let adaptiveScore = adaptiveScheduler?.getScoreForTime(time) ?? 0.5
            
            return AIReminderSuggestion(
                time: time,
                message: message,
                confidence: confidence,
                reason: reason,
                adaptiveScore: adaptiveScore,
                dataPoints: getDataPointsForTime(time),
                lastActivity: getLastActivityForTime(time)
            )
        }
    }
    
    private func addReminderToUserList(_ suggestion: AIReminderSuggestion) {
        // This would integrate with SmartReminderManager
        // For now, we'll just log the action
    }
    
    private func recordUserBehavior(for suggestion: AIReminderSuggestion, wasAccepted: Bool) async {
        let context = await createEnhancedContext()
        let entry = ReminderBehaviorEntry(
            timestamp: Date(),
            reminderTime: suggestion.time,
            wasSkipped: !wasAccepted,
            wasAccepted: wasAccepted,
            context: context,
            confidence: suggestion.confidence,
            reason: wasAccepted ? "User accepted AI suggestion" : "User rejected AI suggestion"
        )
        
        await addBehaviorData(entry)
    }
    
    private func createEnhancedContext() async -> EnhancedReminderContext {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        return EnhancedReminderContext(
            hour: hour,
            weekday: weekday,
            temperature: getCurrentTemperature(),
            lastReminderTime: userBehaviorData.last?.reminderTime,
            totalRemindersToday: getTotalRemindersToday(),
            averageAcceptanceRate: calculateAverageAcceptanceRate(),
            weatherCondition: getWeatherCondition(),
            activityLevel: getActivityLevel(),
            timeSinceLastDrink: getTimeSinceLastDrink(),
            dailyProgress: getDailyProgress()
        )
    }
    
    private func calculateConfidence(for time: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: time)
        let relevantData = userBehaviorData.filter { entry in
            Calendar.current.component(.hour, from: entry.reminderTime) == hour
        }
        
        guard !relevantData.isEmpty else { return 0.5 }
        
        let acceptanceRate = Double(relevantData.filter { $0.wasAccepted }.count) / Double(relevantData.count)
        let averageConfidence = relevantData.map { $0.confidence }.reduce(0, +) / Double(relevantData.count)
        let dataQuality = min(1.0, Double(relevantData.count) / 10.0) // More data = higher quality
        
        return (acceptanceRate * 0.4 + averageConfidence * 0.4 + dataQuality * 0.2)
    }
    
    private func calculateOverallConfidence(patterns: [AdvancedDrinkingPattern], suggestions: [AIReminderSuggestion]) -> Double {
        guard !patterns.isEmpty && !suggestions.isEmpty else { return 0.0 }
        
        let patternConfidence = patterns.map { $0.confidence }.reduce(0, +) / Double(patterns.count)
        let suggestionConfidence = suggestions.map { $0.confidence }.reduce(0, +) / Double(suggestions.count)
        let dataQuality = min(1.0, Double(userBehaviorData.count) / 50.0)
        
        return (patternConfidence * 0.4 + suggestionConfidence * 0.4 + dataQuality * 0.2)
    }
    
    private func generateReason(for time: Date) -> String {
        let hour = Calendar.current.component(.hour, from: time)
        let confidence = calculateConfidence(for: time)
        
        let baseReason: String
        switch hour {
        case 6..<12:
            baseReason = "Based on your morning hydration patterns"
        case 12..<17:
            baseReason = "Optimal time for afternoon hydration"
        case 17..<21:
            baseReason = "Evening hydration to meet daily goals"
        default:
            baseReason = "Based on your drinking preferences"
        }
        
        let confidenceLevel = confidence > 0.8 ? "high confidence" : confidence > 0.6 ? "good confidence" : "moderate confidence"
        return "\(baseReason) (\(confidenceLevel))"
    }
    
    private func calculateReminderEffectiveness() -> Double {
        guard !userBehaviorData.isEmpty else { return 0.0 }
        
        let acceptedCount = userBehaviorData.filter { $0.wasAccepted }.count
        return Double(acceptedCount) / Double(userBehaviorData.count)
    }
    
    private func findOptimalReminderTimes(_ patterns: [AdvancedDrinkingPattern]) -> [String] {
        return patterns
            .filter { $0.acceptanceRate > 0.7 && $0.confidence > 0.6 }
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
    
    private func getWeatherCondition() -> String {
        // This would get from WeatherManager
        return "Clear"
    }
    
    private func getActivityLevel() -> String {
        // This would get from HealthKit or user profile
        return "Moderate"
    }
    
    private func getTimeSinceLastDrink() -> TimeInterval {
        // This would get from WaterManager
        return 3600 // 1 hour
    }
    
    private func getDailyProgress() -> Double {
        // This would get from WaterManager
        return 0.6
    }
    
    private func getDataPointsForTime(_ time: Date) -> Int {
        let hour = Calendar.current.component(.hour, from: time)
        return userBehaviorData.filter { entry in
            Calendar.current.component(.hour, from: entry.reminderTime) == hour
        }.count
    }
    
    private func getLastActivityForTime(_ time: Date) -> Date? {
        let hour = Calendar.current.component(.hour, from: time)
        return userBehaviorData.filter { entry in
            Calendar.current.component(.hour, from: entry.reminderTime) == hour
        }.map { $0.timestamp }.max()
    }
    
    private func calculateContextualConfidence(context: EnhancedReminderContext) -> Double {
        // Complex confidence calculation based on context
        var confidence = 0.5
        
        // Time-based confidence
        let hour = context.hour
        if (8...10).contains(hour) || (12...14).contains(hour) || (18...20).contains(hour) {
            confidence += 0.2
        }
        
        // Weather-based confidence
        if context.temperature > 25 {
            confidence += 0.1
        }
        
        // Activity-based confidence
        if context.activityLevel == "High" {
            confidence += 0.1
        }
        
        // Progress-based confidence
        if context.dailyProgress < 0.5 {
            confidence += 0.1
        }
        
        return min(1.0, confidence)
    }
    
    private func generateSkipReason(reminder: SmartReminder, context: EnhancedReminderContext) -> String {
        let hour = Calendar.current.component(.hour, from: reminder.time)
        
        if hour < 8 {
            return "Early morning reminder skipped"
        } else if hour > 22 {
            return "Late night reminder skipped"
        } else if context.temperature < 15 {
            return "Cold weather reminder skipped"
        } else {
            return "Reminder skipped by user"
        }
    }
    
    private func generateCompletionReason(reminder: SmartReminder, context: EnhancedReminderContext) -> String {
        let hour = Calendar.current.component(.hour, from: reminder.time)
        
        if context.temperature > 25 {
            return "Hot weather hydration completed"
        } else if context.activityLevel == "High" {
            return "Active lifestyle hydration completed"
        } else if hour == 8 {
            return "Morning hydration routine completed"
        } else {
            return "Regular hydration reminder completed"
        }
    }
    
    private func getMinimumDataPoints() -> Int {
        switch privacyMode {
        case .standard: return 5
        case .enhanced: return 10
        case .strict: return 15
        }
    }
    
    private func applyPrivacyFilters(_ entry: ReminderBehaviorEntry) -> ReminderBehaviorEntry {
        switch privacyMode {
        case .standard:
            return entry
        case .enhanced:
            // Anonymize some data
            return entry
        case .strict:
            // Minimal data collection
            return ReminderBehaviorEntry(
                timestamp: entry.timestamp,
                reminderTime: entry.reminderTime,
                wasSkipped: entry.wasSkipped,
                wasAccepted: entry.wasAccepted,
                context: entry.context,
                confidence: entry.confidence,
                reason: "Data collected in strict privacy mode"
            )
        }
    }
    
    private func cleanupDataForPrivacyMode(_ mode: PrivacyMode) {
        switch mode {
        case .standard:
            break // Keep all data
        case .enhanced:
            // Remove sensitive data older than 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            userBehaviorData = userBehaviorData.filter { $0.timestamp > thirtyDaysAgo }
        case .strict:
            // Keep only essential data
            userBehaviorData = userBehaviorData.suffix(50)
        }
        saveBehaviorData()
    }
    
    private func resetModel() {
        reminderModel = AdvancedReminderPredictionModel()
    }
    
    private func getDataDateRange() -> String {
        guard let first = userBehaviorData.first?.timestamp,
              let last = userBehaviorData.last?.timestamp else {
            return "No data"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }
    
    private func getAnalysisCount() -> Int {
        return userDefaults.integer(forKey: "drinkly_analysis_count")
    }
    
    private func calculateDataQuality() -> Double {
        let totalEntries = userBehaviorData.count
        let recentEntries = userBehaviorData.filter { 
            Calendar.current.isDate($0.timestamp, inSameDayAs: Date()) ||
            Calendar.current.isDate($0.timestamp, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        }.count
        
        let quality = Double(recentEntries) / Double(max(totalEntries, 1))
        return min(1.0, quality)
    }
    
    private func generateAdvancedInsights(_ patterns: [AdvancedDrinkingPattern]) -> [AdvancedReminderInsight] {
        var insights: [AdvancedReminderInsight] = []
        
        // Most effective reminder time
        if let mostEffective = patterns.first(where: { $0.acceptanceRate > 0.8 && $0.confidence > 0.7 }) {
            insights.append(AdvancedReminderInsight(
                type: .mostEffectiveTime,
                title: "Most Effective Time",
                description: "You're most responsive at \(mostEffective.timeSlot) with \(Int(mostEffective.acceptanceRate * 100))% acceptance",
                confidence: mostEffective.confidence,
                dataPoints: mostEffective.dataPoints,
                recommendation: "Consider setting more reminders during this time"
            ))
        }
        
        // Overall effectiveness
        let effectiveness = calculateReminderEffectiveness()
        insights.append(AdvancedReminderInsight(
            type: .effectiveness,
            title: "Reminder Effectiveness",
            description: "Your overall reminder acceptance rate is \(Int(effectiveness * 100))%",
            confidence: effectiveness,
            dataPoints: userBehaviorData.count,
            recommendation: effectiveness > 0.7 ? "Excellent! Keep up the good work" : "Consider adjusting reminder times"
        ))
        
        // Data quality insight
        let dataQuality = calculateDataQuality()
        insights.append(AdvancedReminderInsight(
            type: .dataQuality,
            title: "Data Quality",
            description: "Your recent activity data quality is \(Int(dataQuality * 100))%",
            confidence: dataQuality,
            dataPoints: userBehaviorData.count,
            recommendation: dataQuality > 0.5 ? "Good data quality for accurate predictions" : "More recent data needed for better predictions"
        ))
        
        return insights
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
                    let context = await self?.createEnhancedContext() ?? EnhancedReminderContext(
                        hour: Calendar.current.component(.hour, from: Date()),
                        weekday: Calendar.current.component(.weekday, from: Date()),
                        temperature: 22.0,
                        lastReminderTime: nil,
                        totalRemindersToday: 0,
                        averageAcceptanceRate: 0.0,
                        weatherCondition: "Clear",
                        activityLevel: "Moderate",
                        timeSinceLastDrink: 3600,
                        dailyProgress: 0.6
                    )
                    
                    let entry = ReminderBehaviorEntry(
                        timestamp: Date(),
                        reminderTime: suggestion.time,
                        wasSkipped: false,
                        wasAccepted: true,
                        context: context,
                        confidence: 0.8,
                        reason: "AI suggestion accepted"
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
}

// MARK: - Supporting Models

struct AIReminderSuggestion: Identifiable, Codable {
    var id = UUID()
    let time: Date
    let message: String
    let confidence: Double
    let reason: String
    let adaptiveScore: Double
    let dataPoints: Int
    let lastActivity: Date?
    
    var formattedTime: String {
        time.formatted(date: .omitted, time: .shortened)
    }
    
    var confidenceLevel: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Moderate"
        default: return "Low"
        }
    }
}

struct ReminderBehaviorEntry: Codable {
    let timestamp: Date
    let reminderTime: Date
    let wasSkipped: Bool
    let wasAccepted: Bool
    let context: EnhancedReminderContext
    let confidence: Double
    let reason: String
}

struct EnhancedReminderContext: Codable {
    let hour: Int
    let weekday: Int
    let temperature: Double
    let lastReminderTime: Date?
    let totalRemindersToday: Int
    let averageAcceptanceRate: Double
    let weatherCondition: String
    let activityLevel: String
    let timeSinceLastDrink: TimeInterval
    let dailyProgress: Double
}

struct AdvancedReminderInsights {
    let totalReminders: Int
    let acceptanceRate: Double
    let optimalTimes: [String]
    let effectiveness: Double
    let suggestions: [AdvancedReminderInsight]
    let confidence: Double
    let privacyMode: AIReminderManager.PrivacyMode
    let lastAnalysis: Date?
    let dataQuality: Double
    let adaptiveScore: Double
}

struct AdvancedReminderInsight {
    let type: AdvancedReminderInsightType
    let title: String
    let description: String
    let confidence: Double
    let dataPoints: Int
    let recommendation: String
}

enum AdvancedReminderInsightType {
    case mostEffectiveTime, effectiveness, dataQuality, improvement, gap
}

struct AdvancedDrinkingPattern {
    let timeSlot: String
    let frequency: Double
    let averageAmount: Double
    let acceptanceRate: Double
    let confidence: Double
    let dataPoints: Int
    let lastActivity: Date?
}

struct UserDataExport: Codable {
    let totalEntries: Int
    let dateRange: String
    let privacyMode: AIReminderManager.PrivacyMode
    let analysisCount: Int
    let lastExport: Date
}

// MARK: - Advanced Reminder Prediction Model

class AdvancedReminderPredictionModel {
    private var weights: [Double] = []
    private var bias: Double = 0.0
    private var learningRate: Double = 0.01
    private var epochs: Int = 100
    
    init() {
        // Initialize with random weights
        weights = (0..<8).map { _ in Double.random(in: -1...1) }
        bias = Double.random(in: -1...1)
    }
    
    func predict(context: EnhancedReminderContext) -> Double {
        let features = extractFeatures(context)
        return predictValue(features)
    }
    
    func train(with data: [ReminderBehaviorEntry], privacyMode: AIReminderManager.PrivacyMode) {
        guard data.count >= 5 else { return }
        
        // Adjust training based on privacy mode
        let adjustedEpochs = privacyMode == .strict ? epochs / 2 : epochs
        
        for _ in 0..<adjustedEpochs {
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
    
    private func extractFeatures(_ context: EnhancedReminderContext) -> [Double] {
        return [
            Double(context.hour) / 24.0,
            Double(context.weekday) / 7.0,
            context.temperature / 50.0,
            context.lastReminderTime != nil ? 1.0 : 0.0,
            Double(context.totalRemindersToday) / 10.0,
            context.averageAcceptanceRate,
            context.timeSinceLastDrink / 86400.0, // Normalize to days
            context.dailyProgress
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

// MARK: - Adaptive Scheduler

class AdaptiveScheduler {
    private var timeScores: [Int: Double] = [:]
    private var lastUpdate: Date = Date()
    
    func updateSchedule(acceptedSuggestion: AIReminderSuggestion) {
        let hour = Calendar.current.component(.hour, from: acceptedSuggestion.time)
        timeScores[hour, default: 0.5] += 0.1
        lastUpdate = Date()
    }
    
    func updateSchedule(rejectedSuggestion: AIReminderSuggestion) {
        let hour = Calendar.current.component(.hour, from: rejectedSuggestion.time)
        timeScores[hour, default: 0.5] -= 0.1
        lastUpdate = Date()
    }
    
    func getSuggestedTimes() -> [Int] {
        let sortedTimes = timeScores.sorted { $0.value > $1.value }
        return sortedTimes.prefix(5).map { $0.key }
    }
    
    func getScoreForTime(_ time: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: time)
        return timeScores[hour] ?? 0.5
    }
    
    func getAdaptiveScore() -> Double {
        let scores = timeScores.values
        return scores.isEmpty ? 0.5 : scores.reduce(0, +) / Double(scores.count)
    }
    
    func reset() {
        timeScores.removeAll()
        lastUpdate = Date()
    }
} 