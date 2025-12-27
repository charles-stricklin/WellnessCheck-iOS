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
    
    @Environment(\.colorScheme) var colorScheme
    
    // Brand colors
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "#1A3A52") : Color(hex: "#C8E6F5")
    }
    
    private var accentColor: Color {
        colorScheme == .dark ? Color(hex: "#C8E6F5") : Color(hex: "#1A3A52")
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            ZStack {
                // Background color
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 10) {
                    content
                }
                .padding(.top, 20)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
    }
    
    private var content: some View {
        Group {
			// App icon with version badge
            ZStack(alignment: .bottomTrailing) {
                Image("WelcomeIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 250, height: 250)
                
                // Version number to the right of heart
                Text("v0.1.0")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(accentColor.opacity(0.6))
                    .offset(x: -40, y: -44)
            }
            .padding(.bottom, 8)

            // App name
            Text(Constants.appName)
                .font(.system(size: Constants.titleTextSize, weight: .bold))
                .foregroundColor(accentColor)

            // Tagline
            Text(Constants.appTagline)
                .font(.system(size: 17))
                .italic()
                .foregroundColor(accentColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.standardSpacing)
                .padding(.top, 2)
                .padding(.bottom, 20)

            // Features header
            Text("WellnessCheck provides")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(accentColor)
                .padding(.horizontal, Constants.standardSpacing)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)

            // Key features section
            VStack(alignment: .leading, spacing: 16) {
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
                    title: "A Care Circle",
                    description: "Connect with family and friends"
                )

                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Privacy First",
                    description: "Your health data stays on your device"
                )
            }
            .padding(.horizontal, Constants.standardSpacing)

            Spacer(minLength: 16)

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
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
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
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
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
