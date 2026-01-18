//
//  WellnessCheckApp.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.6.0 (2026-01-17)
//
//  By Charles Stricklin, Stricklin Development, LLC
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

// MARK: - App Delegate

/// AppDelegate handles Firebase initialization and any other setup that needs
/// to happen before the SwiftUI lifecycle kicks in. Firebase must be configured
/// early in the app lifecycle before any other Firebase services are used.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase services
        // This must happen before any Firebase Auth, Firestore, or other calls
        FirebaseApp.configure()
        return true
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
                case .inactive, .background:
                    // App going to background or inactive — fade to black immediately
                    inactivityTimer?.invalidate()
                    isObscured = true
                    // Stop fall detection when app is not active
                    // (Note: for true background monitoring, would need Background Modes)
                    FallDetectionService.shared.stopMonitoring()
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
}
