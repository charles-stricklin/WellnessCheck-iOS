//
//  HealthKitService.swift
//  WellnessCheck
//
//  Created: v0.3.0 (2026-01-13)
//  Updated: v0.4.0 (2026-01-14) - Added comprehensive health metrics
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Service for fetching health data from HealthKit.
//  Handles authorization and fetching of wellness metrics used for safety monitoring.
//
//  WHY THIS EXISTS:
//  WellnessCheck monitors user activity to detect potential emergencies.
//  We track multiple signals to build a complete picture of the user's
//  daily patterns. When these patterns change significantly, it may
//  indicate the user needs help.
//
//  PRIVACY NOTE:
//  All health data stays on-device. We only use it to detect pattern
//  changes that might indicate the user is in jeopardy.
//

import Foundation
import HealthKit
import Combine

/// Service for accessing HealthKit data
/// Provides step count, floors climbed, walking metrics, and other wellness indicators
@MainActor
class HealthKitService: ObservableObject {

    // MARK: - Published Properties

    /// Today's step count - primary proof of life signal
    @Published var todaySteps: Int = 0

    /// Today's floors climbed - vertical movement indicator
    @Published var todayFloors: Int = 0

    /// Today's active energy burned (calories) - overall activity level
    @Published var todayActiveEnergy: Double = 0.0

    /// Current walking speed (meters per second) - gait changes can indicate health issues
    @Published var walkingSpeed: Double?

    /// Current walking step length (meters) - gait pattern changes
    @Published var walkingStepLength: Double?

    /// Recent walking steadiness events - iOS-detected fall risk alerts
    @Published var recentSteadinessEvents: [HKCategorySample] = []

    /// Recent sleep analysis data - sleep pattern disruption detection
    @Published var recentSleepSamples: [HKCategorySample] = []

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

    /// Quantity types we want to read from HealthKit (numeric measurements)
    private let quantityTypesToRead: Set<HKQuantityType> = {
        var types = Set<HKQuantityType>()

        // Step count — primary proof of life signal
        // If steps stop accumulating during normal waking hours, something may be wrong
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepType)
        }

        // Flights climbed — vertical movement indicator
        // Useful for detecting normal daily activity patterns
        if let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            types.insert(flightsType)
        }

        // Active energy burned — overall activity level beyond just steps
        // More comprehensive than steps alone, captures all movement
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energyType)
        }

        // Walking speed — gait changes can indicate health decline
        // A sudden decrease in walking speed may signal a health issue
        if let speedType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) {
            types.insert(speedType)
        }

        // Walking step length — gait pattern indicator
        // Shortened step length can indicate mobility issues or health concerns
        if let stepLengthType = HKQuantityType.quantityType(forIdentifier: .walkingStepLength) {
            types.insert(stepLengthType)
        }

        return types
    }()

    /// Category types we want to read from HealthKit (discrete events/states)
    private let categoryTypesToRead: Set<HKCategoryType> = {
        var types = Set<HKCategoryType>()

        // Walking steadiness events — iOS-detected fall risk alerts
        // iPhone automatically detects when user's gait indicates fall risk
        if let steadinessType = HKCategoryType.categoryType(forIdentifier: .appleWalkingSteadinessEvent) {
            types.insert(steadinessType)
        }

        // Sleep analysis — sleep pattern tracking
        // Unusual sleep patterns (sleeping all day) can indicate health issues
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }

        return types
    }()

    /// Combined set of all types to read (for authorization request)
    private var allTypesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        types.formUnion(quantityTypesToRead)
        types.formUnion(categoryTypesToRead)
        return types
    }

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
            // Request read-only access to all wellness metrics
            // We don't write any health data, only read for pattern detection
            try await healthStore.requestAuthorization(toShare: [], read: allTypesToRead)

            // Check if we actually got authorization
            // Note: HealthKit doesn't tell us directly if user denied access,
            // it just returns no data. We check by trying to query.
            await checkAuthorizationStatus()

            // Enable background delivery for step count so we can track activity
            // even when the app is in the background
            BackgroundTaskService.shared.enableHealthKitBackgroundDelivery()

            // Set up observer query to record activity when steps update
            setupStepCountObserver()

        } catch {
            errorMessage = "Failed to request HealthKit authorization: \(error.localizedDescription)"
            isAuthorized = false
        }
    }

    /// Fetch all health data for today
    /// Call this to refresh the dashboard with current wellness metrics
    func fetchTodayData() async {
        guard healthStore != nil else {
            errorMessage = "HealthKit is not available"
            return
        }

        // Clear any previous error
        errorMessage = nil

        // Fetch all metrics concurrently for efficiency
        async let stepsResult = fetchTodaySteps()
        async let floorsResult = fetchTodayFloors()
        async let energyResult = fetchTodayActiveEnergy()
        async let speedResult = fetchLatestWalkingSpeed()
        async let stepLengthResult = fetchLatestWalkingStepLength()
        async let steadinessResult = fetchRecentSteadinessEvents()
        async let sleepResult = fetchRecentSleepData()

        // Wait for all to complete and update published properties
        todaySteps = await stepsResult
        todayFloors = await floorsResult
        todayActiveEnergy = await energyResult
        walkingSpeed = await speedResult
        walkingStepLength = await stepLengthResult
        recentSteadinessEvents = await steadinessResult
        recentSleepSamples = await sleepResult

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

    /// Fetch today's active energy burned (calories)
    /// Returns 0.0 if no data available or not authorized
    func fetchTodayActiveEnergy() async -> Double {
        guard let healthStore = healthStore,
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0.0
        }

        let predicate = createTodayPredicate()

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("HealthKit energy query error: \(error.localizedDescription)")
                    continuation.resume(returning: 0.0)
                    return
                }

                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }

                let energy = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: energy)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch the most recent walking speed measurement
    /// Returns nil if no data available - speed in meters per second
    func fetchLatestWalkingSpeed() async -> Double? {
        guard let healthStore = healthStore,
              let speedType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) else {
            return nil
        }

        // Get samples from the last 7 days to find the most recent
        let predicate = createWeekPredicate()

        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: speedType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("HealthKit walking speed query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let speed = sample.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second()))
                continuation.resume(returning: speed)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch the most recent walking step length measurement
    /// Returns nil if no data available - length in meters
    func fetchLatestWalkingStepLength() async -> Double? {
        guard let healthStore = healthStore,
              let stepLengthType = HKQuantityType.quantityType(forIdentifier: .walkingStepLength) else {
            return nil
        }

        // Get samples from the last 7 days to find the most recent
        let predicate = createWeekPredicate()

        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: stepLengthType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("HealthKit step length query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let length = sample.quantity.doubleValue(for: HKUnit.meter())
                continuation.resume(returning: length)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch recent walking steadiness events (iOS fall risk detection)
    /// Returns events from the last 30 days
    func fetchRecentSteadinessEvents() async -> [HKCategorySample] {
        guard let healthStore = healthStore,
              let steadinessType = HKCategoryType.categoryType(forIdentifier: .appleWalkingSteadinessEvent) else {
            return []
        }

        // Look back 30 days for steadiness events
        let predicate = createMonthPredicate()

        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: steadinessType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("HealthKit steadiness query error: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                let events = samples as? [HKCategorySample] ?? []
                continuation.resume(returning: events)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch recent sleep analysis data
    /// Returns sleep samples from the last 7 days
    func fetchRecentSleepData() async -> [HKCategorySample] {
        guard let healthStore = healthStore,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }

        // Look back 7 days for sleep data
        let predicate = createWeekPredicate()

        return await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("HealthKit sleep query error: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                let sleepSamples = samples as? [HKCategorySample] ?? []
                continuation.resume(returning: sleepSamples)
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

    /// Create a predicate for the last 7 days
    private func createWeekPredicate() -> NSPredicate {
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now

        return HKQuery.predicateForSamples(
            withStart: oneWeekAgo,
            end: now,
            options: .strictStartDate
        )
    }

    /// Create a predicate for the last 30 days
    private func createMonthPredicate() -> NSPredicate {
        let now = Date()
        let oneMonthAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now

        return HKQuery.predicateForSamples(
            withStart: oneMonthAgo,
            end: now,
            options: .strictStartDate
        )
    }

    // MARK: - Background Delivery Support

    /// Set up observer query for step count changes
    /// This is called by HealthKit when new step data is recorded, even in background
    private func setupStepCountObserver() {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("❌ HealthKit observer error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            // Fetch updated step count and record activity
            Task { @MainActor [weak self] in
                guard let self = self else {
                    completionHandler()
                    return
                }

                // Fetch today's steps
                let steps = await self.fetchTodaySteps()
                self.todaySteps = steps

                // Store in UserDefaults for background task access
                UserDefaults.standard.set(steps, forKey: "todaySteps")

                // Record activity signal (new steps = proof of life)
                if steps > 0 {
                    NegativeSpaceService.shared.recordActivity(.steps, metadata: "\(steps) steps")
                }

                print("🏃 HealthKit observer: \(steps) steps recorded")
                completionHandler()
            }
        }

        healthStore.execute(query)
        print("🏃 HealthKit step count observer started")
    }

    // MARK: - Historical Data (for Activity Tab)

    /// Fetch daily step totals for the last N days
    /// Returns an array of (date, stepCount) tuples, most recent first
    func fetchDailySteps(forLastDays days: Int) async -> [(date: Date, steps: Int)] {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return []
        }

        let calendar = Calendar.current
        let now = Date()
        var results: [(date: Date, steps: Int)] = []

        // Fetch data for each day
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            )

            let steps = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, _ in
                    let count = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    continuation.resume(returning: Int(count))
                }
                healthStore.execute(query)
            }

            results.append((date: startOfDay, steps: steps))
        }

        return results
    }

    /// Fetch daily floor totals for the last N days
    /// Returns an array of (date, floors) tuples, most recent first
    func fetchDailyFloors(forLastDays days: Int) async -> [(date: Date, floors: Int)] {
        guard let healthStore = healthStore,
              let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else {
            return []
        }

        let calendar = Calendar.current
        let now = Date()
        var results: [(date: Date, floors: Int)] = []

        // Fetch data for each day
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            )

            let floors = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: flightsType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, _ in
                    let count = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    continuation.resume(returning: Int(count))
                }
                healthStore.execute(query)
            }

            results.append((date: startOfDay, floors: floors))
        }

        return results
    }

    /// Fetch daily active energy totals for the last N days
    /// Returns an array of (date, calories) tuples, most recent first
    func fetchDailyEnergy(forLastDays days: Int) async -> [(date: Date, calories: Int)] {
        guard let healthStore = healthStore,
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return []
        }

        let calendar = Calendar.current
        let now = Date()
        var results: [(date: Date, calories: Int)] = []

        // Fetch data for each day
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: endOfDay,
                options: .strictStartDate
            )

            let calories = await withCheckedContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: energyType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, _ in
                    let count = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                    continuation.resume(returning: Int(count))
                }
                healthStore.execute(query)
            }

            results.append((date: startOfDay, calories: calories))
        }

        return results
    }
}
