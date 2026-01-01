//
//  WelcomeView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 12/31/24.
//
//  First screen seniors see when opening WellnessCheck for the first time.
//  Establishes emotional connection, explains the core promise (you're not alone),
//  and invites them to explore how it works. Calm, reassuring, patient tone.
//  No rush, no pressure - just understanding and support.
//

import SwiftUI

struct WelcomeView: View {
    // MARK: - Properties
    @Environment(\.colorScheme) var colorScheme
    let onContinue: () -> Void
    
    @State private var showingCaregiverInfo = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Top section - Logo and tagline
                VStack(spacing: 16) {
                    // WellnessCheck app icon
                    Image("WelcomeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    Text("WellnessCheck")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    
                    Text("Living alone doesn't mean having to be alone")
                        .font(.system(size: 20))
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                    .frame(height: 60)
                
                // Middle section - Care Circle illustration
                VStack(spacing: 32) {
                    // Main illustration
                    Image("CareCircleIllustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320, maxHeight: 320)
                        .padding(.horizontal, 24)
                    
                    // Primary message
                    VStack(spacing: 20) {
                        Text("Stay connected to the people who care about you. If something happens, they'll know right away.")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(primaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("WellnessCheck gives you independence and gives them peace of mind.")
                            .font(.system(size: 20))
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                    .frame(height: 60)
                
                // Bottom section - Action button
                VStack(spacing: 16) {
                    // Main action button
                    Button(action: onContinue) {
                        Text("Show Me How This Works")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color("#1A3A52"))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    
                    // Caregiver setup link
                    Button(action: {
                        showingCaregiverInfo = true
                    }) {
                        Text("I'm helping someone set this up")
                            .font(.system(size: 18))
                            .foregroundColor(secondaryTextColor)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .alert("Setting Up for Someone Else", isPresented: $showingCaregiverInfo) {
            Button("Continue with Setup", role: .cancel) {
                onContinue()
            }
        } message: {
            Text("Great! You can complete the setup for your loved one. They'll need to approve Care Circle connections on their device later.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color("#C8E6F5")
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color("#1A3A52")
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    WelcomeView {
        print("Continue tapped")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    WelcomeView {
        print("Continue tapped")
    }
    .preferredColorScheme(.dark)
}
