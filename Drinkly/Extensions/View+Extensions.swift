//
//  View+Extensions.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

extension View {
    
    // MARK: - Card Styling
    
    /// Applies card styling to a view
    /// - Returns: Styled view
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    /// Applies primary button styling
    /// - Returns: Styled button
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.drinklyPrimary)
            .cornerRadius(25)
    }
    
    /// Applies secondary button styling
    /// - Returns: Styled button
    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(.drinklyPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.drinklyPrimary.opacity(0.1))
            .cornerRadius(25)
    }
    
    // MARK: - Accessibility
    
    /// Adds accessibility label and hint
    /// - Parameters:
    ///   - label: Accessibility label
    ///   - hint: Accessibility hint
    /// - Returns: View with accessibility
    func accessibilityConfig(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    // MARK: - Animation
    
    /// Applies scale animation on press
    /// - Returns: Animated view
    func scaleOnPress() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Layout
    
    /// Centers the view horizontally
    /// - Returns: Centered view
    func centerHorizontally() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
    
    /// Centers the view vertically
    /// - Returns: Centered view
    func centerVertically() -> some View {
        VStack {
            Spacer()
            self
            Spacer()
        }
    }
    
    /// Centers the view both horizontally and vertically
    /// - Returns: Centered view
    func centerInParent() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                self
                Spacer()
            }
            Spacer()
        }
    }
} 