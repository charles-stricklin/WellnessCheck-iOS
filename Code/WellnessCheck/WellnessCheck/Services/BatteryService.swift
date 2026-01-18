//
//  BatteryService.swift
//  WellnessCheck
//
//  Created: v0.6.0 (2026-01-17)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Monitors device battery level and charging state.
//  Battery context is crucial for interpreting "negative space" — if the phone
//  died, that explains the silence and isn't an emergency.
//
//  WHY THIS MATTERS:
//  When analyzing activity gaps (negative space), we need to know if the phone
//  was simply dead. A gap with "last known battery: 3%" is very different from
//  a gap with "last known battery: 85%". The former suggests the phone died;
//  the latter suggests something may be wrong.
//
//  WHAT WE TRACK:
//  - Current battery level (0-100%)
//  - Charging state (unplugged, charging, full)
//  - Battery level history (for pattern analysis)
//  - Low battery warnings
//

import Foundation
import UIKit
import Combine

/// Battery charging state
enum BatteryState: String, Codable {
    case unknown
    case unplugged
    case charging
    case full

    init(from uiState: UIDevice.BatteryState) {
        switch uiState {
        case .unknown:
            self = .unknown
        case .unplugged:
            self = .unplugged
        case .charging:
            self = .charging
        case .full:
            self = .full
        @unknown default:
            self = .unknown
        }
    }
}

/// A snapshot of battery status at a point in time
struct BatterySnapshot: Codable {
    let timestamp: Date
    let level: Int          // 0-100
    let state: BatteryState
    let isLowPowerMode: Bool
}

/// Service for monitoring device battery status
@MainActor
class BatteryService: ObservableObject {

    // MARK: - Singleton

    static let shared = BatteryService()

    // MARK: - Published Properties

    /// Current battery level (0-100), or -1 if unavailable
    @Published var batteryLevel: Int = -1

    /// Current charging state
    @Published var batteryState: BatteryState = .unknown

    /// Whether Low Power Mode is enabled
    @Published var isLowPowerMode: Bool = false

    /// Whether battery is critically low (<10%)
    @Published var isCriticallyLow: Bool = false

    /// Whether battery monitoring is enabled
    @Published var isMonitoring: Bool = false

    // MARK: - Private Properties

    /// History of battery snapshots for pattern analysis
    private var batteryHistory: [BatterySnapshot] = []

    /// Maximum number of snapshots to keep (24 hours at 15-min intervals = 96)
    private let maxHistoryCount = 100

    /// UserDefaults key for persisting battery history
    private let historyKey = "batteryHistory"

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        loadHistory()
    }

    // MARK: - Public Methods

    /// Start monitoring battery status
    /// Call this when the app becomes active
    func startMonitoring() {
        guard !isMonitoring else { return }

        // Enable battery monitoring on the device
        UIDevice.current.isBatteryMonitoringEnabled = true

        // Get initial values
        updateBatteryStatus()

        // Listen for battery level changes
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateBatteryStatus()
            }
            .store(in: &cancellables)

        // Listen for charging state changes
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateBatteryStatus()
            }
            .store(in: &cancellables)

        // Listen for Low Power Mode changes
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
            .store(in: &cancellables)

        isMonitoring = true
        print("🔋 Battery monitoring started")
    }

    /// Stop monitoring battery status
    func stopMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = false
        cancellables.removeAll()
        isMonitoring = false
        print("🔋 Battery monitoring stopped")
    }

    /// Take a snapshot of current battery state and add to history
    func recordSnapshot() {
        let snapshot = BatterySnapshot(
            timestamp: Date(),
            level: batteryLevel,
            state: batteryState,
            isLowPowerMode: isLowPowerMode
        )

        batteryHistory.append(snapshot)

        // Trim history if needed
        if batteryHistory.count > maxHistoryCount {
            batteryHistory.removeFirst(batteryHistory.count - maxHistoryCount)
        }

        saveHistory()
    }

    /// Get the last known battery level before a given time
    /// Useful for understanding gaps in activity
    func lastKnownLevel(before date: Date) -> BatterySnapshot? {
        return batteryHistory
            .filter { $0.timestamp < date }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    /// Check if battery was likely dead during a time period
    /// Returns true if last known level before the gap was critically low
    func wasBatteryLikelyDead(gapStart: Date) -> Bool {
        guard let lastSnapshot = lastKnownLevel(before: gapStart) else {
            return false
        }

        // If battery was under 5% and unplugged, it probably died
        return lastSnapshot.level <= 5 && lastSnapshot.state == .unplugged
    }

    /// Get battery drain rate over the last hour (percentage per hour)
    /// Returns nil if not enough data
    func recentDrainRate() -> Double? {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentSnapshots = batteryHistory.filter { $0.timestamp > oneHourAgo }

        guard recentSnapshots.count >= 2,
              let oldest = recentSnapshots.first,
              let newest = recentSnapshots.last,
              oldest.state == .unplugged // Only calculate drain when unplugged
        else {
            return nil
        }

        let levelDrop = oldest.level - newest.level
        let timeDiff = newest.timestamp.timeIntervalSince(oldest.timestamp) / 3600 // hours

        guard timeDiff > 0 else { return nil }

        return Double(levelDrop) / timeDiff
    }

    // MARK: - Private Methods

    /// Update battery status from device
    private func updateBatteryStatus() {
        let device = UIDevice.current

        // Battery level is -1.0 if monitoring not enabled, otherwise 0.0-1.0
        let rawLevel = device.batteryLevel
        batteryLevel = rawLevel < 0 ? -1 : Int(rawLevel * 100)

        batteryState = BatteryState(from: device.batteryState)
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        isCriticallyLow = batteryLevel >= 0 && batteryLevel < 10

        // Auto-record snapshot on significant changes
        if let lastSnapshot = batteryHistory.last {
            let levelChange = abs(batteryLevel - lastSnapshot.level)
            let stateChanged = batteryState != lastSnapshot.state

            // Record if level changed by 5% or more, or state changed
            if levelChange >= 5 || stateChanged {
                recordSnapshot()
            }
        } else {
            // First snapshot
            recordSnapshot()
        }
    }

    /// Save battery history to UserDefaults
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(batteryHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    /// Load battery history from UserDefaults
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([BatterySnapshot].self, from: data) {
            batteryHistory = decoded
        }
    }
}
