//
//  LocationService.swift
//  WellnessCheck
//
//  Created: v0.2.0 (2026-01-10)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Handles location permissions, GPS retrieval, and reverse geocoding for
//  home location setup. Uses CoreLocation for all location operations.
//

import Foundation
import CoreLocation

/// Represents a home location with coordinates and optional address info
struct HomeLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let address: String?          // Human-readable address for display
    let radius: Double            // Geofence radius in meters (default 100m)
    let capturedAt: Date          // When this location was captured

    /// Default geofence radius for "at home" detection (100 meters)
    static let defaultRadius: Double = 100.0

    /// Creates a HomeLocation from CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D, address: String? = nil, radius: Double = defaultRadius) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.radius = radius
        self.capturedAt = Date()
    }

    /// Converts back to CLLocationCoordinate2D for MapKit/CoreLocation use
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Result of a location fetch attempt
enum LocationResult {
    case success(location: CLLocation, address: String?)
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case error(String)
}

/// Service that handles all location-related operations for WellnessCheck.
/// Uses async/await patterns consistent with the rest of the codebase.
@MainActor
class LocationService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = LocationService()

    // MARK: - Published Properties

    /// Current authorization status for location services
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Whether we're currently fetching location
    @Published var isFetchingLocation: Bool = false

    /// The most recently fetched location (if any)
    @Published var currentLocation: CLLocation?

    /// Human-readable address of current location (if reverse geocoded)
    @Published var currentAddress: String?

    /// Error message if something went wrong
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    /// Continuation for async location requests
    private var locationContinuation: CheckedContinuation<LocationResult, Never>?

    // MARK: - Initialization

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Checks if location services are available and authorized
    var isLocationAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    /// Checks if we can request location permission (not yet determined)
    var canRequestPermission: Bool {
        authorizationStatus == .notDetermined
    }

    /// Requests location permission from the user.
    /// Returns true if permission was granted, false otherwise.
    func requestLocationPermission() async -> Bool {
        // If already authorized, return true immediately
        if isLocationAuthorized {
            return true
        }

        // If permission was already denied/restricted, return false
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            return false
        }

        // Request permission and wait for delegate callback
        return await withCheckedContinuation { continuation in
            // Store continuation to resume when delegate fires
            Task { @MainActor in
                // Request "when in use" permission - sufficient for our needs
                // and less intrusive than "always"
                locationManager.requestWhenInUseAuthorization()

                // Wait a moment for the authorization status to update
                // The delegate will update authorizationStatus
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                continuation.resume(returning: isLocationAuthorized)
            }
        }
    }

    /// Fetches the current GPS location and reverse geocodes it to an address.
    /// This is the main method used during onboarding.
    func fetchCurrentLocation() async -> LocationResult {
        // Clear previous state
        errorMessage = nil
        currentLocation = nil
        currentAddress = nil

        // Check authorization
        guard isLocationAuthorized else {
            if authorizationStatus == .denied {
                return .permissionDenied
            } else if authorizationStatus == .restricted {
                return .permissionRestricted
            } else {
                // Not yet determined - request permission first
                let granted = await requestLocationPermission()
                if !granted {
                    return .permissionDenied
                }
            }
        }

        // Check if location services are enabled system-wide
        guard CLLocationManager.locationServicesEnabled() else {
            return .locationUnavailable
        }

        isFetchingLocation = true

        // Use async continuation to wrap the delegate-based location request
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<LocationResult, Never>) in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }

        isFetchingLocation = false

        return result
    }

    /// Reverse geocodes a location to get a human-readable address
    func reverseGeocode(location: CLLocation) async -> String? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            guard let placemark = placemarks.first else {
                return nil
            }

            // Build a readable address string
            var addressParts: [String] = []

            if let streetNumber = placemark.subThoroughfare,
               let streetName = placemark.thoroughfare {
                addressParts.append("\(streetNumber) \(streetName)")
            } else if let streetName = placemark.thoroughfare {
                addressParts.append(streetName)
            }

            if let city = placemark.locality {
                addressParts.append(city)
            }

            if let state = placemark.administrativeArea {
                addressParts.append(state)
            }

            return addressParts.isEmpty ? nil : addressParts.joined(separator: ", ")

        } catch {
            // Geocoding failed - not critical, we can proceed without address
            print("Reverse geocoding failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Creates a HomeLocation from the current location
    func createHomeLocation() -> HomeLocation? {
        guard let location = currentLocation else { return nil }

        return HomeLocation(
            coordinate: location.coordinate,
            address: currentAddress,
            radius: HomeLocation.defaultRadius
        )
    }

    /// Saves home location to UserDefaults
    func saveHomeLocation(_ homeLocation: HomeLocation) {
        if let encoded = try? JSONEncoder().encode(homeLocation) {
            UserDefaults.standard.set(encoded, forKey: Constants.homeLocationKey)
        }
    }

    /// Loads saved home location from UserDefaults
    func loadHomeLocation() -> HomeLocation? {
        guard let data = UserDefaults.standard.data(forKey: Constants.homeLocationKey),
              let homeLocation = try? JSONDecoder().decode(HomeLocation.self, from: data) else {
            return nil
        }
        return homeLocation
    }

    /// Checks if a given location is within the home geofence
    func isAtHome(location: CLLocation) -> Bool {
        guard let home = loadHomeLocation() else { return false }

        let homeLocation = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let distance = location.distance(from: homeLocation)

        return distance <= home.radius
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Task { @MainActor in
                locationContinuation?.resume(returning: .locationUnavailable)
                locationContinuation = nil
            }
            return
        }

        Task { @MainActor in
            self.currentLocation = location

            // Reverse geocode to get address
            let address = await reverseGeocode(location: location)
            self.currentAddress = address

            // Resume the continuation with success
            locationContinuation?.resume(returning: .success(location: location, address: address))
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            let clError = error as? CLError

            if clError?.code == .denied {
                locationContinuation?.resume(returning: .permissionDenied)
            } else if clError?.code == .locationUnknown {
                locationContinuation?.resume(returning: .locationUnavailable)
            } else {
                errorMessage = error.localizedDescription
                locationContinuation?.resume(returning: .error(error.localizedDescription))
            }

            locationContinuation = nil
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}
