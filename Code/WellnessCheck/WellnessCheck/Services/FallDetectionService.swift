//
//  FallDetectionService.swift
//  WellnessCheck
//
//  Created: v0.6.0 (2026-01-17)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  CoreMotion-based fall detection service.
//  Monitors accelerometer data for high-g impacts followed by stillness,
//  which is the signature pattern of a fall.
//
//  HOW IT WORKS:
//  1. Continuously monitor accelerometer at 50Hz
//  2. Detect sudden acceleration spike (> 2.5g threshold)
//  3. After spike, check for 3 seconds of stillness (< 0.2g movement)
//  4. If both conditions met, trigger fall alert
//  5. User has 60 seconds to respond "I'm OK"
//  6. If no response, alert Care Circle via Twilio
//
//  LIMITATIONS:
//  - Less accurate than Apple Watch (no barometer, gyroscope fusion)
//  - Requires app to be running (foreground or background)
//  - May have false positives (phone dropped) or false negatives
//  - Battery impact when monitoring continuously
//
//  PRIVACY:
//  - Motion data is processed on-device only
//  - No motion data is stored or transmitted
//  - Only the fall event itself triggers an alert
//

import Foundation
import CoreMotion
import Combine
import UIKit
import AVFoundation

/// Represents a detected fall event
struct FallEvent {
    let timestamp: Date
    let peakAcceleration: Double  // g-force at impact
    let stillnessDuration: Double // seconds of stillness after impact
}

/// Current state of fall detection
enum FallDetectionState {
    case disabled           // User has disabled fall detection
    case monitoring         // Actively monitoring for falls
    case impactDetected     // High-g impact detected, checking for stillness
    case fallDetected       // Fall confirmed, awaiting user response
    case alerting           // User didn't respond, alerting Care Circle
    case cancelled          // User responded "I'm OK"
}

/// Service that monitors for falls using CoreMotion accelerometer data
@MainActor
class FallDetectionService: ObservableObject {

    // MARK: - Singleton

    static let shared = FallDetectionService()

    // MARK: - Published Properties

    /// Current detection state
    @Published var state: FallDetectionState = .disabled

    /// Whether fall detection is currently active
    @Published var isMonitoring: Bool = false

    /// Countdown seconds remaining when fall is detected (60 → 0)
    @Published var countdownSeconds: Int = 60

    /// The most recent fall event (if any)
    @Published var lastFallEvent: FallEvent?

    /// Error message if something goes wrong
    @Published var errorMessage: String?

    // MARK: - Detection Configuration

    /// Acceleration threshold to detect impact (in g-force)
    /// Typical falls register 2.5-4g. Setting slightly lower to catch more events.
    private let impactThreshold: Double = 2.5

    /// Maximum acceleration considered "stillness" after impact
    /// Normal phone on table is ~1g (gravity), so we look for low variance
    private let stillnessThreshold: Double = 0.2

    /// Duration of stillness required to confirm fall (seconds)
    private let requiredStillnessDuration: Double = 3.0

    /// Time user has to respond before alerting Care Circle
    private let responseTimeout: Int = 60

    /// Accelerometer sampling rate (Hz)
    private let sampleRate: Double = 50.0

    // MARK: - Private Properties

    private let motionManager = CMMotionManager()
    private var accelerometerData: [(timestamp: Date, magnitude: Double)] = []
    private var impactTimestamp: Date?
    private var countdownTimer: Timer?
    private var alertSoundTimer: Timer?
    private var audioPlayer: AVAudioPlayer?

    /// Queue for processing motion data
    private let motionQueue = OperationQueue()

    // MARK: - Initialization

    private init() {
        motionQueue.name = "com.wellnesscheck.falldetection"
        motionQueue.maxConcurrentOperationCount = 1

        // Check if accelerometer is available
        if !motionManager.isAccelerometerAvailable {
            errorMessage = "Accelerometer not available on this device"
        }
    }

    // MARK: - Public Methods

    /// Start monitoring for falls
    /// Call this when app becomes active and user has fall detection enabled
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            errorMessage = "Accelerometer not available"
            return
        }

        // Check if user has fall detection enabled
        let fallDetectionEnabled = UserDefaults.standard.bool(forKey: "monitoring_fallDetection")
        guard fallDetectionEnabled else {
            state = .disabled
            return
        }

        guard !isMonitoring else { return } // Already monitoring

        // Configure accelerometer
        motionManager.accelerometerUpdateInterval = 1.0 / sampleRate

        // Start receiving accelerometer updates
        motionManager.startAccelerometerUpdates(to: motionQueue) { [weak self] data, error in
            guard let self = self, let data = data else { return }

            Task { @MainActor in
                self.processAccelerometerData(data)
            }
        }

        isMonitoring = true
        state = .monitoring
        print("📱 Fall detection started")
    }

    /// Stop monitoring for falls
    /// Call this when app goes to background or user disables fall detection
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        isMonitoring = false
        state = .disabled
        accelerometerData.removeAll()
        impactTimestamp = nil
        stopCountdown()
        print("📱 Fall detection stopped")
    }

    /// User responded "I'm OK" - cancel the alert
    func userRespondedOK() {
        stopCountdown()
        stopAlertSound()
        state = .cancelled
        impactTimestamp = nil
        accelerometerData.removeAll()

        // Resume monitoring after a brief pause
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            if UserDefaults.standard.bool(forKey: "monitoring_fallDetection") {
                state = .monitoring
            }
        }

        print("✅ User responded OK - alert cancelled")
    }

    /// Manually trigger fall alert (for testing)
    func triggerTestFall() {
        let testEvent = FallEvent(
            timestamp: Date(),
            peakAcceleration: 3.2,
            stillnessDuration: 3.5
        )
        fallDetected(event: testEvent)
    }

    // MARK: - Private Methods

    /// Process incoming accelerometer data
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        // Calculate total acceleration magnitude (combines x, y, z)
        // Subtract 1g for gravity - we want deviation from rest
        let x = data.acceleration.x
        let y = data.acceleration.y
        let z = data.acceleration.z
        let magnitude = sqrt(x*x + y*y + z*z)

        let dataPoint = (timestamp: Date(), magnitude: magnitude)
        accelerometerData.append(dataPoint)

        // Keep only last 5 seconds of data
        let cutoff = Date().addingTimeInterval(-5)
        accelerometerData.removeAll { $0.timestamp < cutoff }

        switch state {
        case .monitoring:
            // Look for high-g impact
            if magnitude > impactThreshold {
                impactDetected(magnitude: magnitude)
            }

        case .impactDetected:
            // Check if stillness period has been met
            checkForStillness()

        default:
            break
        }
    }

    /// High-g impact detected - start checking for stillness
    private func impactDetected(magnitude: Double) {
        impactTimestamp = Date()
        state = .impactDetected
        print("⚡ Impact detected: \(String(format: "%.1f", magnitude))g")
    }

    /// Check if phone has been still since the impact
    private func checkForStillness() {
        guard let impactTime = impactTimestamp else {
            state = .monitoring
            return
        }

        // Get data since impact
        let dataSinceImpact = accelerometerData.filter { $0.timestamp > impactTime }

        // Need enough data to confirm stillness
        let timeSinceImpact = Date().timeIntervalSince(impactTime)
        guard timeSinceImpact >= requiredStillnessDuration else { return }

        // Calculate variance in acceleration since impact
        let magnitudes = dataSinceImpact.map { abs($0.magnitude - 1.0) } // Deviation from 1g
        let averageDeviation = magnitudes.isEmpty ? 0 : magnitudes.reduce(0, +) / Double(magnitudes.count)

        if averageDeviation < stillnessThreshold {
            // Stillness confirmed - this looks like a fall
            let peakMagnitude = accelerometerData
                .filter { $0.timestamp >= impactTime.addingTimeInterval(-0.5) && $0.timestamp <= impactTime.addingTimeInterval(0.5) }
                .map { $0.magnitude }
                .max() ?? impactThreshold

            let event = FallEvent(
                timestamp: impactTime,
                peakAcceleration: peakMagnitude,
                stillnessDuration: timeSinceImpact
            )

            fallDetected(event: event)
        } else if timeSinceImpact > 5.0 {
            // Too much movement after impact - probably not a fall
            state = .monitoring
            impactTimestamp = nil
            print("📱 Impact followed by movement - not a fall")
        }
    }

    /// Fall confirmed - start the response countdown
    private func fallDetected(event: FallEvent) {
        state = .fallDetected
        lastFallEvent = event
        countdownSeconds = responseTimeout

        print("🚨 FALL DETECTED at \(event.timestamp)")
        print("   Peak acceleration: \(String(format: "%.1f", event.peakAcceleration))g")
        print("   Stillness duration: \(String(format: "%.1f", event.stillnessDuration))s")

        // Play alert sound
        playAlertSound()

        // Vibrate
        triggerHapticFeedback()

        // Start countdown
        startCountdown()

        // Post notification so UI can respond
        NotificationCenter.default.post(name: .fallDetected, object: event)
    }

    /// Start the response countdown timer
    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.countdownSeconds -= 1

                // Haptic every 10 seconds
                if self.countdownSeconds % 10 == 0 {
                    self.triggerHapticFeedback()
                }

                if self.countdownSeconds <= 0 {
                    self.countdownExpired()
                }
            }
        }
    }

    /// Stop the countdown timer
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownSeconds = responseTimeout
    }

    /// Countdown expired - user didn't respond, send alert
    private func countdownExpired() {
        stopCountdown()
        stopAlertSound()
        state = .alerting

        print("⏰ Countdown expired - sending alert to Care Circle")

        // Post notification to trigger alert sending
        NotificationCenter.default.post(name: .fallAlertTriggered, object: lastFallEvent)
    }

    /// Play loud alert sound to get user's attention
    private func playAlertSound() {
        // Use system alarm sound
        AudioServicesPlaySystemSound(SystemSoundID(1005)) // Alarm sound

        // Also try to play a repeating alert
        guard let url = Bundle.main.url(forResource: "fall_alert", withExtension: "mp3") else {
            // Fallback to system sound on repeat
            repeatSystemAlert()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
        } catch {
            repeatSystemAlert()
        }
    }

    /// Fallback: repeat system alert sound
    private func repeatSystemAlert() {
        // Cancel any existing alert sound timer
        alertSoundTimer?.invalidate()

        // Play system sound every 2 seconds
        alertSoundTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Stop repeating if state changed
                guard self.state == .fallDetected else {
                    self.alertSoundTimer?.invalidate()
                    self.alertSoundTimer = nil
                    return
                }
                AudioServicesPlaySystemSound(SystemSoundID(1005))
            }
        }
    }

    /// Stop the alert sound
    private func stopAlertSound() {
        audioPlayer?.stop()
        audioPlayer = nil
        alertSoundTimer?.invalidate()
        alertSoundTimer = nil
    }

    /// Trigger haptic feedback
    private func triggerHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a fall is detected, object is FallEvent
    static let fallDetected = Notification.Name("com.wellnesscheck.fallDetected")

    /// Posted when countdown expires and alert should be sent
    static let fallAlertTriggered = Notification.Name("com.wellnesscheck.fallAlertTriggered")
}
