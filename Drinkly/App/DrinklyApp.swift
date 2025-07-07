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
    @StateObject private var weatherManager = WeatherManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @StateObject private var hydrationHistory = HydrationHistory()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var smartReminderManager = SmartReminderManager()
    @StateObject private var profilePictureManager = ProfilePictureManager()
    @StateObject private var aiWaterPredictor = AIWaterPredictor()
    @StateObject private var aiReminderManager = AIReminderManager()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            MainView()
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
                .preferredColorScheme(themeManager.currentColorScheme)
                .onAppear {
                    setupApp()
                }
                .sheet(isPresented: $waterManager.showingDrinkOptions) {
                    DrinkOptionsView()
                        .environmentObject(waterManager)
                        .environmentObject(locationManager)
                        .environmentObject(weatherManager)
                        .environmentObject(notificationManager)
                        .environmentObject(performanceMonitor)
                        .environmentObject(hydrationHistory)
                        .environmentObject(achievementManager)
                        .environmentObject(smartReminderManager)
                        .environmentObject(aiReminderManager)
                        .environmentObject(themeManager)
                }
                .sheet(isPresented: $waterManager.showingCelebration) {
                    CelebrationView(isShowing: $waterManager.showingCelebration)
                        .environmentObject(waterManager)
                        .environmentObject(locationManager)
                        .environmentObject(weatherManager)
                        .environmentObject(notificationManager)
                        .environmentObject(performanceMonitor)
                        .environmentObject(hydrationHistory)
                        .environmentObject(achievementManager)
                        .environmentObject(smartReminderManager)
                        .environmentObject(aiReminderManager)
                        .environmentObject(themeManager)
                }
        }
    }
    
    // MARK: - App Setup
    private func setupApp() {
        PerformanceMonitor.shared.startTiming("app_initialization")
        
        configureAppAppearance()
        setupManagers()
        requestPermissions()
        loadInitialData()
        
        PerformanceMonitor.shared.endTiming("app_initialization")
    }
    
    // MARK: - App Configuration
    private func configureAppAppearance() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor.systemBackground
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    // MARK: - Manager Setup
    private func setupManagers() {
        waterManager.setDependencies(
            hydrationHistory: hydrationHistory,
            achievementManager: achievementManager,
            smartReminderManager: smartReminderManager,
            weatherManager: weatherManager,
            aiWaterPredictor: aiWaterPredictor
        )
        
        locationManager.weatherManager = weatherManager
        notificationManager.configure()
        smartReminderManager.analyzeAndSuggest()
        aiReminderManager.analyzeAndSuggestReminders()
        achievementManager.loadAchievements()
    }
    
    // MARK: - Permission Requests
    private func requestPermissions() {
        locationManager.requestLocationPermission()
        notificationManager.requestAuthorization()
    }
    
    // MARK: - Initial Data Loading
    private func loadInitialData() {
        let userProfile = UserProfile.load()
        waterManager.updateUserProfile(userProfile)
        
        locationManager.loadLastLocation()
        
        weatherManager.loadCachedData()
        waterManager.updateTemperature(weatherManager.currentTemperature)
        
        hydrationHistory.loadHistory()
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
        locationManager.refreshLocation()
        waterManager.updateDailyGoal()
        checkInitialAchievements()
    }
    
    func applicationWillResignActive() {
        waterManager.saveData()
        hydrationHistory.saveHistory()
        achievementManager.saveUnlockedAchievements()
    }
    
    func applicationDidEnterBackground() {
        scheduleBackgroundTasks()
    }
    
    private func scheduleBackgroundTasks() {
        notificationManager.scheduleDailySummary()
        smartReminderManager.analyzeAndSuggest()
        aiReminderManager.analyzeAndSuggestReminders()
    }
}

// MARK: - Performance Monitoring Extensions
extension DrinklyApp {
    func logPerformanceMetrics() {
        // MARK: - Performance Monitoring
        #if DEBUG
        let _ = PerformanceMonitor.shared.metrics
        #endif
        // Performance metrics logged for debugging
    }
}

// MARK: - Error Handling Extensions
extension DrinklyApp {
    func handleAppError(_ error: Error) {
        // Error logged for debugging
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
