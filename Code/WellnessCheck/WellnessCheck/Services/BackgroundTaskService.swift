//
//  BackgroundTaskService.swift
//  WellnessCheck
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Coordinates background task execution using BGTaskScheduler.
//  Handles periodic inactivity checks and HealthKit background delivery.
//
//  iOS BACKGROUND LIMITATIONS:
//  - BGAppRefreshTask runs ~every 15 minutes at iOS's discretion
//  - Maximum 30 seconds execution time per wake
//  - Cannot run continuous accelerometer (fall detection requires foreground)
//  - HealthKit background delivery provides wake-on-data-change
//
//  WHAT THIS SERVICE DOES:
//  1. Registers background tasks with BGTaskScheduler on app launch
//  2. Schedules tasks when app enters background
//  3. Executes inactivity checks when iOS wakes the app
//  4. Sends alerts via CloudFunctionsService if thresholds exceeded
//  5. Respects quiet hours and learning period
//
//  IMPORTANT: This service deliberately does NOT use @MainActor because
//  background tasks execute on arbitrary threads. All data is read from
//  UserDefaults which is thread-safe.
//

import Foundation
import BackgroundTasks
import HealthKit
import UserNotifications

/// Service for managing background task execution
/// NOTE: No @MainActor - background tasks run on arbitrary threads
final class BackgroundTaskService {

    // MARK: - Singleton

    static let shared = BackgroundTaskService()

    // MARK: - Task Identifiers

    /// Background app refresh task - periodic wellness check
    static let refreshTaskIdentifier = "com.stricklindevelopment.wellnesscheck.refresh"

    /// Background processing task - deeper inactivity analysis
    static let inactivityTaskIdentifier = "com.stricklindevelopment.wellnesscheck.inactivityCheck"

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()
    private let userDefaults = UserDefaults.standard

    /// Minimum interval between background checks (in seconds)
    /// iOS may schedule less frequently based on battery/usage patterns
    private let minimumBackgroundInterval: TimeInterval = 15 * 60 // 15 minutes

    // MARK: - UserDefaults Keys (matching existing services)

    // NegativeSpaceService keys
    private let lastActivityKey = "lastActivityTimestamp"
    private let silenceThresholdKey = "monitoring_silenceThreshold"
    private let inactivityEnabledKey = "monitoring_inactivityAlerts"
    private let quietHoursEnabledKey = "monitoring_quietHoursEnabled"
    private let quietHoursStartKey = "monitoring_quietHoursStart"
    private let quietHoursEndKey = "monitoring_quietHoursEnd"

    // App-wide keys
    private let installDateKey = "appInstallDate"
    private let learningPeriodDays = 14
    private let userNameKey = "userName"

    // Care Circle key
    private let membersKey = "careCircleMembers"

    // Battery history key
    private let batteryHistoryKey = "batteryHistory"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Register background tasks with BGTaskScheduler
    /// MUST be called from AppDelegate.didFinishLaunchingWithOptions BEFORE
    /// returning true (before app finishes launching)
    func registerBackgroundTasks() {
        // Register refresh task (lightweight, frequent)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }

        // Register processing task (can run longer when conditions allow)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.inactivityTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleInactivityCheck(task: task as! BGProcessingTask)
        }

        print("📋 Background tasks registered")
    }

    /// Schedule background tasks when app enters background
    /// Call this from scenePhase .background handler
    func scheduleBackgroundTasks() {
        scheduleAppRefresh()
        scheduleInactivityCheck()
    }

    /// Cancel all scheduled background tasks
    /// Call this if user disables monitoring entirely
    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.inactivityTaskIdentifier)
        print("📋 Background tasks cancelled")
    }

    /// Enable HealthKit background delivery for step count
    /// Call this after HealthKit authorization is granted
    func enableHealthKitBackgroundDelivery() {
        guard HKHealthStore.isHealthDataAvailable(),
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        // Enable background delivery - iOS will wake app when new steps are recorded
        healthStore.enableBackgroundDelivery(
            for: stepType,
            frequency: .hourly
        ) { success, error in
            if success {
                print("🏃 HealthKit background delivery enabled for steps")
            } else if let error = error {
                print("❌ HealthKit background delivery failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Task Scheduling

    /// Schedule the next app refresh task
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: minimumBackgroundInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📋 App refresh scheduled for ~\(Int(minimumBackgroundInterval / 60)) minutes from now")
        } catch {
            print("❌ Could not schedule app refresh: \(error.localizedDescription)")
        }
    }

    /// Schedule a longer-running inactivity check task
    private func scheduleInactivityCheck() {
        let request = BGProcessingTaskRequest(identifier: Self.inactivityTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: minimumBackgroundInterval)
        request.requiresNetworkConnectivity = true // Need network to send SMS
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📋 Inactivity check scheduled")
        } catch {
            print("❌ Could not schedule inactivity check: \(error.localizedDescription)")
        }
    }

    // MARK: - Task Handlers

    /// Handle background app refresh task (lightweight check)
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("📋 Background refresh starting")

        // Schedule next refresh FIRST (in case we're terminated)
        scheduleAppRefresh()

        // Set expiration handler
        task.expirationHandler = {
            print("📋 Background refresh expired")
            task.setTaskCompleted(success: false)
        }

        // Perform the check
        Task {
            let alertSent = await performInactivityCheck()
            task.setTaskCompleted(success: true)
            print("📋 Background refresh completed, alert sent: \(alertSent)")
        }
    }

    /// Handle background processing task (can do more work)
    private func handleInactivityCheck(task: BGProcessingTask) {
        print("📋 Background inactivity check starting")

        // Schedule next check
        scheduleInactivityCheck()

        task.expirationHandler = {
            print("📋 Inactivity check expired")
            task.setTaskCompleted(success: false)
        }

        Task {
            let alertSent = await performInactivityCheck()

            // Also check pattern deviation if we have time and no alert sent yet
            if !alertSent {
                await checkPatternDeviation()
            }

            task.setTaskCompleted(success: true)
            print("📋 Background inactivity check completed")
        }
    }

    // MARK: - Background Check Logic

    /// Perform inactivity check using UserDefaults data
    /// Returns true if an alert was sent
    private func performInactivityCheck() async -> Bool {
        // Check if monitoring is enabled
        guard userDefaults.bool(forKey: inactivityEnabledKey) else {
            print("📊 Inactivity monitoring disabled")
            return false
        }

        // Check if in learning period
        if isInLearningPeriod() {
            print("📊 In learning period - not alerting")
            return false
        }

        // Check quiet hours
        if isCurrentlyQuietHours() {
            print("📊 In quiet hours - not alerting")
            return false
        }

        // Get last activity timestamp
        guard let lastActivityTimestamp = userDefaults.object(forKey: lastActivityKey) as? TimeInterval else {
            print("📊 No last activity recorded")
            return false
        }

        let lastActivity = Date(timeIntervalSince1970: lastActivityTimestamp)
        let timeSinceLastActivity = Date().timeIntervalSince(lastActivity)

        // Get threshold (default 4 hours)
        let thresholdHours = userDefaults.double(forKey: silenceThresholdKey)
        let threshold = thresholdHours > 0 ? thresholdHours : 4.0
        let thresholdSeconds = threshold * 3600

        print("📊 Time since last activity: \(Int(timeSinceLastActivity / 60)) minutes, threshold: \(Int(thresholdSeconds / 60)) minutes")

        // Check if threshold exceeded
        if timeSinceLastActivity >= thresholdSeconds {
            // Check if battery was likely dead
            if wasBatteryLikelyDead(gapStart: lastActivity) {
                print("🔋 Silence likely due to dead battery - not alerting")
                return false
            }

            // Send alert
            return await sendBackgroundAlert(type: .inactivity)
        }

        // Check if approaching threshold (75%) - send notification
        let warningThreshold = thresholdSeconds * 0.75
        if timeSinceLastActivity >= warningThreshold {
            await sendCheckInNotification()
        }

        return false
    }

    /// Check for pattern deviation (simplified version for background)
    private func checkPatternDeviation() async {
        // Load hourly patterns from UserDefaults
        guard let hourlyData = userDefaults.data(forKey: "hourlyPatterns"),
              let patterns = try? JSONDecoder().decode([String: HourlyPatternData].self, from: hourlyData) else {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let isWeekend = calendar.isDateInWeekend(now)
        let key = "\(hour)_\(isWeekend)"

        guard let pattern = patterns[key], pattern.sampleCount >= 7 else {
            return // Not enough data
        }

        // Get current step count from last recorded value
        let todaySteps = userDefaults.integer(forKey: "todaySteps")
        let expectedSteps = pattern.averageSteps

        // Flag deviation if <25% of expected and expected is meaningful
        if expectedSteps > 100 && Double(todaySteps) < expectedSteps * 0.25 {
            print("📊 Pattern deviation detected - sending alert")
            await sendBackgroundAlert(type: .missedCheckin)
        }
    }

    /// Send alert from background context
    @discardableResult
    private func sendBackgroundAlert(type: AlertType) async -> Bool {
        // Load Care Circle members from UserDefaults
        guard let membersData = userDefaults.data(forKey: membersKey),
              let members = try? JSONDecoder().decode([CareCircleMember].self, from: membersData),
              !members.isEmpty else {
            print("⚠️ No Care Circle members to alert")
            return false
        }

        // Get user name
        let userName = userDefaults.string(forKey: userNameKey) ?? "WellnessCheck User"

        print("📤 Sending background alert: \(type.rawValue) to \(members.count) members")

        // Use CloudFunctionsService via Task to send alert
        // This needs to hop to MainActor since CloudFunctionsService is @MainActor
        let result = await MainActor.run {
            Task {
                let cloudFunctions = CloudFunctionsService()
                return await cloudFunctions.sendAlert(
                    userName: userName,
                    alertType: type,
                    location: nil,
                    members: members
                )
            }
        }

        let smsResult = await result.value

        if smsResult.success {
            print("✅ Background alert sent to \(smsResult.sent) Care Circle members")
            return true
        } else {
            print("❌ Background alert failed: \(smsResult.error ?? "Unknown error")")
            return false
        }
    }

    /// Send check-in notification when approaching threshold
    private func sendCheckInNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Are you okay?"
        content.body = "We haven't seen any activity in a while. Tap to let us know you're fine."
        content.sound = .default
        content.categoryIdentifier = "CHECK_IN"

        let request = UNNotificationRequest(
            identifier: "wellness_check_in_bg",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📬 Check-in notification sent from background")
        } catch {
            print("❌ Failed to send check-in notification: \(error)")
        }
    }

    // MARK: - Helper Methods

    /// Check if app is in learning period
    private func isInLearningPeriod() -> Bool {
        guard let installTimestamp = userDefaults.object(forKey: installDateKey) as? TimeInterval else {
            return true
        }
        let installDate = Date(timeIntervalSince1970: installTimestamp)
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return daysSinceInstall < learningPeriodDays
    }

    /// Check if currently in quiet hours
    private func isCurrentlyQuietHours() -> Bool {
        guard userDefaults.bool(forKey: quietHoursEnabledKey) else {
            return false
        }

        let startInterval = userDefaults.double(forKey: quietHoursStartKey)
        let endInterval = userDefaults.double(forKey: quietHoursEndKey)

        guard startInterval > 0 && endInterval > 0 else { return false }

        let startDate = Date(timeIntervalSince1970: startInterval)
        let endDate = Date(timeIntervalSince1970: endInterval)

        let calendar = Calendar.current
        let now = Date()

        let startHour = calendar.component(.hour, from: startDate)
        let startMinute = calendar.component(.minute, from: startDate)
        let endHour = calendar.component(.hour, from: endDate)
        let endMinute = calendar.component(.minute, from: endDate)

        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        // Handle overnight quiet hours (e.g., 22:00 - 07:00)
        if startMinutes > endMinutes {
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        } else {
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        }
    }

    /// Check if battery was likely dead at gap start
    private func wasBatteryLikelyDead(gapStart: Date) -> Bool {
        guard let historyData = userDefaults.data(forKey: batteryHistoryKey),
              let history = try? JSONDecoder().decode([BatterySnapshot].self, from: historyData) else {
            return false
        }

        let snapshotsBefore = history
            .filter { $0.timestamp < gapStart }
            .sorted { $0.timestamp > $1.timestamp }

        guard let lastSnapshot = snapshotsBefore.first else {
            return false
        }

        // If battery was under 5% and unplugged, it probably died
        return lastSnapshot.level <= 5 && lastSnapshot.state == .unplugged
    }
}

// MARK: - Supporting Types for Background Decoding

/// Simplified hourly pattern for background decoding
/// Mirrors the structure in PatternLearningService
struct HourlyPatternData: Codable {
    let hour: Int
    let isWeekend: Bool
    var stepCounts: [Int]
    var activityCounts: [Int]
    var sampleCount: Int

    var averageSteps: Double {
        guard !stepCounts.isEmpty else { return 0 }
        return Double(stepCounts.reduce(0, +)) / Double(stepCounts.count)
    }
}
