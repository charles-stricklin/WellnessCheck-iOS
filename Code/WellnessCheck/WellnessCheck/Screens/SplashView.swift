//
//  SplashView.swift
//  WellnessCheck
//
//  Created: v0.3.0 (2026-01-13)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Brief splash screen shown when the app launches after onboarding is complete.
//  Displays the app name, tagline, and version number before transitioning
//  to the main dashboard.
//
//  WHY THIS EXISTS:
//  A splash screen provides visual continuity during app launch and gives
//  users confidence the app is loading. Showing the version number helps
//  with support conversations and lets users confirm they have the latest version.
//
//  DESIGN NOTE:
//  Matches the onboarding screens exactly — dark mode uses dark blue background
//  with light blue heart, light mode uses light blue background with dark blue heart.
//

import SwiftUI

/// Splash screen shown briefly at app launch (post-onboarding)
struct SplashView: View {
    // MARK: - Properties

    @Environment(\.colorScheme) var colorScheme

    /// Callback triggered when splash duration completes
    let onComplete: () -> Void

    /// Controls fade-in animation
    @State private var isVisible = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background — matches onboarding screens
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                // App Logo — uses AppLogo or WelcomeIcon asset (same as onboarding)
                if let _ = UIImage(named: "AppLogo") {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                } else {
                    Image("WelcomeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                }

                // App Name
                Text(Constants.appName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(primaryTextColor)

                // Tagline — "be" is italicized to emphasize the distinction
                // between living alone and *being* alone
                Text("Living alone doesn't mean having to *be* alone.")
                    .font(.system(size: 20))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Version number at bottom
                Text("Version \(appVersion)")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .padding(.bottom, 40)
            }
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            // Fade in the content
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
            }

            // After a brief display, trigger the completion callback
            // 2.5 seconds total: 0.3s fade in + 2.2s display
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onComplete()
            }
        }
    }

    // MARK: - Computed Properties

    /// Background color matching onboarding screens
    /// Dark mode: dark blue, Light mode: light blue
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.075, green: 0.106, blue: 0.196)
            : Color(red: 0.784, green: 0.902, blue: 0.961)
    }

    /// Primary text color matching onboarding screens
    /// Dark mode: white, Light mode: dark blue
    private var primaryTextColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color(red: 0.102, green: 0.227, blue: 0.322)
    }

    /// Secondary text color for tagline and version
    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color.gray
            : Color.gray
    }

    /// App version string pulled from the bundle (e.g., "1.0.0")
    /// Falls back to "0.0.0" if not found (shouldn't happen in a real build)
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    SplashView {
        print("Splash complete")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    SplashView {
        print("Splash complete")
    }
    .preferredColorScheme(.dark)
}
