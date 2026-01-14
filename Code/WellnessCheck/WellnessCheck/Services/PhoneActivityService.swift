//
//  PhoneActivityService.swift
//  WellnessCheck
//
//  Created: v0.3.0 (2026-01-13)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Service for tracking phone pickup activity using CoreMotion as a proxy.
//
//  WHY THIS EXISTS:
//  The real Screen Time API (DeviceActivity framework) requires Apple's
//  Family Controls entitlement, which needs approval. While we wait for that,
//  this service uses accelerometer data to approximate phone pickups by
//  detecting when the device transitions from stationary to active motion.
//
//  HOW IT WORKS:
//  - Monitors accelerometer for motion patterns
//  - Detects "pickup" when device goes from still to moving
//  - Requires the device to be stationary for a threshold period before
//    counting a new pickup (prevents counting continuous handling as multiple pickups)
//  - Resets count at midnight each day
//
//  LIMITATIONS:
//  - This is an approximation, not actual screen unlock data
//  - May undercount (if phone is in pocket during pickup) or overcount
//    (if phone is bumped on a table)
//  - Will be replaced with Screen Time API once entitlement is approved
//

import Foundation
import CoreMotion
import Combine

/// Service that approximates phone pickups using accelerometer data
@MainActor
class PhoneActivityService: ObservableObject {

    // MARK: - Published Properties

    /// Estimated phone pickups today (proxy metric)
    @Published var estimatedPickups: Int = 0

    /// Whether motion tracking is active
    @Published var isTracking: Bool = false

    /// Error message if motion tracking fails
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// CoreMotion manager for accelerometer access
    private let motionManager = CMMotionManager()

    /// Pedometer for step-based activity detection (more battery efficient)
    private let pedometer = CMPedometer()

    /// Motion activity manager for detecting device state changes
    private let activityManager = CMMotionActivityManager()

    /// UserDefaults for persisting daily count
    private let userDefaults = UserDefaults.standard

    /// Key for storing today's pickup count
    private let pickupCountKey = "estimatedPhonePickups"

    /// Key for storing the date of the last count
    private let pickupDateKey = "phonePickupDate"

    /// Minimum seconds device must be stationary before a new pickup counts
    /// Prevents counting continuous handling as multiple pickups
    private let stationaryThreshold: TimeInterval = 30

    /// Tracks when device was last detected as stationary
    private var lastStationaryTime: Date?

    /// Whether device is currently considered stationary
    private var isStationary: Bool = true

    /// Timer for periodic activity checks
    private var activityCheckTimer: Timer?

    // MARK: - Initialization

    init() {
        loadTodayCount()
    }

    // NOTE: No deinit needed — CMMotionActivityManager stops automatically when deallocated,
    // and Timer is invalidated when its reference is released.

    // MARK: - Public Methods

    /// Start tracking phone activity
    /// Call this when the app becomes active
    func startTracking() {
        // Check if motion activity is available
        guard CMMotionActivityManager.isActivityAvailable() else {
            errorMessage = "Motion activity not available on this device"
            return
        }

        // Reset count if it's a new day
        checkForNewDay()

        isTracking = true
        errorMessage = nil

        // Start monitoring motion activity changes
        // This is more battery-efficient than raw accelerometer polling
        startActivityMonitoring()
    }

    /// Stop tracking phone activity
    /// Call this when the app goes to background
    func stopTracking() {
        activityManager.stopActivityUpdates()
        activityCheckTimer?.invalidate()
        activityCheckTimer = nil
        isTracking = false
    }

    /// Manually increment pickup count
    /// Useful for detecting app foreground events as a proxy signal
    func recordPickup() {
        // Only count if device was stationary long enough
        if let lastStationary = lastStationaryTime,
           Date().timeIntervalSince(lastStationary) >= stationaryThreshold {
            incrementCount()
        } else if lastStationaryTime == nil {
            // First pickup of the session
            incrementCount()
        }

        // Reset stationary tracking
        isStationary = false
        lastStationaryTime = nil
    }

    /// Mark device as stationary
    /// Called when motion activity indicates device is still
    func markStationary() {
        if !isStationary {
            isStationary = true
            lastStationaryTime = Date()
        }
    }

    // MARK: - Private Methods

    /// Start monitoring motion activity for state changes
    private func startActivityMonitoring() {
        // Use motion activity manager to detect stationary vs moving
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }

            Task { @MainActor in
                if activity.stationary {
                    // Device is stationary — mark the time
                    self.markStationary()
                } else if activity.walking || activity.running || activity.automotive {
                    // Device is in motion — this could be a pickup
                    if self.isStationary {
                        self.recordPickup()
                    }
                }
            }
        }
    }

    /// Load today's pickup count from storage
    private func loadTodayCount() {
        checkForNewDay()
        estimatedPickups = userDefaults.integer(forKey: pickupCountKey)
    }

    /// Check if it's a new day and reset count if needed
    private func checkForNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let storedDate = userDefaults.object(forKey: pickupDateKey) as? Date {
            let storedDay = calendar.startOfDay(for: storedDate)

            if today > storedDay {
                // New day — reset count
                userDefaults.set(0, forKey: pickupCountKey)
                userDefaults.set(today, forKey: pickupDateKey)
                estimatedPickups = 0
            }
        } else {
            // First run — initialize date
            userDefaults.set(today, forKey: pickupDateKey)
        }
    }

    /// Increment and persist the pickup count
    private func incrementCount() {
        estimatedPickups += 1
        userDefaults.set(estimatedPickups, forKey: pickupCountKey)
    }
}
