//
//  PatternLearningService.swift
//  WellnessCheck
//
//  Created: v0.6.0 (2026-01-17)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Learns user's activity patterns during the 14-day learning period and
//  detects significant deviations that may indicate a problem.
//
//  HOW IT WORKS:
//  1. During learning period, record activity patterns by time of day
//  2. Build baseline expectations for each time slot
//  3. After learning, compare current activity to baseline
//  4. Flag significant deviations for investigation
//
//  WHAT WE LEARN:
//  - Typical wake time (first activity of day)
//  - Typical step count by time of day
//  - Normal periods of inactivity (naps, TV time, etc.)
//  - Weekend vs weekday differences
//  - Night owl patterns (if enabled)
//
//  DEVIATION DETECTION:
//  - Compare current hour's activity to historical average
//  - Flag if current is <25% of typical
//  - Consider time-of-day context (less concern at 3am vs 3pm)
//  - Account for quiet hours and night owl mode
//

import Foundation
import Combine

/// Activity data for a specific hour of a specific day type
struct HourlyPattern: Codable {
    let hour: Int                   // 0-23
    let isWeekend: Bool
    var stepCounts: [Int]           // Historical step counts for this hour
    var activityCounts: [Int]       // Number of activity events in this hour
    var sampleCount: Int            // How many days we have data for

    /// Average steps for this hour
    var averageSteps: Double {
        guard !stepCounts.isEmpty else { return 0 }
        return Double(stepCounts.reduce(0, +)) / Double(stepCounts.count)
    }

    /// Average activity events for this hour
    var averageActivityCount: Double {
        guard !activityCounts.isEmpty else { return 0 }
        return Double(activityCounts.reduce(0, +)) / Double(activityCounts.count)
    }

    /// Standard deviation of steps (for detecting outliers)
    var stepStandardDeviation: Double {
        guard stepCounts.count > 1 else { return 0 }
        let mean = averageSteps
        let variance = stepCounts.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(stepCounts.count - 1)
        return sqrt(variance)
    }
}

/// Daily summary pattern
struct DailyPattern: Codable {
    let date: Date
    let isWeekend: Bool
    var totalSteps: Int
    var firstActivityHour: Int?     // When user first became active
    var lastActivityHour: Int?      // When user last showed activity
    var activeHours: Int            // How many hours had activity
}

/// Service for learning and detecting pattern deviations
@MainActor
class PatternLearningService: ObservableObject {

    // MARK: - Singleton

    static let shared = PatternLearningService()

    // MARK: - Published Properties

    /// Whether we're still in learning period
    @Published var isLearning: Bool = true

    /// Current day of learning period (1-14)
    @Published var learningDay: Int = 1

    /// Whether a deviation has been detected today
    @Published var deviationDetected: Bool = false

    /// Description of the detected deviation
    @Published var deviationDescription: String?

    // MARK: - Private Properties

    /// Hourly patterns indexed by "hour_isWeekend" key
    private var hourlyPatterns: [String: HourlyPattern] = [:]

    /// Daily pattern summaries
    private var dailyPatterns: [DailyPattern] = []

    /// Today's activity by hour
    private var todayActivityByHour: [Int: (steps: Int, events: Int)] = [:]

    /// UserDefaults keys
    private let hourlyPatternsKey = "hourlyPatterns"
    private let dailyPatternsKey = "dailyPatterns"
    private let installDateKey = "appInstallDate"

    /// Learning period duration
    private let learningPeriodDays = 14

    /// Deviation threshold (current must be at least this % of average)
    private let deviationThreshold = 0.25  // 25%

    // MARK: - Initialization

    private init() {
        loadPatterns()
        updateLearningStatus()
    }

    // MARK: - Public Methods

    /// Record activity data for the current hour
    func recordHourlyActivity(steps: Int, events: Int) {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let isWeekend = calendar.isDateInWeekend(now)

        // Update today's tracking
        todayActivityByHour[hour] = (steps: steps, events: events)

        // Update patterns
        let key = patternKey(hour: hour, isWeekend: isWeekend)

        if var pattern = hourlyPatterns[key] {
            pattern.stepCounts.append(steps)
            pattern.activityCounts.append(events)
            pattern.sampleCount += 1

            // Keep last 30 days of data per hour
            if pattern.stepCounts.count > 30 {
                pattern.stepCounts.removeFirst()
                pattern.activityCounts.removeFirst()
            }

            hourlyPatterns[key] = pattern
        } else {
            hourlyPatterns[key] = HourlyPattern(
                hour: hour,
                isWeekend: isWeekend,
                stepCounts: [steps],
                activityCounts: [events],
                sampleCount: 1
            )
        }

        savePatterns()

        // Check for deviation if not in learning period
        if !isLearning {
            checkForDeviation(hour: hour, isWeekend: isWeekend, currentSteps: steps, currentEvents: events)
        }
    }

    /// Record end-of-day summary
    func recordDailySummary(totalSteps: Int, firstActiveHour: Int?, lastActiveHour: Int?, activeHours: Int) {
        let now = Date()
        let calendar = Calendar.current
        let isWeekend = calendar.isDateInWeekend(now)

        let summary = DailyPattern(
            date: now,
            isWeekend: isWeekend,
            totalSteps: totalSteps,
            firstActivityHour: firstActiveHour,
            lastActivityHour: lastActiveHour,
            activeHours: activeHours
        )

        dailyPatterns.append(summary)

        // Keep last 60 days
        if dailyPatterns.count > 60 {
            dailyPatterns.removeFirst()
        }

        savePatterns()

        // Reset today's tracking
        todayActivityByHour.removeAll()
    }

    /// Get the expected activity level for the current hour
    func expectedActivityForCurrentHour() -> (steps: Double, events: Double)? {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let isWeekend = calendar.isDateInWeekend(now)

        let key = patternKey(hour: hour, isWeekend: isWeekend)
        guard let pattern = hourlyPatterns[key], pattern.sampleCount >= 3 else {
            return nil
        }

        return (steps: pattern.averageSteps, events: pattern.averageActivityCount)
    }

    /// Get typical wake time (first activity hour)
    func typicalWakeTime(isWeekend: Bool) -> Int? {
        let relevantDays = dailyPatterns.filter { $0.isWeekend == isWeekend }
        guard relevantDays.count >= 3 else { return nil }

        let wakeTimes = relevantDays.compactMap { $0.firstActivityHour }
        guard !wakeTimes.isEmpty else { return nil }

        return wakeTimes.reduce(0, +) / wakeTimes.count
    }

    /// Get typical daily step count
    func typicalDailySteps(isWeekend: Bool) -> Int? {
        let relevantDays = dailyPatterns.filter { $0.isWeekend == isWeekend }
        guard relevantDays.count >= 3 else { return nil }

        return relevantDays.map { $0.totalSteps }.reduce(0, +) / relevantDays.count
    }

    /// Check if current activity is significantly below normal
    func isActivityBelowNormal(currentSteps: Int, forHour hour: Int, isWeekend: Bool) -> Bool {
        let key = patternKey(hour: hour, isWeekend: isWeekend)
        guard let pattern = hourlyPatterns[key], pattern.sampleCount >= 5 else {
            return false // Not enough data
        }

        let expected = pattern.averageSteps
        guard expected > 100 else {
            return false // Low activity hour anyway
        }

        return Double(currentSteps) < expected * deviationThreshold
    }

    // MARK: - Private Methods

    /// Generate key for hourly pattern lookup
    private func patternKey(hour: Int, isWeekend: Bool) -> String {
        return "\(hour)_\(isWeekend)"
    }

    /// Update learning period status
    private func updateLearningStatus() {
        guard let installTimestamp = UserDefaults.standard.object(forKey: installDateKey) as? TimeInterval else {
            isLearning = true
            learningDay = 1
            return
        }

        let installDate = Date(timeIntervalSince1970: installTimestamp)
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0

        if daysSinceInstall < learningPeriodDays {
            isLearning = true
            learningDay = daysSinceInstall + 1
        } else {
            isLearning = false
            learningDay = learningPeriodDays
        }
    }

    /// Check for deviation in current hour
    private func checkForDeviation(hour: Int, isWeekend: Bool, currentSteps: Int, currentEvents: Int) {
        let key = patternKey(hour: hour, isWeekend: isWeekend)
        guard let pattern = hourlyPatterns[key], pattern.sampleCount >= 7 else {
            return // Need at least a week of data
        }

        // Skip late night / early morning hours (less concerning)
        if hour >= 0 && hour < 6 {
            // Check if night owl mode is enabled
            let nightOwlEnabled = UserDefaults.standard.bool(forKey: "monitoring_nightOwlMode")
            if !nightOwlEnabled {
                return // Normal sleeping hours
            }
        }

        let expectedSteps = pattern.averageSteps
        let expectedEvents = pattern.averageActivityCount

        // Check for significant deviation
        let stepsDeviation = expectedSteps > 100 && Double(currentSteps) < expectedSteps * deviationThreshold
        let eventsDeviation = expectedEvents > 2 && Double(currentEvents) < expectedEvents * deviationThreshold

        if stepsDeviation || eventsDeviation {
            deviationDetected = true

            if stepsDeviation && eventsDeviation {
                deviationDescription = "Activity is unusually low for this time of day"
            } else if stepsDeviation {
                deviationDescription = "Step count is much lower than usual"
            } else {
                deviationDescription = "Phone activity is less than usual"
            }

            // Post notification for the app to handle
            NotificationCenter.default.post(
                name: .patternDeviationDetected,
                object: nil,
                userInfo: [
                    "hour": hour,
                    "expectedSteps": expectedSteps,
                    "actualSteps": currentSteps,
                    "description": deviationDescription ?? ""
                ]
            )

            print("⚠️ Pattern deviation detected: \(deviationDescription ?? "")")
        } else {
            // Reset if activity normalizes
            if deviationDetected {
                deviationDetected = false
                deviationDescription = nil
            }
        }
    }

    /// Save patterns to UserDefaults
    private func savePatterns() {
        if let hourlyData = try? JSONEncoder().encode(hourlyPatterns) {
            UserDefaults.standard.set(hourlyData, forKey: hourlyPatternsKey)
        }

        if let dailyData = try? JSONEncoder().encode(dailyPatterns) {
            UserDefaults.standard.set(dailyData, forKey: dailyPatternsKey)
        }
    }

    /// Load patterns from UserDefaults
    private func loadPatterns() {
        if let hourlyData = UserDefaults.standard.data(forKey: hourlyPatternsKey),
           let decoded = try? JSONDecoder().decode([String: HourlyPattern].self, from: hourlyData) {
            hourlyPatterns = decoded
        }

        if let dailyData = UserDefaults.standard.data(forKey: dailyPatternsKey),
           let decoded = try? JSONDecoder().decode([DailyPattern].self, from: dailyData) {
            dailyPatterns = decoded
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a pattern deviation is detected
    static let patternDeviationDetected = Notification.Name("com.wellnesscheck.patternDeviationDetected")
}
