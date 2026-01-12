//
//  WhyNotificationsView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/2/26.
//
//  Screen 5A of onboarding - Explains WHY WellnessCheck needs Notification
//  permissions in simple, clear language. Focuses ONLY on notifications.
//

import SwiftUI

struct WhyNotificationsView: View {
    // MARK: - Properties
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    
    @State private var isRequestingPermission = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Header with illustration
                    VStack(spacing: 12) {
                        Image("Gladtomeetyou")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                        
                        Text("Good to meet you, \(viewModel.userName)!")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Main explanation
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Let's talk about notifications")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("WellnessCheck watches for signs that something might be wrong. When we notice something unusual, we need to be able to ask you a simple question:")
                            .font(.system(size: 20))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Big emphasis on the key question
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                            
                            Text("\"Are you okay?\"")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color(red: 0.102, green: 0.227, blue: 0.322).opacity(0.1))
                        .cornerRadius(16)
                        
                        Text("If you answer \"yes\" or tap that you're fine, great! We leave you alone.")
                            .font(.system(size: 20))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("But if you don't respond after a few minutes, that's when we alert your Care Circle that you might need help.")
                            .font(.system(size: 20))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                    
                    // What else notifications do
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notifications also help with:")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(primaryTextColor)

                        VStack(alignment: .leading, spacing: 16) {
                            // MARK: - Future Features (commented out for v1)
//                            NotificationPurposeRow(
//                                icon: "pills.fill",
//                                text: "Reminding you to take your medications on time"
//                            )
//
//                            NotificationPurposeRow(
//                                icon: "calendar.badge.clock",
//                                text: "Alerting you about upcoming doctor appointments"
//                            )

                            NotificationPurposeRow(
                                icon: "checkmark.circle.fill",
                                text: "Letting you know when we've notified your Care Circle"
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Request notification permission button
                    Button(action: {
                        Task {
                            isRequestingPermission = true
                            await viewModel.requestNotificationPermission()
                            isRequestingPermission = false
                            // Proceed to next screen after permission request
                            onContinue()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isRequestingPermission ? "Requesting..." : "Yes, I Allow Notifications")
                                .font(.system(size: 22, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(Color(red: 0.102, green: 0.227, blue: 0.322))
                        .cornerRadius(16)
                    }
                    .disabled(isRequestingPermission)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 32)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.784, green: 0.902, blue: 0.961)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.102, green: 0.227, blue: 0.322)
    }
}

// MARK: - Supporting Views

struct NotificationPurposeRow: View {
    let icon: String
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                .frame(width: 30)

            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    WhyNotificationsView(viewModel: {
        let vm = OnboardingViewModel()
        vm.userName = "Charles"
        return vm
    }()) {
        print("Continue tapped")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    WhyNotificationsView(viewModel: {
        let vm = OnboardingViewModel()
        vm.userName = "Mary"
        return vm
    }()) {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
