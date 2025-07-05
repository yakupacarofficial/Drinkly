//
//  WaterDrink.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation

/// Represents a single water intake entry
struct WaterDrink: Codable, Identifiable, Equatable {
    var id = UUID()
    let amount: Double
    let timestamp: Date
    
    /// Formatted time string for display
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Amount in milliliters for display
    var amountInMilliliters: Int {
        return Int(amount * 1000)
    }
    
    /// Formatted amount string
    var formattedAmount: String {
        return "\(amountInMilliliters)ml"
    }
    
    // MARK: - Initialization
    init(amount: Double, timestamp: Date = Date()) {
        self.amount = amount
        self.timestamp = timestamp
    }
} 