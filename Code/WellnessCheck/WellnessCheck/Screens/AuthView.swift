//
//  AuthView.swift
//  WellnessCheck
//
//  Created: v0.4.0 (2026-01-15)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Authentication screen for WellnessCheck. Allows users to sign in with
//  email/password or Sign in with Apple. Follows senior-friendly design
//  with large touch targets and clear, simple language.
//
//  WHY THIS EXISTS:
//  User accounts enable cloud sync of Care Circle data and allow
//  Cloud Functions to send SMS alerts on behalf of the user.
//  Without authentication, data stays local and alerts can't be sent.
//
//  FLOW:
//  This screen appears after onboarding completes. Users must create
//  an account or sign in before using the main app features.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    // MARK: - Properties

    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authService = AuthService()

    /// Callback when authentication succeeds
    let onAuthenticated: () -> Void

    /// Whether we're showing the sign-up form (vs sign-in)
    @State private var isSignUp = true

    /// Email input field
    @State private var email = ""

    /// Password input field
    @State private var password = ""

    /// Confirm password field (sign-up only)
    @State private var confirmPassword = ""

    /// Whether to show password in plain text
    @State private var showPassword = false

    /// Whether to show password reset flow
    @State private var showingPasswordReset = false

    /// Email for password reset
    @State private var resetEmail = ""

    /// Whether password reset was sent successfully
    @State private var resetEmailSent = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(accentColor)

                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(primaryTextColor)

                        Text(isSignUp
                             ? "Create an account to keep your Care Circle safe and synced."
                             : "Sign in to access your Care Circle.")
                            .font(.system(size: 18))
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Spacer()
                        .frame(height: 20)

                    // Email/Password Form
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(primaryTextColor)

                            TextField("your@email.com", text: $email)
                                .font(.system(size: 20))
                                .padding()
                                .frame(height: 60)
                                .background(inputBackgroundColor)
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 24)

                        // Password field with visibility toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(primaryTextColor)

                            HStack {
                                if showPassword {
                                    TextField("", text: $password)
                                        .font(.system(size: 20))
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("", text: $password)
                                        .font(.system(size: 20))
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(secondaryTextColor)
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .padding(.horizontal)
                            .frame(height: 60)
                            .background(inputBackgroundColor)
                            .cornerRadius(12)

                            // Password requirements hint
                            Text("At least 6 characters")
                                .font(.system(size: 14))
                                .foregroundColor(secondaryTextColor)
                        }
                        .padding(.horizontal, 24)

                        // Confirm password field (sign-up only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(primaryTextColor)

                                HStack {
                                    if showPassword {
                                        TextField("", text: $confirmPassword)
                                            .font(.system(size: 20))
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("", text: $confirmPassword)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.horizontal)
                                .frame(height: 60)
                                .background(inputBackgroundColor)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                        }

                        // Password mismatch message (sign-up only)
                        if isSignUp && !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords don't match")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                        }

                        // Error message from Firebase
                        if let error = authService.errorMessage {
                            Text(error)
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // Submit button
                        Button(action: submitForm) {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(isFormValid ? Color("#1A3A52") : Color.gray)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .disabled(!isFormValid || authService.isLoading)

                        // Forgot password (sign-in only)
                        if !isSignUp {
                            Button(action: { showingPasswordReset = true }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 18))
                                    .foregroundColor(accentColor)
                            }
                        }
                    }

                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(dividerColor)
                        Text("or")
                            .font(.system(size: 16))
                            .foregroundColor(secondaryTextColor)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(dividerColor)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)

                    // Sign in with Apple
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let appleRequest = authService.prepareAppleSignInRequest()
                            request.requestedScopes = appleRequest.requestedScopes
                            request.nonce = appleRequest.nonce
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                Task {
                                    await authService.signInWithApple(authorization: authorization)
                                }
                            case .failure(let error):
                                // User cancelled or error occurred
                                print("Sign in with Apple failed: \(error.localizedDescription)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 70)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 20)

                    // Toggle sign-in / sign-up
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp
                             ? "Already have an account? Sign In"
                             : "Don't have an account? Create One")
                            .font(.system(size: 18))
                            .foregroundColor(accentColor)
                    }

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .onChange(of: authService.currentUser) { oldValue, newValue in
            // When user successfully authenticates, call the completion handler
            if newValue != nil {
                onAuthenticated()
            }
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetSheet(
                email: $resetEmail,
                emailSent: $resetEmailSent,
                authService: authService,
                isPresented: $showingPasswordReset
            )
        }
    }

    // MARK: - Actions

    /// Submit the email/password form
    private func submitForm() {
        Task {
            if isSignUp {
                await authService.signUp(email: email, password: password)
            } else {
                await authService.signIn(email: email, password: password)
            }
        }
    }

    // MARK: - Validation

    /// Whether the form has valid input
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6

        if isSignUp {
            let passwordsMatch = password == confirmPassword
            return emailValid && passwordValid && passwordsMatch
        } else {
            return emailValid && passwordValid
        }
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.067, green: 0.133, blue: 0.267) : Color("#C8E6F5")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color("#1A3A52")
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }

    private var accentColor: Color {
        Color("#C8E6F5")
    }

    private var inputBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white
    }

    private var dividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }
}

// MARK: - Password Reset Sheet

/// Sheet for requesting a password reset email
struct PasswordResetSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var email: String
    @Binding var emailSent: Bool
    var authService: AuthService
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    if emailSent {
                        // Success state
                        VStack(spacing: 16) {
                            Image(systemName: "envelope.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)

                            Text("Check Your Email")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(primaryTextColor)

                            Text("We sent a password reset link to \(email)")
                                .font(.system(size: 18))
                                .foregroundColor(secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Button(action: { isPresented = false }) {
                                Text("Done")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 70)
                                    .background(Color("#1A3A52"))
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        }
                    } else {
                        // Input state
                        VStack(spacing: 16) {
                            Text("Reset Password")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(primaryTextColor)

                            Text("Enter your email and we'll send you a link to reset your password.")
                                .font(.system(size: 18))
                                .foregroundColor(secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            TextField("your@email.com", text: $email)
                                .font(.system(size: 20))
                                .padding()
                                .frame(height: 60)
                                .background(inputBackgroundColor)
                                .cornerRadius(12)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 24)

                            if let error = authService.errorMessage {
                                Text(error)
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 24)
                            }

                            Button(action: {
                                Task {
                                    await authService.sendPasswordReset(email: email)
                                    if authService.errorMessage == nil {
                                        emailSent = true
                                    }
                                }
                            }) {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Send Reset Link")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(email.contains("@") ? Color("#1A3A52") : Color.gray)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            .disabled(!email.contains("@") || authService.isLoading)
                        }
                    }

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
    }

    // MARK: - Colors

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.067, green: 0.133, blue: 0.267) : Color("#C8E6F5")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color("#1A3A52")
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.gray : Color.gray
    }

    private var accentColor: Color {
        Color("#C8E6F5")
    }

    private var inputBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white
    }
}

// MARK: - Preview

#Preview("Sign Up - Light") {
    AuthView {
        print("Authenticated")
    }
    .preferredColorScheme(.light)
}

#Preview("Sign Up - Dark") {
    AuthView {
        print("Authenticated")
    }
    .preferredColorScheme(.dark)
}
