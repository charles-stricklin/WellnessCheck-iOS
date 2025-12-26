//
//  WellnessCheckApp.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import SwiftUI

@main
struct WellnessCheckApp: App {
    // MARK: - Properties

    /// Tracks whether user has completed onboarding
    @AppStorage(Constants.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                // Show main app dashboard after onboarding
                MainDashboardView()
            } else {
                // Show onboarding flow for new users
                OnboardingContainerView {
                    // When onboarding is complete, update the flag
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
