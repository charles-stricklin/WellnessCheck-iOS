//
//  WellnessCheckApp.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.3.0 (2026-01-13)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  UPDATE 2026-01-13: Added splash screen that displays briefly before
//  showing the main dashboard (only after onboarding is complete).
//  Added fade-to-black transition when app backgrounds/foregrounds or
//  after a period of inactivity.
//

import SwiftUI

@main
struct WellnessCheckApp: App {
    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase

    /// Tracks whether user has completed onboarding
    @AppStorage(Constants.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false

    /// User's selected language preference (defaults to English)
    @AppStorage(Constants.selectedLanguageKey) private var selectedLanguage = "en"

    /// Controls whether the splash screen is showing (post-onboarding launches only)
    @State private var showingSplash = true

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
                        // Post-onboarding: show splash briefly, then dashboard
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
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    // App became active — fade in from black and restart timer
                    wakeScreen()
                case .inactive, .background:
                    // App going to background or inactive — fade to black immediately
                    inactivityTimer?.invalidate()
                    isObscured = true
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
