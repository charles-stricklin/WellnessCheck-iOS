//
//  WhyPermissionsView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/1/25.
//
//  Screen 5A of onboarding - Explains WHY WellnessCheck needs Health Data and
//  Notification permissions BEFORE requesting them. Builds understanding and trust
//  so seniors aren't confused when iOS permission dialogs appear.
//

import SwiftUI

struct WhyPermissionsView: View {
    // MARK: - Properties
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    
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
                    
                    // Header
                    VStack(spacing: 12) {
                        Image("Gladtomeetyou")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                        
                        Text("Good to meet you, \(viewModel.userName)!")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("Before we continue, let's talk about what WellnessCheck needs to watch for signs you might need help")
                            .font(.system(size: 20))
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Explanation cards
                    VStack(spacing: 24) {
                        // Health Data explanation
                        PermissionExplanationCard(
                            icon: "heart.text.square.fill",
                            title: "Access to Your Health Data",
                            reasons: [
                                "Monitor your daily activity patterns so we know what's normal for YOU",
                                "Detect falls using your iPhone's sensors (or Apple Watch if you have one)",
                                "Notice unusual inactivity that might mean you need help",
                                "Track your movement throughout the day to spot concerning changes"
                            ],
                            colorScheme: colorScheme
                        )
                        
                        // Notifications explanation
                        PermissionExplanationCard(
                            icon: "bell.badge.fill",
                            title: "Permission to Send Notifications",
                            reasons: [
                                "Check in with you if something seems wrong: \"Are you okay?\"",
                                "Remind you to take your medications on time",
                                "Alert you about upcoming doctor appointments",
                                "Let you know when your Care Circle has been notified"
                            ],
                            colorScheme: colorScheme
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Reassurance
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 28))
                                .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Data Stays Private")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(primaryTextColor)
                                
                                Text("We only use this information to keep you safe. Nothing is shared without your permission.")
                                    .font(.system(size: 16))
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.102, green: 0.227, blue: 0.322).opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Continue button
                    Button(action: onContinue) {
                        Text("That Makes Sense")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color(red: 0.102, green: 0.227, blue: 0.322))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 32)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.067, green: 0.133, blue: 0.267) : Color(red: 0.784, green: 0.902, blue: 0.961)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.102, green: 0.227, blue: 0.322)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }
}

// MARK: - Supporting Views

struct PermissionExplanationCard: View {
    let icon: String
    let title: String
    let reasons: [String]
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.102, green: 0.227, blue: 0.322))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Reasons list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(reasons, id: \.self) { reason in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                            .padding(.top, 2)
                        
                        Text(reason)
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(16)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(red: 0.784, green: 0.902, blue: 0.961).opacity(0.3)
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    WhyPermissionsView(viewModel: {
        let vm = OnboardingViewModel()
        vm.userName = "John"
        return vm
    }()) {
        print("Continue tapped")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    WhyPermissionsView(viewModel: {
        let vm = OnboardingViewModel()
        vm.userName = "Mary"
        return vm
    }()) {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
