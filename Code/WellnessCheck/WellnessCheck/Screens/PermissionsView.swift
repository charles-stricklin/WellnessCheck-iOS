//
//  PermissionsView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-31)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import SwiftUI

/// Onboarding screen to request necessary permissions from the user
struct PermissionsView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.largeSpacing) {
            Spacer(minLength: 40)
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue.gradient)

                Text("Permissions Needed")
                    .font(.system(size: Constants.headerTextSize, weight: .bold))
                    .foregroundColor(.primary)

                Text("To keep you safe, WellnessCheck needs access to a few things")
                    .font(.system(size: Constants.bodyTextSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.standardSpacing)
            }

            Spacer()

            // Permissions list
            VStack(spacing: Constants.standardSpacing) {
                PermissionCard(
                    icon: "heart.fill",
                    title: "Health Data",
                    description: "Monitor your activity and detect falls using HealthKit",
                    isGranted: viewModel.hasHealthKitPermission,
                    buttonTitle: viewModel.hasHealthKitPermission ? "Granted" : "Allow Health Data",
                    action: {
                        Task {
                            await viewModel.requestHealthKitPermission()
                        }
                    }
                )

                PermissionCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Send you reminders and check-in alerts",
                    isGranted: viewModel.hasNotificationPermission,
                    buttonTitle: viewModel.hasNotificationPermission ? "Granted" : "Allow Notifications",
                    action: {
                        Task {
                            await viewModel.requestNotificationPermission()
                        }
                    }
                )
            }
            .padding(.horizontal, Constants.standardSpacing)

            // Error message if any
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.standardSpacing)
                    .padding(.vertical, 8)
            }

            Spacer()

            // Privacy note
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                    Text("Your Privacy Matters")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Text("Your health data stays on your device. We only share what you choose with your Care Circle.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.standardSpacing)
            }
            .padding(.vertical, Constants.standardSpacing)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(Constants.cornerRadius)
            .padding(.horizontal, Constants.standardSpacing)

            // Continue button (enabled only when all permissions granted)
            LargeButton(
                title: "Continue",
                systemImage: "arrow.right",
                backgroundColor: viewModel.canProceed() ? .blue : .gray,
                action: {
                    if viewModel.canProceed() {
                        onContinue()
                    }
                }
            )
            .disabled(!viewModel.canProceed())
            .padding(.horizontal, Constants.standardSpacing)
            .padding(.bottom, Constants.standardSpacing)
            }
        }
    }
}

// MARK: - Permission Card Component

/// Individual permission card showing status and action button
private struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isGranted ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isGranted ? .green : .blue)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        if isGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }

                    Text(description)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Action button
            if !isGranted {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Constants.standardSpacing)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(Constants.cornerRadius)
    }
}

// MARK: - Preview

#Preview {
    PermissionsView(
        viewModel: OnboardingViewModel(),
        onContinue: {
            print("Continue tapped")
        }
    )
}
