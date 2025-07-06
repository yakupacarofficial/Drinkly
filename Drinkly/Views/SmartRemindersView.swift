//
//  SmartRemindersView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

struct SmartRemindersView: View {
    @ObservedObject private var smartReminderManager: SmartReminderManager
    @EnvironmentObject private var aiReminderManager: AIReminderManager
    @EnvironmentObject private var waterManager: WaterManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(smartReminderManager: SmartReminderManager) {
        self.smartReminderManager = smartReminderManager
    }
    
    @State private var showingAddReminder = false
    @State private var showingEditReminder = false
    @State private var selectedReminder: SmartReminder?
    @State private var showingAIInsights = false
    @State private var showingPrivacySettings = false
    @State private var showingDeleteConfirmation = false
    @State private var reminderToDelete: SmartReminder?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with smart features
                smartFeaturesHeader
                
                // Reminders list
                remindersList
            }
            .navigationTitle("Smart Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Analyze Patterns") {
                            showingAIInsights = true
                        }
                        
                        Button("Privacy Settings") {
                            showingPrivacySettings = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedbackHelper.shared.trigger()
                        showingAddReminder = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView()
                    .environmentObject(smartReminderManager)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingEditReminder) {
                if let reminder = selectedReminder {
                    EditReminderView(reminder: reminder)
                        .environmentObject(smartReminderManager)
                        .environmentObject(themeManager)
                }
            }
            .alert("Delete Reminder", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let reminder = reminderToDelete {
                        Task {
                            await deleteReminder(reminder)
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this reminder? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Smart Features Header
    private var smartFeaturesHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Features")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Adaptive reminders that learn from your habits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // AI Confidence Indicator
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .trim(from: 0, to: aiReminderManager.aiConfidence)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    Text("\(Int(aiReminderManager.aiConfidence * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            // Smart features summary
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                SmartFeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Pattern Analysis",
                    description: "Learns your drinking habits",
                    color: .blue,
                    confidence: aiReminderManager.aiConfidence
                )
                
                SmartFeatureCard(
                    icon: "clock.arrow.circlepath",
                    title: "Adaptive Timing",
                    description: "Adjusts reminder times",
                    color: .green,
                    confidence: aiReminderManager.aiConfidence
                )
                
                SmartFeatureCard(
                    icon: "hand.raised.fill",
                    title: "Skip Detection",
                    description: "Suggests better times",
                    color: .orange,
                    confidence: aiReminderManager.aiConfidence
                )
                
                SmartFeatureCard(
                    icon: "lightbulb.fill",
                    title: "Smart Suggestions",
                    description: "Optimizes your schedule",
                    color: .purple,
                    confidence: aiReminderManager.aiConfidence
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Reminders List
    private var remindersList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Active reminders
                Section(header: sectionHeader("Active Reminders", count: activeReminders.count)) {
                    ForEach(activeReminders, id: \.id) { reminder in
                        ReminderCard(
                            manager: smartReminderManager,
                            reminderId: reminder.id,
                            onEdit: {
                                selectedReminder = reminder
                                showingEditReminder = true
                            },
                            onToggle: {
                                Task {
                                    await toggleReminder(reminder)
                                }
                            },
                            onDelete: {
                                reminderToDelete = reminder
                                showingDeleteConfirmation = true
                            }
                        )
                    }
                }
                
                // AI Suggested reminders
                if !aiReminderManager.suggestedReminders.isEmpty {
                    Section(header: sectionHeader("AI Suggestions", count: aiReminderManager.suggestedReminders.count)) {
                        ForEach(aiReminderManager.suggestedReminders) { suggestion in
                            AIReminderSuggestionCard(
                                suggestion: suggestion,
                                onAccept: {
                                    Task {
                                        await aiReminderManager.acceptSuggestion(suggestion)
                                    }
                                },
                                onDecline: {
                                    Task {
                                        await aiReminderManager.dismissSuggestion(suggestion)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Disabled reminders
                if !disabledReminders.isEmpty {
                    Section(header: sectionHeader("Disabled Reminders", count: disabledReminders.count)) {
                        ForEach(disabledReminders, id: \.id) { reminder in
                            ReminderCard(
                                manager: smartReminderManager,
                                reminderId: reminder.id,
                                onEdit: {
                                    selectedReminder = reminder
                                    showingEditReminder = true
                                },
                                onToggle: {
                                    Task {
                                        await toggleReminder(reminder)
                                    }
                                },
                                onDelete: {
                                    reminderToDelete = reminder
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                }
                
                // AI Learning Status
                if aiReminderManager.totalDataPoints > 0 {
                    Section(header: sectionHeader("AI Learning Status", count: nil)) {
                        AILearningStatusCard(aiReminderManager: aiReminderManager)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    private var activeReminders: [SmartReminder] {
        smartReminderManager.reminders.filter { $0.isEnabled }
    }
    
    private var disabledReminders: [SmartReminder] {
        smartReminderManager.reminders.filter { !$0.isEnabled }
    }
    
    // MARK: - Helper Methods
    private func sectionHeader(_ title: String, count: Int?) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if let count = count {
                Text("(\(count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func toggleReminder(_ reminder: SmartReminder) async {
        HapticFeedbackHelper.shared.trigger()
        
        // Get the current reminder from manager to ensure we have the latest state
        guard let currentReminder = smartReminderManager.reminders.first(where: { $0.id == reminder.id }) else {
            return
        }
        
        // Create a new reminder with toggled enabled state
        let updatedReminder = SmartReminder(
            id: currentReminder.id,
            time: currentReminder.time,
            message: currentReminder.message,
            isEnabled: !currentReminder.isEnabled,
            isAdaptive: currentReminder.isAdaptive,
            skipCount: currentReminder.skipCount,
            lastSkipped: currentReminder.lastSkipped
        )
        
        // Update the reminder in the manager on main thread
        await MainActor.run {
            smartReminderManager.updateReminder(updatedReminder)
        }
    }
    
    private func deleteReminder(_ reminder: SmartReminder) async {
        HapticFeedbackHelper.shared.trigger()
        // Remove the reminder from the manager
        await MainActor.run {
            smartReminderManager.removeReminder(reminder)
        }
    }
}





// MARK: - Smart Feature Card
struct SmartFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Confidence indicator
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < Int(confidence * 3) ? color : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

// MARK: - Reminder Card
struct ReminderCard: View {
    @ObservedObject var manager: SmartReminderManager
    let reminderId: UUID
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    private var reminder: SmartReminder? {
        manager.reminders.first { $0.id == reminderId }
    }
    
    var body: some View {
        if let reminder = reminder {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: reminder.isEnabled ? "bell.fill" : "bell.slash.fill")
                            .foregroundColor(reminder.isEnabled ? .blue : .gray)
                            .font(.system(size: 16))
                        
                        Text(reminder.time.formatted(date: .omitted, time: .shortened))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Text(reminder.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Status indicators
                VStack(spacing: 4) {
                    // Skip count indicator
                    if reminder.skipCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("\(reminder.skipCount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    }
                    
                    // Adaptive learning indicator
                    if reminder.isAdaptive {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption)
                                .foregroundColor(.purple)
                            
                            Text("AI")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                        Text("Edit")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.blue)
                
                Button(action: onToggle) {
                    HStack(spacing: 4) {
                        Image(systemName: reminder.isEnabled ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                        Text(reminder.isEnabled ? "Disable" : "Enable")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(reminder.isEnabled ? .orange : .green)
                
                Spacer()
                
                Button(action: onDelete) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 12))
                        Text("Delete")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .opacity(reminder.isEnabled ? 1.0 : 0.7)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(reminder.isEnabled ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .id(reminder.id)
        }
    }
}

// MARK: - AI Learning Status Card
struct AILearningStatusCard: View {
    @ObservedObject var aiReminderManager: AIReminderManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Learning Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(aiReminderManager.totalDataPoints) data points collected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Confidence indicator
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                            .frame(width: 30, height: 30)
                        
                        Circle()
                            .trim(from: 0, to: aiReminderManager.aiConfidence)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    Text("\(Int(aiReminderManager.aiConfidence * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            // Progress indicators
            VStack(spacing: 8) {
                HStack {
                    Text("Data Quality:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(aiReminderManager.getReminderInsights().dataQuality * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Adaptive Score:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(aiReminderManager.getReminderInsights().adaptiveScore * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
            
            // Privacy mode indicator
            HStack {
                Image(systemName: "lock.shield")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("Privacy Mode: \(aiReminderManager.privacyMode.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Add Reminder View
struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var smartReminderManager: SmartReminderManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTime = Date()
    @State private var message = "Time to hydrate! 💧"
    @State private var isAdaptive = true
    @State private var showingValidationError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time") {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Message") {
                    TextField("Message", text: $message)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Settings") {
                    Toggle("Adaptive Learning", isOn: $isAdaptive)
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Preview:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            
                            Text(selectedTime.formatted(date: .omitted, time: .shortened))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                            
                            Text(message.isEmpty ? "Enter a message..." : message)
                                .font(.body)
                                .foregroundColor(message.isEmpty ? .secondary : .primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addReminder()
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Invalid Input", isPresented: $showingValidationError) {
                Button("OK") { }
            } message: {
                Text("Please enter a valid message for the reminder.")
            }
        }
    }
    
    private func addReminder() {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedMessage.isEmpty else {
            showingValidationError = true
            return
        }
        
        let reminder = SmartReminder(
            time: selectedTime,
            message: trimmedMessage,
            isEnabled: true,
            isAdaptive: isAdaptive
        )
        
        smartReminderManager.addReminder(reminder)
        dismiss()
    }
}

// MARK: - Edit Reminder View
struct EditReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var smartReminderManager: SmartReminderManager
    @EnvironmentObject private var themeManager: ThemeManager
    let reminder: SmartReminder
    
    @State private var selectedTime: Date
    @State private var message: String
    @State private var isAdaptive: Bool
    @State private var showingValidationError = false
    
    init(reminder: SmartReminder) {
        self.reminder = reminder
        self._selectedTime = State(initialValue: reminder.time)
        self._message = State(initialValue: reminder.message)
        self._isAdaptive = State(initialValue: reminder.isAdaptive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time") {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Message") {
                    TextField("Message", text: $message)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Settings") {
                    Toggle("Adaptive Learning", isOn: $isAdaptive)
                }
                
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Preview:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            
                            Text(selectedTime.formatted(date: .omitted, time: .shortened))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                            
                            Text(message.isEmpty ? "Enter a message..." : message)
                                .font(.body)
                                .foregroundColor(message.isEmpty ? .secondary : .primary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Invalid Input", isPresented: $showingValidationError) {
                Button("OK") { }
            } message: {
                Text("Please enter a valid message for the reminder.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func saveChanges() {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedMessage.isEmpty else {
            showingValidationError = true
            return
        }
        
        // Create updated reminder
        let updatedReminder = SmartReminder(
            id: reminder.id,
            time: selectedTime,
            message: trimmedMessage,
            isEnabled: reminder.isEnabled,
            isAdaptive: isAdaptive,
            skipCount: reminder.skipCount,
            lastSkipped: reminder.lastSkipped
        )
        
        // Update the reminder
        smartReminderManager.updateReminder(updatedReminder)
        
        dismiss()
    }
}



#Preview {
    SmartRemindersView(smartReminderManager: SmartReminderManager())
        .environmentObject(AIReminderManager())
        .environmentObject(ThemeManager())
} 