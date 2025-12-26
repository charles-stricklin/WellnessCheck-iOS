//
//  ProfileSetupView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import SwiftUI

/// Onboarding screen to collect user's basic profile information
struct ProfileSetupView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @FocusState private var focusedField: Field?

    // MARK: - Focus State

    private enum Field {
        case name
        case phone
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Constants.largeSpacing) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue.gradient)

                Text("Set Up Your Profile")
                    .font(.system(size: Constants.headerTextSize, weight: .bold))
                    .foregroundColor(.primary)

                Text("This helps your Care Circle know who you are")
                    .font(.system(size: Constants.bodyTextSize))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.standardSpacing)
            }
            .padding(.top, Constants.largeSpacing)

            Spacer()

            // Form fields
            VStack(spacing: Constants.standardSpacing) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("John Doe", text: $viewModel.userName)
                        .font(.system(size: Constants.bodyTextSize))
                        .padding()
                        .frame(height: Constants.minTouchTargetSize)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .focused($focusedField, equals: .name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }

                // Phone number field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("(555) 123-4567", text: $viewModel.userPhone)
                        .font(.system(size: Constants.bodyTextSize))
                        .padding()
                        .frame(height: Constants.minTouchTargetSize)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .focused($focusedField, equals: .phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .onChange(of: viewModel.userPhone) { oldValue, newValue in
                            // Auto-format phone number as user types
                            viewModel.userPhone = viewModel.formatPhoneNumber(newValue)
                        }
                }

                // Helper text
                Text("We'll use your phone number to connect you with your Care Circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Constants.standardSpacing)

            Spacer()

            // Privacy note
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                    Text("Your Information is Secure")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Text("We encrypt your data and only share it with people you add to your Care Circle.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.standardSpacing)
            }
            .padding(.vertical, Constants.standardSpacing)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(Constants.cornerRadius)
            .padding(.horizontal, Constants.standardSpacing)

            // Continue button
            LargeButton(
                title: "Continue",
                systemImage: "arrow.right",
                backgroundColor: viewModel.canProceed() ? .blue : .gray,
                action: {
                    if viewModel.canProceed() {
                        // Dismiss keyboard
                        focusedField = nil
                        onContinue()
                    }
                }
            )
            .disabled(!viewModel.canProceed())
            .padding(.horizontal, Constants.standardSpacing)
            .padding(.bottom, Constants.standardSpacing)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside fields
            focusedField = nil
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileSetupView(
        viewModel: OnboardingViewModel(),
        onContinue: {
            print("Continue tapped")
        }
    )
}
