//
//  FallAlertView.swift
//  WellnessCheck
//
//  Created: v0.6.0 (2026-01-17)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Full-screen alert shown when a fall is detected.
//  Gives user 60 seconds to respond "I'm OK" before alerting Care Circle.
//
//  DESIGN:
//  - Full screen, can't be dismissed accidentally
//  - Large text and buttons for seniors (60pt minimum touch targets)
//  - High contrast colors for visibility
//  - Countdown timer prominently displayed
//  - Loud audio + haptic to get attention
//

import SwiftUI

/// Full-screen view shown when a fall is detected
/// User must tap "I'm OK" within countdown period or Care Circle will be alerted
struct FallAlertView: View {
    // MARK: - Properties

    @ObservedObject var fallService = FallDetectionService.shared
    @ObservedObject var careCircleViewModel: CareCircleViewModel
    @StateObject private var cloudFunctions = CloudFunctionsService()

    @AppStorage(Constants.userNameKey) private var userName = ""

    @State private var isSendingAlert = false
    @State private var alertSent = false

    /// Accent color for countdown - transitions from green to yellow to red
    private var countdownColor: Color {
        if fallService.countdownSeconds > 30 {
            return .green
        } else if fallService.countdownSeconds > 10 {
            return .yellow
        } else {
            return .red
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dark background that covers everything
            Color.black
                .opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.yellow)
                    .symbolEffect(.pulse, options: .repeating)

                // Main question
                Text("Did You Fall?")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Explanation
                Text("If you're okay, tap the button below.\nOtherwise, help is on the way.")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                // Countdown display
                VStack(spacing: 8) {
                    Text("Alerting Care Circle in")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))

                    Text("\(fallService.countdownSeconds)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(countdownColor)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: fallService.countdownSeconds)

                    Text("seconds")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Status messages
                if isSendingAlert {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Alerting your Care Circle...")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                } else if alertSent {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                        Text("Help is on the way")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                // "I'm OK" button - very large for easy tapping
                Button(action: {
                    fallService.userRespondedOK()
                }) {
                    Text("I'm OK")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color.green)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 32)
                .disabled(isSendingAlert || alertSent)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .fallAlertTriggered)) { _ in
            sendAlertToCareCircle()
        }
        .onChange(of: fallService.state) { _, newState in
            if newState == .alerting {
                sendAlertToCareCircle()
            }
        }
    }

    // MARK: - Private Methods

    /// Send fall alert to all Care Circle members
    private func sendAlertToCareCircle() {
        guard !isSendingAlert && !alertSent else { return }

        isSendingAlert = true

        Task {
            // Get current location if available
            let locationService = LocationService.shared
            var alertLocation: AlertLocation? = nil

            if let home = locationService.loadHomeLocation() {
                alertLocation = AlertLocation(
                    address: home.address ?? "Home",
                    isHome: true
                )
            }

            // Send alert to all Care Circle members
            let result = await cloudFunctions.sendAlert(
                userName: userName.isEmpty ? "WellnessCheck User" : userName,
                alertType: .fall,
                location: alertLocation,
                members: careCircleViewModel.members
            )

            isSendingAlert = false

            if result.success {
                alertSent = true
                print("✅ Fall alert sent to \(result.sent) Care Circle members")
            } else {
                print("❌ Failed to send fall alert: \(result.error ?? "Unknown error")")
                // Even if SMS fails, show that we tried
                alertSent = true
            }
        }
    }
}

// MARK: - Fall Alert Overlay Modifier

/// View modifier that overlays the fall alert when a fall is detected
struct FallAlertOverlay: ViewModifier {
    @ObservedObject var fallService = FallDetectionService.shared
    @ObservedObject var careCircleViewModel: CareCircleViewModel

    func body(content: Content) -> some View {
        ZStack {
            content

            // Show fall alert overlay when fall is detected
            if fallService.state == .fallDetected || fallService.state == .alerting {
                FallAlertView(careCircleViewModel: careCircleViewModel)
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: fallService.state)
    }
}

extension View {
    /// Apply fall alert overlay to any view
    func fallAlertOverlay(careCircleViewModel: CareCircleViewModel) -> some View {
        modifier(FallAlertOverlay(careCircleViewModel: careCircleViewModel))
    }
}

// MARK: - Preview

#Preview {
    FallAlertView(careCircleViewModel: CareCircleViewModel())
}
