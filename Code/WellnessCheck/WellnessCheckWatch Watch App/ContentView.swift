//
//  ContentView.swift
//  WellnessCheckWatch Watch App
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Main watch view - shows simple status when monitoring,
//  or full-screen fall alert when fall is detected.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var fallManager: FallDetectionManager

    var body: some View {
        ZStack {
            // Normal status view
            if !fallManager.fallDetected {
                StatusView()
                    .environmentObject(fallManager)
            }

            // Fall alert overlay (covers everything when fall detected)
            if fallManager.fallDetected {
                FallAlertView()
                    .environmentObject(fallManager)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: fallManager.fallDetected)
    }
}

/// Simple status display when monitoring
struct StatusView: View {
    @EnvironmentObject var fallManager: FallDetectionManager

    var body: some View {
        VStack(spacing: 16) {
            // Status icon
            Image(systemName: statusIcon)
                .font(.system(size: 40))
                .foregroundColor(statusColor)

            // Status text
            Text(fallManager.statusMessage)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Availability warning if needed
            if !fallManager.isAvailable {
                Text("Requires Apple Watch Series 4+")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var statusIcon: String {
        if !fallManager.isAvailable {
            return "exclamationmark.circle"
        } else if fallManager.statusMessage == "Alert Sent" {
            return "checkmark.circle.fill"
        } else {
            return "checkmark.shield.fill"
        }
    }

    private var statusColor: Color {
        if !fallManager.isAvailable {
            return .orange
        } else if fallManager.statusMessage == "Alert Sent" {
            return .blue
        } else {
            return .green
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FallDetectionManager())
}
