//
//  MainDashboardView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import SwiftUI

/// Main dashboard view shown after onboarding is complete
/// This is a placeholder that will be expanded with full dashboard functionality
struct MainDashboardView: View {
    // MARK: - Properties

    @AppStorage(Constants.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false
    @AppStorage(Constants.userNameKey) private var userName = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: Constants.largeSpacing) {
                Spacer()

                // Welcome message
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.green.gradient)

                    Text("Welcome to WellnessCheck!")
                        .font(.system(size: Constants.headerTextSize, weight: .bold))
                        .foregroundColor(.primary)

                    if !userName.isEmpty {
                        Text("Hi, \(userName.components(separatedBy: " ").first ?? userName)!")
                            .font(.system(size: Constants.bodyTextSize))
                            .foregroundColor(.secondary)
                    }

                    Text("Your safety monitoring is ready to go")
                        .font(.system(size: Constants.bodyTextSize))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.standardSpacing)
                }

                Spacer()

                // Status cards (placeholder)
                VStack(spacing: 16) {
                    StatusPlaceholderCard(
                        icon: "heart.fill",
                        title: "Monitoring Active",
                        subtitle: "All systems running"
                    )

                    StatusPlaceholderCard(
                        icon: "person.2.fill",
                        title: "Care Circle",
                        subtitle: "No members yet"
                    )

                    StatusPlaceholderCard(
                        icon: "bell.fill",
                        title: "Notifications",
                        subtitle: "Enabled"
                    )
                }
                .padding(.horizontal, Constants.standardSpacing)

                Spacer()

                // Coming soon message
                VStack(spacing: 8) {
                    Text("Dashboard Coming Soon")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("The full dashboard with monitoring controls and settings is under development.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.standardSpacing)
                }
                .padding(.vertical, Constants.standardSpacing)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(Constants.cornerRadius)
                .padding(.horizontal, Constants.standardSpacing)

                Spacer()
            }
            .navigationTitle("WellnessCheck")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Status Placeholder Card

/// Temporary status card component for the placeholder dashboard
private struct StatusPlaceholderCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
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

                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(Constants.standardSpacing)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(Constants.cornerRadius)
    }
}

// MARK: - Preview

#Preview {
    MainDashboardView()
}
