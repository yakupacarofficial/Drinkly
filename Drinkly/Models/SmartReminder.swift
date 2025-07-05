//
//  SmartReminder.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI
import UserNotifications

/// Represents a smart reminder that adapts to user behavior
struct SmartReminder: Codable, Identifiable {
    var id = UUID()
    let time: Date
    let message: String
    let isEnabled: Bool
    let isAdaptive: Bool
    let skipCount: Int
    let lastSkipped: Date?
    
    init(time: Date, message: String, isEnabled: Bool = true, isAdaptive: Bool = true, skipCount: Int = 0, lastSkipped: Date? = nil) {
        self.time = time
        self.message = message
        self.isEnabled = isEnabled
        self.isAdaptive = isAdaptive
        self.skipCount = skipCount
        self.lastSkipped = lastSkipped
    }
    
    var shouldSuggestRemoval: Bool {
        return skipCount >= 5 && isAdaptive
    }
    
    var shouldSuggestTimeChange: Bool {
        return skipCount >= 3 && skipCount < 5 && isAdaptive
    }
}

/// Manages smart reminders and adaptive scheduling
@MainActor
class SmartReminderManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var reminders: [SmartReminder] = []
    @Published var suggestedReminders: [SmartReminder] = []
    @Published var showingSuggestion = false
    @Published var currentSuggestion: SmartReminder?
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let remindersKey = "drinkly_smart_reminders"
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    init() {
        loadReminders()
        createDefaultReminders()
    }
    
    // MARK: - Public Methods
    
    /// Add a new reminder
    func addReminder(_ reminder: SmartReminder) {
        reminders.append(reminder)
        saveReminders()
        scheduleNotification(for: reminder)
    }
    
    /// Remove a reminder
    func removeReminder(_ reminder: SmartReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders.remove(at: index)
            saveReminders()
            cancelNotification(for: reminder)
        }
    }
    
    /// Update reminder time
    func updateReminderTime(_ reminder: SmartReminder, newTime: Date) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            var updatedReminder = reminder
            updatedReminder = SmartReminder(
                time: newTime,
                message: reminder.message,
                isEnabled: reminder.isEnabled,
                isAdaptive: reminder.isAdaptive,
                skipCount: 0,
                lastSkipped: nil
            )
            reminders[index] = updatedReminder
            saveReminders()
            cancelNotification(for: reminder)
            scheduleNotification(for: updatedReminder)
        }
    }
    
    /// Mark reminder as skipped
    func markReminderAsSkipped(_ reminder: SmartReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            var updatedReminder = reminder
            updatedReminder = SmartReminder(
                time: reminder.time,
                message: reminder.message,
                isEnabled: reminder.isEnabled,
                isAdaptive: reminder.isAdaptive,
                skipCount: reminder.skipCount + 1,
                lastSkipped: Date()
            )
            reminders[index] = updatedReminder
            saveReminders()
            
            // Check if we should suggest changes
            checkForSuggestions(updatedReminder)
        }
    }
    
    /// Mark reminder as completed
    func markReminderAsCompleted(_ reminder: SmartReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            var updatedReminder = reminder
            updatedReminder = SmartReminder(
                time: reminder.time,
                message: reminder.message,
                isEnabled: reminder.isEnabled,
                isAdaptive: reminder.isAdaptive,
                skipCount: max(0, reminder.skipCount - 1),
                lastSkipped: reminder.lastSkipped
            )
            reminders[index] = updatedReminder
            saveReminders()
        }
    }
    
    /// Analyze user behavior and suggest optimal times
    func analyzeAndSuggest() {
        let drinkingPatterns = analyzeDrinkingPatterns()
        let optimalTimes = calculateOptimalTimes(from: drinkingPatterns)
        
        suggestedReminders = createSuggestedReminders(for: optimalTimes)
    }
    
    /// Apply suggested reminder changes
    func applySuggestion(_ suggestion: SmartReminder) {
        addReminder(suggestion)
        suggestedReminders.removeAll { $0.id == suggestion.id }
    }
    
    /// Get reminders for a specific time range
    func getReminders(for timeRange: DateInterval) -> [SmartReminder] {
        return reminders.filter { reminder in
            let reminderTime = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
            let startTime = Calendar.current.dateComponents([.hour, .minute], from: timeRange.start)
            let endTime = Calendar.current.dateComponents([.hour, .minute], from: timeRange.end)
            
            // Safely unwrap hour and minute components with fallback values
            guard let reminderHour = reminderTime.hour,
                  let reminderMinute = reminderTime.minute,
                  let startHour = startTime.hour,
                  let startMinute = startTime.minute,
                  let endHour = endTime.hour,
                  let endMinute = endTime.minute else {
                // If we can't get valid time components, exclude this reminder
                print("[SmartReminder] Warning: Invalid time components for reminder \(reminder.id)")
                return false
            }
            
            let reminderMinutes = reminderHour * 60 + reminderMinute
            let startMinutes = startHour * 60 + startMinute
            let endMinutes = endHour * 60 + endMinute
            
            return reminderMinutes >= startMinutes && reminderMinutes <= endMinutes
        }
    }
    
    // MARK: - Private Methods
    
    private func loadReminders() {
        if let data = userDefaults.data(forKey: remindersKey),
           let savedReminders = try? JSONDecoder().decode([SmartReminder].self, from: data) {
            reminders = savedReminders
        }
    }
    
    func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            userDefaults.set(data, forKey: remindersKey)
        }
    }
    
    private func createDefaultReminders() {
        if reminders.isEmpty {
            let defaultTimes = [
                (hour: 8, minute: 0, message: "Good morning! Time to start your day with hydration"),
                (hour: 10, minute: 30, message: "Mid-morning hydration break"),
                (hour: 13, minute: 0, message: "Lunch time! Don't forget to drink water"),
                (hour: 15, minute: 30, message: "Afternoon pick-me-up with water"),
                (hour: 18, minute: 0, message: "Evening hydration check"),
                (hour: 20, minute: 30, message: "Final hydration reminder for the day")
            ]
            
            for (hour, minute, message) in defaultTimes {
                let time = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
                let reminder = SmartReminder(time: time, message: message)
                reminders.append(reminder)
            }
            
            saveReminders()
        }
    }
    
    private func scheduleNotification(for reminder: SmartReminder) {
        guard reminder.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Drinkly Reminder"
        content.body = reminder.message
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminder.time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    private func cancelNotification(for reminder: SmartReminder) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
    
    private func checkForSuggestions(_ reminder: SmartReminder) {
        if reminder.shouldSuggestRemoval {
            currentSuggestion = createRemovalSuggestion(for: reminder)
            showingSuggestion = true
        } else if reminder.shouldSuggestTimeChange {
            currentSuggestion = createTimeChangeSuggestion(for: reminder)
            showingSuggestion = true
        }
    }
    
    private func createRemovalSuggestion(for reminder: SmartReminder) -> SmartReminder {
        let newTime = Calendar.current.date(byAdding: .hour, value: 1, to: reminder.time) ?? reminder.time
        return SmartReminder(
            time: newTime,
            message: "Suggested new reminder time",
            isEnabled: true,
            isAdaptive: true
        )
    }
    
    private func createTimeChangeSuggestion(for reminder: SmartReminder) -> SmartReminder {
        let newTime = Calendar.current.date(byAdding: .hour, value: 30, to: reminder.time) ?? reminder.time
        return SmartReminder(
            time: newTime,
            message: "Suggested adjusted reminder time",
            isEnabled: true,
            isAdaptive: true
        )
    }
    
    private func analyzeDrinkingPatterns() -> [DrinkingPattern] {
        // This would analyze actual drinking data from HydrationHistory
        // For now, return default patterns
        return [
            DrinkingPattern(timeSlot: "Morning", frequency: 0.8, averageAmount: 0.3),
            DrinkingPattern(timeSlot: "Mid-morning", frequency: 0.6, averageAmount: 0.25),
            DrinkingPattern(timeSlot: "Lunch", frequency: 0.9, averageAmount: 0.4),
            DrinkingPattern(timeSlot: "Afternoon", frequency: 0.7, averageAmount: 0.3),
            DrinkingPattern(timeSlot: "Evening", frequency: 0.5, averageAmount: 0.25),
            DrinkingPattern(timeSlot: "Night", frequency: 0.2, averageAmount: 0.1)
        ]
    }
    
    private func calculateOptimalTimes(from patterns: [DrinkingPattern]) -> [Date] {
        var optimalTimes: [Date] = []
        let calendar = Calendar.current
        
        for pattern in patterns where pattern.frequency > 0.5 {
            let hour: Int
            switch pattern.timeSlot {
            case "Morning": hour = 8
            case "Mid-morning": hour = 10
            case "Lunch": hour = 13
            case "Afternoon": hour = 15
            case "Evening": hour = 18
            case "Night": hour = 20
            default: hour = 12
            }
            
            if let time = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) {
                optimalTimes.append(time)
            }
        }
        
        return optimalTimes
    }
    
    private func createSuggestedReminders(for times: [Date]) -> [SmartReminder] {
        let messages = [
            "Time to hydrate! 💧",
            "Stay refreshed with water",
            "Hydration reminder",
            "Don't forget to drink water",
            "Water break time!",
            "Keep yourself hydrated"
        ]
        
        return times.enumerated().map { index, time in
            let message = messages[index % messages.count]
            return SmartReminder(
                time: time,
                message: message,
                isEnabled: true,
                isAdaptive: true
            )
        }
    }
}

// MARK: - Supporting Models

struct DrinkingPattern {
    let timeSlot: String
    let frequency: Double // 0.0 to 1.0
    let averageAmount: Double // in liters
}

// MARK: - Smart Reminder Suggestion View
struct SmartReminderSuggestionView: View {
    let suggestion: SmartReminder
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            
            Text("Smart Suggestion")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Based on your drinking patterns, we suggest adjusting your reminder time.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(suggestion.time.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Message")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(suggestion.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            HStack(spacing: 16) {
                Button("Decline") {
                    onDecline()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.secondary)
                
                Button("Accept") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
} 