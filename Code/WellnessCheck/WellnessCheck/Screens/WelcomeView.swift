//
//  WelcomeView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import SwiftUI

/// First screen in the onboarding flow - introduces WellnessCheck to the user
struct WelcomeView: View {
    // MARK: - Properties

    let onContinue: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: Constants.largeSpacing) {
            Spacer()

            // App icon or logo placeholder
            Image(systemName: "heart.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundStyle(.blue.gradient)
                .padding(.bottom, Constants.standardSpacing)

            // App name
            Text(Constants.appName)
                .font(.system(size: Constants.titleTextSize, weight: .bold))
                .foregroundColor(.primary)

            // Tagline
            Text(Constants.appTagline)
                .font(.system(size: Constants.bodyTextSize))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.standardSpacing)

            Spacer()

            // Key features section
            VStack(alignment: .leading, spacing: Constants.standardSpacing) {
                FeatureRow(
                    icon: "figure.fall",
                    title: "Fall Detection",
                    description: "Automatic alerts if a fall is detected"
                )

                FeatureRow(
                    icon: "bell.fill",
                    title: "Inactivity Monitoring",
                    description: "Check-ins when you're inactive too long"
                )

                FeatureRow(
                    icon: "person.2.fill",
                    title: "Care Circle",
                    description: "Connect with family and friends"
                )

                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Privacy First",
                    description: "Your health data stays on your device"
                )
            }
            .padding(.horizontal, Constants.standardSpacing)

            Spacer()

            // Disclaimer
            VStack(spacing: 12) {
                Text("Important Safety Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("WellnessCheck is a wellness monitoring tool designed to provide peace of mind. It is NOT a medical device and should NOT replace professional medical care or emergency services. In case of emergency, always call 911 immediately.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.standardSpacing)
            }
            .padding(.vertical, Constants.standardSpacing)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(Constants.cornerRadius)
            .padding(.horizontal, Constants.standardSpacing)

            // Continue button
            LargeButton(
                title: "Get Started",
                systemImage: "arrow.right",
                backgroundColor: .blue,
                action: onContinue
            )
            .padding(.horizontal, Constants.standardSpacing)
            .padding(.bottom, Constants.standardSpacing)
        }
        .padding(.top, Constants.largeSpacing)
    }
}

// MARK: - Feature Row Component

/// Single feature row showing icon, title, and description
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView {
        print("Continue tapped")
    }
}
