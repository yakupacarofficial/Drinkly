//
//  DrinklyApp.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

@main
struct DrinklyApp: App {
    @StateObject private var waterManager = WaterManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @StateObject private var hydrationHistory = HydrationHistory()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var smartReminderManager = SmartReminderManager()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(waterManager)
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .environmentObject(performanceMonitor)
                .environmentObject(hydrationHistory)
                .environmentObject(achievementManager)
                .environmentObject(smartReminderManager)
                .preferredColorScheme(.light)
                .onAppear {
                    setupApp()
                }
                .sheet(isPresented: $waterManager.showingDrinkOptions) {
                    DrinkOptionsView()
                        .environmentObject(waterManager)
                        .environmentObject(locationManager)
                        .environmentObject(notificationManager)
                        .environmentObject(performanceMonitor)
                        .environmentObject(hydrationHistory)
                        .environmentObject(achievementManager)
                        .environmentObject(smartReminderManager)
                }
                .sheet(isPresented: $waterManager.showingCelebration) {
                    CelebrationView(isShowing: $waterManager.showingCelebration)
                        .environmentObject(waterManager)
                        .environmentObject(locationManager)
                        .environmentObject(notificationManager)
                        .environmentObject(performanceMonitor)
                        .environmentObject(hydrationHistory)
                        .environmentObject(achievementManager)
                        .environmentObject(smartReminderManager)
                }
        }
    }
    
    // MARK: - App Setup
    private func setupApp() {
        PerformanceMonitor.shared.startTiming("app_initialization")
        
        // Configure app appearance
        configureAppAppearance()
        
        // Set up managers
        setupManagers()
        
        // Request permissions
        requestPermissions()
        
        // Load initial data
        loadInitialData()
        
        PerformanceMonitor.shared.endTiming("app_initialization")
        
        // Log app launch
    }
    
    // MARK: - App Configuration
    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor.systemBackground
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    // MARK: - Manager Setup
    private func setupManagers() {
        // Set up dependencies for WaterManager
        waterManager.setDependencies(
            hydrationHistory: hydrationHistory,
            achievementManager: achievementManager,
            smartReminderManager: smartReminderManager
        )
        
        // Configure location manager
        
        // Set up notification manager
        notificationManager.configure()
        
        // Initialize smart reminders
        smartReminderManager.analyzeAndSuggest()
        
        // Load achievement data
        achievementManager.loadAchievements()
    }
    
    // MARK: - Permission Requests
    private func requestPermissions() {
        // Request location permission
        locationManager.requestLocationPermission()
        
        // Request notification permission
        notificationManager.requestAuthorization()
    }
    
    // MARK: - Initial Data Loading
    private func loadInitialData() {
        // Load user profile
        let userProfile = UserProfile.load()
        waterManager.updateUserProfile(userProfile)
        
        // Load location data
        locationManager.loadLastLocation()
        
        // Load temperature data
        let temperature = UserDefaults.standard.double(forKey: "drinkly_last_temperature")
        if temperature > 0 {
            waterManager.updateTemperature(temperature)
        }
        
        // Load hydration history
        hydrationHistory.loadHistory()
        
        // Check for achievements
        checkInitialAchievements()
    }
    
    // MARK: - Achievement Checking
    private func checkInitialAchievements() {
        let totalIntake = hydrationHistory.dailyRecords.reduce(0) { $0 + $1.totalIntake }
        let consecutiveDays = calculateConsecutiveDays()
        let perfectWeek = calculatePerfectWeek()
        let perfectMonth = calculatePerfectMonth()
        
        achievementManager.checkAchievements(
            currentStreak: hydrationHistory.currentStreak,
            totalIntake: totalIntake,
            consecutiveDays: consecutiveDays,
            perfectWeek: perfectWeek,
            perfectMonth: perfectMonth
        )
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

// MARK: - App Lifecycle Extensions

extension DrinklyApp {
    func applicationDidBecomeActive() {
        
        // Refresh data when app becomes active
        locationManager.refreshLocation()
        waterManager.updateDailyGoal()
        
        // Check for new achievements
        checkInitialAchievements()
    }
    
    func applicationWillResignActive() {
        
        // Save current state
        waterManager.saveData()
        hydrationHistory.saveHistory()
        achievementManager.saveUnlockedAchievements()
    }
    
    func applicationDidEnterBackground() {
        
        // Schedule background tasks if needed
        scheduleBackgroundTasks()
    }
    
    private func scheduleBackgroundTasks() {
        // Schedule daily summary notification
        notificationManager.scheduleDailySummary()
        
        // Schedule smart reminder analysis
        smartReminderManager.analyzeAndSuggest()
    }
}

// MARK: - Performance Monitoring Extensions

extension DrinklyApp {
    func logPerformanceMetrics() {
        let metrics = PerformanceMonitor.shared.metrics
        
        for (key, metric) in metrics {
            print("Performance Metric - \(key): \(metric.duration)s")
        }
    }
}

// MARK: - Error Handling Extensions

extension DrinklyApp {
    func handleAppError(_ error: Error) {
        
        // Log error for debugging
        print("App Error: \(error.localizedDescription)")
    }
}

// MARK: - Data Management Extensions

extension DrinklyApp {
    func exportUserData() -> Data? {
        let exportData = AppExportData(
            waterManagerData: AppExportData.WaterManagerData(
                currentAmount: waterManager.currentAmount,
                dailyGoal: waterManager.dailyGoal,
                todayDrinks: waterManager.todayDrinks,
                userProfile: waterManager.userProfile,
                smartGoalEnabled: waterManager.smartGoalEnabled,
                currentTemperature: waterManager.currentTemperature
            ),
            hydrationHistoryData: hydrationHistory.dailyRecords,
            achievementManagerData: achievementManager.unlockedAchievements,
            smartReminderManagerData: smartReminderManager.reminders
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func importUserData(_ data: Data) -> Bool {
        guard let importData = try? JSONDecoder().decode(AppExportData.self, from: data) else {
            return false
        }
        
        // Import data to managers
        waterManager.importData(importData.waterManagerData)
        hydrationHistory.importData(importData.hydrationHistoryData)
        achievementManager.importData(importData.achievementManagerData)
        smartReminderManager.importData(importData.smartReminderManagerData)
        
        return true
    }
}

// MARK: - Supporting Models

struct AppExportData: Codable {
    let waterManagerData: WaterManagerData
    let hydrationHistoryData: [DailyHydration]
    let achievementManagerData: [Achievement]
    let smartReminderManagerData: [SmartReminder]
    
    struct WaterManagerData: Codable {
        let currentAmount: Double
        let dailyGoal: Double
        let todayDrinks: [WaterDrink]
        let userProfile: UserProfile
        let smartGoalEnabled: Bool
        let currentTemperature: Double
    }
}

// MARK: - Manager Extensions for Data Import/Export

extension WaterManager {
    func importData(_ data: AppExportData.WaterManagerData) {
        currentAmount = data.currentAmount
        dailyGoal = data.dailyGoal
        todayDrinks = data.todayDrinks
        userProfile = data.userProfile
        smartGoalEnabled = data.smartGoalEnabled
        currentTemperature = data.currentTemperature
        saveData()
    }
}

extension HydrationHistory {
    func importData(_ data: [DailyHydration]) {
        dailyRecords = data
        saveHistory()
        calculateStreaks()
    }
}

extension AchievementManager {
    func importData(_ data: [Achievement]) {
        unlockedAchievements = data
        saveUnlockedAchievements()
    }
}

extension SmartReminderManager {
    func importData(_ data: [SmartReminder]) {
        reminders = data
        saveReminders()
    }
}
