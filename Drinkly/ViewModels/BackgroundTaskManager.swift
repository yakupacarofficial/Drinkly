//
//  BackgroundTaskManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import UIKit

/// Manages background tasks and AI operations for optimal battery performance
@MainActor
class BackgroundTaskManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isBackgroundTaskActive = false
    @Published var lastBackgroundTaskDate: Date?
    
    // MARK: - Private Properties
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var backgroundQueue = DispatchQueue(label: "com.drinkly.background", qos: .background)
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Constants
    private let minBackgroundTaskInterval: TimeInterval = 300 // 5 minutes
    private let maxBackgroundTaskDuration: TimeInterval = 30 // 30 seconds
    
    // MARK: - Initialization
    init() {
        setupBackgroundTaskHandling()
    }
    
    deinit {
        // Swift 6: Main actor gerektiren cleanup burada yapılmaz!
        // Sadece flag sıfırlanır, cleanup fonksiyonu AppDelegate/SceneDelegate/Notification ile main actor'da çağrılır.
        backgroundTaskID = .invalid
    }
    
    // MARK: - Public Methods
    
    /// Execute AI training in background with battery optimization
    func executeAITraining(completion: @escaping () -> Void) {
        guard shouldExecuteBackgroundTask() else {
            completion()
            return
        }
        
        startBackgroundTask()
        
        backgroundQueue.async { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            Task { @MainActor in
                // Execute AI training with low priority
                self.performAITraining()
                
                self.endBackgroundTask()
                completion()
            }
        }
    }
    
    /// Execute data analysis in background
    func executeDataAnalysis(completion: @escaping () -> Void) {
        guard shouldExecuteBackgroundTask() else {
            completion()
            return
        }
        
        startBackgroundTask()
        
        backgroundQueue.async { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            Task { @MainActor in
                // Execute data analysis
                self.performDataAnalysis()
                
                self.endBackgroundTask()
                completion()
            }
        }
    }
    
    /// Execute periodic maintenance tasks
    func executeMaintenanceTasks() {
        guard shouldExecuteBackgroundTask() else { return }
        
        startBackgroundTask()
        
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.performMaintenanceTasks()
                
                self.endBackgroundTask()
            }
        }
    }
    
    /// Main actor context'te çağrılmalı!
    @MainActor
    func cleanupBackgroundTaskIfNeeded() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            isBackgroundTaskActive = false
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBackgroundTaskHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func shouldExecuteBackgroundTask() -> Bool {
        guard let lastTask = lastBackgroundTaskDate else { return true }
        
        let timeSinceLastTask = Date().timeIntervalSince(lastTask)
        return timeSinceLastTask >= minBackgroundTaskInterval
    }
    
    private func startBackgroundTask() {
        guard backgroundTaskID == .invalid else { return }
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "DrinklyAITraining") { [weak self] in
            self?.endBackgroundTask()
        }
        
        isBackgroundTaskActive = true
        lastBackgroundTaskDate = Date()
    }
    
    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
        isBackgroundTaskActive = false
    }
    
    private func performAITraining() {
        // Simulate AI training with battery optimization
        let startTime = Date()
        
        // Use lower CPU priority for AI operations
        Thread.current.threadPriority = 0.3
        
        // Perform lightweight AI operations
        for _ in 1...5 {
            // Simulate training steps
            Thread.sleep(forTimeInterval: 0.1)
            
            // Check if we're running out of background time
            if Date().timeIntervalSince(startTime) > maxBackgroundTaskDuration {
                break
            }
        }
        
        // Reset thread priority
        Thread.current.threadPriority = 0.5
    }
    
    private func performDataAnalysis() {
        // Simulate data analysis with battery optimization
        let startTime = Date()
        
        Thread.current.threadPriority = 0.3
        
        // Perform lightweight data analysis
        for _ in 1...3 {
            Thread.sleep(forTimeInterval: 0.05)
            
            if Date().timeIntervalSince(startTime) > maxBackgroundTaskDuration {
                break
            }
        }
        
        Thread.current.threadPriority = 0.5
    }
    
    private func performMaintenanceTasks() {
        // Clean up old data, optimize storage
        let startTime = Date()
        
        Thread.current.threadPriority = 0.2
        
        // Perform maintenance tasks
        for _ in 1...2 {
            Thread.sleep(forTimeInterval: 0.05)
            
            if Date().timeIntervalSince(startTime) > maxBackgroundTaskDuration {
                break
            }
        }
        
        Thread.current.threadPriority = 0.5
    }
    
    // MARK: - Notification Handlers
    
    @objc private func appWillResignActive() {
        // App is going to background, ensure background tasks are properly managed
        if isBackgroundTaskActive {
            // Extend background task if needed
        }
    }
    
    @objc private func appDidBecomeActive() {
        // App is back in foreground, end any background tasks
        endBackgroundTask()
    }
}

// MARK: - Battery Optimization Extensions

extension BackgroundTaskManager {
    
    /// Check if device is on low battery
    var isLowBattery: Bool {
        return UIDevice.current.batteryLevel < 0.2
    }
    
    /// Check if device is charging
    var isCharging: Bool {
        return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }
    
    /// Get recommended background task interval based on battery state
    var recommendedBackgroundTaskInterval: TimeInterval {
        if isLowBattery {
            return 600 // 10 minutes when low battery
        } else if isCharging {
            return 180 // 3 minutes when charging
        } else {
            return 300 // 5 minutes normally
        }
    }
} 