//
//  DrinkingPattern.swift
//  Drinkly
//
//  Created by Yakup ACAR on 7.07.2025.
//

import Foundation

/// Represents a time-based drinking pattern for hydration analysis and AI
struct DrinkingPattern: Codable, Hashable {
    /// Name of the time slot (e.g., "Morning", "Afternoon")
    let timeSlot: String
    /// Frequency of drinking in this slot (0.0 - 1.0)
    let frequency: Double
    /// Average amount consumed in this slot (liters)
    let averageAmount: Double
    /// Acceptance rate for reminders in this slot (0.0 - 1.0)
    let acceptanceRate: Double
} 