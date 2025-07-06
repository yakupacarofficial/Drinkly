//
//  WeatherDisplayView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI

struct WeatherDisplayView: View {
    @EnvironmentObject var weatherManager: WeatherManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "thermometer")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text("\(Int(weatherManager.currentTemperature))°C")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if weatherManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if !weatherManager.cityName.isEmpty {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                    
                    Text(weatherManager.cityName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            if !weatherManager.errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    
                    Text(weatherManager.errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .lineLimit(2)
                    
                    Spacer()
                }
            }
            
            // Hot weather warning
            if weatherManager.currentTemperature > 30 {
                HStack {
                    Image(systemName: "thermometer.sun.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    
                    Text("It's very hot! Stay hydrated!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(2)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            // Fetch weather data if we have location
            if locationManager.isAuthorized && locationManager.location != nil {
                weatherManager.fetchWeather(
                    latitude: locationManager.location!.coordinate.latitude,
                    longitude: locationManager.location!.coordinate.longitude
                )
            } else if !locationManager.city.isEmpty {
                weatherManager.fetchWeather(for: locationManager.city)
            }
        }
    }
}

#Preview {
    WeatherDisplayView()
        .environmentObject(WeatherManager())
        .environmentObject(LocationManager())
} 