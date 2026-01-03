//
//  ProfileSetupView.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.2.0 (2026-01-02)
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
        case surname
        case phone
        case email
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
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
                // Name field (REQUIRED)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Your First Name")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("*")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)
                    }

                    TextField("John", text: $viewModel.userName)
                        .font(.system(size: Constants.bodyTextSize))
                        .padding()
                        .frame(height: Constants.minTouchTargetSize)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .focused($focusedField, equals: .name)
                        .textContentType(.givenName)
                        .autocapitalization(.words)
                }
                
                // Surname field (REQUIRED)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Your Last Name")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("*")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)
                    }

                    TextField("Doe", text: $viewModel.userSurname)
                        .font(.system(size: Constants.bodyTextSize))
                        .padding()
                        .frame(height: Constants.minTouchTargetSize)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .focused($focusedField, equals: .surname)
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                }

                // Phone number field (REQUIRED)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Phone Number")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("*")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.red)
                    }

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
                
                // Email field (OPTIONAL)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email (optional)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    TextField("john@example.com", text: $viewModel.userEmail)
                        .font(.system(size: Constants.bodyTextSize))
                        .padding()
                        .frame(height: Constants.minTouchTargetSize)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }

                // Helper text
                Text("We'll use your phone number to connect you with your Care Circle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
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

            // Continue button (with validation)
            LargeButton(
                title: "Continue",
                systemImage: "arrow.right",
                backgroundColor: isFormValid ? .blue : .gray,
                action: {
                    // Dismiss keyboard
                    focusedField = nil
                    onContinue()
                }
            )
            .disabled(!isFormValid)
            .padding(.horizontal, Constants.standardSpacing)
            .padding(.bottom, Constants.standardSpacing)
        }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss keyboard when tapping outside fields
            focusedField = nil
        }
    }
    
    // MARK: - Validation
    
    /// Check if required fields are filled
    private var isFormValid: Bool {
        let name = viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let surname = viewModel.userSurname.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = viewModel.userPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !name.isEmpty && !surname.isEmpty && !phone.isEmpty
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
