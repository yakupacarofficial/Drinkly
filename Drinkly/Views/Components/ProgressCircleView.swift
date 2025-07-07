//
//  ProgressCircleView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Progress circle view showing water, other liquids, or total liquid intake progress
struct ProgressCircleView: View {
    enum Mode { case water, other, total }
    let mode: Mode
    
    @EnvironmentObject private var liquidManager: LiquidManager
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var cachedProgress: Double = 0.0
    @State private var cachedCurrentAmount: Double = 0.0
    @State private var cachedDailyGoal: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            if mode == .other {
                Text("Other Liquids")
                    .font(.headline)
                    .foregroundColor(.orange)
            } else if mode == .total {
                Text("Total Liquid")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            progressContainer
            if mode == .water {
                progressText
            }
        }
        .onAppear { updateCache() }
        .onChange(of: progressValue) { _, _ in updateCache() }
        .onChange(of: currentAmount) { _, _ in updateCache() }
        .onChange(of: dailyGoal) { _, _ in updateCache() }
        .onChange(of: liquidManager.drinks) { _, _ in updateCache() }
    }
    
    // MARK: - Private Views
    private var progressContainer: some View {
        ZStack {
            backgroundCircle
            progressCircle
            waterDropIcon
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Liquid progress")
        .accessibilityValue("\(Int(progressValue * 100))% complete, \(String(format: "%.1f", currentAmount)) ml of \(String(format: "%.1f", dailyGoal)) ml")
        .padding(Constants.UI.progressStrokeWidth / 2)
        .frame(width: Constants.UI.progressCircleSize, height: Constants.UI.progressCircleSize)
    }
    private var backgroundCircle: some View {
        Circle()
            .stroke(backgroundColor, lineWidth: Constants.UI.progressStrokeWidth)
            .frame(width: Constants.UI.progressCircleSize, height: Constants.UI.progressCircleSize)
    }
    
    private var backgroundColor: Color {
        switch mode {
        case .water: return Color.blue.opacity(0.2)
        case .other: return Color.orange.opacity(0.2)
        case .total: return Color.green.opacity(0.2)
        }
    }
    
    private var progressCircle: some View {
        Circle()
            .trim(from: 0, to: cachedProgress)
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
            .animation(.easeInOut(duration: Constants.AnimationDuration.slow), value: cachedProgress)
    }
    
    private var waterDropIcon: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
                .accessibilityHidden(true)
            VStack(spacing: 4) {
                Text("\(String(format: "%.1f", currentAmount / 1000))L")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(iconColor)
                if mode == .water {
                    Text("of \(String(format: "%.1f", dailyGoal / 1000))L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var iconName: String {
        switch mode {
        case .water: return "drop.fill"
        case .other: return "cup.and.saucer.fill"
        case .total: return "drop.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch mode {
        case .water: return .blue
        case .other: return .orange
        case .total: return .green
        }
    }
    private var progressText: some View {
        VStack(spacing: 4) {
            Text("\(Int(progressValue * 100))% Complete")
                .font(.headline)
                .foregroundColor(mode == .water ? .blue : .green)
            Text("\(String(format: "%.1f", (dailyGoal - currentAmount) / 1000))L remaining")
                .font(.caption)
                .foregroundColor(.secondary)
            if !locationManager.city.isEmpty {
                locationInfo
            }
        }
    }
    private var locationInfo: some View {
        Text("Your location: \(locationManager.city). Your liquid goal: \(String(format: "%.1f", dailyGoal / 1000))L 💧")
            .font(.caption)
            .foregroundColor(mode == .water ? .blue : .green)
            .multilineTextAlignment(.center)
    }
    // MARK: - Computed Properties
    private var progressValue: Double {
        switch mode {
        case .water: return min(1.0, liquidManager.totalWater / dailyGoal)
        case .other: return min(1.0, liquidManager.totalOtherLiquids / dailyGoal)
        case .total: return min(1.0, liquidManager.totalLiquids / dailyGoal)
        }
    }
    private var currentAmount: Double {
        switch mode {
        case .water: return liquidManager.totalWater
        case .other: return liquidManager.totalOtherLiquids
        case .total: return liquidManager.totalLiquids
        }
    }
    private var dailyGoal: Double { liquidManager.dailyGoal }
    private var progressColors: [Color] {
        let p = progressValue
        switch mode {
        case .water:
            switch p {
            case 0..<0.33: return [.gray, .gray.opacity(0.7)]
            case 0.33..<0.67: return [.blue, .blue.opacity(0.7)]
            default: return [.green, .green.opacity(0.7)]
            }
        case .other:
            switch p {
            case 0..<0.33: return [.gray, .gray.opacity(0.7)]
            case 0.33..<0.67: return [.orange, .orange.opacity(0.7)]
            default: return [.red, .red.opacity(0.7)]
            }
        case .total:
            switch p {
            case 0..<0.33: return [.gray, .gray.opacity(0.7)]
            case 0.33..<0.67: return [.green, .green.opacity(0.7)]
            default: return [.blue, .blue.opacity(0.7)]
            }
        }
    }
    private func updateCache() {
        var progress = progressValue
        
        // Hedefe ulaşıldığında %100 göster (floating point precision sorunu için)
        if progress >= 0.999 || currentAmount >= dailyGoal {
            progress = 1.0
        }
        
        cachedProgress = progress
        cachedCurrentAmount = currentAmount
        cachedDailyGoal = dailyGoal
    }
}

#Preview {
    VStack {
        ProgressCircleView(mode: .water).environmentObject(LiquidManager()).environmentObject(LocationManager()).environmentObject(ThemeManager())
        ProgressCircleView(mode: .total).environmentObject(LiquidManager()).environmentObject(LocationManager()).environmentObject(ThemeManager())
    }.padding()
} 