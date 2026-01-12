//
//  CompletionView.swift
//  WellnessCheck
//
//  Screen 11 of 11 - Completion
//  Final onboarding screen celebrating setup completion
//

import SwiftUI

struct CompletionView: View {
    @StateObject private var viewModel = CompletionViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Celebration Header
                    VStack(spacing: 24) {
                        // Celebration thumbs-up image
                        Image("ThumbsUp")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        
                        VStack(spacing: 12) {
                            Text("You're All Set")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("WellnessCheck is ready to keep you connected to the people who care about you.")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 40)
                    
                    // MARK: - Summary Card
                    VStack(alignment: .leading, spacing: 0) {
                        Text("YOUR SETUP")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 16)
                        
                        // Care Circle
                        // Note: subtitle is dynamic (names list), status uses localized singular/plural
                        SummaryRow(
                            icon: "👥",
                            iconBackground: Color.blue.opacity(0.15),
                            title: "Care Circle",
                            subtitle: viewModel.careCircleNames,
                            status: "\(viewModel.careCircleCount) \(viewModel.careCircleCount == 1 ? String(localized: "member") : String(localized: "members"))",
                            showDivider: true
                        )

                        // Monitoring
                        // Note: subtitle is dynamic (feature list), status is localized static text
                        SummaryRow(
                            icon: "🛡️",
                            iconBackground: Color.orange.opacity(0.15),
                            title: "Monitoring",
                            subtitle: viewModel.monitoringFeatures,
                            status: String(localized: "Active"),
                            showDivider: true
                        )

                        // Home Location
                        // Note: subtitle and status are localized static text
                        SummaryRow(
                            icon: "🏠",
                            iconBackground: Color.purple.opacity(0.15),
                            title: "Home Location",
                            subtitle: String(localized: "Used for context, not tracking"),
                            status: viewModel.homeLocationSet ? String(localized: "Set") : String(localized: "Not Set"),
                            showDivider: false
                        )
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 16)
                    
                    // MARK: - Learning Period Note
                    HStack(alignment: .top, spacing: 12) {
                        Text("📊")
                            .font(.system(size: 24))
                        
                        Text("**First two weeks:** WellnessCheck is learning your patterns. You may see fewer alerts as it figures out what's normal for you.")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 24)
                }
            }
            
            // MARK: - Get Started Button
            VStack {
                Button(action: {
                    hasCompletedOnboarding = true
                }) {
                    Text("Get Started")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.green)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .padding(.top, 16)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Summary Row Component
//
// This component displays a summary row with an icon, title, subtitle, and status.
// The title uses LocalizedStringKey for static localizable text, while subtitle
// and status use String since they often contain dynamic computed values.
// For static text in subtitle/status, use String(localized:) at the call site.

struct SummaryRow: View {
    let icon: String
    let iconBackground: Color
    let title: LocalizedStringKey  // Static titles are localized via string catalog
    let subtitle: String           // Dynamic content - use String(localized:) for static text
    let status: String             // Dynamic content - use String(localized:) for static text
    let showDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 48, height: 48)

                    Text(icon)
                        .font(.system(size: 20))
                }

                // Title and Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Status
                Text(status)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.vertical, 12)

            if showDivider {
                Divider()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CompletionView()
}
