//
//  Color+Extensions.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

extension Color {
    
    // MARK: - App Colors
    
    /// Primary app color
    static let drinklyPrimary = Color.blue
    
    /// Secondary app color
    static let drinklySecondary = Color.blue.opacity(0.7)
    
    /// Background gradient colors
    static let drinklyBackground = LinearGradient(
        gradient: Gradient(colors: [
            Color.blue.opacity(0.1),
            Color.white,
            Color.blue.opacity(0.05)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Success color for goal completion
    static let drinklySuccess = Color.green
    
    /// Warning color
    static let drinklyWarning = Color.orange
    
    /// Error color
    static let drinklyError = Color.red
    
    // MARK: - Progress Colors
    
    /// Returns appropriate color based on progress percentage
    /// - Parameter percentage: Progress percentage (0.0 to 1.0)
    /// - Returns: Color for the progress
    static func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<0.33:
            return .gray
        case 0.33..<0.67:
            return .blue
        default:
            return .green
        }
    }
    
    /// Returns gradient colors for progress circle
    /// - Parameter percentage: Progress percentage (0.0 to 1.0)
    /// - Returns: Array of colors for gradient
    static func progressGradientColors(for percentage: Double) -> [Color] {
        switch percentage {
        case 0..<0.33:
            return [.gray, .blue.opacity(0.7)]
        case 0.33..<0.67:
            return [.blue.opacity(0.7), .blue]
        default:
            return [.blue, .green]
        }
    }
} 