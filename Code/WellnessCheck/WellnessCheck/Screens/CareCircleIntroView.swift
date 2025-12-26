//
//  CareCircleIntroView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import SwiftUI

/// Onboarding screen introducing the Care Circle concept
struct CareCircleIntroView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: Constants.largeSpacing) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.2.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.blue.gradient)

                Text("Your Care Circle")
                    .font(.system(size: Constants.headerTextSize, weight: .bold))
                    .foregroundColor(.primary)

                Text("Connect with the people who care about you")
                    .font(.system(size: Constants.bodyTextSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.standardSpacing)
            }
            .padding(.top, Constants.largeSpacing)

            Spacer()

            // How it works section
            VStack(alignment: .leading, spacing: Constants.standardSpacing) {
                Text("How It Works")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, Constants.standardSpacing)

                CareCircleStep(
                    number: 1,
                    icon: "person.badge.plus.fill",
                    title: "Invite Family & Friends",
                    description: "Add trusted people to your Care Circle by sending them an invitation"
                )

                CareCircleStep(
                    number: 2,
                    icon: "bell.badge.fill",
                    title: "Automatic Alerts",
                    description: "If WellnessCheck detects a fall or extended inactivity, your Care Circle is notified"
                )

                CareCircleStep(
                    number: 3,
                    icon: "checkmark.shield.fill",
                    title: "Quick Response",
                    description: "Your Care Circle can check on you immediately or contact emergency services"
                )
            }

            Spacer()

            // Privacy and control section
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.blue)
                        Text("You're Always in Control")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("You decide who joins your Care Circle and can remove anyone at any time. You can also pause monitoring whenever you need privacy.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.standardSpacing)
                }

                Divider()
                    .padding(.horizontal, Constants.standardSpacing)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("Set Up Later")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Text("You can add members to your Care Circle now or do it later from the app settings.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.standardSpacing)
                }
            }
            .padding(.vertical, Constants.standardSpacing)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(Constants.cornerRadius)
            .padding(.horizontal, Constants.standardSpacing)

            // Action buttons
            VStack(spacing: 12) {
                LargeButton(
                    title: "Add Care Circle Members",
                    systemImage: "person.badge.plus",
                    backgroundColor: .blue,
                    action: {
                        // TODO: Navigate to add Care Circle members flow
                        onContinue()
                    }
                )

                LargeOutlineButton(
                    title: "I'll Do This Later",
                    foregroundColor: .gray,
                    action: {
                        onContinue()
                    }
                )
            }
            .padding(.horizontal, Constants.standardSpacing)
            .padding(.bottom, Constants.standardSpacing)
        }
    }
}

// MARK: - Care Circle Step Component

/// Individual step in the Care Circle explanation
private struct CareCircleStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.blue)
                .frame(width: 40, alignment: .leading)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, Constants.standardSpacing)
    }
}

// MARK: - Preview

#Preview {
    CareCircleIntroView(
        viewModel: OnboardingViewModel(),
        onContinue: {
            print("Continue tapped")
        }
    )
}
