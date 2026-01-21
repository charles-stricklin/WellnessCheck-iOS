//
//  FallAlertView.swift
//  WellnessCheckWatch Watch App
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Full-screen alert shown when a fall is detected.
//  Displays countdown and large "I'm OK" button.
//  Haptic feedback every 5 seconds to get user's attention.
//

import SwiftUI

/// Full-screen fall alert with countdown and "I'm OK" button
struct FallAlertView: View {
    @EnvironmentObject var fallManager: FallDetectionManager

    var body: some View {
        VStack(spacing: 12) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(.yellow)

            // "Fall Detected" text
            Text("Fall Detected")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            // Countdown display
            Text(countdownText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(countdownColor)
                .monospacedDigit()

            // Help message
            Text("Tap if you're OK")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // I'm OK button - large and easy to tap
            Button(action: {
                fallManager.userRespondedOK()
            }) {
                Text("I'm OK")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
        .padding()
    }

    /// Format countdown as "0:30"
    private var countdownText: String {
        let minutes = fallManager.countdownSeconds / 60
        let seconds = fallManager.countdownSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Color changes as countdown progresses
    /// Green > 15s, Yellow > 5s, Red <= 5s
    private var countdownColor: Color {
        if fallManager.countdownSeconds > 15 {
            return .green
        } else if fallManager.countdownSeconds > 5 {
            return .yellow
        } else {
            return .red
        }
    }
}
