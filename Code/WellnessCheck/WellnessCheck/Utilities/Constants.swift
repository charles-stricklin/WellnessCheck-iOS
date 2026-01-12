//
//  Constants.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import Foundation

/// App-wide constants for WellnessCheck
struct Constants {

    // MARK: - Design Constants

    /// Minimum touch target size for senior-friendly UI (60x60pt)
    static let minTouchTargetSize: CGFloat = 60

    /// Standard button height
    static let buttonHeight: CGFloat = 70

    /// Standard corner radius for buttons and cards
    static let cornerRadius: CGFloat = 16

    /// Standard spacing between elements
    static let standardSpacing: CGFloat = 20

    /// Large spacing for major sections
    static let largeSpacing: CGFloat = 32

    // MARK: - Font Sizes

    /// Body text minimum size (20pt for readability)
    static let bodyTextSize: CGFloat = 20

    /// Button text size (22pt minimum)
    static let buttonTextSize: CGFloat = 22

    /// Header text size (28pt+)
    static let headerTextSize: CGFloat = 28

    /// Title text size for major headings
    static let titleTextSize: CGFloat = 34

    // MARK: - UserDefaults Keys

    /// Key to check if user has completed onboarding
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    /// Key for user's name
    static let userNameKey = "userName"
    
    /// Key for user's surname
    static let userSurnameKey = "userSurname"

    /// Key for user's phone number
    static let userPhoneKey = "userPhone"
    
    /// Key for user's email address
    static let userEmailKey = "userEmail"

    /// Key for user's home location (stored as JSON-encoded HomeLocation)
    static let homeLocationKey = "homeLocation"

    /// Key for whether home location setup was deferred
    static let homeLocationDeferredKey = "homeLocationDeferred"

    /// Key for user's selected language (en or es)
    static let selectedLanguageKey = "selectedLanguage"

    // MARK: - App Info

    /// App display name
    static let appName = "WellnessCheck"

    /// App tagline
    static let appTagline = "Living alone doesn't mean having to be alone."
}
