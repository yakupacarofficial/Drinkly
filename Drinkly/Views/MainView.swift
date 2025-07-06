//
//  MainView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI
import Combine

/// Main view of the Drinkly app
struct MainView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var waterManager: WaterManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var weatherManager: WeatherManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var performanceMonitor: PerformanceMonitor
    @EnvironmentObject private var hydrationHistory: HydrationHistory
    @EnvironmentObject private var achievementManager: AchievementManager
    @EnvironmentObject private var smartReminderManager: SmartReminderManager
    @EnvironmentObject private var profilePictureManager: ProfilePictureManager
    @EnvironmentObject private var aiWaterPredictor: AIWaterPredictor
    @EnvironmentObject private var aiReminderManager: AIReminderManager
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var liquidManager = LiquidManager() // Yeni eklenen LiquidManager
    
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
    @State private var progressMode: ProgressMode = .water // Water Only / Total Liquid
    
    enum Tab {
        case home, statistics, achievements, reminders
    }
    
    enum ProgressMode: String, CaseIterable {
        case water = "Water Only"
        case total = "Total Liquid"
        
        var displayName: String { rawValue }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            homeView
                .environmentObject(waterManager)
                .environmentObject(locationManager)
                .environmentObject(weatherManager)
                .environmentObject(notificationManager)
                .environmentObject(performanceMonitor)
                .environmentObject(hydrationHistory)
                .environmentObject(achievementManager)
                .environmentObject(smartReminderManager)
                .environmentObject(profilePictureManager)
                .environmentObject(aiWaterPredictor)
                .environmentObject(aiReminderManager)
                .environmentObject(themeManager)
                .environmentObject(liquidManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(Tab.home)
            
            // Statistics Tab
            StatisticsView()
                .environmentObject(waterManager)
                .environmentObject(locationManager)
                .environmentObject(weatherManager)
                .environmentObject(notificationManager)
                .environmentObject(performanceMonitor)
                .environmentObject(hydrationHistory)
                .environmentObject(achievementManager)
                .environmentObject(smartReminderManager)
                .environmentObject(profilePictureManager)
                .environmentObject(aiWaterPredictor)
                .environmentObject(aiReminderManager)
                .environmentObject(themeManager)
                .environmentObject(liquidManager)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Statistics")
                }
                .tag(Tab.statistics)
            
            // Achievements Tab
            AchievementsView()
                .environmentObject(waterManager)
                .environmentObject(locationManager)
                .environmentObject(weatherManager)
                .environmentObject(notificationManager)
                .environmentObject(performanceMonitor)
                .environmentObject(hydrationHistory)
                .environmentObject(achievementManager)
                .environmentObject(smartReminderManager)
                .environmentObject(profilePictureManager)
                .environmentObject(aiWaterPredictor)
                .environmentObject(aiReminderManager)
                .environmentObject(themeManager)
                .environmentObject(liquidManager)
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Achievements")
                }
                .tag(Tab.achievements)
            
            // Smart Reminders Tab
            SmartRemindersView(smartReminderManager: smartReminderManager)
                .environmentObject(waterManager)
                .environmentObject(locationManager)
                .environmentObject(weatherManager)
                .environmentObject(notificationManager)
                .environmentObject(performanceMonitor)
                .environmentObject(hydrationHistory)
                .environmentObject(achievementManager)
                .environmentObject(smartReminderManager)
                .environmentObject(profilePictureManager)
                .environmentObject(aiWaterPredictor)
                .environmentObject(aiReminderManager)
                .environmentObject(themeManager)
                .environmentObject(liquidManager)
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
        .onChange(of: waterManager.todayDrinks) { _, _ in
            // WaterManager'dan su eklenince LiquidManager'ı güncelle
            let waterDrinks = waterManager.todayDrinks.map { drink in
                LiquidDrink(
                    type: .water,
                    name: "Water",
                    amount: drink.amount * 1000, // L'den ml'ye çevir
                    date: drink.timestamp
                )
            }
            
            // Sadece su içeceklerini güncelle, diğerlerini koru
            let otherDrinks = liquidManager.drinks.filter { $0.type != .water }
            liquidManager.drinks = waterDrinks + otherDrinks
            liquidManager.saveDrinks()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(waterManager)
                .environmentObject(locationManager)
                .environmentObject(weatherManager)
                .environmentObject(notificationManager)
                .environmentObject(performanceMonitor)
                .environmentObject(hydrationHistory)
                .environmentObject(achievementManager)
                .environmentObject(smartReminderManager)
                .environmentObject(profilePictureManager)
                .environmentObject(aiWaterPredictor)
                .environmentObject(aiReminderManager)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(existingProfile: waterManager.userProfile)
                .environmentObject(waterManager)
                .environmentObject(locationManager)
                .environmentObject(weatherManager)
                .environmentObject(notificationManager)
                .environmentObject(performanceMonitor)
                .environmentObject(hydrationHistory)
                .environmentObject(achievementManager)
                .environmentObject(smartReminderManager)
                .environmentObject(profilePictureManager)
                .environmentObject(aiWaterPredictor)
                .environmentObject(aiReminderManager)
                .environmentObject(themeManager)
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
                        
                        // Main progress circle (swipeable)
                        progressCircleSwitcher
                        
                        // Quick actions
                        quickActionsSection
                        
                        // Add Another Liquid button
                        addAnotherLiquidButton
                        
                        // Today's summary
                        todaySummarySection
                        
                        // AI Insights
                        aiInsightsSection
                        
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
                        ProfilePictureView(size: 32, showEditButton: false)
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
    
    // MARK: - Progress Circle Switcher
    private var progressCircleSwitcher: some View {
        TabView(selection: $progressMode) {
            ProgressCircleView(mode: .water)
                .environmentObject(liquidManager)
                .environmentObject(locationManager)
                .environmentObject(themeManager)
                .tag(ProgressMode.water)
            ProgressCircleView(mode: .total)
                .environmentObject(liquidManager)
                .environmentObject(locationManager)
                .environmentObject(themeManager)
                .tag(ProgressMode.total)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .frame(height: 320)
        .padding(.bottom, 8)
    }
    
    // MARK: - Add Another Liquid Button
    private var addAnotherLiquidButton: some View {
        Button(action: {
            liquidManager.showingAddLiquidSheet = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.purple)
                Text("Add Another Liquid")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $liquidManager.showingAddLiquidSheet) {
            AddLiquidView()
                .environmentObject(liquidManager)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Weather display
            WeatherDisplayView()
            
            // Smart goal indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: waterManager.smartGoalEnabled ? "brain.head.profile" : "brain.head.profile")
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
                    icon: "drop.fill",
                    title: "Add Water",
                    subtitle: "Log water intake",
                    color: .blue
                ) {
                    waterManager.showingDrinkOptions = true
                }
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Add Another Liquid",
                    subtitle: "Log other drinks",
                    color: .purple
                ) {
                    liquidManager.showingAddLiquidSheet = true
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
                    title: "Water",
                    value: String(format: "%.1fL", liquidManager.totalWater / 1000),
                    subtitle: "Today",
                    color: .blue
                )
                SummaryCard(
                    title: "Other Liquids",
                    value: String(format: "%.1fL", liquidManager.totalOtherLiquids / 1000),
                    subtitle: "Today",
                    color: .orange
                )
                SummaryCard(
                    title: "Total",
                    value: String(format: "%.1fL", liquidManager.totalLiquids / 1000),
                    subtitle: "Today",
                    color: .green
                )
                SummaryCard(
                    title: "Caffeine",
                    value: "\(liquidManager.totalCaffeine) mg",
                    subtitle: "Total",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - AI Insights Section
    private var aiInsightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI Insights")
                    .font(.headline)
                
                Spacer()
                
                if !aiWaterPredictor.isAnalyzing {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.blue)
                        Text("AI Ready")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if !aiWaterPredictor.isAnalyzing {
                VStack(spacing: 12) {
                    // AI Prediction Card
                    if let prediction = waterManager.aiPrediction {
                        AIPredictionCard(prediction: prediction)
                    }
                    
                    // Learning Progress
                    if let insights = aiWaterPredictor.learningInsights {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                            Text("Learning from your patterns...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(insights.confidenceLevel * 100))%")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // AI Stats
                    if let insights = aiWaterPredictor.learningInsights {
                        AILearningStatsCard(insights: insights)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("AI Learning")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start drinking water to train the AI model")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
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
            smartReminderManager: smartReminderManager,
            weatherManager: weatherManager,
            aiWaterPredictor: aiWaterPredictor
        )
        
        // LiquidManager'a WaterManager'ı set et
        liquidManager.setWaterManager(waterManager)
        
        // Request location permissions
        locationManager.requestLocationPermission()
        
        // Request notification permissions
        notificationManager.requestAuthorization()
        
        // Analyze drinking patterns for smart reminders
        smartReminderManager.analyzeAndSuggest()
        
        performanceMonitor.endTiming("app_setup")
    }
}

// MARK: - AI Supporting Views

struct AIPredictionCard: View {
    let prediction: WaterPrediction
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Prediction")
                    .font(.headline)
                Spacer()
                Text("\(Int(prediction.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Optimal Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prediction.optimalTime.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Recommended")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1fL", prediction.recommendedAmount))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(priorityColor)
                }
            }
            
            Text(prediction.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var priorityColor: Color {
        switch prediction.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .green
        }
    }
}

struct AILearningStatsCard: View {
    let insights: LearningInsights
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Learning Progress")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatItem(
                    title: "Data Points",
                    value: "\(insights.totalDataPoints)",
                    color: .blue
                )
                
                StatItem(
                    title: "Accuracy",
                    value: "\(Int(insights.recentAccuracy * 100))%",
                    color: .green
                )
                
                StatItem(
                    title: "Trend",
                    value: insights.improvementTrend > 0 ? "+" : "",
                    color: insights.improvementTrend > 0 ? .green : .red
                )
                
                StatItem(
                    title: "Confidence",
                    value: "\(Int(insights.confidenceLevel * 100))%",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
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
        .environmentObject(WeatherManager())
        .environmentObject(NotificationManager.shared)
        .environmentObject(PerformanceMonitor.shared)
        .environmentObject(HydrationHistory())
        .environmentObject(AchievementManager())
        .environmentObject(SmartReminderManager())
        .environmentObject(ProfilePictureManager())
        .environmentObject(AIWaterPredictor())
        .environmentObject(AIReminderManager())
        .environmentObject(ThemeManager())
        .environmentObject(LiquidManager())
} 