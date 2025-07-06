//
//  AchievementsView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var achievementManager: AchievementManager
    @EnvironmentObject private var hydrationHistory: HydrationHistory
    @State private var selectedCategory: Achievement.Category = .streak
    @State private var showingUnlockAnimation = false
    @State private var currentUnlockedAchievement: Achievement?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category selector
                categorySelector
                
                // Achievements list
                achievementsList
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stats") {
                        // Show achievement statistics
                    }
                }
            }
            .overlay(
                Group {
                    if showingUnlockAnimation, let achievement = currentUnlockedAchievement {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .overlay(
                                AchievementUnlockView(
                                    achievement: achievement,
                                    isShowing: $showingUnlockAnimation
                                )
                                .padding()
                            )
                            .onTapGesture {
                                showingUnlockAnimation = false
                            }
                    }
                }
            )
            .onReceive(achievementManager.$showingUnlockAnimation) { showing in
                if showing, let achievement = achievementManager.recentUnlocks.last {
                    currentUnlockedAchievement = achievement
                    showingUnlockAnimation = true
                }
            }
        }
    }
    
    // MARK: - Category Selector
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Achievement.Category.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        unlockedCount: achievementManager.getUnlockedAchievements(for: category).count,
                        totalCount: achievementManager.getAchievements(for: category).count
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Achievements List
    private var achievementsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(achievementManager.getAchievements(for: selectedCategory)) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        progress: getProgress(for: achievement),
                        isUnlocked: isAchievementUnlocked(achievement)
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    private func getProgress(for achievement: Achievement) -> Double {
        let totalIntake = hydrationHistory.dailyRecords.reduce(0) { $0 + $1.totalIntake }
        let consecutiveDays = calculateConsecutiveDays()
        
        return achievementManager.getProgress(
            for: achievement,
            currentStreak: hydrationHistory.currentStreak,
            totalIntake: totalIntake,
            consecutiveDays: consecutiveDays
        )
    }
    
    private func isAchievementUnlocked(_ achievement: Achievement) -> Bool {
        return achievementManager.unlockedAchievements.contains { $0.id == achievement.id }
    }
    
    private func calculateConsecutiveDays() -> Int {
        let sortedRecords = hydrationHistory.dailyRecords.sorted { $0.date < $1.date }
        var consecutiveDays = 0
        
        for record in sortedRecords.reversed() {
            if record.isGoalMet {
                consecutiveDays += 1
            } else {
                break
            }
        }
        
        return consecutiveDays
    }
    
    private func calculatePerfectWeek() -> Bool {
        let weekRecords = hydrationHistory.getWeeklyStats(for: 1)
        return weekRecords.first?.goalMetDays == 7
    }
    
    private func calculatePerfectMonth() -> Bool {
        let monthRecords = hydrationHistory.getMonthlyStats(for: 1)
        return monthRecords.first?.goalMetDays == monthRecords.first?.totalDays
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: Achievement.Category
    let isSelected: Bool
    let unlockedCount: Int
    let totalCount: Int
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: categoryIcon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : category.color)
            
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
            
            Text("\(unlockedCount)/\(totalCount)")
                .font(.caption2)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? category.color : Color(.systemBackground))
                .shadow(color: isSelected ? category.color.opacity(0.3) : .clear, radius: 4)
        )
        .onTapGesture {
            action()
        }
    }
    
    private var categoryIcon: String {
        switch category {
        case .streak: return "flame.fill"
        case .total: return "drop.fill"
        case .consistency: return "checkmark.circle.fill"
        case .special: return "star.fill"
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let progress: Double
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Achievement icon
                ZStack {
                    Circle()
                        .fill(isUnlocked ? achievement.category.color : Color(.systemGray4))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.iconName)
                        .font(.title2)
                        .foregroundColor(isUnlocked ? .white : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.headline)
                        .foregroundColor(isUnlocked ? .primary : .secondary)
                    
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    // Progress bar
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: achievement.category.color))
                        .frame(height: 4)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Unlock status
                VStack {
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                    
                    Text(achievement.reward.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Requirement details
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text(achievement.requirement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: isUnlocked ? achievement.category.color.opacity(0.1) : .clear, radius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? achievement.category.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Achievement Statistics View
struct AchievementStatsView: View {
    @EnvironmentObject private var achievementManager: AchievementManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Overall stats
            overallStats
            
            // Category breakdown
            categoryBreakdown
            
            // Recent unlocks
            recentUnlocks
        }
        .padding()
        .navigationTitle("Achievement Stats")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var overallStats: some View {
        VStack(spacing: 16) {
            Text("Overall Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Total Achievements",
                    value: "\(achievementManager.achievements.count)",
                    subtitle: "Available",
                    color: .blue
                )
                
                StatCard(
                    title: "Unlocked",
                    value: "\(achievementManager.unlockedAchievements.count)",
                    subtitle: "Completed",
                    color: .green
                )
                
                StatCard(
                    title: "Completion Rate",
                    value: String(format: "%.0f%%", completionRate),
                    subtitle: "Overall",
                    color: .orange
                )
                
                StatCard(
                    title: "Recent Unlocks",
                    value: "\(achievementManager.recentUnlocks.count)",
                    subtitle: "This week",
                    color: .purple
                )
            }
        }
    }
    
    private var categoryBreakdown: some View {
        VStack(spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(Achievement.Category.allCases, id: \.self) { category in
                CategoryProgressRow(
                    category: category,
                    unlockedCount: achievementManager.getUnlockedAchievements(for: category).count,
                    totalCount: achievementManager.getAchievements(for: category).count
                )
            }
        }
    }
    
    private var recentUnlocks: some View {
        VStack(spacing: 16) {
            Text("Recent Unlocks")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if achievementManager.recentUnlocks.isEmpty {
                Text("No recent achievements unlocked")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(achievementManager.recentUnlocks.prefix(5)) { achievement in
                    HStack {
                        Image(systemName: achievement.iconName)
                            .foregroundColor(achievement.category.color)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(achievement.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(achievement.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(achievement.unlockedDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var completionRate: Double {
        guard achievementManager.achievements.count > 0 else { return 0 }
        return (Double(achievementManager.unlockedAchievements.count) / Double(achievementManager.achievements.count)) * 100
    }
}

struct CategoryProgressRow: View {
    let category: Achievement.Category
    let unlockedCount: Int
    let totalCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: categoryIcon)
                .foregroundColor(category.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(unlockedCount) of \(totalCount) unlocked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.0f%%", progressPercentage))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(category.color)
        }
        .padding(.vertical, 8)
    }
    
    private var categoryIcon: String {
        switch category {
        case .streak: return "flame.fill"
        case .total: return "drop.fill"
        case .consistency: return "checkmark.circle.fill"
        case .special: return "star.fill"
        }
    }
    
    private var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return (Double(unlockedCount) / Double(totalCount)) * 100
    }
}

// MARK: - StatCard (Eksik Kart Bileşeni)
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    AchievementsView()
        .environmentObject(WaterManager())
        .environmentObject(LocationManager())
        .environmentObject(WeatherManager())
        .environmentObject(NotificationManager.shared)
        .environmentObject(PerformanceMonitor.shared)
        .environmentObject(HydrationHistory())
        .environmentObject(AchievementManager())
        .environmentObject(SmartReminderManager())
} 