//
//  AIReminderSuggestionView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

struct AIReminderSuggestionView: View {
    let suggestion: AIReminderSuggestion
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with AI indicator
            headerSection
            
            // Suggestion details
            suggestionDetails
            
            // Confidence and data info
            confidenceSection
            
            // Action buttons
            actionButtons
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Suggestion")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Based on your drinking patterns")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Confidence indicator
            ConfidenceIndicator(confidence: suggestion.confidence)
        }
    }
    
    // MARK: - Suggestion Details
    private var suggestionDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text(suggestion.formattedTime)
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
            
            // Reason for suggestion
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
                
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Confidence Section
    private var confidenceSection: some View {
        VStack(spacing: 12) {
            // Confidence level
            HStack {
                Text("AI Confidence:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(suggestion.confidenceLevel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(confidenceColor)
            }
            
            // Data points
            HStack {
                Text("Data Points:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(suggestion.dataPoints)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Adaptive score
            HStack {
                Text("Adaptive Score:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(suggestion.adaptiveScore * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            // Last activity
            if let lastActivity = suggestion.lastActivity {
                HStack {
                    Text("Last Activity:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(lastActivity.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onDecline) {
                HStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                    Text("Decline")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: onAccept) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14))
                    Text("Accept")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var confidenceColor: Color {
        switch suggestion.confidence {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - Confidence Indicator
struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 30, height: 30)
                
                Circle()
                    .trim(from: 0, to: confidence)
                    .stroke(confidenceColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: confidence)
            }
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(confidenceColor)
        }
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - AI Reminder Suggestions View
struct AIReminderSuggestionsView: View {
    @EnvironmentObject private var aiReminderManager: AIReminderManager
    
    var body: some View {
        VStack(spacing: 16) {
            if aiReminderManager.isAnalyzing {
                analyzingView
            } else if aiReminderManager.suggestedReminders.isEmpty {
                emptyStateView
            } else {
                suggestionsList
            }
        }
    }
    
    // MARK: - Analyzing View
    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing your patterns...")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("AI is learning from your drinking habits to suggest optimal reminder times")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Progress bar
            ProgressView(value: aiReminderManager.learningProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No AI Suggestions Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Continue using reminders to help AI learn your patterns and generate personalized suggestions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Analyze Patterns") {
                aiReminderManager.analyzeAndSuggestReminders()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Suggestions List
    private var suggestionsList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI Suggestions")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // AI confidence indicator
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("\(Int(aiReminderManager.aiConfidence * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
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
}

// MARK: - AI Reminder Suggestion Card
struct AIReminderSuggestionCard: View {
    let suggestion: AIReminderSuggestion
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Time and message
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.formattedTime)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(suggestion.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ConfidenceIndicator(confidence: suggestion.confidence)
            }
            
            // Reason
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Decline") {
                    onDecline()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("Accept") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - AI Reminder Insights View
struct AIReminderInsightsView: View {
    @ObservedObject var aiReminderManager: AIReminderManager
    @State private var showingPrivacySettings = false
    @State private var showingDataExport = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // AI Status
                aiStatusSection
                
                // Insights
                insightsSection
                
                // Privacy & Data
                privacySection
            }
            .padding()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView(aiReminderManager: aiReminderManager)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView(aiReminderManager: aiReminderManager)
        }
    }
    
    // MARK: - AI Status Section
    private var aiStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Confidence: \(Int(aiReminderManager.aiConfidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Data points
            HStack {
                Text("Data Points:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(aiReminderManager.totalDataPoints)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Last analysis
            if let lastAnalysis = aiReminderManager.lastAnalysisDate {
                HStack {
                    Text("Last Analysis:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(lastAnalysis.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("AI Insights")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            let insights = aiReminderManager.getReminderInsights()
            
            ForEach(insights.suggestions, id: \.title) { insight in
                InsightCard(insight: insight)
            }
        }
    }
    
    // MARK: - Privacy Section
    private var privacySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Privacy & Data")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                Button("Privacy Settings") {
                    showingPrivacySettings = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Export Data") {
                    showingDataExport = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Clear All Data") {
                    aiReminderManager.clearAllData()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: AdvancedReminderInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
                
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(confidenceColor)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(insight.recommendation)
                .font(.caption)
                .foregroundColor(.blue)
                .italic()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private var iconName: String {
        switch insight.type {
        case .mostEffectiveTime: return "clock.fill"
        case .effectiveness: return "chart.line.uptrend.xyaxis"
        case .dataQuality: return "checkmark.circle.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .gap: return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch insight.type {
        case .mostEffectiveTime: return .green
        case .effectiveness: return .blue
        case .dataQuality: return .orange
        case .improvement: return .purple
        case .gap: return .red
        }
    }
    
    private var confidenceColor: Color {
        switch insight.confidence {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @ObservedObject var aiReminderManager: AIReminderManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Privacy Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose how much data the AI can collect to improve your reminder suggestions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ForEach(AIReminderManager.PrivacyMode.allCases, id: \.self) { mode in
                        PrivacyModeCard(
                            mode: mode,
                            isSelected: aiReminderManager.privacyMode == mode
                        ) {
                            aiReminderManager.updatePrivacyMode(mode)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy Mode Card
struct PrivacyModeCard: View {
    let mode: AIReminderManager.PrivacyMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    @ObservedObject var aiReminderManager: AIReminderManager
    @Environment(\.dismiss) private var dismiss
    @State private var exportData: Data?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Data Export")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Export your AI learning data for transparency")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let data = exportData {
                    VStack(spacing: 12) {
                        Text("Data exported successfully")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("Export Data") {
                        exportData = aiReminderManager.exportUserData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AIReminderSuggestionView(
        suggestion: AIReminderSuggestion(
            time: Date(),
            message: "Time to hydrate! 💧",
            confidence: 0.85,
            reason: "Based on your morning hydration patterns (high confidence)",
            adaptiveScore: 0.9,
            dataPoints: 15,
            lastActivity: Date()
        ),
        onAccept: {},
        onDecline: {}
    )
} 