//
//  HomeLocationView.swift
//  WellnessCheck
//
//  Created: v0.2.0 (2026-01-10)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Onboarding screen that captures the user's home location using GPS.
//  Follows a hybrid approach: attempts GPS first, allows deferral if not home.
//
//  Flow:
//  1. Request location permission
//  2. If granted, fetch current GPS location and reverse geocode
//  3. Ask "Are you home right now?"
//     - Yes → Save location, continue to next screen
//     - No  → Defer setup, remind them later
//  4. If GPS fails, offer to defer or manually set later
//

import SwiftUI
import CoreLocation

/// Onboarding screen for capturing the user's home location
struct HomeLocationView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var locationService = LocationService.shared
    @Environment(\.colorScheme) var colorScheme

    /// Callback when user is ready to proceed
    let onContinue: () -> Void

    /// Current state of the location setup flow
    @State private var flowState: FlowState = .initial

    /// Address to display (from reverse geocoding)
    @State private var displayAddress: String = ""

    // MARK: - Flow States

    enum FlowState {
        case initial           // Just entered screen
        case requestingPermission
        case fetchingLocation  // GPS in progress
        case confirmHome       // Got location, asking if home
        case notHome           // User said they're not home
        case locationFailed    // GPS failed
        case complete          // Location saved successfully
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.102, green: 0.227, blue: 0.322)  // Navy
            : Color(red: 0.784, green: 0.902, blue: 0.961)  // Light blue
    }

    private var textColor: Color {
        colorScheme == .dark
            ? Color(red: 0.784, green: 0.902, blue: 0.961)  // Light blue
            : Color(red: 0.102, green: 0.227, blue: 0.322)  // Navy
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Constants.largeSpacing) {

                    Spacer()
                        .frame(height: 40)

                    // Icon
                    locationIcon

                    // Title
                    Text("Set Your Home Location")
                        .font(.system(size: Constants.titleTextSize, weight: .bold))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Content based on current state
                    stateContent

                    Spacer()
                        .frame(height: 20)
                }
                .padding(.horizontal, Constants.standardSpacing)
            }
        }
        .onAppear {
            startLocationFlow()
        }
    }

    // MARK: - Icon

    private var locationIcon: some View {
        ZStack {
            Circle()
                .fill(colorScheme == .dark ? Color.blue.opacity(0.2) : Color.white)
                .frame(width: 120, height: 120)

            Image(systemName: flowState == .fetchingLocation ? "location.magnifyingglass" : "house.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolEffect(.pulse, isActive: flowState == .fetchingLocation)
        }
    }

    // MARK: - State Content

    @ViewBuilder
    private var stateContent: some View {
        switch flowState {
        case .initial, .requestingPermission:
            loadingContent(message: "Requesting location access...")

        case .fetchingLocation:
            loadingContent(message: "Finding your location...")

        case .confirmHome:
            confirmHomeContent

        case .notHome:
            notHomeContent

        case .locationFailed:
            locationFailedContent

        case .complete:
            completeContent
        }
    }

    // MARK: - Loading Content

    private func loadingContent(message: String) -> some View {
        VStack(spacing: Constants.standardSpacing) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(textColor)

            Text(message)
                .font(.system(size: Constants.bodyTextSize))
                .foregroundColor(textColor.opacity(0.8))
        }
        .padding(.vertical, 40)
    }

    // MARK: - Confirm Home Content

    private var confirmHomeContent: some View {
        VStack(spacing: Constants.standardSpacing) {

            // Show detected address
            VStack(spacing: 12) {
                Text("We found this location:")
                    .font(.system(size: Constants.bodyTextSize))
                    .foregroundColor(textColor.opacity(0.8))

                Text(displayAddress.isEmpty ? "Your current location" : displayAddress)
                    .font(.system(size: Constants.headerTextSize, weight: .semibold))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, Constants.standardSpacing)

            // Question
            Text("Are you home right now?")
                .font(.system(size: Constants.headerTextSize, weight: .medium))
                .foregroundColor(textColor)
                .padding(.top)

            // Yes button - primary action
            Button(action: confirmHomeLocation) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                    Text("Yes, This Is My Home")
                        .font(.system(size: Constants.buttonTextSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .background(Color.blue)
                .cornerRadius(Constants.cornerRadius)
            }
            .padding(.top, Constants.standardSpacing)

            // No button - secondary action
            Button(action: userNotHome) {
                HStack {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 24))
                    Text("No, I'm Somewhere Else")
                        .font(.system(size: Constants.buttonTextSize, weight: .medium))
                }
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .stroke(textColor.opacity(0.5), lineWidth: 2)
                )
            }

            // Privacy note
            privacyNote
        }
    }

    // MARK: - Not Home Content

    private var notHomeContent: some View {
        VStack(spacing: Constants.standardSpacing) {

            Text("No Problem!")
                .font(.system(size: Constants.headerTextSize, weight: .semibold))
                .foregroundColor(textColor)

            Text("Open the app when you're home and we'll set it then. You'll find this option in Settings.")
                .font(.system(size: Constants.bodyTextSize))
                .foregroundColor(textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Info card
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)

                Text("Home location helps us know if you're away, which affects how we interpret inactivity.")
                    .font(.system(size: 16))
                    .foregroundColor(textColor.opacity(0.8))
            }
            .padding()
            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
            .cornerRadius(Constants.cornerRadius)
            .padding(.vertical)

            // Continue button
            Button(action: deferAndContinue) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                    Text("I'll Set This Later")
                        .font(.system(size: Constants.buttonTextSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .background(Color.blue)
                .cornerRadius(Constants.cornerRadius)
            }
        }
    }

    // MARK: - Location Failed Content

    private var locationFailedContent: some View {
        VStack(spacing: Constants.standardSpacing) {

            Image(systemName: "location.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding(.bottom)

            Text("Couldn't Get Your Location")
                .font(.system(size: Constants.headerTextSize, weight: .semibold))
                .foregroundColor(textColor)

            Text(locationService.errorMessage ?? "Location services may be unavailable. You can set your home location later in Settings.")
                .font(.system(size: Constants.bodyTextSize))
                .foregroundColor(textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Retry button
            Button(action: retryLocation) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 24))
                    Text("Try Again")
                        .font(.system(size: Constants.buttonTextSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .background(Color.blue)
                .cornerRadius(Constants.cornerRadius)
            }

            // Skip button
            Button(action: deferAndContinue) {
                HStack {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 24))
                    Text("Skip For Now")
                        .font(.system(size: Constants.buttonTextSize, weight: .medium))
                }
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.cornerRadius)
                        .stroke(textColor.opacity(0.5), lineWidth: 2)
                )
            }
        }
    }

    // MARK: - Complete Content

    private var completeContent: some View {
        VStack(spacing: Constants.standardSpacing) {

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Home Location Saved!")
                .font(.system(size: Constants.headerTextSize, weight: .semibold))
                .foregroundColor(textColor)

            if !displayAddress.isEmpty {
                Text(displayAddress)
                    .font(.system(size: Constants.bodyTextSize))
                    .foregroundColor(textColor.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            Text("You can update this anytime in Settings.")
                .font(.system(size: 16))
                .foregroundColor(textColor.opacity(0.6))
                .padding(.top, 8)

            Button(action: onContinue) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                    Text("Continue")
                        .font(.system(size: Constants.buttonTextSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.buttonHeight)
                .background(Color.blue)
                .cornerRadius(Constants.cornerRadius)
            }
            .padding(.top)
        }
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 16))
            Text("Your location is stored only on your device.")
                .font(.system(size: 14))
        }
        .foregroundColor(textColor.opacity(0.6))
        .padding(.top, Constants.standardSpacing)
    }

    // MARK: - Actions

    private func startLocationFlow() {
        Task {
            flowState = .requestingPermission

            // First, check/request permission
            let hasPermission = await locationService.requestLocationPermission()

            if !hasPermission {
                // Permission denied - go to failed state
                flowState = .locationFailed
                return
            }

            // Now fetch location
            flowState = .fetchingLocation

            let result = await locationService.fetchCurrentLocation()

            switch result {
            case .success(_, let address):
                displayAddress = address ?? ""
                flowState = .confirmHome

            case .permissionDenied, .permissionRestricted:
                flowState = .locationFailed

            case .locationUnavailable:
                flowState = .locationFailed

            case .error(let message):
                print("Location error: \(message)")
                flowState = .locationFailed
            }
        }
    }

    private func confirmHomeLocation() {
        // Save the location
        if let homeLocation = locationService.createHomeLocation() {
            locationService.saveHomeLocation(homeLocation)
            viewModel.hasHomeLocation = true

            // Clear any deferred flag
            UserDefaults.standard.removeObject(forKey: Constants.homeLocationDeferredKey)

            flowState = .complete
        } else {
            // Shouldn't happen, but handle gracefully
            flowState = .locationFailed
        }
    }

    private func userNotHome() {
        flowState = .notHome
    }

    private func deferAndContinue() {
        // Mark that we deferred home location setup
        UserDefaults.standard.set(true, forKey: Constants.homeLocationDeferredKey)
        viewModel.homeLocationDeferred = true
        onContinue()
    }

    private func retryLocation() {
        startLocationFlow()
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    HomeLocationView(viewModel: OnboardingViewModel()) {
        print("Continue tapped")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    HomeLocationView(viewModel: OnboardingViewModel()) {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
