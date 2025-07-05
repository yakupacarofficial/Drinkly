//
//  MainView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Main view of the Drinkly app
struct MainView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var waterManager: WaterManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var performanceMonitor: PerformanceMonitor
    @EnvironmentObject private var hydrationHistory: HydrationHistory
    @EnvironmentObject private var achievementManager: AchievementManager
    @EnvironmentObject private var smartReminderManager: SmartReminderManager
    
    // MARK: - State Properties
    @State private var selectedTab: Tab = .home
    @State private var showingSettings = false
    @State private var showingProfile = false
    @State private var showingStatistics = false
    @State private var showingAchievements = false
    @State private var showingSmartReminders = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum Tab {
        case home, statistics, achievements, reminders
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            homeView
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(Tab.home)
            
            // Statistics Tab
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Statistics")
                }
                .tag(Tab.statistics)
            
            // Achievements Tab
            AchievementsView()
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Achievements")
                }
                .tag(Tab.achievements)
            
            // Smart Reminders Tab
            SmartRemindersView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Reminders")
                }
                .tag(Tab.reminders)
        }
        .accentColor(.blue)
        .onAppear {
            setupApp()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(existingProfile: waterManager.userProfile)
        }
        .overlay(
            Group {
                if achievementManager.showingUnlockAnimation,
                   let achievement = achievementManager.recentUnlocks.last {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            AchievementUnlockView(
                                achievement: achievement,
                                isShowing: $achievementManager.showingUnlockAnimation
                            )
                            .padding()
                        )
                }
            }
        )
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView("Loading...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
        )
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Home View
    private var homeView: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with weather and location
                        headerSection
                        
                        // Main progress circle
                        ProgressCircleView()
                            .frame(height: 300)
                        
                        // Quick actions
                        quickActionsSection
                        
                        // Today's summary
                        todaySummarySection
                        
                        // Recent achievements
                        recentAchievementsSection
                        
                        // Smart reminders preview
                        smartRemindersPreview
                    }
                    .padding()
                }
            }
            .navigationTitle("Drinkly")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Weather and location info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(locationManager.city.isEmpty ? "Location" : locationManager.city)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f°C", waterManager.currentTemperature))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Smart goal indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Smart Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: waterManager.smartGoalEnabled ? "brain.head.profile" : "brain.head.profile.slash")
                            .foregroundColor(waterManager.smartGoalEnabled ? .blue : .gray)
                        Text(waterManager.smartGoalEnabled ? "Active" : "Disabled")
                            .font(.caption)
                            .foregroundColor(waterManager.smartGoalEnabled ? .blue : .gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Goal status
            goalStatusCard
        }
    }
    
    // MARK: - Goal Status Card
    private var goalStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Goal")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(String(format: "%.1fL / %.1fL", waterManager.currentAmount, waterManager.dailyGoal))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(waterManager.progressColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1fL", waterManager.remainingAmount))
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            
            // Progress bar
            ProgressView(value: waterManager.progressPercentage / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: waterManager.progressColor))
                .frame(height: 8)
            
            Text(waterManager.goalStatus.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Add Water",
                    subtitle: "Log your intake",
                    color: .blue
                ) {
                    waterManager.showingDrinkOptions = true
                }
                
                QuickActionCard(
                    icon: "chart.bar.fill",
                    title: "Statistics",
                    subtitle: "View your progress",
                    color: .green
                ) {
                    selectedTab = .statistics
                }
                
                QuickActionCard(
                    icon: "trophy.fill",
                    title: "Achievements",
                    subtitle: "See your badges",
                    color: .orange
                ) {
                    selectedTab = .achievements
                }
                
                QuickActionCard(
                    icon: "bell.fill",
                    title: "Reminders",
                    subtitle: "Manage alerts",
                    color: .purple
                ) {
                    selectedTab = .reminders
                }
            }
        }
    }
    
    // MARK: - Today Summary Section
    private var todaySummarySection: some View {
        VStack(spacing: 16) {
            Text("Today's Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                SummaryCard(
                    title: "Drinks",
                    value: "\(waterManager.todayDrinks.count)",
                    subtitle: "Today",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Average",
                    value: String(format: "%.1fL", averageDrinkSize),
                    subtitle: "Per drink",
                    color: .green
                )
                
                SummaryCard(
                    title: "Streak",
                    value: "\(hydrationHistory.currentStreak)",
                    subtitle: "Days",
                    color: .orange
                )
                
                SummaryCard(
                    title: "Goal Met",
                    value: waterManager.isGoalMet ? "Yes" : "No",
                    subtitle: "Today",
                    color: waterManager.isGoalMet ? .green : .red
                )
            }
        }
    }
    
    // MARK: - Recent Achievements Section
    private var recentAchievementsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .achievements
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if achievementManager.recentUnlocks.isEmpty {
                Text("No recent achievements")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(achievementManager.recentUnlocks.prefix(3)) { achievement in
                            RecentAchievementCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Smart Reminders Preview
    private var smartRemindersPreview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Upcoming Reminders")
                    .font(.headline)
                
                Spacer()
                
                Button("Manage") {
                    selectedTab = .reminders
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            let upcomingReminders = smartReminderManager.reminders
                .filter { $0.isEnabled }
                .sorted { $0.time < $1.time }
                .prefix(3)
            
            if upcomingReminders.isEmpty {
                Text("No active reminders")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(upcomingReminders), id: \.id) { reminder in
                        ReminderPreviewRow(reminder: reminder)
                    }
                }
            }
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Computed Properties
    private var averageDrinkSize: Double {
        guard !waterManager.todayDrinks.isEmpty else { return 0 }
        let total = waterManager.todayDrinks.reduce(0) { $0 + $1.amount }
        return total / Double(waterManager.todayDrinks.count)
    }
    
    // MARK: - Helper Methods
    private func setupApp() {
        performanceMonitor.startTiming("app_setup")
        
        // Set up dependencies
        waterManager.setDependencies(
            hydrationHistory: hydrationHistory,
            achievementManager: achievementManager,
            smartReminderManager: smartReminderManager
        )
        
        // Request location permissions
        locationManager.requestLocationPermission()
        
        // Request notification permissions
        notificationManager.requestAuthorization()
        
        // Analyze drinking patterns for smart reminders
        smartReminderManager.analyzeAndSuggest()
        
        performanceMonitor.endTiming("app_setup")
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SummaryCard: View {
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

struct RecentAchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(achievement.category.color)
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80, height: 80)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ReminderPreviewRow: View {
    let reminder: SmartReminder
    
    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.blue)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.time.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(reminder.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if reminder.isAdaptive {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .environmentObject(WaterManager())
        .environmentObject(LocationManager())
        .environmentObject(NotificationManager.shared)
        .environmentObject(PerformanceMonitor.shared)
        .environmentObject(HydrationHistory())
        .environmentObject(AchievementManager())
        .environmentObject(SmartReminderManager())
} 