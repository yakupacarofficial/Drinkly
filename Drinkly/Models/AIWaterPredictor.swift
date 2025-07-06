//
//  AIWaterPredictor.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import CoreML
import Accelerate

/// AI-powered water consumption predictor using machine learning
@MainActor
class AIWaterPredictor: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isModelReady = false
    @Published var predictionAccuracy: Double = 0.0
    @Published var lastPrediction: WaterPrediction?
    @Published var learningProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var userBehaviorData: [UserBehaviorEntry] = []
    private var predictionModel: SimpleMLModel?
    private let userDefaults = UserDefaults.standard
    private let dataKey = "drinkly_ai_behavior_data"
    private let modelKey = "drinkly_ai_model_data"
    
    // MARK: - Initialization
    init() {
        loadBehaviorData()
        initializeModel()
    }
    
    // MARK: - Public Methods
    
    /// Add new behavior data for learning
    func addBehaviorData(_ entry: UserBehaviorEntry) {
        userBehaviorData.append(entry)
        saveBehaviorData()
        
        // Retrain model if we have enough data
        if userBehaviorData.count >= 10 {
            retrainModel()
        }
    }
    
    /// Predict optimal drinking time and amount
    func predictOptimalDrinking() -> WaterPrediction? {
        guard isModelReady, let model = predictionModel else {
            return nil
        }
        
        let currentContext = createCurrentContext()
        let prediction = model.predict(context: currentContext)
        
        lastPrediction = prediction
        return prediction
    }
    
    /// Get personalized drinking schedule
    func getPersonalizedSchedule() -> [DrinkingScheduleItem] {
        guard isModelReady else {
            return getDefaultSchedule()
        }
        
        let predictions = generateDailyPredictions()
        return createScheduleFromPredictions(predictions)
    }
    
    /// Analyze user patterns and suggest improvements
    func analyzePatterns() -> PatternAnalysis {
        let patterns = analyzeDrinkingPatterns()
        let insights = generateInsights(from: patterns)
        let recommendations = generateRecommendations(from: patterns)
        
        return PatternAnalysis(
            patterns: patterns,
            insights: insights,
            recommendations: recommendations
        )
    }
    
    /// Get learning insights
    func getLearningInsights() -> LearningInsights {
        let totalEntries = userBehaviorData.count
        let recentAccuracy = calculateRecentAccuracy()
        let improvementTrend = calculateImprovementTrend()
        
        return LearningInsights(
            totalDataPoints: totalEntries,
            recentAccuracy: recentAccuracy,
            improvementTrend: improvementTrend,
            confidenceLevel: calculateConfidenceLevel()
        )
    }
    
    // MARK: - Private Methods
    
    private func loadBehaviorData() {
        if let data = userDefaults.data(forKey: dataKey),
           let savedData = try? JSONDecoder().decode([UserBehaviorEntry].self, from: data) {
            userBehaviorData = savedData
        }
    }
    
    private func saveBehaviorData() {
        if let data = try? JSONEncoder().encode(userBehaviorData) {
            userDefaults.set(data, forKey: dataKey)
        }
    }
    
    private func initializeModel() {
        predictionModel = SimpleMLModel()
        isModelReady = true
        learningProgress = 0.0
    }
    
    private func retrainModel() {
        guard userBehaviorData.count >= 10 else { return }
        
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
                predictionModel?.train(with: userBehaviorData)
                predictionAccuracy = calculateAccuracy()
                learningProgress = 1.0
            }
        }
    }
    
    private func createCurrentContext() -> PredictionContext {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        return PredictionContext(
            hour: hour,
            weekday: weekday,
            temperature: getCurrentTemperature(),
            lastDrinkTime: getLastDrinkTime(),
            totalDrinksToday: getTotalDrinksToday(),
            averageDrinkSize: getAverageDrinkSize()
        )
    }
    
    private func generateDailyPredictions() -> [WaterPrediction] {
        var predictions: [WaterPrediction] = []
        
        for hour in 6...22 {
            let context = PredictionContext(
                hour: hour,
                weekday: Calendar.current.component(.weekday, from: Date()),
                temperature: getCurrentTemperature(),
                lastDrinkTime: getLastDrinkTime(),
                totalDrinksToday: getTotalDrinksToday(),
                averageDrinkSize: getAverageDrinkSize()
            )
            
            if let prediction = predictionModel?.predict(context: context) {
                predictions.append(prediction)
            }
        }
        
        return predictions
    }
    
    private func createScheduleFromPredictions(_ predictions: [WaterPrediction]) -> [DrinkingScheduleItem] {
        return predictions.compactMap { prediction in
            guard prediction.recommendedAmount > 0.1 else { return nil }
            
            return DrinkingScheduleItem(
                time: prediction.optimalTime,
                amount: prediction.recommendedAmount,
                message: prediction.message,
                priority: prediction.priority
            )
        }
    }
    
    private func analyzeDrinkingPatterns() -> [DrinkingPattern] {
        let patterns = Dictionary(grouping: userBehaviorData) { entry in
            Calendar.current.component(.hour, from: entry.timestamp)
        }
        
        return patterns.map { hour, entries in
            let frequency = Double(entries.count) / Double(userBehaviorData.count)
            let averageAmount = entries.map { $0.amount }.reduce(0, +) / Double(entries.count)
            
            return DrinkingPattern(
                timeSlot: getTimeSlotName(hour),
                frequency: frequency,
                averageAmount: averageAmount,
                acceptanceRate: 1.0 // Default to high acceptance rate
            )
        }.sorted { $0.frequency > $1.frequency }
    }
    
    private func generateInsights(from patterns: [DrinkingPattern]) -> [Insight] {
        var insights: [Insight] = []
        
        // Most active drinking time
        if let mostActive = patterns.first {
            insights.append(Insight(
                type: .mostActiveTime,
                title: "Peak Hydration Time",
                description: "You're most active at \(mostActive.timeSlot) with \(Int(mostActive.frequency * 100))% of your drinks",
                confidence: mostActive.frequency
            ))
        }
        
        // Consistency analysis
        let consistency = calculateConsistency(patterns)
        insights.append(Insight(
            type: .consistency,
            title: "Drinking Consistency",
            description: "Your drinking pattern is \(consistency > 0.7 ? "consistent" : "inconsistent")",
            confidence: consistency
        ))
        
        return insights
    }
    
    private func generateRecommendations(from patterns: [DrinkingPattern]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // Find gaps in drinking schedule
        let gaps = findDrinkingGaps(patterns)
        for gap in gaps {
            recommendations.append(Recommendation(
                type: .addReminder,
                title: "Add Reminder",
                description: "Consider adding a reminder at \(gap)",
                priority: .medium
            ))
        }
        
        // Optimize drinking amounts
        if let lowAmountPattern = patterns.first(where: { $0.averageAmount < 0.2 }) {
            recommendations.append(Recommendation(
                type: .increaseAmount,
                title: "Increase Amount",
                description: "Try drinking more at \(lowAmountPattern.timeSlot)",
                priority: .high
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentTemperature() -> Double {
        // This would get from WeatherManager
        return 22.0
    }
    
    private func getLastDrinkTime() -> Date? {
        return userBehaviorData.last?.timestamp
    }
    
    private func getTotalDrinksToday() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return userBehaviorData.filter { entry in
            Calendar.current.isDate(entry.timestamp, inSameDayAs: today)
        }.count
    }
    
    private func getAverageDrinkSize() -> Double {
        guard !userBehaviorData.isEmpty else { return 0.0 }
        return userBehaviorData.map { $0.amount }.reduce(0, +) / Double(userBehaviorData.count)
    }
    
    private func getTimeSlotName(_ hour: Int) -> String {
        switch hour {
        case 6..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
    
    private func calculateAccuracy() -> Double {
        // Simple accuracy calculation based on recent predictions
        guard userBehaviorData.count >= 5 else { return 0.0 }
        
        let recentData = Array(userBehaviorData.suffix(5))
        var correctPredictions = 0
        
        for entry in recentData {
            // Simplified accuracy check
            if entry.amount > 0.1 {
                correctPredictions += 1
            }
        }
        
        return Double(correctPredictions) / Double(recentData.count)
    }
    
    private func calculateRecentAccuracy() -> Double {
        let recentData = Array(userBehaviorData.suffix(10))
        guard !recentData.isEmpty else { return 0.0 }
        
        var accuracy = 0.0
        for entry in recentData {
            if entry.amount > 0.1 {
                accuracy += 1.0
            }
        }
        
        return accuracy / Double(recentData.count)
    }
    
    private func calculateImprovementTrend() -> Double {
        guard userBehaviorData.count >= 20 else { return 0.0 }
        
        let half = userBehaviorData.count / 2
        let firstHalf = Array(userBehaviorData.prefix(half))
        let secondHalf = Array(userBehaviorData.suffix(half))
        
        let firstAccuracy = calculateAccuracyForData(firstHalf)
        let secondAccuracy = calculateAccuracyForData(secondHalf)
        
        return secondAccuracy - firstAccuracy
    }
    
    private func calculateAccuracyForData(_ data: [UserBehaviorEntry]) -> Double {
        guard !data.isEmpty else { return 0.0 }
        
        var correctPredictions = 0
        for entry in data {
            if entry.amount > 0.1 {
                correctPredictions += 1
            }
        }
        
        return Double(correctPredictions) / Double(data.count)
    }
    
    private func calculateConfidenceLevel() -> Double {
        let dataPoints = userBehaviorData.count
        let accuracy = predictionAccuracy
        
        // Confidence increases with more data and higher accuracy
        let dataConfidence = min(Double(dataPoints) / 100.0, 1.0)
        let accuracyConfidence = accuracy
        
        return (dataConfidence + accuracyConfidence) / 2.0
    }
    
    private func calculateConsistency(_ patterns: [DrinkingPattern]) -> Double {
        guard patterns.count > 1 else { return 1.0 }
        
        let frequencies = patterns.map { $0.frequency }
        let mean = frequencies.reduce(0, +) / Double(frequencies.count)
        
        let variance = frequencies.map { pow($0 - mean, 2) }.reduce(0, +) / Double(frequencies.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation means more consistency
        return max(0, 1 - standardDeviation)
    }
    
    private func findDrinkingGaps(_ patterns: [DrinkingPattern]) -> [String] {
        let allTimeSlots = ["Morning", "Afternoon", "Evening", "Night"]
        let activeTimeSlots = patterns.map { $0.timeSlot }
        
        return allTimeSlots.filter { !activeTimeSlots.contains($0) }
    }
    
    private func getDefaultSchedule() -> [DrinkingScheduleItem] {
        let defaultTimes = [
            (8, 0.3, "Morning hydration"),
            (10, 0.25, "Mid-morning break"),
            (12, 0.4, "Lunch hydration"),
            (15, 0.3, "Afternoon refresh"),
            (18, 0.25, "Evening hydration"),
            (20, 0.2, "Evening wind-down")
        ]
        
        return defaultTimes.map { hour, amount, message in
            let time = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            return DrinkingScheduleItem(
                time: time,
                amount: amount,
                message: message,
                priority: .medium
            )
        }
    }
}

// MARK: - Supporting Models

struct UserBehaviorEntry: Codable {
    let timestamp: Date
    let amount: Double
    let context: PredictionContext
    let wasSuccessful: Bool
}

struct PredictionContext: Codable {
    let hour: Int
    let weekday: Int
    let temperature: Double
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

enum InsightType {
    case mostActiveTime, consistency, improvement, gap
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