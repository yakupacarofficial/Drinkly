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
    @EnvironmentObject private var performanceMonitor: PerformanceMonitor
    
    // MARK: - State Properties
    @State private var showingSettings = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                if isLoading {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Drinkly")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsButton
                }
            }
        }
        .sheet(isPresented: $waterManager.showingDrinkOptions) {
            DrinkOptionsView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .overlay(
            Group {
                if waterManager.showingCelebration {
                    CelebrationView(isShowing: $waterManager.showingCelebration)
                }
            }
        )
        .onAppear {
            setupApp()
        }
        .onReceive(locationManager.$city) { newCity in
            waterManager.setUserCity(newCity)
        }
        .onReceive(locationManager.$errorMessage) { error in
            if let error = error {
                errorMessage = error
                showingError = true
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .measurePerformance("MainView")
    }
    
    // MARK: - Private Views
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 30) {
                HeaderView()
                    .measurePerformance("HeaderView")
                
                ProgressCircleView()
                    .measurePerformance("ProgressCircleView")
                
                AddWaterButton()
                    .measurePerformance("AddWaterButton")
                
                TodayLogView()
                    .measurePerformance("TodayLogView")
                
                MotivationView()
                    .measurePerformance("MotivationView")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Drinkly...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.1),
                Color.blue.opacity(0.05),
                Color.white
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var settingsButton: some View {
        Button(action: {
            showingSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens app settings")
    }
    
    // MARK: - Private Methods
    
    private func setupApp() {
        performanceMonitor.startTiming("AppSetup")
        
        Task {
            // Setup location services
            locationManager.requestLocationPermission()
            
            // Small delay to ensure smooth loading
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                isLoading = false
                performanceMonitor.endTiming("AppSetup")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .environmentObject(WaterManager())
        .environmentObject(LocationManager())
        .environmentObject(NotificationManager.shared)
        .environmentObject(PerformanceMonitor.shared)
} 