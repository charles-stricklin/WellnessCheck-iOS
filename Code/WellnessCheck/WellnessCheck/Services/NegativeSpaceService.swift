//
//  NegativeSpaceService.swift
//  WellnessCheck
//
//  Created: v0.6.0 (2026-01-17)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  The core safety monitoring service. Detects "negative space" — periods where
//  the user's phone shows no activity, which may indicate they need help.
//
//  WHAT IS NEGATIVE SPACE:
//  Negative space is the absence of expected signals. A phone that hasn't moved,
//  no steps recorded, no pickups — silence. When that silence exceeds the user's
//  normal patterns or their configured threshold, it may indicate a problem.
//
//  HOW IT WORKS:
//  1. Track last known activity (steps, phone pickup, app open, etc.)
//  2. Periodically check how long since last activity
//  3. Compare against user's silence threshold setting
//  4. Factor in context: time of day, quiet hours, battery status
//  5. If threshold exceeded, initiate check-in or alert
//
//  CONTEXT MATTERS:
//  - During quiet hours: Don't alert (user configured these)
//  - Night owl mode + late night: Relax thresholds
//  - Low battery before gap: Probably phone died, not an emergency
//  - Learning period: Observe patterns, don't alert yet
//
//  ESCALATION:
//  1. Threshold approached → Send check-in notification to user
//  2. User doesn't respond → Send another nudge
//  3. Still no response after threshold → Alert Care Circle
//

import Foundation
import Combine
import UserNotifications

/// Types of activity signals we track
enum ActivitySignal: String, Codable {
    case steps          // HealthKit step count increased
    case phonePickup    // Phone was picked up (CoreMotion)
    case appOpen        // WellnessCheck app opened
    case userCheckIn    // User tapped "I'm OK"
    case movement       // Significant device motion
}

/// A recorded activity event
struct ActivityEvent: Codable {
    let timestamp: Date
    let signal: ActivitySignal
    let metadata: String?   // Optional context (e.g., step count)
}

/// Current monitoring state
enum MonitoringState {
    case learning           // First 14 days, observing patterns
    case active             // Normal monitoring
    case quietHours         // During configured quiet hours
    case paused             // User manually paused
    case alertPending       // Threshold exceeded, awaiting response
    case alertSent          // Care Circle has been notified
}

/// Service that monitors for concerning periods of inactivity
@MainActor
class NegativeSpaceService: ObservableObject {

    // MARK: - Singleton

    static let shared = NegativeSpaceService()

    // MARK: - Published Properties

    /// Current monitoring state
    @Published var state: MonitoringState = .active

    /// Time since last recorded activity
    @Published var timeSinceLastActivity: TimeInterval = 0

    /// Whether we're currently in quiet hours
    @Published var isInQuietHours: Bool = false

    /// Whether check-in notification has been sent
    @Published var checkInNotificationSent: Bool = false

    /// Last activity event
    @Published var lastActivity: ActivityEvent?

    // MARK: - Private Properties

    /// Activity history for pattern analysis
    private var activityHistory: [ActivityEvent] = []

    /// Maximum history to keep (7 days worth)
    private let maxHistoryCount = 1000

    /// Timer for periodic checks
    private var monitoringTimer: Timer?

    /// Check interval (every 5 minutes)
    private let checkInterval: TimeInterval = 300

    /// UserDefaults key for activity history
    private let historyKey = "activityHistory"

    /// UserDefaults key for last activity timestamp
    private let lastActivityKey = "lastActivityTimestamp"

    /// Learning period duration (14 days)
    private let learningPeriodDays = 14

    /// Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        loadHistory()
        checkLearningPeriod()
    }

    // MARK: - Public Methods

    /// Start monitoring for inactivity
    func startMonitoring() {
        // Check if inactivity alerts are enabled
        let inactivityEnabled = UserDefaults.standard.bool(forKey: "monitoring_inactivityAlerts")
        guard inactivityEnabled else {
            print("📊 Inactivity monitoring disabled by user")
            return
        }

        // Stop any existing timer
        monitoringTimer?.invalidate()

        // Start periodic checks
        // Note: Timer callback captures self weakly, then dispatches to MainActor
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.performCheck()
            }
        }

        // Also perform an immediate check
        performCheck()

        print("📊 Negative space monitoring started")
    }

    /// Stop monitoring
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("📊 Negative space monitoring stopped")
    }

    /// Record an activity signal
    func recordActivity(_ signal: ActivitySignal, metadata: String? = nil) {
        let event = ActivityEvent(
            timestamp: Date(),
            signal: signal,
            metadata: metadata
        )

        activityHistory.append(event)
        lastActivity = event
        timeSinceLastActivity = 0

        // Reset alert state when user shows activity
        if state == .alertPending {
            state = .active
            checkInNotificationSent = false
        }

        // Trim history
        if activityHistory.count > maxHistoryCount {
            activityHistory.removeFirst(activityHistory.count - maxHistoryCount)
        }

        // Save
        saveHistory()
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastActivityKey)

        print("📊 Activity recorded: \(signal.rawValue)")
    }

    /// User responded to check-in
    func userRespondedToCheckIn() {
        recordActivity(.userCheckIn)
        state = .active
        checkInNotificationSent = false
        print("✅ User responded to check-in")
    }

    /// Manually pause monitoring (e.g., user going on vacation)
    func pauseMonitoring() {
        state = .paused
        monitoringTimer?.invalidate()
        print("⏸️ Monitoring paused")
    }

    /// Resume monitoring after pause
    func resumeMonitoring() {
        state = .active
        startMonitoring()
        print("▶️ Monitoring resumed")
    }

    // MARK: - Private Methods

    /// Perform periodic inactivity check
    private func performCheck() {
        // Skip if in learning period
        if state == .learning {
            return
        }

        // Skip if paused
        if state == .paused {
            return
        }

        // Check quiet hours
        if isCurrentlyQuietHours() {
            isInQuietHours = true
            state = .quietHours
            return
        } else {
            isInQuietHours = false
            if state == .quietHours {
                state = .active
            }
        }

        // Calculate time since last activity
        updateTimeSinceLastActivity()

        // Get user's threshold
        let thresholdHours = UserDefaults.standard.double(forKey: "monitoring_silenceThreshold")
        let threshold = thresholdHours > 0 ? thresholdHours : 4.0
        let thresholdSeconds = threshold * 3600

        // Check if threshold is approaching (75% of threshold)
        let warningThreshold = thresholdSeconds * 0.75

        if timeSinceLastActivity >= thresholdSeconds {
            // Threshold exceeded
            handleThresholdExceeded()
        } else if timeSinceLastActivity >= warningThreshold && !checkInNotificationSent {
            // Approaching threshold — send check-in nudge
            sendCheckInNotification()
        }
    }

    /// Update time since last activity
    private func updateTimeSinceLastActivity() {
        if let lastTimestamp = UserDefaults.standard.object(forKey: lastActivityKey) as? TimeInterval {
            let lastDate = Date(timeIntervalSince1970: lastTimestamp)
            timeSinceLastActivity = Date().timeIntervalSince(lastDate)
        } else if let lastEvent = activityHistory.last {
            timeSinceLastActivity = Date().timeIntervalSince(lastEvent.timestamp)
        } else {
            // No history — treat app install as first activity
            recordActivity(.appOpen, metadata: "Initial launch")
            timeSinceLastActivity = 0
        }
    }

    /// Check if we're currently in quiet hours
    private func isCurrentlyQuietHours() -> Bool {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "monitoring_quietHoursEnabled") else {
            return false
        }

        let startInterval = defaults.double(forKey: "monitoring_quietHoursStart")
        let endInterval = defaults.double(forKey: "monitoring_quietHoursEnd")

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

    /// Send a check-in notification to the user
    private func sendCheckInNotification() {
        checkInNotificationSent = true

        let content = UNMutableNotificationContent()
        content.title = "Are you okay?"
        content.body = "We haven't seen any activity in a while. Tap to let us know you're fine."
        content.sound = .default
        content.categoryIdentifier = "CHECK_IN"

        let request = UNNotificationRequest(
            identifier: "wellness_check_in",
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send check-in notification: \(error)")
            } else {
                print("📬 Check-in notification sent")
            }
        }
    }

    /// Handle when silence threshold is exceeded
    private func handleThresholdExceeded() {
        // Check battery status first
        let batteryService = BatteryService.shared
        if let lastActivity = lastActivity,
           batteryService.wasBatteryLikelyDead(gapStart: lastActivity.timestamp) {
            // Battery probably died — not an emergency
            print("🔋 Silence likely due to dead battery — not alerting")
            return
        }

        state = .alertPending

        // Send urgent notification first
        sendUrgentNotification()

        // Post notification for the app to show alert UI
        NotificationCenter.default.post(name: .inactivityAlertTriggered, object: nil)

        print("🚨 Silence threshold exceeded — alert pending")
    }

    /// Send urgent notification before alerting Care Circle
    private func sendUrgentNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Urgent: Please respond"
        content.body = "We're about to notify your Care Circle. Open the app if you're okay."
        content.sound = .defaultCritical
        content.categoryIdentifier = "URGENT_CHECK_IN"

        let request = UNNotificationRequest(
            identifier: "wellness_urgent",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Check if still in learning period
    private func checkLearningPeriod() {
        let installDateKey = "appInstallDate"
        let defaults = UserDefaults.standard

        if let installTimestamp = defaults.object(forKey: installDateKey) as? TimeInterval {
            let installDate = Date(timeIntervalSince1970: installTimestamp)
            let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0

            if daysSinceInstall < learningPeriodDays {
                state = .learning
                print("📊 In learning period: Day \(daysSinceInstall + 1) of \(learningPeriodDays)")
            } else {
                state = .active
            }
        } else {
            // First launch — record install date
            defaults.set(Date().timeIntervalSince1970, forKey: installDateKey)
            state = .learning
            print("📊 Learning period started")
        }
    }

    /// Save activity history to UserDefaults
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(activityHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    /// Load activity history from UserDefaults
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([ActivityEvent].self, from: data) {
            activityHistory = decoded
            lastActivity = decoded.last
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when inactivity threshold is exceeded
    static let inactivityAlertTriggered = Notification.Name("com.wellnesscheck.inactivityAlertTriggered")
}
