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

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(waterManager)
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .environmentObject(performanceMonitor)
                .preferredColorScheme(.light)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupApp() {
        // Initialize notification permissions
        notificationManager.checkAuthorizationStatus { granted in
            if !granted {
                notificationManager.requestAuthorization()
            }
        }
        
        #if DEBUG
        // Log performance metrics in debug builds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print(performanceMonitor.getSummary())
        }
        #endif
    }
}
