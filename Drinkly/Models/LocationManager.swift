//
//  LocationManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import CoreLocation
import SwiftUI

/// Manages location services and city information
@MainActor
class LocationManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    
    // MARK: - Published Properties
    @Published var location: CLLocation?
    @Published var city: String = ""
    @Published var isAuthorized: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let cityKey = Constants.UserDefaultsKeys.userCity
    
    // Performance optimizations
    private var geocoder: CLGeocoder?
    private var lastLocationUpdate: Date?
    private var locationCache: [String: CLLocation] = [:]
    private var geocodingTask: Task<Void, Never>?
    
    // Constants for performance
    private let locationUpdateInterval: TimeInterval = 300 // 5 minutes
    private let geocodingTimeout: TimeInterval = 10.0
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        loadSavedCity()
    }
    
    deinit {
        geocodingTask?.cancel()
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Public Methods
    
    /// Requests location permission and starts location updates
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            handleLocationDenied()
        @unknown default:
            break
        }
    }
    
    /// Starts location updates with performance optimization
    func startLocationUpdates() {
        guard isAuthorized else {
            errorMessage = "Location permission not granted"
            return
        }
        
        // Check if we need to update location
        if let lastUpdate = lastLocationUpdate,
           Date().timeIntervalSince(lastUpdate) < locationUpdateInterval {
            // Use cached location if recent
            return
        }
        
        locationManager.startUpdatingLocation()
        isLoading = true
        errorMessage = nil
    }
    
    /// Loads saved city from UserDefaults
    func loadSavedCity() {
        if let savedCity = userDefaults.string(forKey: cityKey) {
            self.city = savedCity
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000 // 1km filter for performance
    }
    
    private func handleLocationDenied() {
        isAuthorized = false
        errorMessage = "Location access denied. Please enable in Settings."
    }
    
    private func saveCity(_ city: String) {
        self.city = city
        userDefaults.set(city, forKey: cityKey)
    }
    
    private func performGeocoding(for location: CLLocation) {
        // Cancel any existing geocoding task
        geocodingTask?.cancel()
        
        geocodingTask = Task {
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                
                await MainActor.run {
                    if let city = placemarks.first?.locality {
                        self.saveCity(city)
                        self.isLoading = false
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = "Could not determine city name"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to get city: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Cache the location
        let locationKey = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        locationCache[locationKey] = location
        
        self.location = location
        lastLocationUpdate = Date()
        
        // Stop location updates to save battery
        locationManager.stopUpdatingLocation()
        
        // Perform geocoding asynchronously
        performGeocoding(for: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLoading = false
            
            // Provide more specific error messages
            switch (error as? CLError)?.code {
            case .denied:
                errorMessage = "Location access denied. Please enable in Settings."
            case .locationUnknown:
                errorMessage = "Unable to determine location. Please try again."
            case .network:
                errorMessage = "Network error. Please check your connection."
            default:
                errorMessage = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
            
            if isAuthorized {
                startLocationUpdates()
            } else if status == .denied || status == .restricted {
                handleLocationDenied()
            }
        }
    }
} 