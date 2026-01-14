//
//  HealthKitService.swift
//  WellnessCheck
//
//  Created: v0.3.0 (2026-01-13)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Service for fetching health data from HealthKit.
//  Handles authorization, step count, floors climbed, and other wellness metrics.
//
//  WHY THIS EXISTS:
//  WellnessCheck monitors user activity to detect potential emergencies.
//  Steps and floors climbed are key "proof of life" signals — if these
//  stop accumulating during normal waking hours, it may indicate a problem.
//

import Foundation
import HealthKit
import Combine

/// Service for accessing HealthKit data
/// Provides step count, floors climbed, and other wellness metrics
@MainActor
class HealthKitService: ObservableObject {

    // MARK: - Published Properties

    /// Today's step count
    @Published var todaySteps: Int = 0

    /// Today's floors climbed
    @Published var todayFloors: Int = 0

    /// Whether HealthKit authorization has been granted
    @Published var isAuthorized: Bool = false

    /// Whether HealthKit is available on this device
    @Published var isAvailable: Bool = false

    /// Last time data was refreshed
    @Published var lastUpdated: Date?

    /// Error message if something goes wrong
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// The HealthKit store instance
    private let healthStore: HKHealthStore?

    /// Data types we want to read from HealthKit
    private let typesToRead: Set<HKSampleType> = {
        var types = Set<HKSampleType>()

        // Step count — primary proof of life signal
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }

        // Flights climbed — secondary activity indicator
        if let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            types.insert(flightsType)
        }

        return types
    }()

    // MARK: - Initialization

    init() {
        // Check if HealthKit is available on this device
        // (Not available on iPad, some older devices, etc.)
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
            self.isAvailable = true
        } else {
            self.healthStore = nil
            self.isAvailable = false
        }
    }

    // MARK: - Public Methods

    /// Request authorization to read health data
    /// Call this during onboarding or when first accessing health features
    func requestAuthorization() async {
        guard let healthStore = healthStore else {
            errorMessage = "HealthKit is not available on this device"
            return
        }

        do {
            // Request read-only access to step count and flights climbed
            // We don't write any health data, only read
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)

            // Check if we actually got authorization
            // Note: HealthKit doesn't tell us directly if user denied access,
            // it just returns no data. We check by trying to query.
            await checkAuthorizationStatus()

        } catch {
            errorMessage = "Failed to request HealthKit authorization: \(error.localizedDescription)"
            isAuthorized = false
        }
    }

    /// Fetch today's health data (steps and floors)
    /// Call this to refresh the dashboard
    func fetchTodayData() async {
        guard healthStore != nil else {
            errorMessage = "HealthKit is not available"
            return
        }

        // Clear any previous error
        errorMessage = nil

        // Fetch steps and floors concurrently
        async let stepsResult = fetchTodaySteps()
        async let floorsResult = fetchTodayFloors()

        // Wait for both to complete
        todaySteps = await stepsResult
        todayFloors = await floorsResult
        lastUpdated = Date()
    }

    /// Fetch today's step count
    /// Returns 0 if no data available or not authorized
    func fetchTodaySteps() async -> Int {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }

        let predicate = createTodayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("HealthKit step query error: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                    return
                }

                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: steps)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch today's floors climbed
    /// Returns 0 if no data available or not authorized
    func fetchTodayFloors() async -> Int {
        guard let healthStore = healthStore,
              let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else {
            return 0
        }

        let predicate = createTodayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: flightsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("HealthKit flights query error: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                    return
                }

                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }

                let floors = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: floors)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Private Methods

    /// Check if we have authorization by attempting to query
    /// HealthKit doesn't expose authorization status directly for privacy reasons
    private func checkAuthorizationStatus() async {
        guard healthStore != nil,
              HKQuantityType.quantityType(forIdentifier: .stepCount) != nil else {
            isAuthorized = false
            return
        }

        // Note: For read-only access, authorizationStatus() always returns .notDetermined
        // or .sharingDenied — we have to try fetching data to know if we have read access.
        // Attempt to fetch data to verify we can read (results don't matter, just that it works)
        _ = await fetchTodaySteps()
        _ = await fetchTodayFloors()

        // For now, assume authorized if HealthKit didn't throw an error
        // The user may simply have 0 steps if they just woke up
        isAuthorized = true
    }

    /// Create a predicate for "today" — from midnight to now
    private func createTodayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        return HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
    }
}
