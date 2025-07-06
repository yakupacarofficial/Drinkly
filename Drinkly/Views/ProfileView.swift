//
//  ProfileView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var waterManager: WaterManager
    @EnvironmentObject var profilePictureManager: ProfilePictureManager
    
    @State private var userProfile: UserProfile
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var isSaving = false
    @State private var showingActivityPicker = false
    
    init(existingProfile: UserProfile? = nil) {
        _userProfile = State(initialValue: existingProfile ?? UserProfile.default)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    formSection
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid Input", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showingActivityPicker) {
                ActivityLevelPickerView(selectedLevel: $userProfile.activityLevel)
                    .environmentObject(waterManager)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ProfilePictureView(size: 80, showEditButton: true)
            
            Text("Personalize Your Hydration")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Help us calculate your optimal daily water intake based on your profile and local weather conditions.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 20) {
            // Age Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Age", systemImage: "calendar")
                    .font(.headline)
                
                HStack {
                    TextField("Enter your age", value: $userProfile.age, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Age input field")
                    
                    Text("years")
                        .foregroundColor(.secondary)
                }
                
                if userProfile.age < 10 || userProfile.age > 100 {
                    Text("Age must be between 10 and 100")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Weight Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Weight", systemImage: "scalemass")
                    .font(.headline)
                
                HStack {
                    TextField("Enter your weight", value: $userProfile.weight, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Weight input field")
                    
                    Text("kg")
                        .foregroundColor(.secondary)
                }
                
                if userProfile.weight < 30 || userProfile.weight > 200 {
                    Text("Weight must be between 30 and 200 kg")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Height Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Height", systemImage: "ruler")
                    .font(.headline)
                
                HStack {
                    TextField("Enter your height", value: $userProfile.height, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Height input field")
                    
                    Text("cm")
                        .foregroundColor(.secondary)
                }
                
                if userProfile.height < 100 || userProfile.height > 250 {
                    Text("Height must be between 100 and 250 cm")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Gender Selection
            VStack(alignment: .leading, spacing: 8) {
                Label("Gender", systemImage: "person.2")
                    .font(.headline)
                
                Picker("Gender", selection: $userProfile.gender) {
                    Text("Male").tag(UserProfile.Gender.male)
                    Text("Female").tag(UserProfile.Gender.female)
                    Text("Other").tag(UserProfile.Gender.other)
                }
                .pickerStyle(SegmentedPickerStyle())
                .accessibilityLabel("Gender selection")
            }
            
            // Activity Level Selection
            VStack(alignment: .leading, spacing: 8) {
                Label("Activity Level", systemImage: "figure.walk")
                    .font(.headline)
                
                Button(action: {
                    showingActivityPicker = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userProfile.activityLevel.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(userProfile.activityLevel.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .accessibilityLabel("Activity level selection")
                .accessibilityHint("Tap to change activity level")
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isSaving ? "Saving..." : "Save Profile")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isFormValid ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isSaving)
        .opacity(isFormValid ? 1.0 : 0.6)
        .padding(.top, 20)
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        let ageValid = userProfile.age >= 10 && userProfile.age <= 100
        let weightValid = userProfile.weight >= 30 && userProfile.weight <= 200
        let heightValid = userProfile.height >= 100 && userProfile.height <= 250
        return ageValid && weightValid && heightValid
    }
    
    private func saveProfile() {
        guard isFormValid else {
            validationMessage = "Please enter valid age (10-100), weight (30-200 kg), and height (100-250 cm)."
            showingValidationAlert = true
            return
        }
        
        // Additional validation for edge cases
        if userProfile.age < 10 || userProfile.age > 100 {
            validationMessage = "Age must be between 10 and 100 years."
            showingValidationAlert = true
            return
        }
        
        if userProfile.weight < 30 || userProfile.weight > 200 {
            validationMessage = "Weight must be between 30 and 200 kg."
            showingValidationAlert = true
            return
        }
        
        if userProfile.height < 100 || userProfile.height > 250 {
            validationMessage = "Height must be between 100 and 250 cm."
            showingValidationAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            // Simulate async save operation
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                // Save profile with error handling
                do {
                    try userProfile.save()
                    
                    // Update water manager with new profile
                    waterManager.updateUserProfile(userProfile)
                    
                    isSaving = false
                    
                    // Dismiss the view
                    dismiss()
                } catch {
                    isSaving = false
                    validationMessage = "Failed to save profile. Please try again."
                    showingValidationAlert = true
                }
            }
        }
    }
}

// MARK: - Activity Level Picker View
struct ActivityLevelPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLevel: UserProfile.ActivityLevel
    @State private var tempSelectedLevel: UserProfile.ActivityLevel
    
    init(selectedLevel: Binding<UserProfile.ActivityLevel>) {
        self._selectedLevel = selectedLevel
        self._tempSelectedLevel = State(initialValue: selectedLevel.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                    Button(action: {
                        tempSelectedLevel = level
                        selectedLevel = level
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(level.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if tempSelectedLevel == level {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Activity Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedLevel = tempSelectedLevel
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions for Display Names
// Only keep the description extension for ActivityLevel if not already in the model
extension UserProfile.ActivityLevel {
    var description: String {
        switch self {
        case .sedentary:
            return NSLocalizedString("Little or no exercise", comment: "")
        case .moderate:
            return NSLocalizedString("Light exercise 1-3 days/week", comment: "")
        case .active:
            return NSLocalizedString("Moderate exercise 3-5 days/week", comment: "")
        case .veryActive:
            return NSLocalizedString("Hard exercise 6-7 days/week", comment: "")
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(WaterManager())
        .environmentObject(LocationManager())
        .environmentObject(WeatherManager())
        .environmentObject(NotificationManager.shared)
        .environmentObject(PerformanceMonitor.shared)
        .environmentObject(HydrationHistory())
        .environmentObject(AchievementManager())
        .environmentObject(SmartReminderManager())
        .environmentObject(ProfilePictureManager())
} 