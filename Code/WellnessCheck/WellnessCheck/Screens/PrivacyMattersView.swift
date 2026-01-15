//
//  PrivacyMattersView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/1/25.
//

import SwiftUI

struct PrivacyMattersView: View {
    @Environment(\.colorScheme) var colorScheme
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 12) {
                        Text("Your Privacy Matters")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("You're in control of your data")
                            .font(.system(size: 20))
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Image("PrivacyIllustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 300)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 24) {
                        PrivacyCard(
                            icon: "iphone.and.arrow.forward",
                            title: "Your Health Data Stays on Your Device",
                            description: "WellnessCheck monitors your activity locally on your iPhone. Your health information never leaves your device without your permission.",
                            colorScheme: colorScheme
                        )
                        
                        PrivacyCard(
                            icon: "person.badge.shield.checkmark",
                            title: "You Control Who Sees What",
                            description: "Your Care Circle only receives alerts when something seems wrong - not constant updates. You decide who's in your Care Circle and can remove anyone at any time.",
                            colorScheme: colorScheme
                        )
                        
                        PrivacyCard(
                            icon: "pause.circle",
                            title: "Pause Monitoring Anytime",
                            description: "Need privacy? You can pause monitoring whenever you want. No questions asked. Turn it back on just as easily.",
                            colorScheme: colorScheme
                        )
                        
                        PrivacyCard(
                            icon: "hand.raised.slash",
                            title: "We Never Sell Your Data",
                            description: "Your information is yours. We don't sell it, share it with advertisers, or use it for anything except keeping you safe.",
                            colorScheme: colorScheme
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 40)
                    
                    Button(action: onContinue) {
                        Text("I Like That")
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
        colorScheme == .dark ? Color(red: 0.067, green: 0.133, blue: 0.267) : Color(red: 0.784, green: 0.902, blue: 0.961)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.102, green: 0.227, blue: 0.322)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }
}

struct PrivacyCard: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(Color(red: 0.784, green: 0.902, blue: 0.961))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.102, green: 0.227, blue: 0.322))
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.system(size: 17))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .cornerRadius(16)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(red: 0.784, green: 0.902, blue: 0.961).opacity(0.3)
    }
}

#Preview {
    PrivacyMattersView {
        print("Continue")
    }
}
