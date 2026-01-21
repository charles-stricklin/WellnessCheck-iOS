//
//  FallDetectionManager.swift
//  WellnessCheckWatch Watch App
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Wraps Apple's CMFallDetectionManager for fall detection.
//  When a fall is detected, shows alert UI with countdown.
//  If user doesn't respond, sends alert to iPhone via WatchConnectivity.
//
//  IMPORTANT: CMFallDetectionManager requires:
//  - Apple Watch Series 4 or later
//  - watchOS 9.0 or later
//  - NSFallDetectionUsageDescription in Info.plist
//

import Foundation
import Combine
import CoreMotion
import WatchConnectivity
import WatchKit

/// Manages fall detection and alert state for the watch app
@MainActor
class FallDetectionManager: NSObject, ObservableObject {

    // MARK: - Published State

    /// Whether a fall has been detected and alert is showing
    @Published var fallDetected: Bool = false

    /// Countdown seconds remaining (30 second countdown)
    @Published var countdownSeconds: Int = 30

    /// Whether fall detection is available on this device
    @Published var isAvailable: Bool = false

    /// Status message for UI
    @Published var statusMessage: String = "Starting..."

    // MARK: - Private Properties

    /// Apple's fall detection manager (does the heavy lifting)
    private var fallManager: CMFallDetectionManager?

    /// WatchConnectivity session for communicating with iPhone
    private var wcSession: WCSession?

    /// Timer for countdown
    private var countdownTimer: Timer?

    /// Timestamp when fall was detected
    private var fallTimestamp: Date?

    /// Peak acceleration from fall event (for reporting)
    private var peakAcceleration: Double = 0

    // MARK: - Constants

    private let countdownDuration = 30 // seconds

    // MARK: - Initialization

    override init() {
        super.init()
        setupFallDetection()
        setupWatchConnectivity()
    }

    // MARK: - Setup

    /// Initialize CMFallDetectionManager if available
    private func setupFallDetection() {
        // Check if fall detection is available (Series 4+, watchOS 9+)
        guard CMFallDetectionManager.isAvailable else {
            isAvailable = false
            statusMessage = "Fall detection not available"
            print("⌚ CMFallDetectionManager not available on this device")
            return
        }

        isAvailable = true
        fallManager = CMFallDetectionManager()
        fallManager?.delegate = self
        statusMessage = "Monitoring Active"
        print("⌚ Fall detection started")
    }

    /// Initialize WatchConnectivity for iPhone communication
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("⌚ WatchConnectivity not supported")
            return
        }

        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()
        print("⌚ WatchConnectivity activating...")
    }

    // MARK: - Public Methods

    /// User tapped "I'm OK" button
    func userRespondedOK() {
        print("⌚ User responded OK")

        // Stop countdown
        countdownTimer?.invalidate()
        countdownTimer = nil

        // Reset state
        fallDetected = false
        countdownSeconds = countdownDuration
        statusMessage = "Monitoring Active"

        // Notify iPhone that user is OK (optional, for logging)
        sendToiPhone(userResponded: true)

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
    }

    // MARK: - Private Methods

    /// Called when fall is detected by CMFallDetectionManager
    private func handleFallDetected(event: CMFallDetectionEvent) {
        print("⌚ Fall detected at \(event.date)")

        fallTimestamp = event.date
        fallDetected = true
        countdownSeconds = countdownDuration
        statusMessage = "Fall Detected"

        // Strong haptic to get attention
        WKInterfaceDevice.current().play(.notification)

        // Start countdown
        startCountdown()
    }

    /// Start the countdown timer
    private func startCountdown() {
        countdownTimer?.invalidate()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.countdownTick()
            }
        }
    }

    /// Called every second during countdown
    private func countdownTick() {
        countdownSeconds -= 1

        // Haptic every 5 seconds
        if countdownSeconds % 5 == 0 && countdownSeconds > 0 {
            WKInterfaceDevice.current().play(.notification)
        }

        // Countdown expired
        if countdownSeconds <= 0 {
            countdownExpired()
        }
    }

    /// Called when countdown reaches zero without user response
    private func countdownExpired() {
        print("⌚ Countdown expired - sending alert to iPhone")

        countdownTimer?.invalidate()
        countdownTimer = nil

        statusMessage = "Alerting Care Circle..."

        // Send alert to iPhone
        sendToiPhone(userResponded: false)

        // Keep alert UI showing briefly, then reset
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await MainActor.run {
                self.fallDetected = false
                self.countdownSeconds = self.countdownDuration
                self.statusMessage = "Alert Sent"

                // Reset status after a few more seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    await MainActor.run {
                        self.statusMessage = "Monitoring Active"
                    }
                }
            }
        }
    }

    /// Send fall alert to iPhone via WatchConnectivity
    private func sendToiPhone(userResponded: Bool) {
        guard let session = wcSession,
              session.activationState == .activated else {
            print("⌚ WCSession not activated - cannot send to iPhone")
            return
        }

        // Create payload
        let payload: [String: Any] = [
            "fallAlert": [
                "timestamp": (fallTimestamp ?? Date()).timeIntervalSince1970,
                "peakAcceleration": peakAcceleration,
                "userResponded": userResponded
            ]
        ]

        // Try immediate message if iPhone is reachable
        if session.isReachable {
            session.sendMessage(payload, replyHandler: { reply in
                print("⌚ iPhone acknowledged fall alert")
            }, errorHandler: { error in
                print("⌚ Failed to send message: \(error.localizedDescription)")
                // Fall back to transferUserInfo
                session.transferUserInfo(payload)
            })
        } else {
            // iPhone not reachable - queue for later delivery
            print("⌚ iPhone not reachable - queueing alert")
            session.transferUserInfo(payload)
        }
    }
}

// MARK: - CMFallDetectionDelegate

extension FallDetectionManager: CMFallDetectionDelegate {

    /// Called by CMFallDetectionManager when a fall is detected
    nonisolated func fallDetectionManager(
        _ manager: CMFallDetectionManager,
        didDetect event: CMFallDetectionEvent,
        completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            self.handleFallDetected(event: event)
        }
        completionHandler()
    }
}

// MARK: - WCSessionDelegate

extension FallDetectionManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("⌚ WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("⌚ WCSession activated: \(activationState.rawValue)")
        }
    }
}
