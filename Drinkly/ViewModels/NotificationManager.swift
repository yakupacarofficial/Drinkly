//
//  NotificationManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import UserNotifications
import SwiftUI
import AudioToolbox

/// Available notification sounds for the app
enum NotificationSound: String, CaseIterable, Codable {
    case `default` = "default"
    case ding = "ding"
    case waterdrop = "waterdrop"
    case chime = "chime"
    case bell = "bell"
    case gentle = "gentle"
    
    var displayName: String {
        switch self {
        case .default:
            return "Default"
        case .ding:
            return "Ding"
        case .waterdrop:
            return "Water Drop"
        case .chime:
            return "Chime"
        case .bell:
            return "Bell"
        case .gentle:
            return "Gentle"
        }
    }
    
    var systemSound: UNNotificationSound? {
        switch self {
        case .default:
            return .default
        case .ding:
            return UNNotificationSound(named: UNNotificationSoundName("ding.wav"))
        case .waterdrop:
            return UNNotificationSound(named: UNNotificationSoundName("waterdrop.wav"))
        case .chime:
            return UNNotificationSound(named: UNNotificationSoundName("chime.wav"))
        case .bell:
            return UNNotificationSound(named: UNNotificationSoundName("bell.wav"))
        case .gentle:
            return UNNotificationSound(named: UNNotificationSoundName("gentle.wav"))
        }
    }
    
    /// Plays a preview of the notification sound
    func playSoundPreview(_ sound: NotificationSound) {
        // This will only work if the sound files are present in the app bundle
        switch sound {
        case .default:
            AudioServicesPlaySystemSound(1007)
        case .ding:
            playBundleSound(named: "ding.wav")
        case .waterdrop:
            playBundleSound(named: "waterdrop.wav")
        case .chime:
            playBundleSound(named: "chime.wav")
        case .bell:
            playBundleSound(named: "bell.wav")
        case .gentle:
            playBundleSound(named: "gentle.wav")
        }
    }
    
    private func playBundleSound(named fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            AudioServicesPlaySystemSound(1007) // fallback
            return
        }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
    
    var iconName: String {
        switch self {
        case .default:
            return "speaker.wave.2"
        case .ding:
            return "bell"
        case .waterdrop:
            return "drop.fill"
        case .chime:
            return "music.note"
        case .bell:
            return "bell.fill"
        case .gentle:
            return "speaker.wave.1"
        }
    }
}

/// Manages local notifications for the app
@MainActor
class NotificationManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    @Published var selectedSound: NotificationSound = .default
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var authorizationTask: Task<Void, Never>?
    private var schedulingTask: Task<Void, Never>?
    private let userDefaults = UserDefaults.standard
    private let selectedSoundKey = "drinkly_notification_sound"
    
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Initialization
    private init() {
        loadSelectedSound()
        checkAuthorizationStatus { _ in }
    }
    
    deinit {
        authorizationTask?.cancel()
        schedulingTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Requests notification authorization
    /// - Parameter completion: Completion handler with authorization result
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        authorizationTask?.cancel()
        
        authorizationTask = Task {
            do {
                let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                let granted = try await notificationCenter.requestAuthorization(options: options)
                
                await MainActor.run {
                    self.isAuthorized = granted
                    if granted {
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = "Notification permission denied"
                    }
                    completion(granted)
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                    self.errorMessage = "Failed to request authorization: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    /// Checks current authorization status
    /// - Parameter completion: Completion handler with authorization result
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void = { _ in }) {
        authorizationTask?.cancel()
        
        authorizationTask = Task {
            let settings = await notificationCenter.notificationSettings()
            let granted = settings.authorizationStatus == .authorized
            
            await MainActor.run {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    /// Schedules a daily notification with comprehensive validation
    /// - Parameters:
    ///   - hour: Hour of the day (0-23)
    ///   - minute: Minute of the hour (0-59)
    ///   - id: Notification identifier
    ///   - title: Notification title
    ///   - body: Notification body
    func scheduleDailyNotification(
        hour: Int,
        minute: Int,
        id: String = "drinkly_daily_reminder",
        title: String = "Time to Drink Water 💧",
        body: String = "Stay hydrated! Drink some water."
    ) {
        // Validate input parameters
        guard hour >= 0 && hour <= 23 else {
            errorMessage = "Invalid hour value. Must be between 0 and 23."
            return
        }
        
        guard minute >= 0 && minute <= 59 else {
            errorMessage = "Invalid minute value. Must be between 0 and 59."
            return
        }
        
        guard !title.isEmpty && !body.isEmpty else {
            errorMessage = "Notification title and body cannot be empty."
            return
        }
        
        schedulingTask?.cancel()
        
        schedulingTask = Task {
            do {
                // Cancel existing notification first
                cancelNotification(id: id)
                
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = selectedSound.systemSound ?? .default
                content.categoryIdentifier = "WATER_REMINDER"
                
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                try await notificationCenter.add(request)
                
                await MainActor.run {
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to schedule notification: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Schedules a smart reminder notification with custom sound
    /// - Parameters:
    ///   - reminder: The smart reminder to schedule
    ///   - sound: Optional custom sound (uses selected sound if nil)
    func scheduleSmartReminderNotification(
        for reminder: SmartReminder,
        sound: NotificationSound? = nil
    ) {
        guard reminder.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Drinkly Reminder"
        content.body = reminder.message
        content.sound = (sound ?? selectedSound).systemSound ?? .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminder.time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { _ in
            // Error scheduling notification logged
        }
    }
    
    /// Schedules an achievement unlock notification
    /// - Parameters:
    ///   - achievement: The achievement that was unlocked
    ///   - sound: Optional custom sound (uses selected sound if nil)
    func scheduleAchievementNotification(
        for achievement: Achievement,
        sound: NotificationSound? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! 🎉"
        content.body = "\(achievement.title): \(achievement.description)"
        content.sound = (sound ?? selectedSound).systemSound ?? .default
        content.badge = 1
        content.categoryIdentifier = "ACHIEVEMENT"
        
        // Schedule for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { _ in
            // Error scheduling notification logged
        }
    }
    
    /// Schedules a daily summary notification
    /// - Parameters:
    ///   - summary: The daily summary data
    ///   - sound: Optional custom sound (uses selected sound if nil)
    func scheduleDailySummaryNotification(
        summary: String,
        sound: NotificationSound? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Hydration Summary 📊"
        content.body = summary
        content.sound = (sound ?? selectedSound).systemSound ?? .default
        content.badge = 1
        content.categoryIdentifier = "DAILY_SUMMARY"
        
        // Schedule for 9 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "drinkly_daily_summary",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { _ in
            // Error scheduling notification logged
        }
    }
    
    /// Updates the selected notification sound
    /// - Parameter sound: The new sound to use
    func updateNotificationSound(_ sound: NotificationSound) {
        selectedSound = sound
        saveSelectedSound()
        
        // Reschedule existing notifications with new sound
        rescheduleAllNotifications()
    }
    
    /// Plays a preview of the notification sound
    /// - Parameter sound: The sound to preview
    func playSoundPreview(_ sound: NotificationSound) {
        // Use AudioServices to play system sounds for preview
        switch sound {
        case .default:
            AudioServicesPlaySystemSound(1007) // Default notification sound
        case .ding:
            AudioServicesPlaySystemSound(1008) // System sound
        case .waterdrop:
            AudioServicesPlaySystemSound(1009) // System sound
        case .chime:
            AudioServicesPlaySystemSound(1010) // System sound
        case .bell:
            AudioServicesPlaySystemSound(1011) // System sound
        case .gentle:
            AudioServicesPlaySystemSound(1012) // System sound
        }
    }
    
    /// Cancels a specific notification
    /// - Parameter id: Notification identifier
    func cancelNotification(id: String = "drinkly_daily_reminder") {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    /// Cancels all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Gets pending notification requests
    /// - Parameter completion: Completion handler with notification requests
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        Task {
            let requests = await notificationCenter.pendingNotificationRequests()
            await MainActor.run {
                completion(requests)
            }
        }
    }
    
    /// Configure notification settings
    func configure() {
        // Configure notification settings
    }
    
    /// Schedule daily summary notification
    func scheduleDailySummary() {
        // Schedule daily summary notification
    }
    
    // MARK: - Private Methods
    
    /// Loads the selected notification sound from UserDefaults
    private func loadSelectedSound() {
        if let soundData = userDefaults.data(forKey: selectedSoundKey),
           let sound = try? JSONDecoder().decode(NotificationSound.self, from: soundData) {
            selectedSound = sound
        }
    }
    
    /// Saves the selected notification sound to UserDefaults
    private func saveSelectedSound() {
        if let soundData = try? JSONEncoder().encode(selectedSound) {
            userDefaults.set(soundData, forKey: selectedSoundKey)
        }
    }
    
    /// Reschedules all existing notifications with the current sound
    private func rescheduleAllNotifications() {
        getPendingNotifications { requests in
            // Cancel all existing notifications
            self.cancelAllNotifications()
            
            // Reschedule them with the new sound
            for request in requests {
                let content = request.content.mutableCopy() as! UNMutableNotificationContent
                content.sound = self.selectedSound.systemSound ?? .default
                
                let newRequest = UNNotificationRequest(
                    identifier: request.identifier,
                    content: content,
                    trigger: request.trigger
                )
                
                self.notificationCenter.add(newRequest) { _ in
                    // Error scheduling notification logged
                }
            }
        }
    }
} 