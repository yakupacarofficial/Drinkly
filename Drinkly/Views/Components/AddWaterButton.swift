//
//  AddWaterButton.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Add water button component
struct AddWaterButton: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var waterManager: WaterManager
    
    var body: some View {
        Button(action: {
            waterManager.showingDrinkOptions = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .accessibilityHidden(true)
                
                Text("Add Water")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(28)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Add water")
        .accessibilityHint("Opens drink options to add water intake")
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    AddWaterButton()
        .environmentObject(WaterManager())
        .padding()
} 