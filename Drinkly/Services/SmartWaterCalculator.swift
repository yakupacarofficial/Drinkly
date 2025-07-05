//
//  SmartWaterCalculator.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation

class SmartWaterCalculator: ObservableObject {
    // Temel günlük su ihtiyacı (litre)
    private let baseWaterNeed: Double = 2.0
    
    // Sıcaklık eşiği (°C)
    private let temperatureThreshold: Double = 25.0
    
    // Her 1°C artış için ek su ihtiyacı (litre)
    private let additionalWaterPerDegree: Double = 0.15
    
    @Published var calculatedWaterGoal: Double = 2.0
    @Published var isSmartGoalEnabled: Bool = true
    
    init() {
        loadSettings()
    }
    
    func calculateWaterGoal(for temperature: Double) -> Double {
        guard isSmartGoalEnabled else {
            return baseWaterNeed
        }
        
        var goal = baseWaterNeed
        
        // Sıcaklık 25°C'den yüksekse ek su ekle
        if temperature > temperatureThreshold {
            let additionalWater = (temperature - temperatureThreshold) * additionalWaterPerDegree
            goal += additionalWater
        }
        
        // Minimum 2L, maksimum 5L
        goal = max(2.0, min(5.0, goal))
        
        calculatedWaterGoal = goal
        return goal
    }
    
    func getWaterGoalDescription(for temperature: Double) -> String {
        let goal = calculateWaterGoal(for: temperature)
        
        if temperature > temperatureThreshold {
            let additional = goal - baseWaterNeed
            return String(format: "%.1fL (%.1fL base + %.1fL for heat)", goal, baseWaterNeed, additional)
        } else {
            return String(format: "%.1fL (base recommendation)", goal)
        }
    }
    
    func toggleSmartGoal() {
        isSmartGoalEnabled.toggle()
        UserDefaults.standard.set(isSmartGoalEnabled, forKey: "drinkly_smart_goal_enabled")
    }
    
    private func loadSettings() {
        isSmartGoalEnabled = UserDefaults.standard.bool(forKey: "drinkly_smart_goal_enabled")
        if UserDefaults.standard.object(forKey: "drinkly_smart_goal_enabled") == nil {
            isSmartGoalEnabled = true // Default olarak açık
        }
    }
} 