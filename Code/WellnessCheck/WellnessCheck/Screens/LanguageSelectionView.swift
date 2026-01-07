//
//  LanguageSelectionView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//
//  Screen 0 of onboarding - Language selection before anything else.
//  Currently supports English and Spanish.
//

import SwiftUI

struct LanguageSelectionView: View {
    // MARK: - Properties
    @Environment(\.colorScheme) var colorScheme
    let onLanguageSelected: (String) -> Void
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // WellnessCheck app icon/logo
                if let _ = UIImage(named: "AppLogo") {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                } else {
                    // Fallback to WelcomeIcon if no AppLogo
                    Image("WelcomeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                }
                
                // App name
                Text("WellnessCheck")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(primaryTextColor)
                
                // Language prompt
                Text("Choose Your Language")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                    .padding(.top, 20)
                
                Text("Elige tu idioma")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Language buttons
                VStack(spacing: 16) {
                    // English button
                    Button(action: {
                        onLanguageSelected("en")
                    }) {
                        HStack(spacing: 16) {
                            Text("🇺🇸")
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("English")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("United States")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.102, green: 0.227, blue: 0.322))
                        .cornerRadius(16)
                    }
                    
                    // Spanish button
                    Button(action: {
                        onLanguageSelected("es")
                    }) {
                        HStack(spacing: 16) {
                            Text("🇪🇸")
                                .font(.system(size: 40))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Español")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Spanish")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.102, green: 0.227, blue: 0.322))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
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

// MARK: - Preview

#Preview("Light Mode") {
    LanguageSelectionView { language in
        print("Selected language: \(language)")
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LanguageSelectionView { language in
        print("Selected language: \(language)")
    }
    .preferredColorScheme(.dark)
}
