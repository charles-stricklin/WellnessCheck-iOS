//
//  HowItWorksView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/1/25.
//

import SwiftUI

struct HowItWorksView: View {
    @Environment(\.colorScheme) var colorScheme
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 12) {
                        Text("How It Works")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("Your complete safety and health companion")
                            .font(.system(size: 20))
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Text("WellnessCheck is your personal safety assistant that keeps you connected to the people who care about you. We work with your iPhone to monitor your activity and make sure your Care Circle knows if you need help.")
                        .font(.system(size: 18))
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Image("CareCircleIllustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 300)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 24) {
                        ExplanationCard(
                            icon: "iphone",
                            title: "Passive Monitoring",
                            description: "Your iPhone + WellnessCheck work together, passively monitoring your movements and activities for indications that might signal trouble - like sudden falls, unusual inactivity, or changes in your daily patterns.",
                            colorScheme: colorScheme
                        )
                        
                        ExplanationCard(
                            icon: "bell.badge",
                            title: "Smart Alerts",
                            description: "If something seems wrong, WellnessCheck springs into action. First, it checks with you: \"Are you okay?\" If you don't respond, it alerts your Care Circle immediately.",
                            colorScheme: colorScheme
                        )
                        
                        // MARK: - Future Features (commented out for v1)
                        // Medication reminders
//                        ExplanationCard(
//                            icon: "pills.circle",
//                            title: "Medication Reminders",
//                            description: "Never miss a dose. WellnessCheck reminds you when it's time to take your medications and keeps track of your schedule.",
//                            colorScheme: colorScheme
//                        )

                        // Appointments & doctors
//                        ExplanationCard(
//                            icon: "calendar.badge.clock",
//                            title: "Track Appointments & Doctors",
//                            description: "Keep all your physicians' contact information in one place and get reminders for upcoming appointments.",
//                            colorScheme: colorScheme
//                        )

                        // MARK: - Future v2 Features
                        // Apple Watch integration
//                        ExplanationCard(
//                            icon: "applewatch",
//                            title: "Add an Apple Watch?",
//                            description: "Even better fall detection and around-the-clock activity monitoring give your loved ones greater peace of mind.",
//                            colorScheme: colorScheme,
//                            isOptional: true
//                        )

                        // CGM (Continuous Glucose Monitor) integration
//                        ExplanationCard(
//                            icon: "heart.text.square",
//                            title: "Use a Glucose Monitor?",
//                            description: "Your blood sugar trends are tracked, so concerning patterns can be spotted before they become emergencies.",
//                            colorScheme: colorScheme,
//                            isOptional: true
//                        )
                    }
                    .padding(.horizontal, 24)
                    
                    VStack(spacing: 12) {
                        Text("Once you set it up:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("WellnessCheck runs quietly in the background. You don't need to remember to check in or press buttons - it's always watching out for you.")
                            .font(.system(size: 18))
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Spacer().frame(height: 40)
                    
                    Button(action: onContinue) {
                        Text("Continue")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color(red: 0.102, green: 0.227, blue: 0.322))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 32)
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.075, green: 0.106, blue: 0.196) : Color(red: 0.784, green: 0.902, blue: 0.961)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.102, green: 0.227, blue: 0.322)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }
}

struct ExplanationCard: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let colorScheme: ColorScheme
    var isOptional: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(isOptional ? Color.gray : Color(red: 0.102, green: 0.227, blue: 0.322))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.102, green: 0.227, blue: 0.322))

                Text(description)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isOptional ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var cardBackground: Color {
        if isOptional {
            return colorScheme == .dark ? Color(white: 0.1) : Color.white.opacity(0.5)
        } else {
            return colorScheme == .dark ? Color(white: 0.15) : Color(red: 0.784, green: 0.902, blue: 0.961).opacity(0.3)
        }
    }
}

#Preview {
    HowItWorksView {
        print("Continue")
    }
}
