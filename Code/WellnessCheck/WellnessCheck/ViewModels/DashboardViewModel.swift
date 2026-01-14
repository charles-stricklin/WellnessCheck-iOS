//
//  DashboardViewModel.swift
//  WellnessCheck
//
//  Created: v0.3.0 (2026-01-13)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  ViewModel for the main dashboard.
//  Coordinates data from HealthKit, Care Circle, and app state.
//
//  WHY THIS EXISTS:
//  The dashboard needs data from multiple sources (HealthKit, stored members,
//  user preferences). This ViewModel centralizes that logic so the View
//  stays clean and focused on presentation.
//

import Foundation
import Combine

/// ViewModel for the main dashboard, coordinating health data and Care Circle info
@MainActor
class DashboardViewModel: ObservableObject {

    // MARK: - Published Properties (Activity Data)

    /// Today's step count from HealthKit
    @Published var steps: Int = 0

    /// Today's floors climbed from HealthKit
    @Published var floors: Int = 0

    /// Phone pickups today (estimated via motion detection)
    /// NOTE: This is a proxy metric until Family Controls entitlement is approved.
    /// Once approved, we'll switch to the DeviceActivity framework for real data.
    @Published var phonePickups: Int = 0

    // MARK: - Published Properties (Status)

    /// Whether the user's status is "all good" (no alerts needed)
    @Published var isAllGood: Bool = true

    /// Human-readable description of last detected activity
    @Published var lastActivityDescription: String = "Just now"

    /// Current day of the 14-day learning period (1-14, or nil if complete)
    @Published var learningDay: Int? = nil

    /// Whether data is currently being refreshed
    @Published var isLoading: Bool = false

    /// Error message to display, if any
    @Published var errorMessage: String?

    // MARK: - Services

    /// HealthKit service for fetching activity data
    private let healthKitService: HealthKitService

    /// Phone activity service for estimating pickups via motion detection
    private let phoneActivityService: PhoneActivityService

    /// Care Circle view model for accessing stored members
    /// We observe this to react to changes in the Care Circle
    let careCircleViewModel: CareCircleViewModel

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    /// Date when the app was first launched (for learning period calculation)
    private let firstLaunchDateKey = "firstLaunchDate"

    // MARK: - Initialization

    init(healthKitService: HealthKitService? = nil,
         phoneActivityService: PhoneActivityService? = nil,
         careCircleViewModel: CareCircleViewModel? = nil) {
        // Create services here (inside @MainActor context) if not injected
        // This avoids Swift 6 concurrency error with default parameter expressions
        // since default parameters are evaluated in a nonisolated context
        self.healthKitService = healthKitService ?? HealthKitService()
        self.phoneActivityService = phoneActivityService ?? PhoneActivityService()
        self.careCircleViewModel = careCircleViewModel ?? CareCircleViewModel()

        // Calculate learning day based on first launch
        calculateLearningDay()

        // Set up bindings to services
        setupBindings()

        // Start phone activity tracking
        self.phoneActivityService.startTracking()
    }

    // MARK: - Public Methods

    /// Refresh all dashboard data
    /// Call this on appear and via pull-to-refresh
    func refreshData() async {
        isLoading = true
        errorMessage = nil

        // Fetch HealthKit data
        await healthKitService.fetchTodayData()

        // Update last activity description based on current data
        updateLastActivityDescription()

        isLoading = false
    }

    /// Request HealthKit authorization if not already granted
    /// Call this when user first accesses the dashboard
    func requestHealthKitAuthorizationIfNeeded() async {
        if !healthKitService.isAuthorized && healthKitService.isAvailable {
            await healthKitService.requestAuthorization()
        }
    }

    /// Record a phone pickup event
    /// Call this when the app comes to foreground as an additional signal
    func recordPhonePickup() {
        phoneActivityService.recordPickup()
    }

    // MARK: - Private Methods

    /// Set up Combine bindings to receive updates from services
    private func setupBindings() {
        // Bind HealthKit steps to our published property
        healthKitService.$todaySteps
            .receive(on: DispatchQueue.main)
            .assign(to: &$steps)

        // Bind HealthKit floors to our published property
        healthKitService.$todayFloors
            .receive(on: DispatchQueue.main)
            .assign(to: &$floors)

        // Bind phone activity pickups to our published property
        phoneActivityService.$estimatedPickups
            .receive(on: DispatchQueue.main)
            .assign(to: &$phonePickups)

        // Propagate any errors from HealthKit
        healthKitService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }

    /// Calculate which day of the 14-day learning period we're on
    /// Returns nil if learning period is complete
    private func calculateLearningDay() {
        let userDefaults = UserDefaults.standard

        // Get or set the first launch date
        let firstLaunchDate: Date
        if let storedDate = userDefaults.object(forKey: firstLaunchDateKey) as? Date {
            firstLaunchDate = storedDate
        } else {
            // First time launching — record today as day 1
            firstLaunchDate = Date()
            userDefaults.set(firstLaunchDate, forKey: firstLaunchDateKey)
        }

        // Calculate days since first launch
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: firstLaunchDate, to: Date())
        let daysSinceFirstLaunch = (components.day ?? 0) + 1 // +1 because day 1 is launch day

        // If within learning period (14 days), show the day number
        // Otherwise, learning is complete
        if daysSinceFirstLaunch <= 14 {
            learningDay = daysSinceFirstLaunch
        } else {
            learningDay = nil
        }
    }

    /// Update the "last activity" description based on current data
    /// This gives users context about when the app last detected movement
    private func updateLastActivityDescription() {
        // For now, base this on whether we have step data
        // In the future, this should track actual movement events
        if steps > 0 {
            // If we have steps today, activity was recent
            // TODO: Track actual timestamps of health samples for more accuracy
            lastActivityDescription = "Active today"
        } else {
            // No steps yet — might be early morning or no movement
            let hour = Calendar.current.component(.hour, from: Date())
            if hour < 8 {
                lastActivityDescription = "Good morning"
            } else {
                lastActivityDescription = "No activity yet"
            }
        }
    }
}
