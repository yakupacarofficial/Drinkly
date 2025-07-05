//
//  HeaderView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

/// Header view component showing title and location
struct HeaderView: View {
    
    // MARK: - Environment Objects
    @EnvironmentObject private var waterManager: WaterManager
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 8) {
            titleSection
            locationSection
            subtitleSection
        }
    }
    
    // MARK: - Private Views
    
    private var titleSection: some View {
        Text("Stay Hydrated!")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
            .accessibilityAddTraits(.isHeader)
    }
    
    private var locationSection: some View {
        Group {
            if !waterManager.userCity.isEmpty {
                locationDisplay
            } else {
                locationButton
            }
        }
    }
    
    private var locationDisplay: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.circle.fill")
                .foregroundColor(.blue)
                .accessibilityHidden(true)
            
            Text(waterManager.userCity)
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityLabel("Current location")
            
            refreshLocationButton
        }
    }
    
    private var locationButton: some View {
        Button(action: {
            locationManager.requestLocationPermission()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .accessibilityHidden(true)
                Text("Get City")
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .accessibilityLabel("Get current location")
    }
    
    private var refreshLocationButton: some View {
        Button(action: {
            locationManager.requestLocationPermission()
        }) {
            Image(systemName: "arrow.clockwise")
                .foregroundColor(.blue)
        }
        .accessibilityLabel("Refresh location")
    }
    
    private var subtitleSection: some View {
        Text("Your daily water companion")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
}

// MARK: - Preview
#Preview {
    HeaderView()
        .environmentObject(WaterManager())
        .environmentObject(LocationManager())
} 