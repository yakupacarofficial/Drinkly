//
//  UserProfile.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation

/// Represents the user's profile for personalized hydration calculation
struct UserProfile: Codable, Equatable {
    enum Gender: String, Codable, CaseIterable, Identifiable {
        case male, female, other
        var id: String { rawValue }
    }
    
    enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
        case sedentary, moderate, active, veryActive
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .sedentary: return NSLocalizedString("Sedentary", comment: "")
            case .moderate: return NSLocalizedString("Moderate", comment: "")
            case .active: return NSLocalizedString("Active", comment: "")
            case .veryActive: return NSLocalizedString("Very Active", comment: "")
            }
        }
    }
    
    var age: Int
    var weight: Double // in kg
    var gender: Gender
    var activityLevel: ActivityLevel
    
    // MARK: - Initializer
    init(age: Int, weight: Double, gender: Gender, activityLevel: ActivityLevel) {
        self.age = age
        self.weight = weight
        self.gender = gender
        self.activityLevel = activityLevel
    }
    
    // MARK: - Validation
    var isValid: Bool {
        (10...100).contains(age) && (30...200).contains(weight)
    }
    
    // MARK: - Default Profile
    static let `default` = UserProfile(age: 25, weight: 70, gender: .male, activityLevel: .moderate)
}

// MARK: - Persistence Helper
extension UserProfile {
    private static let userDefaultsKey = "drinkly_user_profile"
    
    static func load() -> UserProfile {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return .default
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserProfile.userDefaultsKey)
        }
    }
} 