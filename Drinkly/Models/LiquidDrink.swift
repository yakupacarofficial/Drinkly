//
//  LiquidDrink.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI

/// Sıvı türleri (su, kahve, çay, soda, enerji içeceği, diğer)
enum LiquidType: String, CaseIterable, Codable {
    case water = "Water"
    case coffee = "Coffee"
    case tea = "Tea"
    case soda = "Soda"
    case energyDrink = "Energy Drink"
    case other = "Other"
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .water: return "drop.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .tea: return "leaf.fill"
        case .soda: return "bubbles.and.sparkles.fill"
        case .energyDrink: return "bolt.fill"
        case .other: return "drop.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .water: return .blue
        case .coffee: return .brown
        case .tea: return .green
        case .soda: return .orange
        case .energyDrink: return .yellow
        case .other: return .purple
        }
    }
    
    var defaultCaffeine: Int? {
        switch self {
        case .water: return 0
        case .coffee: return 80 // mg (standart 1 fincan)
        case .tea: return 40
        case .soda: return 35
        case .energyDrink: return 80
        case .other: return nil
        }
    }
    
    var defaultCalories: Int? {
        switch self {
        case .water: return 0
        case .coffee: return 2
        case .tea: return 2
        case .soda: return 140
        case .energyDrink: return 110
        case .other: return nil
        }
    }
}

/// Represents a liquid drink with type, amount, and optional properties
struct LiquidDrink: Codable, Identifiable, Equatable {
    var id = UUID()
    let type: LiquidType
    let name: String
    let amount: Double // in ml
    let caffeine: Int? // in mg
    let calories: Int? // in kcal
    let date: Date
    
    init(type: LiquidType, name: String, amount: Double, caffeine: Int? = nil, calories: Int? = nil, date: Date = Date()) {
        self.type = type
        self.name = name
        self.amount = amount
        self.caffeine = caffeine
        self.calories = calories
        self.date = date
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, type, name, amount, caffeine, calories, date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(LiquidType.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        caffeine = try container.decodeIfPresent(Int.self, forKey: .caffeine)
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        date = try container.decode(Date.self, forKey: .date)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encodeIfPresent(caffeine, forKey: .caffeine)
        try container.encodeIfPresent(calories, forKey: .calories)
        try container.encode(date, forKey: .date)
    }
    
    // MARK: - Equatable
    static func == (lhs: LiquidDrink, rhs: LiquidDrink) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.name == rhs.name &&
               lhs.amount == rhs.amount &&
               lhs.caffeine == rhs.caffeine &&
               lhs.calories == rhs.calories &&
               lhs.date == rhs.date
    }
}

// MARK: - Time-based Data Models

/// Time range for statistics
enum TimeRange: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

/// Hourly data model
struct HourlyData: Identifiable, Codable {
    var id = UUID()
    let hour: Int
    let amount: Double
    let caffeine: Int
    let drinkCount: Int
}

/// Daily data model
struct DailyData: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let amount: Double
    let caffeine: Int
    let drinkCount: Int
}

/// Monthly data model
struct MonthlyData: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let amount: Double
    let caffeine: Int
    let drinkCount: Int
}

/// Unified time data model for charts
struct TimeData: Identifiable {
    var id: UUID
    let label: String
    let value: Double
    let date: Date
    let caffeine: Int
    let drinkCount: Int
    
    init(from hourlyData: HourlyData) {
        self.id = UUID()
        self.label = "\(hourlyData.hour):00"
        self.value = hourlyData.amount
        self.date = Calendar.current.date(bySettingHour: hourlyData.hour, minute: 0, second: 0, of: Date()) ?? Date()
        self.caffeine = hourlyData.caffeine
        self.drinkCount = hourlyData.drinkCount
    }
    
    init(from dailyData: DailyData) {
        self.id = UUID()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        self.label = formatter.string(from: dailyData.date)
        self.value = dailyData.amount
        self.date = dailyData.date
        self.caffeine = dailyData.caffeine
        self.drinkCount = dailyData.drinkCount
    }
    
    init(from monthlyData: MonthlyData) {
        self.id = UUID()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        self.label = formatter.string(from: monthlyData.date)
        self.value = monthlyData.amount
        self.date = monthlyData.date
        self.caffeine = monthlyData.caffeine
        self.drinkCount = monthlyData.drinkCount
    }
    
    // Custom initializer for creating TimeData manually
    init(id: UUID = UUID(), label: String, value: Double, date: Date, caffeine: Int, drinkCount: Int) {
        self.id = id
        self.label = label
        self.value = value
        self.date = date
        self.caffeine = caffeine
        self.drinkCount = drinkCount
    }
} 