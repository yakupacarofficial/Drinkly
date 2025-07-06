//
//  SettingsView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI
import UserNotifications

/// Settings view for configuring app preferences
struct SettingsView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var waterManager: WaterManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var achievementManager: AchievementManager
    @EnvironmentObject private var hydrationHistory: HydrationHistory
    @EnvironmentObject private var smartReminderManager: SmartReminderManager
    @EnvironmentObject private var aiReminderManager: AIReminderManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var profilePictureManager: ProfilePictureManager
    @EnvironmentObject private var liquidManager: LiquidManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    @State private var showingResetAlert = false
    @State private var showingResetAllAlert = false
    @State private var showingFullResetAlert = false
    @State private var notificationsEnabled: Bool = false
    @State private var reminderTime: Date = Self.loadReminderTime()
    @State private var showNotificationAlert = false
    @State private var showingProfileView = false
    @State private var showingSmartReminders = false
    
    var body: some View {
        NavigationView {
            List {
                profileSection
                dailyGoalSection
                smartGoalSection
                notificationSection
                statisticsSection
                actionsSection
                aboutSection
                themeSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
            }
        }
        .onAppear {
            loadSettings()
        }
        .onChange(of: themeManager.themeMode) { _, _ in
            // Force UI refresh when theme changes
            DispatchQueue.main.async {
                // This will trigger a UI refresh
            }
        }
        .alert("Reset Today's Progress", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                waterManager.resetToday()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset your progress for today. This action cannot be undone.")
        }
        .alert("Reset All Progress", isPresented: $showingResetAllAlert) {
            Button("Reset All", role: .destructive) {
                resetAllProgress()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all your progress, achievements, and data. This action cannot be undone and will start you fresh.")
        }
        .alert("Notification Permission Required", isPresented: $showNotificationAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive daily reminders.")
        }
        .alert("Tüm Verileri ve Ayarları Sıfırla", isPresented: $showingFullResetAlert) {
            Button("Tümünü Sıfırla", role: .destructive) {
                fullResetAllDataAndSettings()
            }
            Button("Vazgeç", role: .cancel) { }
        } message: {
            Text("Bu işlem tüm kullanıcı verilerini, ayarları, izinleri ve profil bilgilerini sıfırlar. Geri alınamaz. Devam etmek istiyor musunuz?")
        }
        .sheet(isPresented: $showingProfileView, onDismiss: {
            // Ensure UI updates after profile change
            // No-op, as waterManager.dailyGoal is @Published
        }) {
            ProfileView(existingProfile: waterManager.userProfile)
                .environmentObject(waterManager)
        }
        .sheet(isPresented: $showingSmartReminders) {
            SmartRemindersView(smartReminderManager: smartReminderManager)
                .environmentObject(waterManager)
                .environmentObject(notificationManager)
                .environmentObject(achievementManager)
                .environmentObject(hydrationHistory)
                .environmentObject(aiReminderManager)
        }
    }
    
    // MARK: - Private Views
    
    private var profileSection: some View {
        Section("Profile") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if waterManager.userProfile.isValid {
                            let profile = waterManager.userProfile
                            Text("\(profile.age) years, \(String(format: "%.0f", profile.weight))kg")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(profile.activityLevel.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Profile not set")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Edit") {
                        HapticFeedbackHelper.shared.trigger()
                        showingProfileView = true
                    }
                    .foregroundColor(.blue)
                }
                
                if waterManager.userProfile.isValid && waterManager.personalizedGoalEnabled {
                    Text("Personalized goal calculation enabled")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if waterManager.userProfile.isValid && !waterManager.personalizedGoalEnabled {
                    Text("Personalized goal calculation disabled")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Set up your profile for personalized goals")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var themeSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Theme Mode")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Choose how the app should appear")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        ThemeOptionCard(
                            mode: mode,
                            isSelected: themeManager.themeMode == mode,
                            onTap: {
                                HapticFeedbackHelper.shared.trigger()
                                themeManager.setThemeMode(mode)
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var dailyGoalSection: some View {
        Section("Daily Goal") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Target Water Intake")
                        .font(.headline)
                    Spacer()
                    Text("\(String(format: "%.1f", waterManager.dailyGoal))L")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Slider(value: Binding(
                    get: { waterManager.dailyGoal },
                    set: { newValue in waterManager.dailyGoal = newValue }
                ), in: 1.0...5.0, step: 0.1)
                .accentColor(.blue)
                .disabled(waterManager.personalizedGoalEnabled && waterManager.userProfile.isValid)
                .opacity((waterManager.personalizedGoalEnabled && waterManager.userProfile.isValid) ? 0.5 : 1.0)
                
                HStack {
                    Text("1.0L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("5.0L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if waterManager.personalizedGoalEnabled && waterManager.userProfile.isValid {
                    Text("Personalized goal is active. Adjust your profile to change your goal.")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if !waterManager.personalizedGoalEnabled {
                    Text("Manual goal setting is active.")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("Set up your profile for personalized goals")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var smartGoalSection: some View {
        Section("Smart Water Goal") {
            Toggle(isOn: $waterManager.personalizedGoalEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personalized Goal")
                        .font(.headline)
                    Text("Use profile data for goal calculation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: waterManager.personalizedGoalEnabled) { oldValue, newValue in
                waterManager.togglePersonalizedGoal()
            }
            .tint(.blue)
            
            Toggle(isOn: $waterManager.smartGoalEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weather-based Goal")
                        .font(.headline)
                    Text("Adjusts your daily goal based on temperature")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: waterManager.smartGoalEnabled) { oldValue, newValue in
                waterManager.toggleSmartGoal()
            }
            .tint(.blue)
            .disabled(!waterManager.personalizedGoalEnabled)
            .opacity(waterManager.personalizedGoalEnabled ? 1.0 : 0.5)
            
            if waterManager.smartGoalEnabled && waterManager.currentTemperature > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(.orange)
                        Text("Current Temperature: \(String(format: "%.1f", waterManager.currentTemperature))°C")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("Smart Goal: \(String(format: "%.1f", waterManager.dailyGoal))L")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var notificationSection: some View {
        Group {
            Section("Notifications") {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        HapticFeedbackHelper.shared.trigger()
                        showingSmartReminders = true
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                            Text("Open Smart Reminders")
                                .font(.body)
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
            
            NotificationSoundSection()
                .environmentObject(notificationManager)
        }
    }
    
    private var statisticsSection: some View {
        Section("Today's Statistics") {
            StatRow(title: "Current Intake", value: "\(String(format: "%.1f", waterManager.currentAmount))L")
            StatRow(title: "Remaining", value: "\(String(format: "%.1f", waterManager.remainingAmount))L")
            StatRow(title: "Progress", value: "\(Int(waterManager.progressPercentage))%")
            StatRow(title: "Drinks Today", value: "\(waterManager.todayDrinks.count)")
        }
    }
    
    private var actionsSection: some View {
        Section("Actions") {
            Button(action: {
                HapticFeedbackHelper.shared.trigger()
                showingResetAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                    Text("Reset Today's Progress")
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            
            Button(action: {
                HapticFeedbackHelper.shared.trigger()
                showingResetAllAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("Reset All Progress")
                        .foregroundColor(.red)
                    Spacer()
                }
            }

            Button(action: {
                HapticFeedbackHelper.shared.trigger()
                showingFullResetAlert = true
            }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Tüm Verileri ve Ayarları Sıfırla")
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Drinkly")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("Your daily water companion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            HapticFeedbackHelper.shared.trigger()
            saveSettings()
            dismiss()
        }
        .foregroundColor(.blue)
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            HapticFeedbackHelper.shared.trigger()
            dismiss()
        }
        .foregroundColor(.secondary)
    }
    
    // MARK: - Private Methods
    
    private static func loadReminderTime() -> Date {
        let components = UserDefaults.standard.dictionary(forKey: "drinkly_reminder_time") as? [String: Int]
        var date = Date()
        if let hour = components?["hour"], let minute = components?["minute"] {
            date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        }
        return date
    }
    
    private func loadSettings() {
        notificationManager.checkAuthorizationStatus { granted in
            notificationsEnabled = granted && UserDefaults.standard.object(forKey: "drinkly_reminder_time") != nil
        }
    }
    
    private func saveSettings() {
        
        if notificationsEnabled {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            notificationManager.scheduleDailyNotification(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
            saveReminderTime(reminderTime)
        } else {
            notificationManager.cancelNotification()
        }
    }
    
    private func saveReminderTime(_ date: Date) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        UserDefaults.standard.set(["hour": comps.hour ?? 9, "minute": comps.minute ?? 0], forKey: "drinkly_reminder_time")
    }
    
    private func handleNotificationToggle(enabled: Bool) {
        if enabled {
            notificationManager.requestAuthorization { granted in
                if !granted {
                    notificationsEnabled = false
                    showNotificationAlert = true
                }
            }
        } else {
            notificationManager.cancelNotification()
        }
    }
    
    private func resetAllProgress() {
        // Reset all managers
        waterManager.resetToday()
        achievementManager.resetAllProgress()
        hydrationHistory.resetAllData()
        smartReminderManager.resetAllReminders()
        
        // Cancel all notifications
        notificationManager.cancelAllNotifications()
        
        // Reset user profile to default
        waterManager.updateUserProfile(UserProfile.default)
        
        // Save all changes
        waterManager.saveData()
        hydrationHistory.saveHistory()
        smartReminderManager.saveReminders()
    }

    /// Tüm kullanıcı verilerini, ayarları ve izinleri sıfırlar
    private func fullResetAllDataAndSettings() {
        // Tüm UserDefaults anahtarlarını sil
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
            UserDefaults.standard.synchronize()
        }

        // Tüm manager'ları sıfırla
        waterManager.resetToday()
        achievementManager.resetAllProgress()
        hydrationHistory.resetAllData()
        smartReminderManager.resetAllReminders()
        liquidManager.resetAllData()
        profilePictureManager.removeProfileImage()
        themeManager.setThemeMode(.system)
        notificationManager.cancelAllNotifications()

        // Bildirim izinlerini sıfırlamak için kullanıcıya tekrar izin isteği gösterilebilir
        notificationManager.requestAuthorization { _ in }

        // Kullanıcıya bilgi ver
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Başarılı sıfırlama mesajı göster
            self.showingFullResetAlert = false
            // Burada bir başarı mesajı gösterilebilir
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Theme Option Card
struct ThemeOptionCard: View {
    let mode: ThemeMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: mode.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(WaterManager())
        .environmentObject(NotificationManager.shared)
        .environmentObject(AchievementManager())
        .environmentObject(HydrationHistory())
        .environmentObject(SmartReminderManager())
        .environmentObject(ThemeManager())
        .environmentObject(ProfilePictureManager())
        .environmentObject(LiquidManager())
} 