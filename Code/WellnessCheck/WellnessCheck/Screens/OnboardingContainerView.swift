//
//  OnboardingContainerView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import SwiftUI

/// Main container that orchestrates the onboarding flow
struct OnboardingContainerView: View {
    // MARK: - Properties

    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Callback when onboarding is complete
    let onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(.systemBackground)
                    .ignoresSafeArea()

                // Current onboarding screen
                Group {
                    switch viewModel.currentStep {
                    case .languageSelection:
                        LanguageSelectionView { language in
                            viewModel.selectedLanguage = language
                            viewModel.goToNextStep()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                    case .welcome:
                        WelcomeView {
                            viewModel.goToNextStep()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))

                    case .howItWorks:
                        HowItWorksView {
                            viewModel.goToNextStep()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))

                    case .privacy:
                        PrivacyMattersView {
                            viewModel.goToNextStep()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))

                    case .contactSelection:
                        ProfileSetupView(viewModel: viewModel) {
                            viewModel.goToNextStep()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))

                    case .whyNotifications:
                        WhyNotificationsView(viewModel: viewModel) {
                            viewModel.goToNextStep()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                    case .whyHealthData:
                        WhyHealthDataView(viewModel: viewModel) {
                            viewModel.goToNextStep()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))

                    case .careCircleSetup:
                        CareCircleIntroView(viewModel: viewModel) {
                            viewModel.goToNextStep()
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))

                    case .customizeMonitoring:
                        VStack(spacing: 20) {
                            Text("Customize Monitoring")
                                .font(.title)
                            Text("Coming Soon")
                                .foregroundColor(.secondary)
                            Button("Continue") {
                                viewModel.goToNextStep()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                    case .complete:
                        // This case triggers the completion handler
                        EmptyView()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Back button (hidden on language selection screen)
                    if viewModel.currentStep != .languageSelection && viewModel.currentStep != .welcome {
                        Button(action: {
                            withAnimation {
                                viewModel.goToPreviousStep()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 18))
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onChange(of: viewModel.isOnboardingComplete) { oldValue, newValue in
            if newValue {
                onComplete()
            }
        }
    }
}

// MARK: - Progress Indicator Component

/// Shows visual progress through the onboarding flow
private struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Color.blue : Color.white)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView {
        print("Onboarding complete")
    }
}
