//
//  SharedTypes.swift
//  WellnessCheckShared
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Shared types used across iOS and watchOS targets.
//  These define the core data structures for alerts and detection.
//

import Foundation

// MARK: - SMS Result

/// Result of an SMS operation via Cloud Functions
public struct SMSResult: Sendable {
    public let success: Bool
    public let sent: Int
    public let total: Int
    public var error: String?

    public init(success: Bool, sent: Int, total: Int, error: String? = nil) {
        self.success = success
        self.sent = sent
        self.total = total
        self.error = error
    }
}

// MARK: - Alert Types

/// Types of alerts that can be sent to Care Circle
public enum AlertType: String, Sendable {
    case inactivity = "inactivity"      // User hasn't been active for too long
    case fall = "fall"                   // Fall detected
    case missedCheckin = "missed_checkin" // Pattern deviation / missed expected activity
}

/// Location information included with alerts
/// Helps Care Circle understand context (at home vs away)
public struct AlertLocation: Sendable {
    public let address: String
    public let isHome: Bool

    public init(address: String, isHome: Bool) {
        self.address = address
        self.isHome = isHome
    }
}

// MARK: - Fall Detection

/// Represents a detected fall event
/// Created when the fall detection algorithm confirms a fall
public struct FallEvent: Sendable {
    public let timestamp: Date
    public let peakAcceleration: Double  // g-force at impact
    public let stillnessDuration: Double // seconds of stillness after impact

    public init(timestamp: Date, peakAcceleration: Double, stillnessDuration: Double) {
        self.timestamp = timestamp
        self.peakAcceleration = peakAcceleration
        self.stillnessDuration = stillnessDuration
    }
}

/// Current state of fall detection service
/// Used by both iOS FallDetectionService and watchOS WatchFallDetectionService
public enum FallDetectionState: Sendable {
    case disabled           // User has disabled fall detection
    case monitoring         // Actively monitoring for falls
    case impactDetected     // High-g impact detected, checking for stillness
    case fallDetected       // Fall confirmed, awaiting user response
    case alerting           // User didn't respond, alerting Care Circle
    case cancelled          // User responded "I'm OK"
}

// MARK: - WatchConnectivity Messages

/// Keys used for WatchConnectivity message dictionaries
public enum WatchMessageKey: String, Sendable {
    // iPhone → Watch
    case careCircleSync = "careCircleSync"
    case settingsSync = "settingsSync"
    case userName = "userName"

    // Watch → iPhone
    case fallAlert = "fallAlert"
    case userRespondedOK = "userRespondedOK"
}

/// Payload sent from iPhone to Watch with Care Circle and settings
public struct WatchSyncPayload: Codable, Sendable {
    public let userName: String
    public let members: [WatchCareCircleMember]
    public let fallDetectionEnabled: Bool
    public let silenceThresholdHours: Double
    public let syncedAt: Date

    public init(
        userName: String,
        members: [WatchCareCircleMember],
        fallDetectionEnabled: Bool,
        silenceThresholdHours: Double,
        syncedAt: Date = Date()
    ) {
        self.userName = userName
        self.members = members
        self.fallDetectionEnabled = fallDetectionEnabled
        self.silenceThresholdHours = silenceThresholdHours
        self.syncedAt = syncedAt
    }
}

/// Payload sent from Watch to iPhone when fall is detected
public struct WatchFallAlertPayload: Codable, Sendable {
    public let timestamp: Date
    public let peakAcceleration: Double
    public let userResponded: Bool  // true if user tapped "I'm OK", false if countdown expired

    public init(timestamp: Date, peakAcceleration: Double, userResponded: Bool) {
        self.timestamp = timestamp
        self.peakAcceleration = peakAcceleration
        self.userResponded = userResponded
    }
}
