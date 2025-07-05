//
//  DrinkOptionsView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Drink options view for adding water intake
struct DrinkOptionsView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var waterManager: WaterManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    @State private var customAmount: Double = 0.5
    @State private var showingCustomAmount = false
    
    // MARK: - Constants
    private let quickAmounts: [Double] = [0.2, 0.3, 0.5, 0.75, 1.0]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                quickOptionsSection
                customAmountSection
                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Private Views
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "drop.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .accessibilityHidden(true)
            
            Text("How much water did you drink?")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
    }
    
    private var quickOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Options")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(quickAmounts, id: \.self) { amount in
                    QuickAmountButton(amount: amount) {
                        addWater(amount: amount)
                    }
                }
            }
        }
    }
    
    private var customAmountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Amount")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("\(String(format: "%.1f", customAmount))L")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("\(Int(customAmount * 1000))ml")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $customAmount, in: 0.1...2.0, step: 0.1)
                    .accentColor(.blue)
                
                Button(action: {
                    addWater(amount: customAmount)
                }) {
                    Text("Add \(String(format: "%.1f", customAmount))L")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .disabled(customAmount <= 0)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func addWater(amount: Double) {
        waterManager.addWater(amount: amount)
        dismiss()
    }
}

// MARK: - Quick Amount Button
struct QuickAmountButton: View {
    let amount: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(String(format: "%.0f", amount * 1000))ml")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(String(format: "%.1f", amount))L")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Add \(String(format: "%.0f", amount * 1000)) milliliters")
    }
}

// MARK: - Preview
#Preview {
    DrinkOptionsView()
        .environmentObject(WaterManager())
} 