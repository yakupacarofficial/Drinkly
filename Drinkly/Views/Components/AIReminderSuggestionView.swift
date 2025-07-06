//
//  AIReminderSuggestionView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// AI-powered reminder suggestion card with accept/dismiss functionality
struct AIReminderSuggestionView: View {
    let suggestion: AIReminderSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main suggestion card
            VStack(spacing: 16) {
                // Header with AI icon and confidence
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Suggestion")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Confidence: \(Int(suggestion.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Confidence indicator
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: suggestion.confidence)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: suggestion.confidence)
                        
                        Text("\(Int(suggestion.confidence * 100))")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
                // Time and message
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        
                        Text(suggestion.formattedTime)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Text(suggestion.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Reason (expandable)
                VStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetails.toggle()
                        }
                    }) {
                        HStack {
                            Text("Why this time?")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                    
                    if showDetails {
                        Text(suggestion.reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    // Dismiss button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onDismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .font(.caption)
                            
                            Text("Dismiss")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Accept button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onAccept()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.caption)
                            
                            Text("Accept")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

/// AI Reminder Suggestions List View
struct AIReminderSuggestionsView: View {
    @ObservedObject var aiReminderManager: AIReminderManager
    @State private var showingSuggestion = false
    
    var body: some View {
        VStack(spacing: 16) {
            if aiReminderManager.isAnalyzing {
                // Loading state
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("AI is analyzing your patterns...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: aiReminderManager.learningProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 4)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            } else if !aiReminderManager.suggestedReminders.isEmpty {
                // Suggestions list
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text("AI Suggestions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(aiReminderManager.suggestedReminders.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    ForEach(aiReminderManager.suggestedReminders) { suggestion in
                        AIReminderSuggestionView(
                            suggestion: suggestion,
                            onAccept: {
                                Task {
                                    await aiReminderManager.acceptSuggestion(suggestion)
                                }
                            },
                            onDismiss: {
                                Task {
                                    await aiReminderManager.dismissSuggestion(suggestion)
                                }
                            }
                        )
                    }
                }
            } else {
                // No suggestions state
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(.blue.opacity(0.6))
                    
                    Text("No AI suggestions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("AI will learn from your reminder interactions and suggest optimal times")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
}

/// AI Reminder Insights View
struct AIReminderInsightsView: View {
    @ObservedObject var aiReminderManager: AIReminderManager
    @State private var insights: ReminderInsights?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                
                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    insights = aiReminderManager.getReminderInsights()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let insights = insights {
                VStack(spacing: 12) {
                    // Overall stats
                    HStack(spacing: 16) {
                        InsightCard(
                            title: "Acceptance Rate",
                            value: "\(Int(insights.acceptanceRate * 100))%",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        InsightCard(
                            title: "Total Reminders",
                            value: "\(insights.totalReminders)",
                            icon: "bell.fill",
                            color: .blue
                        )
                    }
                    
                    // Optimal times
                    if !insights.optimalTimes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Optimal Times")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(insights.optimalTimes, id: \.self) { time in
                                    Text(time)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Suggestions
                    if !insights.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Recommendations")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(insights.suggestions, id: \.title) { insight in
                                InsightRow(insight: insight)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title)
                        .foregroundColor(.blue.opacity(0.6))
                    
                    Text("No insights available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Interact with reminders to generate AI insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .onAppear {
            insights = aiReminderManager.getReminderInsights()
        }
    }
}

// MARK: - Supporting Views

struct InsightCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct InsightRow: View {
    let insight: ReminderInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(insight.confidence * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        AIReminderSuggestionView(
            suggestion: AIReminderSuggestion(
                time: Date(),
                message: "Time to hydrate! 💧",
                confidence: 0.85,
                reason: "Based on your morning hydration patterns"
            ),
            onAccept: {},
            onDismiss: {}
        )
        
        AIReminderSuggestionsView(aiReminderManager: AIReminderManager())
        
        AIReminderInsightsView(aiReminderManager: AIReminderManager())
    }
    .padding()
} 