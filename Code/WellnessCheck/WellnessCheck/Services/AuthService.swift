//
//  AuthService.swift
//  WellnessCheck
//
//  Created: v0.4.0 (2026-01-15)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Service for handling Firebase Authentication.
//  Manages user sign-in, sign-out, and authentication state.
//
//  WHY THIS EXISTS:
//  WellnessCheck needs user accounts to:
//  1. Sync Care Circle data across devices
//  2. Enable the future WellnessWatch companion app to access shared data
//  3. Associate Cloud Functions (like Twilio SMS) with specific users
//  4. Maintain data ownership and privacy boundaries
//
//  AUTHENTICATION FLOW:
//  - Users can sign in with email/password or Sign in with Apple
//  - Authentication happens after onboarding, before first real use
//  - Anonymous auth could be added later for "try before you buy" flow
//

import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices
import CryptoKit

/// Service for managing Firebase Authentication
/// Handles sign-in methods, auth state, and user session management
@MainActor
class AuthService: ObservableObject {

    // MARK: - Published Properties

    /// The currently signed-in Firebase user (nil if signed out)
    @Published var currentUser: FirebaseAuth.User?

    /// Whether an authentication operation is in progress
    @Published var isLoading: Bool = false

    /// The most recent authentication error message (nil if no error)
    @Published var errorMessage: String?

    /// Convenience property to check if a user is currently signed in
    var isSignedIn: Bool {
        currentUser != nil
    }

    /// The current user's unique ID (for Firestore document paths)
    var userId: String? {
        currentUser?.uid
    }

    // MARK: - Private Properties

    /// Firebase Auth instance
    private let auth = Auth.auth()

    /// Listener for authentication state changes
    private var authStateListener: AuthStateDidChangeListenerHandle?

    /// Nonce for Sign in with Apple (security requirement)
    private var currentNonce: String?

    // MARK: - Initialization

    init() {
        // Listen for auth state changes so we always know when user signs in/out
        // This fires immediately with current state, then again on any change
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    deinit {
        // Clean up the listener when service is destroyed
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Email/Password Authentication

    /// Create a new account with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's chosen password (min 6 characters, Firebase requirement)
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            currentUser = result.user
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
        }

        isLoading = false
    }

    /// Sign in with existing email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            currentUser = result.user
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
        }

        isLoading = false
    }

    /// Send a password reset email
    /// - Parameter email: The email address to send reset link to
    func sendPasswordReset(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
        }

        isLoading = false
    }

    // MARK: - Sign in with Apple

    /// Prepare for Sign in with Apple by generating a nonce
    /// Call this before presenting the ASAuthorizationController
    /// - Returns: A request configured for Sign in with Apple
    func prepareAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        return request
    }

    /// Complete Sign in with Apple after user authorizes
    /// - Parameter authorization: The authorization result from ASAuthorizationController
    func signInWithApple(authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Invalid Apple ID credential"
            return
        }

        guard let nonce = currentNonce else {
            errorMessage = "Invalid state: no nonce available"
            return
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Unable to fetch Apple ID token"
            return
        }

        isLoading = true
        errorMessage = nil

        // Create Firebase credential from Apple credential
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        do {
            let result = try await auth.signIn(with: credential)
            currentUser = result.user
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
        }

        isLoading = false
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }

    // MARK: - Account Management

    /// Delete the current user's account
    /// WARNING: This is irreversible and should require user confirmation
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user signed in"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await user.delete()
            currentUser = nil
        } catch let error as NSError {
            // If this fails with "requires recent login", user needs to re-authenticate
            errorMessage = mapAuthError(error)
        }

        isLoading = false
    }

    // MARK: - Private Helper Methods

    /// Map Firebase Auth error codes to user-friendly messages
    /// - Parameter error: The NSError from Firebase Auth
    /// - Returns: A human-readable error message suitable for display
    private func mapAuthError(_ error: NSError) -> String {
        // Firebase Auth error codes are in the FIRAuthErrorDomain
        guard error.domain == AuthErrorDomain else {
            return error.localizedDescription
        }

        // Map common errors to friendly messages
        // Full list: https://firebase.google.com/docs/auth/admin/errors
        switch error.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return "This email is already registered. Try signing in instead."

        case AuthErrorCode.invalidEmail.rawValue:
            return "Please enter a valid email address."

        case AuthErrorCode.weakPassword.rawValue:
            return "Password must be at least 6 characters."

        case AuthErrorCode.wrongPassword.rawValue:
            return "Incorrect password. Please try again."

        case AuthErrorCode.userNotFound.rawValue:
            return "No account found with this email. Try signing up instead."

        case AuthErrorCode.userDisabled.rawValue:
            return "This account has been disabled. Contact support for help."

        case AuthErrorCode.networkError.rawValue:
            return "Network error. Please check your connection and try again."

        case AuthErrorCode.tooManyRequests.rawValue:
            return "Too many attempts. Please wait a moment and try again."

        case AuthErrorCode.requiresRecentLogin.rawValue:
            return "Please sign in again to complete this action."

        default:
            return error.localizedDescription
        }
    }

    /// Generate a random nonce string for Sign in with Apple
    /// This prevents replay attacks by ensuring each sign-in attempt is unique
    /// - Parameter length: Length of the nonce (default 32)
    /// - Returns: A random alphanumeric string
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    /// Hash a string with SHA256 for Sign in with Apple nonce
    /// - Parameter input: The string to hash
    /// - Returns: Hex-encoded SHA256 hash
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
