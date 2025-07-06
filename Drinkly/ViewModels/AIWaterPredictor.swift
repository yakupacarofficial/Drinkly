//
//  AIWaterPredictor.swift
//  Drinkly
//
//  Created by Yakup ACAR on 7.07.2025.
//

import Foundation
import SwiftUI

/// AI-powered water intake prediction and recommendation system
@MainActor
class AIWaterPredictor: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentPrediction: WaterPrediction?
    @Published var dailySchedule: [DrinkingScheduleItem] = []
    @Published var patternAnalysis: PatternAnalysis?
    @Published var learningInsights: LearningInsights?
    @Published var isAnalyzing = false
    @Published var lastUpdateTime: Date?
    
    // MARK: - Private Properties
    private let mlModel = SimpleMLModel()
    private var userBehaviorData: [UserBehaviorEntry] = []
    private let userDefaults = UserDefaults.standard
    private let dataKey = "AIWaterPredictor_UserBehaviorData"
    
    // MARK: - Initialization
    init() {
        loadUserBehaviorData()
        updatePredictions()
    }
    
    // MARK: - Public Methods
    
    /// Update predictions based on current context
    func updatePredictions() {
        isAnalyzing = true
        
        Task {
            let context = await buildCurrentContext()
            let prediction = mlModel.predict(context: context)
            
            await MainActor.run {
                self.currentPrediction = prediction
                self.lastUpdateTime = Date()
                self.isAnalyzing = false
            }
        }
    }
    
    /// Generate daily drinking schedule
    func generateDailySchedule() {
        Task {
            let schedule = await createDailySchedule()
            
            await MainActor.run {
                self.dailySchedule = schedule
            }
        }
    }
    
    /// Analyze drinking patterns
    func analyzePatterns() {
        Task {
            let analysis = await performPatternAnalysis()
            
            await MainActor.run {
                self.patternAnalysis = analysis
            }
        }
    }
    
    /// Record user behavior for learning
    func recordUserBehavior(amount: Double, wasSuccessful: Bool) {
        Task {
            let context = await buildCurrentContext()
            let entry = UserBehaviorEntry(
                timestamp: Date(),
                amount: amount,
                context: context,
                wasSuccessful: wasSuccessful
            )
            
            await MainActor.run {
                self.userBehaviorData.append(entry)
                self.saveUserBehaviorData()
                self.retrainModel()
            }
        }
    }
    
    /// Get explanation for current prediction
    func getPredictionExplanation() -> String {
        guard let prediction = currentPrediction else {
            return "No prediction available"
        }
        
        let confidence = Int(prediction.confidence * 100)
        let amount = String(format: "%.1f", prediction.recommendedAmount * 1000)
        
        return "AI suggests \(amount)ml with \(confidence)% confidence. \(prediction.message)"
    }
    
    /// Get learning insights
    func updateLearningInsights() {
        let totalDataPoints = userBehaviorData.count
        let recentAccuracy = calculateRecentAccuracy()
        let improvementTrend = calculateImprovementTrend()
        let confidenceLevel = calculateOverallConfidence()
        
        learningInsights = LearningInsights(
            totalDataPoints: totalDataPoints,
            recentAccuracy: recentAccuracy,
            improvementTrend: improvementTrend,
            confidenceLevel: confidenceLevel
        )
    }
    
    // MARK: - Private Methods
    
    private func buildCurrentContext() async -> PredictionContext {
        let now = Date()
        let calendar = Calendar.current
        
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let month = calendar.component(.month, from: now)
        
        // Get weather data (placeholder)
        let temperature = await getCurrentTemperature()
        let humidity = await getCurrentHumidity()
        let weatherCondition = await getCurrentWeatherCondition()
        let activityLevel = await getCurrentActivityLevel()
        
        // Get drinking history
        let lastDrinkTime = getLastDrinkTime()
        let totalDrinksToday = getTotalDrinksToday()
        let averageDrinkSize = getAverageDrinkSize()
        
        return PredictionContext(
            hour: hour,
            weekday: weekday,
            month: month,
            temperature: temperature,
            humidity: humidity,
            weatherCondition: weatherCondition,
            activityLevel: activityLevel,
            lastDrinkTime: lastDrinkTime,
            totalDrinksToday: totalDrinksToday,
            averageDrinkSize: averageDrinkSize
        )
    }
    
    private func createDailySchedule() async -> [DrinkingScheduleItem] {
        var schedule: [DrinkingScheduleItem] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Generate schedule for next 24 hours
        for hour in 0..<24 {
            guard let time = calendar.date(byAdding: .hour, value: hour, to: now) else { continue }
            
            let context = await buildContextForTime(time)
            let prediction = mlModel.predict(context: context)
            
            let scheduleItem = DrinkingScheduleItem(
                time: time,
                amount: prediction.recommendedAmount,
                message: prediction.message,
                priority: prediction.priority
            )
            
            schedule.append(scheduleItem)
        }
        
        return schedule
    }
    
    private func buildContextForTime(_ time: Date) async -> PredictionContext {
        let calendar = Calendar.current
        
        let hour = calendar.component(.hour, from: time)
        let weekday = calendar.component(.weekday, from: time)
        let month = calendar.component(.month, from: time)
        
        // Simplified context for future times
        return PredictionContext(
            hour: hour,
            weekday: weekday,
            month: month,
            temperature: 20.0, // Default temperature
            humidity: nil,
            weatherCondition: nil,
            activityLevel: nil,
            lastDrinkTime: nil,
            totalDrinksToday: 0,
            averageDrinkSize: 0.25
        )
    }
    
    private func performPatternAnalysis() async -> PatternAnalysis {
        let patterns = analyzeDrinkingPatterns()
        let insights = generateInsights(from: patterns)
        let recommendations = generateRecommendations(from: patterns, insights: insights)
        
        return PatternAnalysis(
            patterns: patterns,
            insights: insights,
            recommendations: recommendations
        )
    }
    
    private func analyzeDrinkingPatterns() -> [DrinkingPattern] {
        let timeSlots = ["Morning", "Afternoon", "Evening", "Night"]
        var patterns: [DrinkingPattern] = []
        
        for slot in timeSlots {
            let slotData = filterDataForTimeSlot(slot)
            let frequency = calculateFrequency(slotData)
            let averageAmount = calculateAverageAmount(slotData)
            let acceptanceRate = calculateAcceptanceRate(slotData)
            
            let pattern = DrinkingPattern(
                timeSlot: slot,
                frequency: frequency,
                averageAmount: averageAmount,
                acceptanceRate: acceptanceRate
            )
            
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func filterDataForTimeSlot(_ slot: String) -> [UserBehaviorEntry] {
        let calendar = Calendar.current
        
        return userBehaviorData.filter { entry in
            let hour = calendar.component(.hour, from: entry.timestamp)
            
            switch slot {
            case "Morning":
                return hour >= 6 && hour < 12
            case "Afternoon":
                return hour >= 12 && hour < 18
            case "Evening":
                return hour >= 18 && hour < 22
            case "Night":
                return hour >= 22 || hour < 6
            default:
                return false
            }
        }
    }
    
    private func calculateFrequency(_ data: [UserBehaviorEntry]) -> Double {
        guard !data.isEmpty else { return 0.0 }
        
        let successfulDrinks = data.filter { $0.wasSuccessful }.count
        return Double(successfulDrinks) / Double(data.count)
    }
    
    private func calculateAverageAmount(_ data: [UserBehaviorEntry]) -> Double {
        guard !data.isEmpty else { return 0.0 }
        
        let totalAmount = data.reduce(0.0) { $0 + $1.amount }
        return totalAmount / Double(data.count)
    }
    
    private func calculateAcceptanceRate(_ data: [UserBehaviorEntry]) -> Double {
        guard !data.isEmpty else { return 0.0 }
        
        let acceptedDrinks = data.filter { $0.wasSuccessful }.count
        return Double(acceptedDrinks) / Double(data.count)
    }
    
    private func generateInsights(from patterns: [DrinkingPattern]) -> [Insight] {
        var insights: [Insight] = []
        
        // Find most active time
        if let mostActive = patterns.max(by: { $0.frequency < $1.frequency }) {
            insights.append(Insight(
                type: .bestTime,
                title: "Most Active Time",
                description: "You're most active during \(mostActive.timeSlot.lowercased())",
                confidence: mostActive.frequency
            ))
        }
        
        // Consistency analysis
        let averageFrequency = patterns.map { $0.frequency }.reduce(0, +) / Double(patterns.count)
        insights.append(Insight(
            type: .consistency,
            title: "Consistency",
            description: "Your drinking consistency is \(Int(averageFrequency * 100))%",
            confidence: averageFrequency
        ))
        
        return insights
    }
    
    private func generateRecommendations(from patterns: [DrinkingPattern], insights: [Insight]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Find low frequency time slots
        let lowFrequencySlots = patterns.filter { $0.frequency < 0.3 }
        
        for slot in lowFrequencySlots {
            recommendations.append(Recommendation(
                type: .addReminder,
                title: "Add Reminder",
                description: "Consider adding reminders for \(slot.timeSlot.lowercased())",
                priority: .medium
            ))
        }
        
        return recommendations
    }
    
    private func retrainModel() {
        guard userBehaviorData.count >= 10 else { return }
        
        Task {
            mlModel.train(with: userBehaviorData)
            
            await MainActor.run {
                self.updatePredictions()
                self.updateLearningInsights()
            }
        }
    }
    
    private func calculateRecentAccuracy() -> Double {
        let recentData = userBehaviorData.suffix(20)
        guard !recentData.isEmpty else { return 0.0 }
        
        let successfulPredictions = recentData.filter { $0.wasSuccessful }.count
        return Double(successfulPredictions) / Double(recentData.count)
    }
    
    private func calculateImprovementTrend() -> Double {
        guard userBehaviorData.count >= 20 else { return 0.0 }
        
        let halfPoint = userBehaviorData.count / 2
        let firstHalf = Array(userBehaviorData.prefix(halfPoint))
        let secondHalf = Array(userBehaviorData.suffix(halfPoint))
        
        let firstAccuracy = calculateAccuracy(for: firstHalf)
        let secondAccuracy = calculateAccuracy(for: secondHalf)
        
        return secondAccuracy - firstAccuracy
    }
    
    private func calculateAccuracy(for data: [UserBehaviorEntry]) -> Double {
        guard !data.isEmpty else { return 0.0 }
        
        let successful = data.filter { $0.wasSuccessful }.count
        return Double(successful) / Double(data.count)
    }
    
    private func calculateOverallConfidence() -> Double {
        guard !userBehaviorData.isEmpty else { return 0.0 }
        
        let recentAccuracy = calculateRecentAccuracy()
        let dataPoints = min(userBehaviorData.count, 100)
        let dataConfidence = Double(dataPoints) / 100.0
        
        return (recentAccuracy + dataConfidence) / 2.0
    }
    
    // MARK: - Data Persistence
    
    private func saveUserBehaviorData() {
        do {
            let data = try JSONEncoder().encode(userBehaviorData)
            userDefaults.set(data, forKey: dataKey)
        } catch {
            print("Failed to save user behavior data: \(error)")
        }
    }
    
    private func loadUserBehaviorData() {
        guard let data = userDefaults.data(forKey: dataKey) else { return }
        
        do {
            userBehaviorData = try JSONDecoder().decode([UserBehaviorEntry].self, from: data)
        } catch {
            print("Failed to load user behavior data: \(error)")
            userBehaviorData = []
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentTemperature() async -> Double {
        // TODO: Integrate with WeatherManager
        return 20.0
    }
    
    private func getCurrentHumidity() async -> Int? {
        // TODO: Integrate with WeatherManager
        return 60
    }
    
    private func getCurrentWeatherCondition() async -> String? {
        // TODO: Integrate with WeatherManager
        return nil
    }
    
    private func getCurrentActivityLevel() async -> String? {
        // TODO: Integrate with UserProfile or HealthKit
        return nil
    }
    
    private func getLastDrinkTime() -> Date? {
        // TODO: Integrate with WaterManager
        return nil
    }
    
    private func getTotalDrinksToday() -> Int {
        // TODO: Integrate with WaterManager
        return 0
    }
    
    private func getAverageDrinkSize() -> Double {
        // TODO: Integrate with WaterManager
        return 0.25
    }
}

// MARK: - Supporting Models (GLOBAL SCOPE)

struct UserBehaviorEntry: Codable {
    let timestamp: Date
    let amount: Double
    let context: PredictionContext
    let wasSuccessful: Bool
}

struct PredictionContext: Codable {
    let hour: Int
    let weekday: Int
    let month: Int
    let temperature: Double
    let humidity: Int?
    let weatherCondition: String?
    let activityLevel: String?
    let lastDrinkTime: Date?
    let totalDrinksToday: Int
    let averageDrinkSize: Double
}

struct WaterPrediction {
    let optimalTime: Date
    let recommendedAmount: Double
    let message: String
    let priority: PredictionPriority
    let confidence: Double
}

enum PredictionPriority {
    case low, medium, high, critical
}

struct DrinkingScheduleItem {
    let time: Date
    let amount: Double
    let message: String
    let priority: PredictionPriority
}

struct PatternAnalysis {
    let patterns: [DrinkingPattern]
    let insights: [Insight]
    let recommendations: [Recommendation]
}

struct Insight {
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
}

struct Recommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let priority: PredictionPriority
}

enum RecommendationType {
    case addReminder, increaseAmount, adjustTime, optimizeSchedule
}

struct LearningInsights {
    let totalDataPoints: Int
    let recentAccuracy: Double
    let improvementTrend: Double
    let confidenceLevel: Double
}

// MARK: - Simple ML Model

class SimpleMLModel {
    private var weights: [Double] = []
    private var bias: Double = 0.0
    
    init() {
        // Initialize with random weights
        weights = (0..<7).map { _ in Double.random(in: -1...1) }
        bias = Double.random(in: -1...1)
    }
    
    func predict(context: PredictionContext) -> WaterPrediction {
        let features = extractFeatures(context)
        let prediction = predictValue(features)
        
        let optimalTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let recommendedAmount = max(0.1, min(0.5, prediction))
        
        return WaterPrediction(
            optimalTime: optimalTime,
            recommendedAmount: recommendedAmount,
            message: generateMessage(recommendedAmount),
            priority: determinePriority(recommendedAmount),
            confidence: calculateConfidence(features)
        )
    }
    
    func train(with data: [UserBehaviorEntry]) {
        guard data.count >= 5 else { return }
        
        // Simple gradient descent training
        let learningRate = 0.01
        let epochs = 100
        
        for _ in 0..<epochs {
            for entry in data {
                let features = extractFeatures(entry.context)
                let target = entry.amount
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
    
    private func extractFeatures(_ context: PredictionContext) -> [Double] {
        return [
            Double(context.hour) / 24.0,
            Double(context.weekday) / 7.0,
            context.temperature / 50.0,
            context.lastDrinkTime != nil ? 1.0 : 0.0,
            Double(context.totalDrinksToday) / 10.0,
            context.averageDrinkSize,
            context.lastDrinkTime != nil ? timeSinceLastDrink(context.lastDrinkTime!) : 0.0
        ]
    }
    
    private func predictValue(_ features: [Double]) -> Double {
        var sum = bias
        for i in 0..<min(weights.count, features.count) {
            sum += weights[i] * features[i]
        }
        return max(0, min(1, sum)) // Clamp between 0 and 1
    }
    
    private func timeSinceLastDrink(_ lastDrink: Date) -> Double {
        let timeInterval = Date().timeIntervalSince(lastDrink)
        return min(timeInterval / 3600.0, 24.0) / 24.0 // Normalize to 0-1
    }
    
    private func generateMessage(_ amount: Double) -> String {
        if amount > 0.4 {
            return "Time for a big drink! 💧"
        } else if amount > 0.2 {
            return "Stay hydrated with water"
        } else {
            return "Quick hydration reminder"
        }
    }
    
    private func determinePriority(_ amount: Double) -> PredictionPriority {
        if amount > 0.4 {
            return .critical
        } else if amount > 0.25 {
            return .high
        } else if amount > 0.15 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func calculateConfidence(_ features: [Double]) -> Double {
        // Simple confidence based on feature variance
        let mean = features.reduce(0, +) / Double(features.count)
        let variance = features.map { pow($0 - mean, 2) }.reduce(0, +) / Double(features.count)
        return max(0.1, min(1.0, 1 - sqrt(variance)))
    }
} 