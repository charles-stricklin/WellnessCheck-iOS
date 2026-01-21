//
//  WellnessCheckApp.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.6.0 (2026-01-17)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  UPDATE 2026-01-20: Added Apple Watch fall alert handling.
//  WatchConnectivityService receives fall alerts from watch companion app.
//  Alerts are processed and SMS sent to Care Circle when watch countdown expires.
//
//  UPDATE 2026-01-17: Added fall detection lifecycle management.
//  FallDetectionService starts/stops based on app active state.
//
//  UPDATE 2026-01-15: Added Firebase initialization for backend services.
//  Firebase Auth, Firestore, and Cloud Messaging configured via AppDelegate.
//
//  UPDATE 2026-01-13: Added splash screen that displays briefly before
//  showing the main dashboard (only after onboarding is complete).
//  Added fade-to-black transition when app backgrounds/foregrounds or
//  after a period of inactivity.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseCrashlytics
import UserNotifications
import Combine
import BackgroundTasks

// MARK: - App Delegate

/// AppDelegate handles Firebase initialization, notification setup, and any other
/// setup that needs to happen before the SwiftUI lifecycle kicks in.
/// Firebase must be configured early in the app lifecycle before any other Firebase services are used.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase services
        // This must happen before any Firebase Auth, Firestore, or other calls
        FirebaseApp.configure()

        // Crashlytics is automatically initialized after FirebaseApp.configure()
        // Uncomment below to disable crash collection in debug builds:
        // #if DEBUG
        // Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        // #endif

        // Set up notification delegate to handle notification taps
        UNUserNotificationCenter.current().delegate = self

        // Register notification categories with actions
        registerNotificationCategories()

        // Register background tasks for inactivity monitoring
        // This MUST be called before the app finishes launching
        BackgroundTaskService.shared.registerBackgroundTasks()

        return true
    }

    // MARK: - Notification Categories

    /// Register notification categories so we can handle user actions from notifications
    private func registerNotificationCategories() {
        // "I'm OK" action for check-in notifications
        let imOkAction = UNNotificationAction(
            identifier: "IM_OK_ACTION",
            title: "I'm OK",
            options: [.foreground]
        )

        // Check-in category (shown when approaching silence threshold)
        let checkInCategory = UNNotificationCategory(
            identifier: "CHECK_IN",
            actions: [imOkAction],
            intentIdentifiers: [],
            options: []
        )

        // Urgent check-in category (shown when threshold exceeded)
        let urgentCategory = UNNotificationCategory(
            identifier: "URGENT_CHECK_IN",
            actions: [imOkAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([checkInCategory, urgentCategory])
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is delivered while the app is in foreground
    /// We show the notification anyway so user sees the check-in prompt
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when user taps on a notification or selects an action
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        // Handle "I'm OK" action from check-in notifications
        if actionIdentifier == "IM_OK_ACTION" ||
           (actionIdentifier == UNNotificationDefaultActionIdentifier &&
            (categoryIdentifier == "CHECK_IN" || categoryIdentifier == "URGENT_CHECK_IN")) {
            // User responded to check-in — record activity and reset alert state
            Task { @MainActor in
                NegativeSpaceService.shared.userRespondedToCheckIn()
            }
        }

        completionHandler()
    }
}

@main
struct WellnessCheckApp: App {
    // MARK: - Properties

    /// Connect the AppDelegate to handle Firebase initialization
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @Environment(\.scenePhase) private var scenePhase

    /// Tracks whether user has completed onboarding
    @AppStorage(Constants.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false

    /// User's selected language preference (defaults to English)
    @AppStorage(Constants.selectedLanguageKey) private var selectedLanguage = "en"

    /// Controls whether the splash screen is showing (post-onboarding launches only)
    @State private var showingSplash = true

    /// Tracks whether user is signed in to Firebase
    @State private var isSignedIn = false

    /// Controls the fade-to-black overlay when app backgrounds or is inactive
    @State private var isObscured = false

    /// Timer for inactivity-based fade
    @State private var inactivityTimer: Timer?

    /// How long before the screen fades to black due to inactivity (seconds)
    private let inactivityTimeout: TimeInterval = 30

    /// Care Circle ViewModel for alert sending
    @StateObject private var careCircleViewModel = CareCircleViewModel()

    /// Cloud Functions service for sending SMS alerts
    @StateObject private var cloudFunctions = CloudFunctionsService()

    /// User's name for alert messages
    @AppStorage(Constants.userNameKey) private var userName = ""

    /// Combine cancellables for notification observers
    @State private var cancellables = Set<AnyCancellable>()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if hasCompletedOnboarding {
                        // Post-onboarding: check authentication
                        if isSignedIn {
                            // Signed in: show splash briefly, then dashboard
                            if showingSplash {
                                SplashView {
                                    // Splash duration complete — transition to dashboard
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingSplash = false
                                    }
                                }
                            } else {
                                MainDashboardView()
                            }
                        } else {
                            // Not signed in: show auth screen
                            AuthView {
                                // User authenticated — proceed to dashboard
                                isSignedIn = true
                                showingSplash = false
                            }
                        }
                    } else {
                        // Show onboarding flow for new users
                        OnboardingContainerView {
                            // When onboarding is complete, update the flag
                            // Splash will show on next launch, not immediately after onboarding
                            hasCompletedOnboarding = true
                            showingSplash = false
                        }
                    }
                }
                // Apply the user's selected language to all views
                .environment(\.locale, Locale(identifier: selectedLanguage))
                // Force view recreation when onboarding state changes
                .id(hasCompletedOnboarding)
                // Reset inactivity timer on any touch interaction
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            startInactivityTimer()
                        }
                )

                // Fade-to-black overlay when app is not active or user is inactive
                // Provides smooth transition and obscures sensitive data in app switcher
                Color.black
                    .ignoresSafeArea()
                    .opacity(isObscured ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isObscured)
                    .allowsHitTesting(isObscured) // Only intercept touches when visible
                    .onTapGesture {
                        // Tap on black overlay wakes the screen
                        wakeScreen()
                    }
            }
            .onAppear {
                startInactivityTimer()
                // Check if user is already signed in from a previous session
                isSignedIn = Auth.auth().currentUser != nil
                // Set up alert notification observers
                setupAlertObservers()
                // Initialize WatchConnectivity to receive fall alerts from Apple Watch
                // Accessing the singleton starts WCSession activation
                _ = WatchConnectivityService.shared
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    // App became active — fade in from black and restart timer
                    wakeScreen()
                    // Start fall detection when app is active
                    FallDetectionService.shared.startMonitoring()
                    // Start battery monitoring
                    BatteryService.shared.startMonitoring()
                    // Start negative space (inactivity) monitoring
                    NegativeSpaceService.shared.startMonitoring()
                    // Record that app was opened (activity signal)
                    NegativeSpaceService.shared.recordActivity(.appOpen)
                case .inactive:
                    // App becoming inactive — fade to black
                    inactivityTimer?.invalidate()
                    isObscured = true

                case .background:
                    // App going to background — stop foreground-only services
                    inactivityTimer?.invalidate()
                    isObscured = true
                    // Stop fall detection (requires continuous accelerometer, not possible in background)
                    FallDetectionService.shared.stopMonitoring()
                    // Schedule background tasks for inactivity monitoring
                    BackgroundTaskService.shared.scheduleBackgroundTasks()
                @unknown default:
                    break
                }
            }
            .onChange(of: hasCompletedOnboarding) { oldValue, newValue in
                if !newValue {
                    // Onboarding was reset — prepare for fresh start
                    // Next time onboarding completes and app relaunches, show splash
                    showingSplash = true
                    // Make sure screen isn't obscured so user sees onboarding
                    isObscured = false
                }
            }
        }
    }

    // MARK: - Private Methods

    /// Wake the screen and restart the inactivity timer
    private func wakeScreen() {
        isObscured = false
        startInactivityTimer()
    }

    /// Start or restart the inactivity timer
    private func startInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout, repeats: false) { _ in
            // No interaction for timeout period — fade to black
            withAnimation(.easeInOut(duration: 0.5)) {
                isObscured = true
            }
        }
    }

    /// Set up observers for inactivity, pattern deviation, and watch fall alerts
    /// These trigger SMS alerts to Care Circle when thresholds are exceeded
    private func setupAlertObservers() {
        // Listen for inactivity threshold exceeded
        NotificationCenter.default.publisher(for: .inactivityAlertTriggered)
            .receive(on: DispatchQueue.main)
            .sink { [self] _ in
                Task {
                    await sendInactivityAlert()
                }
            }
            .store(in: &cancellables)

        // Listen for pattern deviation detected
        NotificationCenter.default.publisher(for: .patternDeviationDetected)
            .receive(on: DispatchQueue.main)
            .sink { [self] notification in
                Task {
                    await sendPatternDeviationAlert(userInfo: notification.userInfo)
                }
            }
            .store(in: &cancellables)

        // Listen for fall alerts from Apple Watch
        // Watch app detects fall → shows countdown → sends alert if user doesn't respond
        NotificationCenter.default.publisher(for: .watchFallAlertReceived)
            .receive(on: DispatchQueue.main)
            .sink { [self] notification in
                Task {
                    await sendWatchFallAlert(userInfo: notification.userInfo)
                }
            }
            .store(in: &cancellables)
    }

    /// Send SMS alert to Care Circle when inactivity threshold is exceeded
    private func sendInactivityAlert() async {
        // Don't send if no Care Circle members
        guard !careCircleViewModel.members.isEmpty else {
            print("⚠️ No Care Circle members to alert for inactivity")
            return
        }

        // Get location context if available
        let locationService = LocationService.shared
        var alertLocation: AlertLocation? = nil

        if let home = locationService.loadHomeLocation() {
            // Check if user is currently at home (within home radius)
            let isHome = locationService.isAtHome()
            alertLocation = AlertLocation(
                address: home.address ?? "Location set",
                isHome: isHome
            )
        }

        // Send alert via Cloud Functions → Twilio
        let result = await cloudFunctions.sendAlert(
            userName: userName.isEmpty ? "WellnessCheck User" : userName,
            alertType: .inactivity,
            location: alertLocation,
            members: careCircleViewModel.members
        )

        if result.success {
            print("✅ Inactivity alert sent to \(result.sent) Care Circle members")
            // Update NegativeSpaceService state
            NegativeSpaceService.shared.state = .alertSent
        } else {
            print("❌ Failed to send inactivity alert: \(result.error ?? "Unknown error")")
        }
    }

    /// Send SMS alert to Care Circle when pattern deviation is detected
    private func sendPatternDeviationAlert(userInfo: [AnyHashable: Any]?) async {
        // Don't send if no Care Circle members
        guard !careCircleViewModel.members.isEmpty else {
            print("⚠️ No Care Circle members to alert for pattern deviation")
            return
        }

        // Extract deviation details from notification (for logging)
        let deviationDescription = userInfo?["description"] as? String ?? "Unusual activity pattern detected"
        print("📊 Pattern deviation: \(deviationDescription)")

        // Get location context if available
        let locationService = LocationService.shared
        var alertLocation: AlertLocation? = nil

        if let home = locationService.loadHomeLocation() {
            let isHome = locationService.isAtHome()
            alertLocation = AlertLocation(
                address: home.address ?? "Location set",
                isHome: isHome
            )
        }

        // Send alert via Cloud Functions → Twilio
        // Using missedCheckin type since pattern deviation is conceptually similar
        let result = await cloudFunctions.sendAlert(
            userName: userName.isEmpty ? "WellnessCheck User" : userName,
            alertType: .missedCheckin,
            location: alertLocation,
            members: careCircleViewModel.members
        )

        if result.success {
            print("✅ Pattern deviation alert sent to \(result.sent) Care Circle members")
        } else {
            print("❌ Failed to send pattern deviation alert: \(result.error ?? "Unknown error")")
        }
    }

    /// Send SMS alert to Care Circle when Apple Watch detects fall and countdown expires
    /// The watch handles fall detection 24/7 and relays alerts to iPhone for SMS sending
    private func sendWatchFallAlert(userInfo: [AnyHashable: Any]?) async {
        // Don't send if no Care Circle members
        guard !careCircleViewModel.members.isEmpty else {
            print("⚠️ No Care Circle members to alert for watch fall")
            return
        }

        // Extract fall details from notification (for logging)
        let timestamp = userInfo?["timestamp"] as? Date ?? Date()
        let peakAcceleration = userInfo?["peakAcceleration"] as? Double ?? 0
        print("⌚ Processing watch fall alert - timestamp: \(timestamp), peak acceleration: \(peakAcceleration)")

        // Get location context if available
        let locationService = LocationService.shared
        var alertLocation: AlertLocation? = nil

        if let home = locationService.loadHomeLocation() {
            let isHome = locationService.isAtHome()
            alertLocation = AlertLocation(
                address: home.address ?? "Location set",
                isHome: isHome
            )
        }

        // Send alert via Cloud Functions → Twilio
        // Use .fall alert type since this is a fall detection event
        let result = await cloudFunctions.sendAlert(
            userName: userName.isEmpty ? "WellnessCheck User" : userName,
            alertType: .fall,
            location: alertLocation,
            members: careCircleViewModel.members
        )

        if result.success {
            print("✅ Watch fall alert sent to \(result.sent) Care Circle members")
        } else {
            print("❌ Failed to send watch fall alert: \(result.error ?? "Unknown error")")
        }
    }
}
