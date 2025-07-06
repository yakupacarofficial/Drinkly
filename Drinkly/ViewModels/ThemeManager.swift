//
//  ThemeManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI

/// Manages app themes and color schemes
@MainActor
class ThemeManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentTheme: AppTheme = .default
    @Published var colorScheme: ColorScheme? = nil
    @Published var accentColor: Color = .blue
    @Published var backgroundColor: Color = Color(.systemBackground)
    @Published var cardBackgroundColor: Color = Color(.secondarySystemBackground)
    @Published var textColor: Color = Color(.label)
    
    // MARK: - App Storage for Theme Selection
    @AppStorage("drinkly_theme_mode") var themeMode: ThemeMode = .system
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let themeKey = "drinkly_app_theme"
    private let accentColorKey = "drinkly_accent_color"
    
    // MARK: - Initialization
    init() {
        loadThemeSettings()
        updateColors()
    }
    
    // MARK: - Public Methods
    
    /// Set app theme
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        updateColors()
        saveThemeSettings()
    }
    
    /// Set theme mode (system, light, dark)
    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
        updateColorScheme()
        updateColors()
        objectWillChange.send()
    }
    
    /// Set accent color
    func setAccentColor(_ color: Color) {
        accentColor = color
        updateColors()
        saveThemeSettings()
    }
    
    /// Get current color scheme based on theme mode
    var currentColorScheme: ColorScheme? {
        switch themeMode {
        case .system:
            return nil // System will handle it automatically
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    /// Get color for specific usage
    func getColor(for usage: ColorUsage) -> Color {
        switch usage {
        case .primary:
            return accentColor
        case .secondary:
            return accentColor.opacity(0.7)
        case .background:
            return backgroundColor
        case .cardBackground:
            return cardBackgroundColor
        case .text:
            return textColor
        case .textSecondary:
            return textColor.opacity(0.7)
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .info:
            return .blue
        }
    }
    
    /// Get gradient for specific usage
    func getGradient(for usage: GradientUsage) -> LinearGradient {
        switch usage {
        case .primary:
            return LinearGradient(
                colors: [accentColor, accentColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .background:
            return LinearGradient(
                colors: [backgroundColor, backgroundColor.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .success:
            return LinearGradient(
                colors: [.green, .green.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .warning:
            return LinearGradient(
                colors: [.orange, .orange.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func loadThemeSettings() {
        // Load theme
        if let themeData = userDefaults.data(forKey: themeKey),
           let theme = try? JSONDecoder().decode(AppTheme.self, from: themeData) {
            currentTheme = theme
        }
        
        // Load accent color
        if let colorData = userDefaults.data(forKey: accentColorKey),
           let colorComponents = try? JSONDecoder().decode([Double].self, from: colorData),
           colorComponents.count == 4 {
            accentColor = Color(
                red: colorComponents[0],
                green: colorComponents[1],
                blue: colorComponents[2],
                opacity: colorComponents[3]
            )
        }
        
        updateColorScheme()
    }
    
    private func saveThemeSettings() {
        // Save theme
        if let themeData = try? JSONEncoder().encode(currentTheme) {
            userDefaults.set(themeData, forKey: themeKey)
        }
        
        // Save accent color
        let colorComponents = accentColor.components
        if let colorData = try? JSONEncoder().encode(colorComponents) {
            userDefaults.set(colorData, forKey: accentColorKey)
        }
    }
    
    private func updateColorScheme() {
        colorScheme = currentColorScheme
    }
    
    private func updateColors() {
        switch currentTheme {
        case .default:
            backgroundColor = Color(.systemBackground)
            cardBackgroundColor = Color(.secondarySystemBackground)
            textColor = Color(.label)
            
        case .dark:
            backgroundColor = Color(.systemBackground)
            cardBackgroundColor = Color(.tertiarySystemBackground)
            textColor = Color(.label)
            
        case .light:
            backgroundColor = Color(.systemBackground)
            cardBackgroundColor = Color(.secondarySystemBackground)
            textColor = Color(.label)
            
        case .ocean:
            backgroundColor = Color(red: 0.1, green: 0.2, blue: 0.3)
            cardBackgroundColor = Color(red: 0.15, green: 0.25, blue: 0.35)
            textColor = .white
            
        case .sunset:
            backgroundColor = Color(red: 0.3, green: 0.2, blue: 0.1)
            cardBackgroundColor = Color(red: 0.35, green: 0.25, blue: 0.15)
            textColor = .white
            
        case .forest:
            backgroundColor = Color(red: 0.1, green: 0.3, blue: 0.2)
            cardBackgroundColor = Color(red: 0.15, green: 0.35, blue: 0.25)
            textColor = .white
            
        case .lavender:
            backgroundColor = Color(red: 0.3, green: 0.2, blue: 0.4)
            cardBackgroundColor = Color(red: 0.35, green: 0.25, blue: 0.45)
            textColor = .white
        }
    }
}

// MARK: - Supporting Models

enum ThemeMode: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return "System Default"
        case .light:
            return "Light Mode"
        case .dark:
            return "Dark Mode"
        }
    }
    
    var iconName: String {
        switch self {
        case .system:
            return "gear"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    var description: String {
        switch self {
        case .system:
            return "Follows your device's appearance setting"
        case .light:
            return "Always use light appearance"
        case .dark:
            return "Always use dark appearance"
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case `default` = "default"
    case dark = "dark"
    case light = "light"
    case ocean = "ocean"
    case sunset = "sunset"
    case forest = "forest"
    case lavender = "lavender"
    
    var displayName: String {
        switch self {
        case .default:
            return "Default"
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        case .ocean:
            return "Ocean"
        case .sunset:
            return "Sunset"
        case .forest:
            return "Forest"
        case .lavender:
            return "Lavender"
        }
    }
    
    var iconName: String {
        switch self {
        case .default:
            return "circle.fill"
        case .dark:
            return "moon.fill"
        case .light:
            return "sun.max.fill"
        case .ocean:
            return "drop.fill"
        case .sunset:
            return "sunset.fill"
        case .forest:
            return "leaf.fill"
        case .lavender:
            return "flower"
        }
    }
}

enum ColorUsage {
    case primary, secondary, background, cardBackground, text, textSecondary
    case success, warning, error, info
}

enum GradientUsage {
    case primary, background, success, warning
}

// MARK: - Color Extensions

extension Color {
    var components: [Double] {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return [Double(red), Double(green), Double(blue), Double(alpha)]
    }
}

// MARK: - Predefined Color Palettes

extension ThemeManager {
    
    static let predefinedAccentColors: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .pink,
        .red,
        .teal,
        .indigo
    ]
    
    static let predefinedColorNames: [String] = [
        "Blue",
        "Green",
        "Orange",
        "Purple",
        "Pink",
        "Red",
        "Teal",
        "Indigo"
    ]
    
    func getAccentColorName(for color: Color) -> String {
        let colors = Self.predefinedAccentColors
        let names = Self.predefinedColorNames
        
        for (index, predefinedColor) in colors.enumerated() {
            if predefinedColor.components == color.components {
                return names[index]
            }
        }
        
        return "Custom"
    }
} 