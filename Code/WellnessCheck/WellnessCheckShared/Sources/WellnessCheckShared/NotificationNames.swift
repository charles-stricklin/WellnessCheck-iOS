//
//  NotificationNames.swift
//  WellnessCheckShared
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Shared notification names used across iOS and watchOS targets.
//  Using a central definition prevents typos and ensures consistency.
//

import Foundation

public extension Notification.Name {
    // MARK: - Fall Detection

    /// Posted when a fall is detected, object is FallEvent
    static let fallDetected = Notification.Name("com.wellnesscheck.fallDetected")

    /// Posted when countdown expires and alert should be sent
    static let fallAlertTriggered = Notification.Name("com.wellnesscheck.fallAlertTriggered")

    // MARK: - Inactivity

    /// Posted when inactivity threshold is exceeded
    static let inactivityAlertTriggered = Notification.Name("com.wellnesscheck.inactivityAlertTriggered")

    // MARK: - Pattern Deviation

    /// Posted when unusual activity pattern is detected
    static let patternDeviationDetected = Notification.Name("com.wellnesscheck.patternDeviationDetected")

    // MARK: - Care Circle

    /// Posted when Care Circle members change (add/edit/delete)
    static let careCircleDidChange = Notification.Name("com.wellnesscheck.careCircleDidChange")

    // MARK: - Watch Connectivity

    /// Posted when watch connection state changes
    static let watchConnectionStateChanged = Notification.Name("com.wellnesscheck.watchConnectionStateChanged")

    /// Posted when Care Circle sync to watch completes
    static let watchSyncCompleted = Notification.Name("com.wellnesscheck.watchSyncCompleted")

    /// Posted when fall alert is received from watch
    static let watchFallAlertReceived = Notification.Name("com.wellnesscheck.watchFallAlertReceived")
}
