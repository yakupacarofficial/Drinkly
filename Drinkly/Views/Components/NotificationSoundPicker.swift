//
//  NotificationSoundPicker.swift
//  Drinkly
//
//  Created by Yakup ACAR on 7.07.2025.
//

import SwiftUI

/// A picker component for selecting notification sounds
struct NotificationSoundPicker: View {
    
    // MARK: - Properties
    @Binding var selectedSound: NotificationSound
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var showingSoundPreview = false
    @State private var previewSound: NotificationSound?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notification Sound")
                    .font(.headline)
                Spacer()
                Button("Preview") {
                    notificationManager.playSoundPreview(selectedSound)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(NotificationSound.allCases, id: \.self) { sound in
                    SoundOptionCard(
                        sound: sound,
                        isSelected: selectedSound == sound,
                        onTap: {
                            selectedSound = sound
                            notificationManager.updateNotificationSound(sound)
                        }
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

/// Individual sound option card
struct SoundOptionCard: View {
    let sound: NotificationSound
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: sound.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(sound.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Notification sound settings section
struct NotificationSoundSection: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var selectedSound: NotificationSound = .default
    
    var body: some View {
        Section("Notification Sounds") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose your preferred notification sound")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                NotificationSoundPicker(selectedSound: $selectedSound)
                    .environmentObject(notificationManager)
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            selectedSound = notificationManager.selectedSound
        }
    }
}

// MARK: - Preview
#Preview {
    NotificationSoundPicker(selectedSound: .constant(.default))
        .environmentObject(NotificationManager.shared)
        .padding()
} 