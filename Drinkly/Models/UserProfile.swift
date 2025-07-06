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
    var height: Double // in cm
    var gender: Gender
    var activityLevel: ActivityLevel
    
    // MARK: - Initializer
    init(age: Int, weight: Double, height: Double, gender: Gender, activityLevel: ActivityLevel) {
        self.age = age
        self.weight = weight
        self.height = height
        self.gender = gender
        self.activityLevel = activityLevel
    }
    
    // MARK: - Validation
    var isValid: Bool {
        let ageValid = (10...100).contains(age)
        let weightValid = (30...200).contains(weight)
        let heightValid = (100...250).contains(height)
        return ageValid && weightValid && heightValid
    }
    
    /// Validate specific fields and return error messages
    func validate() -> [String] {
        var errors: [String] = []
        
        if age < 10 || age > 100 {
            errors.append("Age must be between 10 and 100 years")
        }
        
        if weight < 30 || weight > 200 {
            errors.append("Weight must be between 30 and 200 kg")
        }
        
        if height < 100 || height > 250 {
            errors.append("Height must be between 100 and 250 cm")
        }
        
        return errors
    }
    
    /// Sanitize profile data to ensure valid values
    mutating func sanitize() {
        age = max(10, min(100, age))
        weight = max(30, min(200, weight))
        height = max(100, min(250, height))
    }
    
    // MARK: - Default Profile
    static let `default` = UserProfile(age: 25, weight: 70, height: 170, gender: .male, activityLevel: .moderate)
}

// MARK: - Persistence Helper
extension UserProfile {
    private static let userDefaultsKey = "drinkly_user_profile"
    
    static func load() -> UserProfile {
        do {
            if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
                let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                
                // Validate and sanitize loaded profile
                var sanitizedProfile = profile
                sanitizedProfile.sanitize()
                
                return sanitizedProfile
            }
        } catch {
            print("[UserProfile] Error loading profile: \(error)")
        }
        return .default
    }
    
    func save() throws {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: UserProfile.userDefaultsKey)
        } catch {
            print("[UserProfile] Error saving profile: \(error)")
            throw error
        }
    }
} 