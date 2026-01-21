//
//  WatchConnectivityService.swift
//  WellnessCheck
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Handles communication between the iPhone app and Apple Watch companion.
//  Uses WatchConnectivity framework to sync Care Circle members and settings,
//  and to receive fall alert notifications from the watch.
//
//  SYNC STRATEGY:
//  - Application Context: Used for Care Circle and settings (always delivers latest)
//  - sendMessage: Used for real-time events when watch is reachable
//  - transferUserInfo: Used for queued delivery when watch isn't immediately available
//
//  WHY THIS EXISTS:
//  The Apple Watch app needs Care Circle data to display alerts and send SMS.
//  This service keeps the watch in sync whenever Care Circle changes on iPhone.
//

import Foundation
import WatchConnectivity
import Combine

/// Service for managing WatchConnectivity between iPhone and Apple Watch
/// Syncs Care Circle members, settings, and handles fall alerts from watch
@MainActor
class WatchConnectivityService: NSObject, ObservableObject {

    // MARK: - Singleton

    static let shared = WatchConnectivityService()

    // MARK: - Published Properties

    /// Whether an Apple Watch is paired with this iPhone
    @Published var isPaired: Bool = false

    /// Whether the Watch app is installed
    @Published var isWatchAppInstalled: Bool = false

    /// Whether the Watch is currently reachable for real-time messages
    @Published var isReachable: Bool = false

    /// Last time Care Circle was synced to watch
    @Published var lastSyncDate: Date?

    /// Any error that occurred during sync
    @Published var syncError: String?

    // MARK: - Private Properties

    /// The WatchConnectivity session (nil if not supported)
    private var session: WCSession?

    /// Combine cancellables for observing Care Circle changes
    private var cancellables = Set<AnyCancellable>()

    /// User defaults for reading settings
    private let userDefaults = UserDefaults.standard

    // MARK: - Initialization

    private override init() {
        super.init()

        // Only set up WatchConnectivity if supported on this device
        // (All iPhones support it, but good to check)
        guard WCSession.isSupported() else {
            print("⌚ WatchConnectivity not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()

        print("⌚ WatchConnectivity session activating...")

        // Listen for Care Circle changes to auto-sync
        setupCareCircleObserver()
    }

    // MARK: - Public Methods

    /// Sync Care Circle members to the Apple Watch
    /// Call this whenever Care Circle changes (add, edit, delete members)
    /// - Parameter members: The current list of Care Circle members
    func syncCareCircle(_ members: [CareCircleMember]) {
        guard let session = session,
              session.activationState == .activated else {
            print("⌚ Cannot sync - WCSession not activated")
            return
        }

        guard session.isPaired else {
            print("⌚ Cannot sync - No Apple Watch paired")
            return
        }

        // Convert to lightweight watch-compatible format (no imageData)
        let watchMembers = members.map { member in
            WatchCareCircleMember(from: member)
        }

        // Build sync payload with current settings
        let userName = userDefaults.string(forKey: "userName") ?? ""
        let fallDetectionEnabled = userDefaults.bool(forKey: "monitoring_fallDetection")
        let silenceThreshold = userDefaults.double(forKey: "monitoring_silenceThreshold")

        let payload = WatchSyncPayload(
            userName: userName,
            members: watchMembers,
            fallDetectionEnabled: fallDetectionEnabled,
            silenceThresholdHours: silenceThreshold > 0 ? silenceThreshold : 4.0,
            syncedAt: Date()
        )

        // Encode payload to data for transfer
        do {
            let encoder = JSONEncoder()
            let payloadData = try encoder.encode(payload)

            // Use Application Context for persistent sync
            // This ensures watch always has latest data even if it wasn't reachable
            try session.updateApplicationContext([
                WatchMessageKey.careCircleSync.rawValue: payloadData
            ])

            lastSyncDate = Date()
            syncError = nil
            print("⌚ Care Circle synced to watch: \(watchMembers.count) members")

            // Post notification for UI updates
            NotificationCenter.default.post(name: .watchSyncCompleted, object: nil)

        } catch {
            syncError = error.localizedDescription
            print("⌚ Failed to sync Care Circle: \(error.localizedDescription)")
        }
    }

    /// Send an immediate message to watch (only works if watch is reachable)
    /// Use for time-sensitive data that needs immediate delivery
    /// - Parameter message: Dictionary of data to send
    /// - Returns: True if message was sent, false if watch not reachable
    @discardableResult
    func sendImmediateMessage(_ message: [String: Any]) -> Bool {
        guard let session = session,
              session.isReachable else {
            print("⌚ Watch not reachable for immediate message")
            return false
        }

        session.sendMessage(message, replyHandler: nil) { error in
            print("⌚ Failed to send immediate message: \(error.localizedDescription)")
        }
        return true
    }

    /// Handle a fall alert received from the watch
    /// Called when watch detects fall and countdown expires without user response
    /// - Parameter payload: The fall alert data from watch
    func handleWatchFallAlert(_ payload: WatchFallAlertPayload) {
        if payload.userResponded {
            // User tapped "I'm OK" on watch - just log it
            print("⌚ User responded OK to fall alert on watch")
        } else {
            // Countdown expired - need to send alert via iPhone
            print("⌚ Fall alert from watch - user didn't respond, triggering SMS")

            // Post notification so WellnessCheckApp can handle alert sending
            // This reuses existing alert infrastructure
            NotificationCenter.default.post(
                name: .watchFallAlertReceived,
                object: nil,
                userInfo: [
                    "timestamp": payload.timestamp,
                    "peakAcceleration": payload.peakAcceleration
                ]
            )
        }
    }

    // MARK: - Private Methods

    /// Set up observer to auto-sync when Care Circle changes
    private func setupCareCircleObserver() {
        NotificationCenter.default.publisher(for: .careCircleDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                // Extract members from notification if provided
                if let members = notification.object as? [CareCircleMember] {
                    self?.syncCareCircle(members)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {

    /// Called when session activation completes
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                print("⌚ WCSession activation failed: \(error.localizedDescription)")
                return
            }

            switch activationState {
            case .activated:
                print("⌚ WCSession activated successfully")
                self.isPaired = session.isPaired
                self.isWatchAppInstalled = session.isWatchAppInstalled
                self.isReachable = session.isReachable

                // Post notification about connection state
                NotificationCenter.default.post(name: .watchConnectionStateChanged, object: nil)

            case .inactive:
                print("⌚ WCSession inactive")
            case .notActivated:
                print("⌚ WCSession not activated")
            @unknown default:
                break
            }
        }
    }

    /// Called when session becomes inactive (iOS only, for handoff)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("⌚ WCSession became inactive")
    }

    /// Called when session is deactivated (iOS only, for handoff)
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("⌚ WCSession deactivated - reactivating")
        // Reactivate session after deactivation (required for proper handoff)
        session.activate()
    }

    /// Called when watch reachability changes
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("⌚ Watch reachability changed: \(session.isReachable)")
        }
    }

    /// Called when a message is received from watch
    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        Task { @MainActor in
            handleIncomingMessage(message)
        }
    }

    /// Called when a message with reply handler is received from watch
    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            handleIncomingMessage(message)
            // Acknowledge receipt
            replyHandler(["received": true])
        }
    }

    /// Called when user info is received from watch
    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any]
    ) {
        Task { @MainActor in
            handleIncomingMessage(userInfo)
        }
    }

    /// Process incoming message from watch
    @MainActor
    private func handleIncomingMessage(_ message: [String: Any]) {
        // Check for fall alert
        if let fallAlertData = message[WatchMessageKey.fallAlert.rawValue] as? Data {
            do {
                let decoder = JSONDecoder()
                let payload = try decoder.decode(WatchFallAlertPayload.self, from: fallAlertData)
                handleWatchFallAlert(payload)
            } catch {
                print("⌚ Failed to decode fall alert: \(error)")
            }
        }

        // Check for user responded OK
        if message[WatchMessageKey.userRespondedOK.rawValue] != nil {
            print("⌚ User responded OK on watch")
            // Could update UI or log activity here
        }
    }
}

// MARK: - Temporary Type Definitions
// These duplicate types from WellnessCheckShared until the package is integrated
// TODO: Remove these once the shared package is added to the Xcode project

/// Lightweight version of CareCircleMember for WatchConnectivity transfer
struct WatchCareCircleMember: Codable, Sendable {
    let id: UUID
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let relationship: String
    let isPrimary: Bool

    init(from member: CareCircleMember) {
        self.id = member.id
        self.firstName = member.firstName
        self.lastName = member.lastName
        self.phoneNumber = member.phoneNumber
        self.relationship = member.relationship
        self.isPrimary = member.isPrimary
    }
}

/// Payload sent from iPhone to Watch with Care Circle and settings
struct WatchSyncPayload: Codable, Sendable {
    let userName: String
    let members: [WatchCareCircleMember]
    let fallDetectionEnabled: Bool
    let silenceThresholdHours: Double
    let syncedAt: Date
}

/// Payload sent from Watch to iPhone when fall is detected
struct WatchFallAlertPayload: Codable, Sendable {
    let timestamp: Date
    let peakAcceleration: Double
    let userResponded: Bool
}

/// Keys used for WatchConnectivity message dictionaries
enum WatchMessageKey: String, Sendable {
    case careCircleSync = "careCircleSync"
    case settingsSync = "settingsSync"
    case userName = "userName"
    case fallAlert = "fallAlert"
    case userRespondedOK = "userRespondedOK"
}

// MARK: - Notification Names Extension
// Temporary until shared package is integrated

extension Notification.Name {
    static let watchConnectionStateChanged = Notification.Name("com.wellnesscheck.watchConnectionStateChanged")
    static let watchSyncCompleted = Notification.Name("com.wellnesscheck.watchSyncCompleted")
    static let watchFallAlertReceived = Notification.Name("com.wellnesscheck.watchFallAlertReceived")
    static let careCircleDidChange = Notification.Name("com.wellnesscheck.careCircleDidChange")
}
