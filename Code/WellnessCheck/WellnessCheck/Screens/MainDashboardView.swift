//
//  MainDashboardView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.3.0 (2026-01-13)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Main dashboard view shown after onboarding is complete.
//  Displays wellness status, daily activity, and Care Circle at a glance.
//
//  UPDATE 2026-01-13: Connected to real HealthKit data and Care Circle members.
//  Steps and floors now pull from HealthKit. Care Circle preview shows actual
//  stored members instead of mock data.
//

import SwiftUI

/// Main dashboard view shown after onboarding is complete
struct MainDashboardView: View {
    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Constants.userNameKey) private var userName = ""
    @State private var selectedTab: DashboardTab = .home

    /// Shared ViewModel for dashboard data (HealthKit + Care Circle)
    /// StateObject ensures it persists across view updates
    @StateObject private var viewModel = DashboardViewModel()

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView(userName: userName, viewModel: viewModel)
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
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Record phone pickup when app comes to foreground
            // This is a reliable proxy signal — user picked up phone and opened app
            if newPhase == .active && oldPhase != .active {
                viewModel.recordPhonePickup()
            }
        }
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

    /// ViewModel providing real data from HealthKit and Care Circle
    @ObservedObject var viewModel: DashboardViewModel

    /// Track color scheme for dark mode background
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingImOkConfirmation = false

    /// Background color - dark blue in dark mode, system grouped in light mode
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.067, green: 0.133, blue: 0.267)
            : Color(.systemGroupedBackground)
    }

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
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // MARK: - Main Status Card
                    MainStatusCard(
                        isAllGood: viewModel.isAllGood,
                        lastActivity: viewModel.lastActivityDescription,
                        learningDay: viewModel.learningDay
                    )
                    .padding(.horizontal, 16)

                    // MARK: - Today's Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TODAY'S ACTIVITY")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        ActivityCard(
                            steps: viewModel.steps,
                            floors: viewModel.floors,
                            phonePickups: viewModel.phonePickups
                        )
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Care Circle Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR CARE CIRCLE")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        CareCirclePreviewCard(members: viewModel.careCircleViewModel.members)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Quick Action (only show if Care Circle has members)
                    if !viewModel.careCircleViewModel.members.isEmpty {
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
                                // TODO: Actually send the message to Care Circle via Twilio
                            }
                        } message: {
                            Text("This will notify your Care Circle that you're doing fine.")
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .task {
                // Request HealthKit authorization and fetch data on appear
                await viewModel.requestHealthKitAuthorizationIfNeeded()
                await viewModel.refreshData()
            }
            .refreshable {
                // Pull-to-refresh support
                await viewModel.refreshData()
            }
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
    let learningDay: Int? // nil if learning period is complete

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
            if let day = learningDay {
                HStack(spacing: 6) {
                    Text("📊")
                        .font(.system(size: 14))

                    Text("Learning your patterns • Day \(day) of 14")
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
    let floors: Int
    let phonePickups: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                // Steps — shown as activity indicator, not a goal to hit
                ActivityStatBox(
                    emoji: "👟",
                    value: "\(steps.formatted())",
                    label: "steps"
                )

                // Floors
                ActivityStatBox(
                    emoji: "🏢",
                    value: "\(floors)",
                    label: "floors climbed"
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
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Care Circle Preview Card

struct CareCirclePreviewCard: View {
    /// Real Care Circle members from the ViewModel
    let members: [CareCircleMember]

    var body: some View {
        VStack(spacing: 0) {
            if members.isEmpty {
                // Empty state — prompt user to add members
                VStack(spacing: 12) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No Care Circle members yet")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)

                    Text("Add people who should be notified if something seems wrong.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
            } else {
                // Show up to 3 members in the preview
                ForEach(Array(members.prefix(3).enumerated()), id: \.element.id) { index, member in
                    HStack(spacing: 14) {
                        // Avatar — show photo if available, otherwise initials
                        if let imageData = member.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 48, height: 48)

                                Text(member.firstName.prefix(1).uppercased())
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                        }

                        // Name and status
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(member.firstName)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)

                                // Show primary badge for first member
                                if member.isPrimary {
                                    Text("PRIMARY")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .cornerRadius(4)
                                }
                            }

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

                    if index < min(members.count, 3) - 1 {
                        Divider()
                            .padding(.leading, 82)
                    }
                }

                // If there are more than 3 members, show a "more" indicator
                if members.count > 3 {
                    Divider()
                        .padding(.leading, 82)

                    HStack {
                        Spacer()
                        Text("+\(members.count - 3) more")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 12)
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
                    Button {
                        // Reset onboarding for testing
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Reset Onboarding (Dev)", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview

#Preview("Dashboard") {
    MainDashboardView()
}

#Preview("Care Circle Empty") {
    CareCirclePreviewCard(members: [])
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("Care Circle With Members") {
    CareCirclePreviewCard(members: [
        CareCircleMember(
            firstName: "Sarah",
            lastName: "Johnson",
            phoneNumber: "555-1234",
            relationship: "Daughter",
            isPrimary: true
        ),
        CareCircleMember(
            firstName: "Michael",
            lastName: "Johnson",
            phoneNumber: "555-5678",
            relationship: "Son"
        )
    ])
    .padding()
    .background(Color(.systemGroupedBackground))
}
