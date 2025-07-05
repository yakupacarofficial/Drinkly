//
//  WeatherManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI

class WeatherManager: ObservableObject {
    @Published var currentTemperature: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    // API kullanmadan sabit sıcaklık değeri (test için)
    // Gerçek uygulamada bu değer kullanıcı tarafından ayarlanabilir
    private let defaultTemperature: Double = 22.0
    
    func fetchWeather(for city: String) {
        guard !city.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        // API kullanmadan sabit sıcaklık değeri
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.currentTemperature = self.defaultTemperature
            UserDefaults.standard.set(self.defaultTemperature, forKey: "drinkly_last_temperature")
        }
    }
    
    func loadLastTemperature() {
        currentTemperature = UserDefaults.standard.double(forKey: "drinkly_last_temperature")
        if currentTemperature == 0.0 {
            currentTemperature = defaultTemperature
        }
    }
    
    // Kullanıcının manuel olarak sıcaklık ayarlayabilmesi için
    func setTemperature(_ temperature: Double) {
        currentTemperature = temperature
        UserDefaults.standard.set(temperature, forKey: "drinkly_last_temperature")
    }
} 