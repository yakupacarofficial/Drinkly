//
//  Achievement.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI

/// Represents an achievement or badge that users can earn
struct Achievement: Codable, Identifiable, Equatable {
    var id: String
    let title: String
    let description: String
    let iconName: String
    let category: Category
    let requirement: Requirement
    let reward: Reward
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    enum Category: String, Codable, CaseIterable {
        case streak = "Streak"
        case total = "Total"
        case consistency = "Consistency"
        case special = "Special"
        
        var displayName: String {
            switch self {
            case .streak: return "Streak Achievements"
            case .total: return "Total Intake"
            case .consistency: return "Consistency"
            case .special: return "Special Events"
            }
        }
        
        var color: Color {
            switch self {
            case .streak: return .orange
            case .total: return .blue
            case .consistency: return .green
            case .special: return .purple
            }
        }
    }
    
    enum Requirement: Codable, Equatable {
        case streak(days: Int)
        case totalIntake(liters: Double)
        case consecutiveDays(days: Int)
        case perfectWeek
        case perfectMonth
        case specialEvent
        
        var description: String {
            switch self {
            case .streak(let days):
                return "Maintain a \(days)-day streak"
            case .totalIntake(let liters):
                return "Drink \(String(format: "%.0f", liters))L total"
            case .consecutiveDays(let days):
                return "Meet your goal for \(days) consecutive days"
            case .perfectWeek:
                return "Meet your goal every day for a week"
            case .perfectMonth:
                return "Meet your goal every day for a month"
            case .specialEvent:
                return "Complete a special challenge"
            }
        }
    }
    
    enum Reward: Codable, Equatable {
        case badge
        case title(String)
        case theme(String)
        
        var description: String {
            switch self {
            case .badge:
                return "Badge"
            case .title(let title):
                return "Title: \(title)"
            case .theme(let theme):
                return "Theme: \(theme)"
            }
        }
    }
    
    init(id: String, title: String, description: String, iconName: String, category: Category, requirement: Requirement, reward: Reward, isUnlocked: Bool = false, unlockedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.reward = reward
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
}

/// Manages achievements and badges
@MainActor
class AchievementManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var achievements: [Achievement] = []
    @Published var unlockedAchievements: [Achievement] = []
    @Published var recentUnlocks: [Achievement] = []
    @Published var showingUnlockAnimation = false
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "drinkly_achievements"
    private let unlockedKey = "drinkly_unlocked_achievements"
    
    // MARK: - Initialization
    init() {
        loadAchievements()
        loadUnlockedAchievements()
    }
    
    // MARK: - Public Methods
    
    /// Check and update achievements based on current stats
    func checkAchievements(currentStreak: Int, totalIntake: Double, consecutiveDays: Int, perfectWeek: Bool, perfectMonth: Bool) {
        var newUnlocks: [Achievement] = []
        
        for achievement in achievements where !achievement.isUnlocked {
            if isAchievementUnlocked(achievement, currentStreak: currentStreak, totalIntake: totalIntake, consecutiveDays: consecutiveDays, perfectWeek: perfectWeek, perfectMonth: perfectMonth) {
                let unlockedAchievement = Achievement(
                    id: achievement.id,
                    title: achievement.title,
                    description: achievement.description,
                    iconName: achievement.iconName,
                    category: achievement.category,
                    requirement: achievement.requirement,
                    reward: achievement.reward,
                    isUnlocked: true,
                    unlockedDate: Date()
                )
                
                newUnlocks.append(unlockedAchievement)
            }
        }
        
        // Unlock new achievements
        for achievement in newUnlocks {
            unlockAchievement(achievement)
        }
    }
    
    /// Get achievements by category
    func getAchievements(for category: Achievement.Category) -> [Achievement] {
        return achievements.filter { $0.category == category }
    }
    
    /// Get unlocked achievements by category
    func getUnlockedAchievements(for category: Achievement.Category) -> [Achievement] {
        return unlockedAchievements.filter { $0.category == category }
    }
    
    /// Get progress for an achievement
    func getProgress(for achievement: Achievement, currentStreak: Int, totalIntake: Double, consecutiveDays: Int) -> Double {
        switch achievement.requirement {
        case .streak(let days):
            return min(1.0, Double(currentStreak) / Double(days))
        case .totalIntake(let liters):
            return min(1.0, totalIntake / liters)
        case .consecutiveDays(let days):
            return min(1.0, Double(consecutiveDays) / Double(days))
        case .perfectWeek:
            return consecutiveDays >= 7 ? 1.0 : Double(consecutiveDays) / 7.0
        case .perfectMonth:
            return consecutiveDays >= 30 ? 1.0 : Double(consecutiveDays) / 30.0
        case .specialEvent:
            return 0.0 // Special events are manually triggered
        }
    }
    
    // MARK: - Private Methods
    
    private func loadUnlockedAchievements() {
        if let data = userDefaults.data(forKey: unlockedKey),
           let unlocked = try? JSONDecoder().decode([Achievement].self, from: data) {
            unlockedAchievements = unlocked
        }
    }
    
    func saveUnlockedAchievements() {
        if let data = try? JSONEncoder().encode(unlockedAchievements) {
            userDefaults.set(data, forKey: unlockedKey)
        }
    }
    
    func loadAchievements() {
        achievements = createDefaultAchievements()
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        unlockedAchievements.append(achievement)
        recentUnlocks.append(achievement)
        saveUnlockedAchievements()
        
        // Show unlock animation
        showingUnlockAnimation = true
        
        // Remove from recent unlocks after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let index = self.recentUnlocks.firstIndex(of: achievement) {
                self.recentUnlocks.remove(at: index)
            }
            self.showingUnlockAnimation = false
        }
    }
    
    private func isAchievementUnlocked(_ achievement: Achievement, currentStreak: Int, totalIntake: Double, consecutiveDays: Int, perfectWeek: Bool, perfectMonth: Bool) -> Bool {
        switch achievement.requirement {
        case .streak(let days):
            return currentStreak >= days
        case .totalIntake(let liters):
            return totalIntake >= liters
        case .consecutiveDays(let days):
            return consecutiveDays >= days
        case .perfectWeek:
            return perfectWeek
        case .perfectMonth:
            return perfectMonth
        case .specialEvent:
            return false // Special events are manually triggered
        }
    }
    
    private func createDefaultAchievements() -> [Achievement] {
        return [
            // Streak Achievements
            Achievement(
                id: "first_streak",
                title: "First Steps",
                description: "Complete your first day of hydration",
                iconName: "drop.fill",
                category: .streak,
                requirement: .streak(days: 1),
                reward: .badge
            ),
            
            Achievement(
                id: "week_streak",
                title: "Week Warrior",
                description: "Maintain a 7-day hydration streak",
                iconName: "calendar",
                category: .streak,
                requirement: .streak(days: 7),
                reward: .badge
            ),
            
            Achievement(
                id: "month_streak",
                title: "Monthly Master",
                description: "Maintain a 30-day hydration streak",
                iconName: "calendar.badge.clock",
                category: .streak,
                requirement: .streak(days: 30),
                reward: .title("Hydration Master")
            ),
            
            Achievement(
                id: "hundred_streak",
                title: "Century Club",
                description: "Maintain a 100-day hydration streak",
                iconName: "100.circle.fill",
                category: .streak,
                requirement: .streak(days: 100),
                reward: .theme("Golden")
            ),
            
            // Total Intake Achievements
            Achievement(
                id: "first_liter",
                title: "First Liter",
                description: "Drink your first liter of water",
                iconName: "drop.degreesign",
                category: .total,
                requirement: .totalIntake(liters: 1),
                reward: .badge
            ),
            
            Achievement(
                id: "hundred_liters",
                title: "Century Hydrator",
                description: "Drink 100 liters of water total",
                iconName: "drop.circle.fill",
                category: .total,
                requirement: .totalIntake(liters: 100),
                reward: .badge
            ),
            
            Achievement(
                id: "thousand_liters",
                title: "Thousand Club",
                description: "Drink 1000 liters of water total",
                iconName: "drop.triangle.fill",
                category: .total,
                requirement: .totalIntake(liters: 1000),
                reward: .title("Hydration Legend")
            ),
            
            // Consistency Achievements
            Achievement(
                id: "perfect_week",
                title: "Perfect Week",
                description: "Meet your goal every day for a week",
                iconName: "checkmark.circle.fill",
                category: .consistency,
                requirement: .perfectWeek,
                reward: .badge
            ),
            
            Achievement(
                id: "perfect_month",
                title: "Perfect Month",
                description: "Meet your goal every day for a month",
                iconName: "checkmark.circle.fill",
                category: .consistency,
                requirement: .perfectMonth,
                reward: .title("Consistency King")
            ),
            
            Achievement(
                id: "consecutive_week",
                title: "Week Champion",
                description: "Meet your goal for 7 consecutive days",
                iconName: "calendar.badge.plus",
                category: .consistency,
                requirement: .consecutiveDays(days: 7),
                reward: .badge
            ),
            
            Achievement(
                id: "consecutive_month",
                title: "Month Champion",
                description: "Meet your goal for 30 consecutive days",
                iconName: "calendar.badge.clock",
                category: .consistency,
                requirement: .consecutiveDays(days: 30),
                reward: .badge
            ),
            
            // Special Achievements
            Achievement(
                id: "early_bird",
                title: "Early Bird",
                description: "Drink water within 30 minutes of waking up",
                iconName: "sunrise.fill",
                category: .special,
                requirement: .specialEvent,
                reward: .badge
            ),
            
            Achievement(
                id: "night_owl",
                title: "Night Owl",
                description: "Stay hydrated late into the evening",
                iconName: "moon.fill",
                category: .special,
                requirement: .specialEvent,
                reward: .badge
            ),
            
            Achievement(
                id: "social_hydrator",
                title: "Social Hydrator",
                description: "Share your hydration progress with friends",
                iconName: "person.2.fill",
                category: .special,
                requirement: .specialEvent,
                reward: .badge
            )
        ]
    }
}

// MARK: - Achievement Unlock Animation View
struct AchievementUnlockView: View {
    let achievement: Achievement
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 48))
                .foregroundColor(achievement.category.color)
            
            Text("Achievement Unlocked!")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(achievement.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(achievement.category.color)
            
            Text(achievement.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(.orange)
                Text(achievement.reward.description)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .scaleEffect(isShowing ? 1.0 : 0.8)
        .opacity(isShowing ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowing)
    }
} 