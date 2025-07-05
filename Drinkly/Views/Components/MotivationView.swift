//
//  MotivationView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Motivation view component showing daily tips
struct MotivationView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            messageSection
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Private Views
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .accessibilityHidden(true)
            
            Text("Tip of the Day")
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
    
    private var messageSection: some View {
        Text(motivationMessage)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
    }
    
    // MARK: - Computed Properties
    
    private var motivationMessage: String {
        let messages = [
            "Drinking water improves focus and productivity.",
            "Stay hydrated to maintain energy throughout the day.",
            "Water helps flush toxins and keeps your skin healthy.",
            "Proper hydration supports your immune system.",
            "Great job! You're making excellent progress.",
            "Hydration is key to peak performance.",
            "Water is essential for every cell in your body.",
            "Stay hydrated for better mood and clarity."
        ]
        return messages.randomElement() ?? messages[0]
    }
}

// MARK: - Preview
#Preview {
    MotivationView()
        .padding()
} 