//
//  CelebrationView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Celebration view shown when daily goal is reached
struct CelebrationView: View {
    
    // MARK: - Properties
    @Binding var isShowing: Bool
    @State private var animationScale: CGFloat = 0.1
    @State private var animationOpacity: Double = 0
    @State private var confettiOffset: CGFloat = -100
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCelebration()
                }
            
            // Celebration content
            VStack(spacing: 24) {
                celebrationIcon
                celebrationText
                actionButtons
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(animationScale)
            .opacity(animationOpacity)
            .offset(y: confettiOffset)
            .onAppear {
                startCelebrationAnimation()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Goal reached celebration")
        .accessibilityAddTraits(.isModal)
    }
    
    // MARK: - Private Views
    
    private var celebrationIcon: some View {
        ZStack {
            // Animated circles
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                    .scaleEffect(animationScale)
                    .opacity(animationOpacity)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: animationScale)
            }
            
            // Main icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .scaleEffect(animationScale)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animationScale)
        }
    }
    
    private var celebrationText: some View {
        VStack(spacing: 12) {
            Text("🎉 Congratulations! 🎉")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
            
            Text("You've reached your daily water goal!")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Keep up the great work staying hydrated!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                dismissCelebration()
            }) {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            
            Button(action: {
                dismissCelebration()
            }) {
                Text("Share Achievement")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startCelebrationAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            animationScale = 1.0
            animationOpacity = 1.0
            confettiOffset = 0
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationScale = 0.1
            animationOpacity = 0
            confettiOffset = 100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// MARK: - Preview
#Preview {
    CelebrationView(isShowing: .constant(true))
} 