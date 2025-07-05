//
//  SmartRemindersView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

struct SmartRemindersView: View {
    @EnvironmentObject private var smartReminderManager: SmartReminderManager
    @State private var showingAddReminder = false
    @State private var selectedReminder: SmartReminder?
    @State private var showingEditReminder = false
    @State private var showingSuggestion = false
    @State private var currentSuggestion: SmartReminder?
    
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
                    Button("Analyze") {
                        smartReminderManager.analyzeAndSuggest()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddReminder = true
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView()
            }
            .sheet(isPresented: $showingEditReminder) {
                if let reminder = selectedReminder {
                    EditReminderView(reminder: reminder)
                }
            }
            .overlay(
                Group {
                    if showingSuggestion, let suggestion = currentSuggestion {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .overlay(
                                SmartReminderSuggestionView(
                                    suggestion: suggestion,
                                    onAccept: {
                                        smartReminderManager.applySuggestion(suggestion)
                                        showingSuggestion = false
                                    },
                                    onDecline: {
                                        showingSuggestion = false
                                    }
                                )
                                .padding()
                            )
                    }
                }
            )
            .onReceive(smartReminderManager.$showingSuggestion) { showing in
                if showing, let suggestion = smartReminderManager.currentSuggestion {
                    currentSuggestion = suggestion
                    showingSuggestion = true
                }
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
            }
            
            // Smart features summary
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                SmartFeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Pattern Analysis",
                    description: "Learns your drinking habits",
                    color: .blue
                )
                
                SmartFeatureCard(
                    icon: "clock.arrow.circlepath",
                    title: "Adaptive Timing",
                    description: "Adjusts reminder times",
                    color: .green
                )
                
                SmartFeatureCard(
                    icon: "hand.raised.fill",
                    title: "Skip Detection",
                    description: "Suggests better times",
                    color: .orange
                )
                
                SmartFeatureCard(
                    icon: "lightbulb.fill",
                    title: "Smart Suggestions",
                    description: "Optimizes your schedule",
                    color: .purple
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
                    ForEach(activeReminders) { reminder in
                        ReminderCard(
                            reminder: reminder,
                            onEdit: {
                                selectedReminder = reminder
                                showingEditReminder = true
                            },
                            onToggle: {
                                toggleReminder(reminder)
                            },
                            onDelete: {
                                deleteReminder(reminder)
                            }
                        )
                    }
                }
                
                // Suggested reminders
                if !smartReminderManager.suggestedReminders.isEmpty {
                    Section(header: sectionHeader("Suggested Reminders", count: smartReminderManager.suggestedReminders.count)) {
                        ForEach(smartReminderManager.suggestedReminders) { suggestion in
                            SuggestedReminderCard(
                                suggestion: suggestion,
                                onAccept: {
                                    smartReminderManager.applySuggestion(suggestion)
                                },
                                onDecline: {
                                    smartReminderManager.suggestedReminders.removeAll { $0.id == suggestion.id }
                                }
                            )
                        }
                    }
                }
                
                // Disabled reminders
                if !disabledReminders.isEmpty {
                    Section(header: sectionHeader("Disabled Reminders", count: disabledReminders.count)) {
                        ForEach(disabledReminders) { reminder in
                            ReminderCard(
                                reminder: reminder,
                                onEdit: {
                                    selectedReminder = reminder
                                    showingEditReminder = true
                                },
                                onToggle: {
                                    toggleReminder(reminder)
                                },
                                onDelete: {
                                    deleteReminder(reminder)
                                }
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    private var activeReminders: [SmartReminder] {
        smartReminderManager.reminders.filter { $0.isEnabled }.sorted { $0.time < $1.time }
    }
    
    private var disabledReminders: [SmartReminder] {
        smartReminderManager.reminders.filter { !$0.isEnabled }.sorted { $0.time < $1.time }
    }
    
    // MARK: - Helper Methods
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
    
    private func toggleReminder(_ reminder: SmartReminder) {
        if let index = smartReminderManager.reminders.firstIndex(where: { $0.id == reminder.id }) {
            var updatedReminder = reminder
            updatedReminder = SmartReminder(
                time: reminder.time,
                message: reminder.message,
                isEnabled: !reminder.isEnabled,
                isAdaptive: reminder.isAdaptive,
                skipCount: reminder.skipCount,
                lastSkipped: reminder.lastSkipped
            )
            smartReminderManager.reminders[index] = updatedReminder
            smartReminderManager.saveReminders()
        }
    }
    
    private func deleteReminder(_ reminder: SmartReminder) {
        smartReminderManager.removeReminder(reminder)
    }
}

// MARK: - Supporting Views

struct SmartFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct ReminderCard: View {
    let reminder: SmartReminder
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Time and status
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.time.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(reminder.isEnabled ? .primary : .secondary)
                    
                    Text(reminder.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Status indicators
                VStack(spacing: 8) {
                    // Skip count indicator
                    if reminder.skipCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.raised.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(reminder.skipCount)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    // Adaptive indicator
                    if reminder.isAdaptive {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Button(reminder.isEnabled ? "Disable" : "Enable") {
                    onToggle()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .foregroundColor(reminder.isEnabled ? .orange : .green)
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: reminder.isEnabled ? .blue.opacity(0.1) : .clear, radius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(reminder.isEnabled ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(reminder.isEnabled ? 1.0 : 0.6)
    }
}

struct SuggestedReminderCard: View {
    let suggestion: SmartReminder
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Suggestion")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(suggestion.time.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(suggestion.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button("Accept") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
                Button("Decline") {
                    onDecline()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Add Reminder View
struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var smartReminderManager: SmartReminderManager
    @State private var selectedTime = Date()
    @State private var message = ""
    @State private var isAdaptive = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time") {
                    DatePicker("Reminder Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Message") {
                    TextField("Reminder message", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Settings") {
                    Toggle("Smart Adaptive", isOn: $isAdaptive)
                    
                    if isAdaptive {
                        Text("This reminder will learn from your habits and suggest better times")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                    .disabled(message.isEmpty)
                }
            }
        }
    }
    
    private func addReminder() {
        let reminder = SmartReminder(
            time: selectedTime,
            message: message.isEmpty ? "Time to hydrate!" : message,
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
    let reminder: SmartReminder
    
    @State private var selectedTime: Date
    @State private var message: String
    @State private var isAdaptive: Bool
    
    init(reminder: SmartReminder) {
        self.reminder = reminder
        _selectedTime = State(initialValue: reminder.time)
        _message = State(initialValue: reminder.message)
        _isAdaptive = State(initialValue: reminder.isAdaptive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time") {
                    DatePicker("Reminder Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Message") {
                    TextField("Reminder message", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Settings") {
                    Toggle("Smart Adaptive", isOn: $isAdaptive)
                    
                    if isAdaptive {
                        Text("This reminder will learn from your habits and suggest better times")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Statistics") {
                    HStack {
                        Text("Skip Count")
                        Spacer()
                        Text("\(reminder.skipCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastSkipped = reminder.lastSkipped {
                        HStack {
                            Text("Last Skipped")
                            Spacer()
                            Text(lastSkipped.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                    }
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
                        saveReminder()
                    }
                }
            }
        }
    }
    
    private func saveReminder() {
        smartReminderManager.updateReminderTime(reminder, newTime: selectedTime)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    SmartRemindersView()
        .environmentObject(SmartReminderManager())
} 