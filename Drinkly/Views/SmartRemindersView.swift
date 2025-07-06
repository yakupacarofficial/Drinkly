//
//  SmartRemindersView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

struct SmartRemindersView: View {
    @EnvironmentObject private var smartReminderManager: SmartReminderManager
    @EnvironmentObject private var aiReminderManager: AIReminderManager
    @State private var showingAddReminder = false
    @State private var selectedReminder: SmartReminder?
    @State private var showingEditReminder = false
    @State private var showingSuggestion = false
    @State private var currentSuggestion: SmartReminder?
    @State private var showingAIInsights = false
    @State private var showingPrivacySettings = false
    
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
                            smartReminderManager.analyzeAndSuggest()
                        }
                        
                        Button("AI Analysis") {
                            aiReminderManager.analyzeAndSuggestReminders()
                        }
                        
                        Button("AI Insights") {
                            showingAIInsights = true
                        }
                        
                        Divider()
                        
                        Button("Privacy Settings") {
                            showingPrivacySettings = true
                        }
                    } label: {
                        Image(systemName: "brain.head.profile")
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
            .sheet(isPresented: $showingAIInsights) {
                NavigationView {
                    AIReminderInsightsView(aiReminderManager: aiReminderManager)
                        .navigationTitle("AI Insights")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingAIInsights = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingPrivacySettings) {
                NavigationView {
                    PrivacySettingsView(aiReminderManager: aiReminderManager)
                        .navigationTitle("Privacy Settings")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingPrivacySettings = false
                                }
                            }
                        }
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
                    ForEach(activeReminders) { reminder in
                        ReminderCard(
                            reminder: reminder,
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
                                Task {
                                    await deleteReminder(reminder)
                                }
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
                        ForEach(disabledReminders) { reminder in
                            ReminderCard(
                                reminder: reminder,
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
                                    Task {
                                        await deleteReminder(reminder)
                                    }
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
        // Implementation for toggling reminder
    }
    
    private func deleteReminder(_ reminder: SmartReminder) async {
        // Implementation for deleting reminder
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
    let reminder: SmartReminder
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.time.formatted(date: .omitted, time: .shortened))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(reminder.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            HStack(spacing: 8) {
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(reminder.isEnabled ? "Disable" : "Enable") {
                    onToggle()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(reminder.isEnabled ? .red : .green)
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
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
        .opacity(reminder.isEnabled ? 1.0 : 0.6)
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
    @State private var selectedTime = Date()
    @State private var message = "Time to hydrate! 💧"
    @State private var isAdaptive = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time") {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Message") {
                    TextField("Message", text: $message)
                }
                
                Section("Settings") {
                    Toggle("Adaptive Learning", isOn: $isAdaptive)
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
                        let reminder = SmartReminder(
                            time: selectedTime,
                            message: message,
                            isEnabled: true,
                            isAdaptive: isAdaptive
                        )
                        smartReminderManager.addReminder(reminder)
                        dismiss()
                    }
                }
            }
        }
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
                }
                
                Section("Settings") {
                    Toggle("Adaptive Learning", isOn: $isAdaptive)
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
                        smartReminderManager.updateReminderTime(reminder, newTime: selectedTime)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Smart Reminder Suggestion View
struct SmartReminderSuggestionView: View {
    let suggestion: SmartReminder
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Suggestion")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Based on your patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    
                    Text(suggestion.time.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    
                    Text(suggestion.message)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            
            HStack(spacing: 12) {
                Button("Decline") {
                    onDecline()
                }
                .buttonStyle(.bordered)
                
                Button("Accept") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

#Preview {
    SmartRemindersView()
        .environmentObject(SmartReminderManager())
        .environmentObject(AIReminderManager())
} 