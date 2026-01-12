//
//  MainDashboardView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.2.0 (2026-01-10)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Main dashboard view shown after onboarding is complete.
//  Displays wellness status, daily activity, and Care Circle at a glance.
//

import SwiftUI

/// Main dashboard view shown after onboarding is complete
struct MainDashboardView: View {
    // MARK: - Properties

    @AppStorage(Constants.userNameKey) private var userName = ""
    @State private var selectedTab: DashboardTab = .home

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView(userName: userName)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(DashboardTab.home)

            ActivityTabView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Activity")
                }
                .tag(DashboardTab.activity)

            CareCircleTabView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Care Circle")
                }
                .tag(DashboardTab.careCircle)

            SettingsTabView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(DashboardTab.settings)
        }
        .tint(.blue)
    }
}

// MARK: - Dashboard Tab Enum

enum DashboardTab {
    case home
    case activity
    case careCircle
    case settings
}

// MARK: - Home Tab View

struct HomeTabView: View {
    let userName: String

    // Mock data - will be replaced with real data from services
    @State private var isAllGood = true
    @State private var lastActivity = "2 minutes ago"
    @State private var learningDay = 5

    @State private var steps = 3247
    @State private var stepsGoal = 5000
    @State private var floors = 2
    @State private var phonePickups = 12

    @State private var showingImOkConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)

                            Text(firstName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        NavigationLink(destination: SettingsTabView()) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // MARK: - Main Status Card
                    MainStatusCard(
                        isAllGood: isAllGood,
                        lastActivity: lastActivity,
                        learningDay: learningDay
                    )
                    .padding(.horizontal, 16)

                    // MARK: - Today's Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TODAY'S ACTIVITY")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        ActivityCard(
                            steps: steps,
                            stepsGoal: stepsGoal,
                            floors: floors,
                            phonePickups: phonePickups
                        )
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Care Circle Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR CARE CIRCLE")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        CareCirclePreviewCard()
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Quick Action
                    Button(action: {
                        showingImOkConfirmation = true
                    }) {
                        HStack(spacing: 8) {
                            Text("💬")
                                .font(.system(size: 20))

                            Text("Send \"I'm OK\" to Care Circle")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .alert("Send \"I'm OK\"?", isPresented: $showingImOkConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Send") {
                            // TODO: Actually send the message to Care Circle
                        }
                    } message: {
                        Text("This will notify your Care Circle that you're doing fine.")
                    }

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }

    // MARK: - Computed Properties

    private var firstName: String {
        userName.components(separatedBy: " ").first ?? userName
    }

    private var greetingText: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
}

// MARK: - Main Status Card

struct MainStatusCard: View {
    let isAllGood: Bool
    let lastActivity: String
    let learningDay: Int

    var body: some View {
        VStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: isAllGood ? "checkmark" : "exclamationmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }

            // Status Text
            Text(isAllGood ? "All Good" : "Check In Needed")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)

            // Last Activity
            Text("Last activity: \(lastActivity)")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))

            // Learning Period Badge (only show during first 14 days)
            if learningDay <= 14 {
                HStack(spacing: 6) {
                    Text("📊")
                        .font(.system(size: 14))

                    Text("Learning your patterns • Day \(learningDay) of 14")
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
                .foregroundColor(.white)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: isAllGood
                    ? [Color.green, Color.green.opacity(0.8)]
                    : [Color.orange, Color.orange.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

// MARK: - Activity Card

struct ActivityCard: View {
    let steps: Int
    let stepsGoal: Int
    let floors: Int
    let phonePickups: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                // Steps
                ActivityStatBox(
                    emoji: "👟",
                    value: "\(steps.formatted())",
                    label: "steps",
                    progress: Double(steps) / Double(stepsGoal)
                )

                // Floors
                ActivityStatBox(
                    emoji: "🏢",
                    value: "\(floors)",
                    label: "floors climbed",
                    progress: nil
                )
            }

            // Phone Pickups (full width)
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("📱")
                        .font(.system(size: 28))

                    Text("\(phonePickups)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Text("phone pickups today")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Activity Stat Box

struct ActivityStatBox: View {
    let emoji: String
    let value: String
    let label: LocalizedStringKey
    let progress: Double?

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 28))

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            // Progress bar for steps
            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green)
                            .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Care Circle Preview Card

struct CareCirclePreviewCard: View {
    // Mock data - will be replaced with real data
    private let members = [
        (name: "Sarah", initial: "S"),
        (name: "Michael", initial: "M")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(members.enumerated()), id: \.offset) { index, member in
                HStack(spacing: 14) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Text(member.initial)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }

                    // Name and status
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Text("No alerts sent")
                                .font(.system(size: 14))
                                .foregroundColor(.green)

                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)

                if index < members.count - 1 {
                    Divider()
                        .padding(.leading, 82)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Placeholder Tab Views

struct ActivityTabView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.5))

                Text("Activity History")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 16)

                Text("Coming Soon")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("Activity")
        }
    }
}

struct CareCircleTabView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.5))

                Text("Care Circle Management")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 16)

                Text("Coming Soon")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("Care Circle")
        }
    }
}

struct SettingsTabView: View {
    @AppStorage(Constants.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink(destination: Text("Profile")) {
                        Label("Profile", systemImage: "person.circle")
                    }

                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section("Monitoring") {
                    NavigationLink(destination: Text("Monitoring Settings")) {
                        Label("Monitoring Settings", systemImage: "shield")
                    }

                    NavigationLink(destination: Text("Home Location")) {
                        Label("Home Location", systemImage: "house")
                    }
                }

                Section("Support") {
                    NavigationLink(destination: Text("Help")) {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }

                    NavigationLink(destination: Text("About")) {
                        Label("About WellnessCheck", systemImage: "info.circle")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        // Reset onboarding for testing
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Reset Onboarding (Dev)", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview

#Preview {
    MainDashboardView()
}
