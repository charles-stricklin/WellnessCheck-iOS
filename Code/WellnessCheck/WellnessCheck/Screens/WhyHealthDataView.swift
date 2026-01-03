//
//  WhyHealthDataView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/2/26.
//
//  Screen 5B of onboarding - Explains WHY WellnessCheck needs Health Data
//  access in simple, clear language. Comes AFTER notifications explanation.
//

import SwiftUI

struct WhyHealthDataView: View {
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
                    
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                        
                        Text("About Your Health Data")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(primaryTextColor)
                    }
                    
                    // Main explanation
                    VStack(alignment: .leading, spacing: 20) {
                        Text("How we know when to check on you")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Your iPhone (and Apple Watch, if you have one) already tracks things like how much you move around during the day.")
                            .font(.system(size: 20))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("WellnessCheck looks at this information to learn what's normal for YOU. Everyone is different - some people are very active, others less so. That's perfectly fine.")
                            .font(.system(size: 20))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Emphasis box
                        VStack(spacing: 12) {
                            Text("We're looking for changes in YOUR patterns")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                                .multilineTextAlignment(.center)
                            
                            Text("If you're usually active in the morning but one day there's no movement for hours, that's unusual for you - and we check in.")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(Color(red: 0.102, green: 0.227, blue: 0.322).opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    
                    // What we monitor
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What we monitor:")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HealthDataRow(
                                icon: "figure.walk",
                                text: "Your daily activity and movement patterns"
                            )
                            
                            HealthDataRow(
                                icon: "figure.fall",
                                text: "Potential falls detected by your device sensors"
                            )
                            
                            HealthDataRow(
                                icon: "bed.double.fill",
                                text: "Unusual periods of inactivity"
                            )
                            
                            HealthDataRow(
                                icon: "chart.line.uptrend.xyaxis",
                                text: "Changes in your typical routine"
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Privacy reassurance
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Data Stays Private")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(primaryTextColor)
                                
                                Text("This information never leaves your iPhone. We use it only to watch for signs you might need help.")
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
                        .frame(height: 20)
                    
                    // Request permission button
                    Button(action: {
                        Task {
                            isRequestingPermission = true
                            await viewModel.requestHealthKitPermission()
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
                            Text(isRequestingPermission ? "Requesting..." : "Yes, I Allow Access")
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
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }
}

// MARK: - Supporting Views

struct HealthDataRow: View {
    let icon: String
    let text: String
    
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
    WhyHealthDataView(viewModel: OnboardingViewModel()) {
        print("Continue tapped")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    WhyHealthDataView(viewModel: OnboardingViewModel()) {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
