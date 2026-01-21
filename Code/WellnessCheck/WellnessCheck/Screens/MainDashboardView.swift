//
//  MainDashboardView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.6.0 (2026-01-17)
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
//  UPDATE 2026-01-17: Built out all four main tabs:
//  - Home: Status card, today's activity, Care Circle preview, "I'm OK" button
//  - Activity: Weekly/monthly history with daily breakdown, totals, averages
//  - Care Circle: Full member management (add/edit/reorder/delete)
//  - Settings: Profile, Notifications, Monitoring, Home Location, Help, About
//

import SwiftUI
import UIKit
import Contacts
import CoreLocation

/// Main dashboard view shown after onboarding is complete
struct MainDashboardView: View {
    // MARK: - Properties

    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(Constants.userNameKey) private var userName = ""
    @State private var selectedTab: DashboardTab = .home

    /// Shared ViewModel for dashboard data (HealthKit + Care Circle)
    /// StateObject ensures it persists across view updates
    @StateObject private var viewModel = DashboardViewModel()

    /// Care Circle ViewModel for fall alert integration
    @StateObject private var careCircleViewModel = CareCircleViewModel()

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
        // Fall alert overlay - shows full-screen when fall is detected
        .fallAlertOverlay(careCircleViewModel: careCircleViewModel)
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

    /// Service for calling Cloud Functions (SMS via Twilio)
    @StateObject private var cloudFunctions = CloudFunctionsService()

    /// Fall detection service to check monitoring status
    @ObservedObject private var fallDetectionService = FallDetectionService.shared

    /// Track color scheme for dark mode background
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingImOkConfirmation = false
    @State private var showingImOkResult = false
    @State private var imOkResultSuccess = false
    @State private var imOkResultMessage = ""

    /// Check if fall detection is enabled in settings but not currently monitoring
    /// This happens when the app is backgrounded (iOS cannot run continuous accelerometer)
    private var showFallDetectionPausedWarning: Bool {
        let fallDetectionEnabled = UserDefaults.standard.bool(forKey: "monitoring_fallDetection")
        return fallDetectionEnabled && !fallDetectionService.isMonitoring
    }

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

                    // MARK: - Fall Detection Paused Warning
                    // Show when fall detection is enabled but app is backgrounded
                    // iOS cannot run continuous accelerometer monitoring in background
                    if showFallDetectionPausedWarning {
                        FallDetectionPausedBanner()
                            .padding(.horizontal, 16)
                    }

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
                                Task {
                                    let result = await cloudFunctions.sendImOkMessage(
                                        userName: userName.isEmpty ? "Your contact" : userName,
                                        members: viewModel.careCircleViewModel.members
                                    )
                                    imOkResultSuccess = result.success
                                    if result.success {
                                        imOkResultMessage = "Message sent to \(result.sent) of \(result.total) Care Circle member\(result.total == 1 ? "" : "s")."
                                    } else {
                                        imOkResultMessage = result.error ?? "Failed to send message. Please try again."
                                    }
                                    showingImOkResult = true
                                }
                            }
                        } message: {
                            Text("This will notify your Care Circle that you're doing fine.")
                        }
                        .alert(imOkResultSuccess ? "Message Sent" : "Message Failed", isPresented: $showingImOkResult) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text(imOkResultMessage)
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

// MARK: - Fall Detection Paused Banner
// Shows when fall detection is enabled but app is backgrounded
// iOS limitation: continuous accelerometer monitoring requires foreground

struct FallDetectionPausedBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fall Detection Paused")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Keep app open for fall protection")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
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
    // MARK: - Properties

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var healthKit = HealthKitService()

    /// Daily activity data for the past week
    @State private var dailySteps: [(date: Date, steps: Int)] = []
    @State private var dailyFloors: [(date: Date, floors: Int)] = []
    @State private var dailyEnergy: [(date: Date, calories: Int)] = []

    /// Loading state
    @State private var isLoading = true

    /// Time period selection
    @State private var selectedPeriod: ActivityPeriod = .week

    /// Light blue accent color
    private let lightBlue = Color(red: 0.784, green: 0.902, blue: 0.961)

    /// Background color - dark blue in dark mode, system grouped in light mode
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.067, green: 0.133, blue: 0.267)
            : Color(.systemGroupedBackground)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Period selector
                        periodSelector
                            .padding(.top, 8)

                        if isLoading {
                            loadingView
                        } else if dailySteps.isEmpty {
                            emptyStateView
                        } else {
                            // Weekly summary card
                            weeklySummaryCard
                                .padding(.horizontal, 16)

                            // Daily breakdown
                            dailyBreakdownSection
                                .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadActivityData()
            }
            .refreshable {
                await loadActivityData()
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("Period", selection: $selectedPeriod) {
            Text("Week").tag(ActivityPeriod.week)
            Text("Month").tag(ActivityPeriod.month)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                await loadActivityData()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading activity data...")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(minHeight: 300)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "figure.walk")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Activity Data")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text("Activity will appear here once your device starts recording steps and movement.")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(minHeight: 300)
    }

    // MARK: - Weekly Summary Card

    private var weeklySummaryCard: some View {
        VStack(spacing: 16) {
            Text(selectedPeriod == .week ? "THIS WEEK" : "THIS MONTH")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                // Total Steps
                VStack(spacing: 4) {
                    Text("👟")
                        .font(.system(size: 28))
                    Text("\(totalSteps.formatted())")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("steps")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 60)

                // Total Floors
                VStack(spacing: 4) {
                    Text("🏢")
                        .font(.system(size: 28))
                    Text("\(totalFloors)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("floors")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1, height: 60)

                // Total Calories
                VStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 28))
                    Text("\(totalCalories.formatted())")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("cal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)

            // Daily average
            HStack {
                Text("Daily Average:")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(averageSteps.formatted()) steps")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Daily Breakdown

    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DAILY BREAKDOWN")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(dailySteps.indices, id: \.self) { index in
                    let stepData = dailySteps[index]
                    let floorData = dailyFloors.first { Calendar.current.isDate($0.date, inSameDayAs: stepData.date) }
                    let energyData = dailyEnergy.first { Calendar.current.isDate($0.date, inSameDayAs: stepData.date) }

                    DailyActivityRow(
                        date: stepData.date,
                        steps: stepData.steps,
                        floors: floorData?.floors ?? 0,
                        calories: energyData?.calories ?? 0,
                        maxSteps: maxDailySteps,
                        isToday: Calendar.current.isDateInToday(stepData.date)
                    )
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var totalSteps: Int {
        dailySteps.reduce(0) { $0 + $1.steps }
    }

    private var totalFloors: Int {
        dailyFloors.reduce(0) { $0 + $1.floors }
    }

    private var totalCalories: Int {
        dailyEnergy.reduce(0) { $0 + $1.calories }
    }

    private var averageSteps: Int {
        guard !dailySteps.isEmpty else { return 0 }
        return totalSteps / dailySteps.count
    }

    private var maxDailySteps: Int {
        dailySteps.map { $0.steps }.max() ?? 1
    }

    // MARK: - Data Loading

    private func loadActivityData() async {
        isLoading = true

        let days = selectedPeriod == .week ? 7 : 30

        async let steps = healthKit.fetchDailySteps(forLastDays: days)
        async let floors = healthKit.fetchDailyFloors(forLastDays: days)
        async let energy = healthKit.fetchDailyEnergy(forLastDays: days)

        dailySteps = await steps
        dailyFloors = await floors
        dailyEnergy = await energy

        isLoading = false
    }
}

// MARK: - Activity Period Enum

enum ActivityPeriod {
    case week
    case month
}

// MARK: - Daily Activity Row

struct DailyActivityRow: View {
    let date: Date
    let steps: Int
    let floors: Int
    let calories: Int
    let maxSteps: Int
    let isToday: Bool

    /// Light blue for the progress bar
    private let lightBlue = Color(red: 0.784, green: 0.902, blue: 0.961)

    var body: some View {
        HStack(spacing: 12) {
            // Date column
            VStack(alignment: .leading, spacing: 2) {
                Text(dayName)
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? lightBlue : .primary)
                Text(dateString)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)

            // Steps with visual bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(steps.formatted())")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("steps")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(floors) fl")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(calories) cal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                // Progress bar showing relative activity level
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 8)

                        // Fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isToday ? lightBlue : Color.green.opacity(0.7))
                            .frame(width: max(4, geometry.size.width * progressRatio), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Computed Properties

    private var dayName: String {
        if isToday {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private var progressRatio: CGFloat {
        guard maxSteps > 0 else { return 0 }
        return CGFloat(steps) / CGFloat(maxSteps)
    }
}

struct CareCircleTabView: View {
    // MARK: - Properties

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = CareCircleViewModel()

    @State private var showAddMember = false
    @State private var showContactPicker = false
    @State private var selectedMemberToEdit: CareCircleMember? = nil
    @State private var showConfirmContact = false
    @State private var selectedContactData: (firstName: String, lastName: String, phone: String, email: String?, imageData: Data?)? = nil

    /// Light blue accent color used throughout the app
    private let lightBlue = Color(red: 0.784, green: 0.902, blue: 0.961)

    /// Background color - dark blue in dark mode, system grouped in light mode
    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.067, green: 0.133, blue: 0.267)
            : Color(.systemGroupedBackground)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if viewModel.members.isEmpty {
                        // Empty state
                        emptyStateView
                    } else {
                        // Member list
                        memberListView
                    }

                    // Action buttons at bottom
                    actionButtonsView
                }
            }
            .navigationTitle("Care Circle")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddMember) {
                AddCareCircleMemberView(viewModel: viewModel)
            }
            .sheet(item: $selectedMemberToEdit) { member in
                EditCareCircleMemberView(viewModel: viewModel, member: member)
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker(isPresented: $showContactPicker) { contact in
                    // Store the selected contact data (including photo) and show confirmation view
                    selectedContactData = (
                        firstName: contact.firstName,
                        lastName: contact.lastName,
                        phone: contact.primaryPhoneNumber ?? "",
                        email: contact.primaryEmailAddress,
                        imageData: contact.contactImageData
                    )
                    showConfirmContact = true
                }
            }
            .sheet(isPresented: $showConfirmContact) {
                if let contactData = selectedContactData {
                    ConfirmCareCircleMemberView(
                        viewModel: viewModel,
                        firstName: contactData.firstName,
                        lastName: contactData.lastName,
                        phoneNumber: contactData.phone,
                        email: contactData.email,
                        imageData: contactData.imageData
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Care Circle Members")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text("Add trusted people who will be notified if you need help.")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Member List

    private var memberListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Member count header
                HStack {
                    Text("\(viewModel.members.count) member\(viewModel.members.count == 1 ? "" : "s")")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)

                // Member rows
                ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                    CareCircleTabMemberRow(
                        member: member,
                        position: index + 1,
                        isFirst: index == 0,
                        isLast: index == viewModel.members.count - 1,
                        colorScheme: colorScheme,
                        onMoveUp: { viewModel.moveMemberUp(member) },
                        onMoveDown: { viewModel.moveMemberDown(member) }
                    )
                    .onTapGesture {
                        selectedMemberToEdit = member
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            // Add from Contacts button (primary action)
            Button(action: {
                showContactPicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 22))
                    Text("Add from Contacts")
                        .font(.system(size: 22, weight: .semibold))
                }
                .foregroundColor(colorScheme == .dark ? Color(red: 0.102, green: 0.227, blue: 0.322) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(lightBlue)
                .cornerRadius(16)
            }

            // Manual Add Member button (secondary action)
            Button(action: {
                showAddMember = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 22))
                    Text("Add Manually")
                        .font(.system(size: 22, weight: .semibold))
                }
                .foregroundColor(lightBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lightBlue, lineWidth: 2)
                )
                .cornerRadius(16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Care Circle Tab Member Row
// Separate from onboarding row to allow independent styling if needed

struct CareCircleTabMemberRow: View {
    let member: CareCircleMember
    let position: Int
    let isFirst: Bool
    let isLast: Bool
    let colorScheme: ColorScheme
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    private let lightBlue = Color(red: 0.784, green: 0.902, blue: 0.961)

    var body: some View {
        HStack(spacing: 12) {
            // Order number
            Text("\(position)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(lightBlue)
                .frame(width: 36)

            // Up/Down arrows for reordering
            VStack(spacing: 4) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isFirst ? .gray.opacity(0.3) : lightBlue)
                }
                .disabled(isFirst)

                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isLast ? .gray.opacity(0.3) : lightBlue)
                }
                .disabled(isLast)
            }
            .frame(width: 30)

            // Avatar - show contact photo if available, otherwise initials
            if let imageData = member.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(member.isPrimary ? lightBlue : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(member.isPrimary ? lightBlue : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)

                    Text("\(member.firstName.prefix(1))\(member.lastName.prefix(1))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(member.isPrimary ? Color(red: 0.102, green: 0.227, blue: 0.322) : .gray)
                }
            }

            // Name, relationship, and status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(member.fullName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    if member.isPrimary {
                        Text("PRIMARY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(lightBlue)
                            .cornerRadius(4)
                    }
                }

                Text(member.relationship)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text(member.phoneNumber)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    // Invitation status badge
                    invitationStatusBadge(for: member)
                }
            }

            Spacer()

            // Chevron indicating tappable
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func invitationStatusBadge(for member: CareCircleMember) -> some View {
        switch member.invitationStatus {
        case .pending:
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                Text("Pending")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)

        case .sent:
            HStack(spacing: 4) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 10))
                Text("Invited")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)

        case .accepted:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                Text("Connected")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.1))
            .cornerRadius(4)

        case .declined:
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                Text("Declined")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.1))
            .cornerRadius(4)
        }
    }
}

struct SettingsTabView: View {
    @AppStorage(Constants.hasCompletedOnboardingKey) private var hasCompletedOnboarding = false
    @StateObject private var authService = AuthService()

    /// Controls display of account deletion confirmation
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var isDeletingAccount = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        Label("Profile", systemImage: "person.circle")
                    }

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                } header: {
                    Text("Account")
                }

                Section {
                    NavigationLink {
                        MonitoringSettingsView()
                    } label: {
                        Label("Monitoring Settings", systemImage: "shield")
                    }

                    NavigationLink {
                        HomeLocationSettingsView()
                    } label: {
                        Label("Home Location", systemImage: "house")
                    }
                } header: {
                    Text("Monitoring")
                }

                Section {
                    NavigationLink {
                        HelpView()
                    } label: {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About WellnessCheck", systemImage: "info.circle")
                    }
                } header: {
                    Text("Support")
                }

                // Sign out section (only show if signed in)
                if authService.isSignedIn {
                    Section {
                        Button {
                            authService.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }

                    // Account deletion section (App Store requirement)
                    Section {
                        Button {
                            showingDeleteConfirmation = true
                        } label: {
                            if isDeletingAccount {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                    Text("Deleting Account...")
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Label("Delete Account", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .disabled(isDeletingAccount)
                    } footer: {
                        Text("Permanently deletes your account and all associated data. This cannot be undone.")
                            .font(.system(size: 12))
                    }
                    .alert("Delete Account?", isPresented: $showingDeleteConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            Task {
                                isDeletingAccount = true
                                await authService.deleteAccount()
                                isDeletingAccount = false

                                if authService.errorMessage != nil {
                                    showingDeleteError = true
                                }
                            }
                        }
                    } message: {
                        Text("This will permanently delete your account, Care Circle data, and all settings. This action cannot be undone.")
                    }
                    .alert("Unable to Delete Account", isPresented: $showingDeleteError) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(authService.errorMessage ?? "An error occurred. You may need to sign in again before deleting your account.")
                    }
                }

                // Developer section
                #if DEBUG
                Section {
                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Developer")
                }
                #endif
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Profile Settings View

struct ProfileSettingsView: View {
    @AppStorage(Constants.userNameKey) private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @AppStorage("userPhone") private var userPhone = ""

    @State private var editedName = ""
    @State private var editedEmail = ""
    @State private var editedPhone = ""
    @State private var showingSaveConfirmation = false

    var body: some View {
        Form {
            Section("Personal Information") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    TextField("Your name", text: $editedName)
                        .font(.system(size: 18))
                        .textContentType(.name)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    TextField("your@email.com", text: $editedEmail)
                        .font(.system(size: 18))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    TextField("(555) 123-4567", text: $editedPhone)
                        .font(.system(size: 18))
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button("Save Changes") {
                    saveChanges()
                }
                .frame(maxWidth: .infinity)
                .font(.system(size: 18, weight: .semibold))
                .disabled(!hasChanges)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editedName = userName
            editedEmail = userEmail
            editedPhone = userPhone
        }
        .alert("Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your profile has been updated.")
        }
    }

    private var hasChanges: Bool {
        editedName != userName || editedEmail != userEmail || editedPhone != userPhone
    }

    private func saveChanges() {
        userName = editedName
        userEmail = editedEmail
        userPhone = editedPhone
        showingSaveConfirmation = true
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("quietHoursStart") private var quietHoursStartInterval: Double = 22 * 3600 // 10 PM
    @AppStorage("quietHoursEnd") private var quietHoursEndInterval: Double = 7 * 3600 // 7 AM

    private var quietHoursStart: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: quietHoursStartInterval) },
            set: { quietHoursStartInterval = $0.timeIntervalSince1970 }
        )
    }

    private var quietHoursEnd: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: quietHoursEndInterval) },
            set: { quietHoursEndInterval = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .font(.system(size: 18))
            } footer: {
                Text("Receive alerts when WellnessCheck detects something unusual or needs your attention.")
            }

            Section {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                    .font(.system(size: 18))

                if quietHoursEnabled {
                    DatePicker("Start", selection: quietHoursStart, displayedComponents: .hourAndMinute)
                        .font(.system(size: 18))

                    DatePicker("End", selection: quietHoursEnd, displayedComponents: .hourAndMinute)
                        .font(.system(size: 18))
                }
            } header: {
                Text("Quiet Hours")
            } footer: {
                Text("During quiet hours, WellnessCheck won't send you check-in nudges. Emergency alerts to your Care Circle are not affected.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: quietHoursEnabled)
    }
}

// MARK: - Monitoring Settings View

struct MonitoringSettingsView: View {
    @StateObject private var viewModel = CustomizeMonitoringViewModel()

    var body: some View {
        Form {
            Section {
                Toggle("Fall Detection", isOn: $viewModel.fallDetectionEnabled)
                    .font(.system(size: 18))
            } footer: {
                Text("Alert your Care Circle if you take a hard fall and don't respond.\n\nNote: Fall detection requires the app to be open. When backgrounded, inactivity monitoring continues but fall detection pauses.")
            }

            Section {
                Toggle("Inactivity Alerts", isOn: $viewModel.inactivityAlertsEnabled)
                    .font(.system(size: 18))

                if viewModel.inactivityAlertsEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Silence Threshold")
                                .font(.system(size: 18))
                            Spacer()
                            Text("\(Int(viewModel.silenceThresholdHours)) hours")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                        }

                        Slider(
                            value: $viewModel.silenceThresholdHours,
                            in: 2...12,
                            step: 0.5
                        )
                        .tint(.blue)

                        HStack {
                            Text("2 hrs")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("12 hrs")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } footer: {
                Text("Alert your Care Circle if there's no phone activity for the specified duration. Adjust based on your daily routine.")
            }

            Section {
                Toggle("Night Owl Mode", isOn: $viewModel.nightOwlModeEnabled)
                    .font(.system(size: 18))
            } footer: {
                Text("Don't flag late-night activity as unusual. Enable this if you regularly stay up late.")
            }

            Section {
                Toggle("Enable Quiet Hours", isOn: $viewModel.quietHoursEnabled)
                    .font(.system(size: 18))

                if viewModel.quietHoursEnabled {
                    DatePicker("Start", selection: $viewModel.quietHoursStart, displayedComponents: .hourAndMinute)
                        .font(.system(size: 18))

                    DatePicker("End", selection: $viewModel.quietHoursEnd, displayedComponents: .hourAndMinute)
                        .font(.system(size: 18))
                }
            } header: {
                Text("Quiet Hours")
            } footer: {
                Text("Pause check-ins during set hours. Your Care Circle can still be alerted in emergencies.")
            }
        }
        .navigationTitle("Monitoring")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: viewModel.quietHoursEnabled)
        .onDisappear {
            viewModel.saveSettings()
        }
    }
}

// MARK: - Home Location Settings View

struct HomeLocationSettingsView: View {
    /// Use the shared LocationService singleton
    @ObservedObject private var locationService = LocationService.shared

    @State private var showingUpdateConfirmation = false
    @State private var homeLocation: HomeLocation?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Home Location")
                            .font(.system(size: 16, weight: .medium))
                        if let home = homeLocation {
                            Text(home.address ?? "Location set")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not set")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if homeLocation != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                Button {
                    Task {
                        await updateHomeLocation()
                    }
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Update to Current Location")
                    }
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 18, weight: .semibold))
                }
                .disabled(locationService.isFetchingLocation)
            } footer: {
                Text("WellnessCheck uses your home location to provide context when interpreting your activity patterns.")
            }

            if locationService.isFetchingLocation {
                Section {
                    HStack {
                        ProgressView()
                        Text("Getting location...")
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
            }
        }
        .navigationTitle("Home Location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            homeLocation = locationService.loadHomeLocation()
        }
        .alert("Location Updated", isPresented: $showingUpdateConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your home location has been updated to your current location.")
        }
    }

    private func updateHomeLocation() async {
        errorMessage = nil

        // Request permission if needed
        let hasPermission = await locationService.requestLocationPermission()
        guard hasPermission else {
            errorMessage = "Location permission denied. Please enable location access in Settings."
            return
        }

        // Fetch current location
        let result = await locationService.fetchCurrentLocation()

        switch result {
        case .success(let location, _):
            // Reverse geocode to get address
            let address = await locationService.reverseGeocode(location: location)

            // Create and save home location
            let newHome = HomeLocation(coordinate: location.coordinate, address: address)
            locationService.saveHomeLocation(newHome)
            homeLocation = newHome
            showingUpdateConfirmation = true

        case .permissionDenied:
            errorMessage = "Location permission denied. Please enable location access in Settings."

        case .permissionRestricted:
            errorMessage = "Location access is restricted on this device."

        case .locationUnavailable:
            errorMessage = "Location services are not available. Please enable them in Settings."

        case .error(let message):
            errorMessage = message
        }
    }
}

// MARK: - Help View

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                HelpRow(
                    title: "How does WellnessCheck work?",
                    detail: "WellnessCheck monitors your daily activity patterns using your iPhone's sensors. When something unusual happens — like extended inactivity or a detected fall — it can alert your Care Circle."
                )

                HelpRow(
                    title: "What is a Care Circle?",
                    detail: "Your Care Circle is the group of trusted people who will be notified if WellnessCheck detects that you might need help. You can add family members, friends, or caregivers."
                )

                HelpRow(
                    title: "What is the learning period?",
                    detail: "During the first 14 days, WellnessCheck observes your normal routines. This helps it understand what's typical for you, reducing false alerts."
                )
            }

            Section("Privacy & Safety") {
                HelpRow(
                    title: "What data does WellnessCheck collect?",
                    detail: "WellnessCheck uses step count, floors climbed, and motion data from your iPhone to detect activity patterns. This data stays on your device and is never sold or shared with third parties."
                )

                HelpRow(
                    title: "Is WellnessCheck a medical device?",
                    detail: "No. WellnessCheck is not a medical device and cannot detect or prevent medical emergencies. It monitors for inactivity and notifies your designated contacts. It does not replace 911 or professional medical services."
                )
            }

            Section("Contact") {
                Link(destination: URL(string: "mailto:support@wellnesscheck.dev")!) {
                    HStack {
                        Label("Email Support", systemImage: "envelope")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpRow: View {
    let title: String
    let detail: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(detail)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - About View

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // App icon placeholder
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.784, green: 0.902, blue: 0.961))

                    Text("WellnessCheck")
                        .font(.system(size: 28, weight: .bold))

                    Text("Living alone doesn't mean having to be alone.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)

            Section("Developer") {
                HStack {
                    Text("Developed by")
                    Spacer()
                    Text("Stricklin Development, LLC")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Location")
                    Spacer()
                    Text("San Antonio, TX")
                        .foregroundColor(.secondary)
                }
            }

            Section("Legal") {
                Link(destination: URL(string: "https://wellnesscheck.dev/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: URL(string: "https://wellnesscheck.dev/terms")!) {
                    HStack {
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Text("© 2026 Stricklin Development, LLC. All rights reserved.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
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
