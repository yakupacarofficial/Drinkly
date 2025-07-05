//
//  TodayLogView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Today's water log view component
struct TodayLogView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var waterManager: WaterManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            contentSection
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Private Views
    
    private var headerSection: some View {
        HStack {
            Text("Today's Log")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(waterManager.todayDrinks.count) entries")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var contentSection: some View {
        Group {
            if waterManager.todayDrinks.isEmpty {
                emptyStateView
            } else {
                drinkLogList
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop")
                .font(.system(size: 30))
                .foregroundColor(.blue.opacity(0.5))
                .accessibilityHidden(true)
            
            Text("No water logged today")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityLabel("No water logged today")
    }
    
    private var drinkLogList: some View {
        LazyVStack(spacing: 12) {
            ForEach(waterManager.todayDrinks.reversed(), id: \.id) { drink in
                DrinkLogRow(drink: drink)
            }
        }
        .accessibilityLabel("Today's water intake log")
    }
}

// MARK: - Drink Log Row
struct DrinkLogRow: View {
    let drink: WaterDrink
    
    var body: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundColor(.blue)
                .font(.caption)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(drink.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(drink.timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+\(drink.formattedAmount)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(drink.formattedAmount) at \(drink.timeString)")
    }
}

// MARK: - Preview
#Preview {
    TodayLogView()
        .environmentObject(WaterManager())
        .padding()
} 