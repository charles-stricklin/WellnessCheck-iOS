//
//  User.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import Foundation

/// Represents a solo dweller using the WellnessCheck app
struct User: Codable, Identifiable {
    // MARK: - Properties

    /// Unique identifier (Firebase user ID)
    let id: String

    /// User's full name
    var name: String

    /// User's phone number (primary contact method)
    var phoneNumber: String

    /// Optional email address
    var email: String?

    /// Timestamp when account was created
    let createdAt: Date

    /// Whether monitoring is currently enabled
    var monitoringEnabled: Bool

    /// Last time user checked in or app detected activity
    var lastCheckIn: Date?

    /// User's monitoring and alert settings
    var settings: UserSettings

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        name: String,
        phoneNumber: String,
        email: String? = nil,
        createdAt: Date = Date(),
        monitoringEnabled: Bool = false,
        lastCheckIn: Date? = nil,
        settings: UserSettings = UserSettings()
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.createdAt = createdAt
        self.monitoringEnabled = monitoringEnabled
        self.lastCheckIn = lastCheckIn
        self.settings = settings
    }
}

/// User's configurable settings for monitoring and alerts
struct UserSettings: Codable {
    // MARK: - Safety Monitoring Settings

    /// Hours of inactivity before triggering alert (1-4 hours)
    var inactivityThresholdHours: Int = 2

    /// Enable fall detection monitoring
    var fallDetectionEnabled: Bool = true

    /// Enable wellness concern monitoring (depression patterns)
    var wellnessConcernEnabled: Bool = true

    // MARK: - Do Not Disturb Settings

    /// Enable Do Not Disturb schedule
    var dndEnabled: Bool = false

    /// DND start time (24-hour format, e.g., "22:00")
    var dndStartTime: String = "22:00"

    /// DND end time (24-hour format, e.g., "08:00")
    var dndEndTime: String = "08:00"

    // MARK: - Alert Settings

    /// Countdown seconds before sending emergency alert (30-120)
    var emergencyCountdownSeconds: Int = 60

    /// Enable SMS notifications to Care Circle
    var smsNotificationsEnabled: Bool = true

    /// Enable push notifications to Care Circle (WellnessWatch app)
    var pushNotificationsEnabled: Bool = true

    // MARK: - Wellness Monitoring Settings

    /// Hours of inactivity per day to trigger wellness concern (e.g., 16 hours)
    var wellnessInactivityHoursPerDay: Int = 16

    /// Consecutive days of excessive inactivity before alerting (e.g., 3 days)
    var wellnessConsecutiveDays: Int = 3
}

// MARK: - User Extensions

extension User {
    /// Returns a display-friendly name (first name only or full name)
    var displayName: String {
        let components = name.components(separatedBy: " ")
        return components.first ?? name
    }

    /// Checks if user has completed initial setup
    var hasCompletedSetup: Bool {
        return !name.isEmpty && !phoneNumber.isEmpty
    }

    /// Returns formatted phone number for display
    var formattedPhoneNumber: String {
        // Simple US phone number formatting
        let digits = phoneNumber.filter { $0.isNumber }
        guard digits.count == 10 else { return phoneNumber }

        let areaCode = digits.prefix(3)
        let prefix = digits.dropFirst(3).prefix(3)
        let suffix = digits.dropFirst(6)

        return "(\(areaCode)) \(prefix)-\(suffix)"
    }
}

// MARK: - Sample Data for Previews

extension User {
    /// Sample user for SwiftUI previews
    static let preview = User(
        name: "John Doe",
        phoneNumber: "5551234567",
        email: "john.doe@example.com",
        monitoringEnabled: true,
        lastCheckIn: Date(),
        settings: UserSettings()
    )
}
