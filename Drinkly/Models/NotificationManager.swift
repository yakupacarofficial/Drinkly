//
//  NotificationManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import UserNotifications
import SwiftUI

/// Manages local notifications for the app
@MainActor
class NotificationManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var authorizationTask: Task<Void, Never>?
    private var schedulingTask: Task<Void, Never>?
    
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Initialization
    private init() {
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
            do {
                let settings = try await notificationCenter.notificationSettings()
                let granted = settings.authorizationStatus == .authorized
                
                await MainActor.run {
                    self.isAuthorized = granted
                    completion(granted)
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                    self.errorMessage = "Failed to check authorization: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    /// Schedules a daily notification
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
        schedulingTask?.cancel()
        
        schedulingTask = Task {
            do {
                // Cancel existing notification first
                await cancelNotification(id: id)
                
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                content.categoryIdentifier = "WATER_REMINDER"
                
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                
                try await notificationCenter.add(request)
                
                await MainActor.run {
                    self.errorMessage = nil
                    print("[NotificationManager] Daily notification scheduled at \(hour):\(minute)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to schedule notification: \(error.localizedDescription)"
                    print("[NotificationManager] Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Cancels a specific notification
    /// - Parameter id: Notification identifier
    func cancelNotification(id: String = "drinkly_daily_reminder") {
        Task {
            await notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
            await MainActor.run {
                print("[NotificationManager] Cancelled notification: \(id)")
            }
        }
    }
    
    /// Cancels all pending notifications
    func cancelAllNotifications() {
        Task {
            await notificationCenter.removeAllPendingNotificationRequests()
            await MainActor.run {
                print("[NotificationManager] Cancelled all notifications")
            }
        }
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
} 