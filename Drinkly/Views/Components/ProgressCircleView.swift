//
//  ProgressCircleView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Progress circle view showing water intake progress
struct ProgressCircleView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var waterManager: WaterManager
    @EnvironmentObject private var locationManager: LocationManager
    
    // MARK: - Private Properties
    @State private var cachedProgressPercentage: Double = 0.0
    @State private var cachedCurrentAmount: Double = 0.0
    @State private var cachedDailyGoal: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            progressContainer
            progressText
        }
        .onChange(of: waterManager.progressPercentage) { _, newValue in
            cachedProgressPercentage = newValue
        }
        .onChange(of: waterManager.currentAmount) { _, newValue in
            cachedCurrentAmount = newValue
        }
        .onChange(of: waterManager.dailyGoal) { _, newValue in
            cachedDailyGoal = newValue
        }
    }
    
    // MARK: - Private Views
    
    private var progressContainer: some View {
        ZStack {
            backgroundCircle
            progressCircle
            waterDropIcon
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Water progress")
        .accessibilityValue("\(Int(cachedProgressPercentage * 100))% complete, \(String(format: "%.1f", cachedCurrentAmount)) liters of \(String(format: "%.1f", cachedDailyGoal)) liters")
    }
    
    private var backgroundCircle: some View {
        Circle()
            .stroke(Color.blue.opacity(0.2), lineWidth: Constants.UI.progressStrokeWidth)
            .frame(width: Constants.UI.progressCircleSize, height: Constants.UI.progressCircleSize)
    }
    
    private var progressCircle: some View {
        Circle()
            .trim(from: 0, to: cachedProgressPercentage)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: progressColors),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: Constants.UI.progressStrokeWidth, lineCap: .round)
            )
            .frame(width: Constants.UI.progressCircleSize, height: Constants.UI.progressCircleSize)
            .rotationEffect(.degrees(-90))
            .animation(.easeInOut(duration: Constants.AnimationDuration.slow), value: cachedProgressPercentage)
    }
    
    private var waterDropIcon: some View {
        VStack(spacing: 8) {
            Image(systemName: "drop.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .scaleEffect(waterManager.isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: Constants.AnimationDuration.standard).repeatForever(autoreverses: true), value: waterManager.isAnimating)
                .accessibilityHidden(true)
            
            VStack(spacing: 4) {
                Text("\(String(format: "%.1f", cachedCurrentAmount))L")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("of \(String(format: "%.1f", cachedDailyGoal))L")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var progressText: some View {
        VStack(spacing: 4) {
            Text("\(Int(cachedProgressPercentage * 100))% Complete")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text("\(String(format: "%.1f", waterManager.remainingAmount))L remaining")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !locationManager.city.isEmpty {
                locationInfo
            }
        }
    }
    
    private var locationInfo: some View {
        Text("Your location: \(locationManager.city). Your water goal: \(String(format: "%.2f", cachedDailyGoal))L 💧")
            .font(.caption)
            .foregroundColor(.blue)
            .multilineTextAlignment(.center)
    }
    
    // MARK: - Computed Properties
    
    private var progressColors: [Color] {
        let percentage = cachedProgressPercentage
        switch percentage {
        case 0..<0.33:
            return [.gray, .gray.opacity(0.7)]
        case 0.33..<0.67:
            return [.blue, .blue.opacity(0.7)]
        default:
            return [.green, .green.opacity(0.7)]
        }
    }
}

// MARK: - Preview
#Preview {
    ProgressCircleView()
        .environmentObject(WaterManager())
        .padding()
} 