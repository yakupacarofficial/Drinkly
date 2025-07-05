//
//  WeatherManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - OpenWeatherMap API Response Models

struct WeatherResponse: Codable {
    let main: MainWeather
    let name: String
    let weather: [WeatherDescription]
    let cod: Int
    
    struct MainWeather: Codable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
        let pressure: Int
    }
    
    struct WeatherDescription: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
}

struct WeatherAPIError: Codable {
    let cod: String
    let message: String
}

// MARK: - Weather Manager

@MainActor
class WeatherManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentTemperature: Double = 22.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var lastUpdated: Date?
    @Published var cityName: String = ""
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let session = URLSession.shared
    private var lastFetchTime: Date?
    private var fetchTask: Task<Void, Never>?
    
    // Cache keys
    private let temperatureCacheKey = "drinkly_cached_temperature"
    private let cityCacheKey = "drinkly_cached_city"
    private let lastFetchCacheKey = "drinkly_last_fetch_time"
    
    // MARK: - Initialization
    
    init() {
        loadCachedData()
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Fetches current weather data for a specific city
    /// - Parameter city: City name to fetch weather for
    func fetchWeather(for city: String) {
        guard !city.isEmpty else {
            errorMessage = "City name cannot be empty"
            return
        }
        
        // Check if we need to fetch new data
        if shouldUseCachedData() {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        fetchTask?.cancel()
        fetchTask = Task {
            await fetchWeatherData(for: city)
        }
    }
    
    /// Fetches current weather data using GPS coordinates
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    func fetchWeather(latitude: Double, longitude: Double) {
        // Check if we need to fetch new data
        if shouldUseCachedData() {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        fetchTask?.cancel()
        fetchTask = Task {
            await fetchWeatherData(latitude: latitude, longitude: longitude)
        }
    }
    
    /// Manually sets temperature (for testing or user override)
    /// - Parameter temperature: Temperature in Celsius
    func setTemperature(_ temperature: Double) {
        currentTemperature = temperature
        saveCachedData()
    }
    
    /// Loads cached weather data
    func loadCachedData() {
        currentTemperature = userDefaults.double(forKey: temperatureCacheKey)
        cityName = userDefaults.string(forKey: cityCacheKey) ?? ""
        
        if currentTemperature == 0.0 {
            currentTemperature = 22.0 // Default temperature
        }
        
        if let lastFetch = userDefaults.object(forKey: lastFetchCacheKey) as? Date {
            lastFetchTime = lastFetch
            lastUpdated = lastFetch
        }
    }
    
    /// Refreshes weather data regardless of cache
    func refreshWeather() {
        lastFetchTime = nil
        if !cityName.isEmpty {
            fetchWeather(for: cityName)
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldUseCachedData() -> Bool {
        guard let lastFetch = lastFetchTime else { return false }
        
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        return timeSinceLastFetch < Constants.WeatherAPI.cacheTimeout
    }
    
    private func fetchWeatherData(for city: String) async {
        do {
            let url = buildWeatherURL(for: city)
            let (data, response) = try await session.data(from: url)
            
            await handleWeatherResponse(data: data, response: response, city: city)
            
        } catch {
            await handleWeatherError(error)
        }
    }
    
    private func fetchWeatherData(latitude: Double, longitude: Double) async {
        do {
            let url = buildWeatherURL(latitude: latitude, longitude: longitude)
            let (data, response) = try await session.data(from: url)
            
            await handleWeatherResponse(data: data, response: response)
            
        } catch {
            await handleWeatherError(error)
        }
    }
    
    private func buildWeatherURL(for city: String) -> URL {
        var components = URLComponents(string: "\(Constants.WeatherAPI.baseURL)/weather")!
        components.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: Constants.WeatherAPI.apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "en")
        ]
        return components.url!
    }
    
    private func buildWeatherURL(latitude: Double, longitude: Double) -> URL {
        var components = URLComponents(string: "\(Constants.WeatherAPI.baseURL)/weather")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: Constants.WeatherAPI.apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "en")
        ]
        return components.url!
    }
    
    private func handleWeatherResponse(data: Data, response: URLResponse, city: String? = nil) async {
        guard let httpResponse = response as? HTTPURLResponse else {
            await handleWeatherError(WeatherError.invalidResponse)
            return
        }
        
        if httpResponse.statusCode == 200 {
            do {
                let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                
                await MainActor.run {
                    self.currentTemperature = weatherResponse.main.temp
                    self.cityName = weatherResponse.name
                    self.lastUpdated = Date()
                    self.lastFetchTime = Date()
                    self.isLoading = false
                    self.errorMessage = ""
                    
                    self.saveCachedData()
                }
                
            } catch {
                await handleWeatherError(WeatherError.decodingError(error))
            }
        } else {
            // Try to decode error response
            do {
                let errorResponse = try JSONDecoder().decode(WeatherAPIError.self, from: data)
                await handleWeatherError(WeatherError.apiError(errorResponse.message))
            } catch {
                await handleWeatherError(WeatherError.httpError(httpResponse.statusCode))
            }
        }
    }
    
    private func handleWeatherError(_ error: Error) async {
        await MainActor.run {
            self.isLoading = false
            
            switch error {
            case let weatherError as WeatherError:
                switch weatherError {
                case .networkError:
                    self.errorMessage = Constants.Messages.networkError
                case .apiError(let message):
                    self.errorMessage = "Weather API error: \(message)"
                case .decodingError:
                    self.errorMessage = "Failed to parse weather data"
                case .invalidResponse:
                    self.errorMessage = "Invalid response from weather service"
                case .httpError(let code):
                    self.errorMessage = "Weather service error (HTTP \(code))"
                }
            default:
                self.errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
            }
        }
    }
    
    private func saveCachedData() {
        userDefaults.set(currentTemperature, forKey: temperatureCacheKey)
        userDefaults.set(cityName, forKey: cityCacheKey)
        userDefaults.set(lastFetchTime, forKey: lastFetchCacheKey)
    }
}

// MARK: - Weather Error Types

enum WeatherError: Error, LocalizedError {
    case networkError
    case apiError(String)
    case decodingError(Error)
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error"
        case .apiError(let message):
            return "API Error: \(message)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        }
    }
} 