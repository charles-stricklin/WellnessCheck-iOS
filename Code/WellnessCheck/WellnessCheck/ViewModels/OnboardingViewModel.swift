//
//  OnboardingViewModel.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import Foundation
import Combine
import HealthKit
import UserNotifications

/// Manages the onboarding flow state and user data collection
@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current step in the onboarding flow
    @Published var currentStep: OnboardingStep = .welcome

    /// User's name (collected during profile setup)
    @Published var userName: String = ""
    
    /// User's surname (collected during profile setup)
    @Published var userSurname: String = ""

    /// User's phone number (collected during profile setup)
    @Published var userPhone: String = ""
    
    /// User's email address (optional, collected during profile setup)
    @Published var userEmail: String = ""

    /// Whether HealthKit permission has been granted
    @Published var hasHealthKitPermission: Bool = false

    /// Whether Notification permission has been granted
    @Published var hasNotificationPermission: Bool = false

    /// Error message to display to user
    @Published var errorMessage: String?

    /// Whether onboarding is complete
    @Published var isOnboardingComplete: Bool = false

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()
    private let userDefaults = UserDefaults.standard

    // MARK: - Onboarding Steps

    /// Defines the sequence of onboarding screens
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case howItWorks
        case privacy
        case contactSelection
        case whyNotifications
        case whyHealthData
        case permissions
        case careCircleSetup
        case customizeMonitoring
        case complete

        var title: String {
            switch self {
            case .welcome:
                return "Welcome"
            case .howItWorks:
                return "How It Works"
            case .privacy:
                return "Privacy"
            case .contactSelection:
                return "Contact Selection"
            case .whyNotifications:
                return "Why Notifications"
            case .whyHealthData:
                return "Why Health Data"
            case .permissions:
                return "Permissions"
            case .careCircleSetup:
                return "Care Circle"
            case .customizeMonitoring:
                return "Settings"
            case .complete:
                return "Complete"
            }
        }
    }

    // MARK: - Initialization

    init() {
        // DEVELOPMENT ONLY - Clear onboarding data on every launch
        #if DEBUG
        userDefaults.removeObject(forKey: Constants.hasCompletedOnboardingKey)
        userDefaults.removeObject(forKey: Constants.userNameKey)
        userDefaults.removeObject(forKey: Constants.userSurnameKey)
        userDefaults.removeObject(forKey: Constants.userPhoneKey)
        userDefaults.removeObject(forKey: Constants.userEmailKey)
        #endif
        
        checkExistingPermissions()
    }

    // MARK: - Navigation Methods

    /// Moves to the next onboarding step
    func goToNextStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        currentStep = nextStep
    }

    /// Goes back to the previous onboarding step
    func goToPreviousStep() {
        guard let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = previousStep
    }

    /// Checks if user can proceed from current step
    func canProceed() -> Bool {
        switch currentStep {
        case .welcome, .howItWorks, .privacy, .whyNotifications, .whyHealthData:
            return true
        case .contactSelection:
            return !userName.isEmpty && !userSurname.isEmpty && !userPhone.isEmpty && isValidPhoneNumber(userPhone)
        case .permissions:
            return hasHealthKitPermission && hasNotificationPermission
        case .careCircleSetup, .customizeMonitoring:
            return true
        case .complete:
            return true
        }
    }

    // MARK: - Permission Methods

    /// Checks for existing permissions on app launch
    private func checkExistingPermissions() {
        // Check HealthKit authorization
        if HKHealthStore.isHealthDataAvailable() {
            let fallType = HKObjectType.categoryType(forIdentifier: .appleStandHour)
            let activityType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)

            if let fallType = fallType, let activityType = activityType {
                let fallStatus = healthStore.authorizationStatus(for: fallType)
                let activityStatus = healthStore.authorizationStatus(for: activityType)

                hasHealthKitPermission = fallStatus == .sharingAuthorized &&
                                       activityStatus == .sharingAuthorized
            }
        }

        // Check Notification permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.hasNotificationPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Requests HealthKit permissions for fall detection and activity monitoring
    func requestHealthKitPermission() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit is not available on this device"
            return
        }

        // Define the health data types we want to read
        guard let fallType = HKObjectType.categoryType(forIdentifier: .appleStandHour),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            errorMessage = "Unable to access HealthKit data types"
            return
        }

        let typesToRead: Set<HKObjectType> = [
            fallType,
            activeEnergyType,
            stepCountType
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            hasHealthKitPermission = true
            errorMessage = nil
        } catch {
            errorMessage = "Failed to request HealthKit permission: \(error.localizedDescription)"
            hasHealthKitPermission = false
        }
    }

    /// Requests notification permissions for alerts and reminders
    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])

            hasNotificationPermission = granted

            if !granted {
                errorMessage = "Notification permission is required for emergency alerts"
            } else {
                errorMessage = nil
            }
        } catch {
            errorMessage = "Failed to request notification permission: \(error.localizedDescription)"
            hasNotificationPermission = false
        }
    }

    // MARK: - Validation Methods

    /// Validates phone number format (simple US format validation)
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count == 10
    }

    /// Formats phone number as user types (US format)
    func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }

        // Limit to 10 digits
        let limitedDigits = String(digits.prefix(10))

        // Format as (XXX) XXX-XXXX
        var formatted = ""
        for (index, digit) in limitedDigits.enumerated() {
            if index == 0 {
                formatted += "("
            } else if index == 3 {
                formatted += ") "
            } else if index == 6 {
                formatted += "-"
            }
            formatted.append(digit)
        }

        return formatted
    }

    // MARK: - Completion Methods

    /// Completes the onboarding process and saves user data
    func completeOnboarding() {
        // Save user data to UserDefaults (in production, this would go to Firebase)
        userDefaults.set(true, forKey: Constants.hasCompletedOnboardingKey)
        userDefaults.set(userName, forKey: Constants.userNameKey)
        userDefaults.set(userSurname, forKey: Constants.userSurnameKey)
        userDefaults.set(userPhone, forKey: Constants.userPhoneKey)
        if !userEmail.isEmpty {
            userDefaults.set(userEmail, forKey: Constants.userEmailKey)
        }

        isOnboardingComplete = true
    }

    /// Skips onboarding (for testing purposes)
    func skipOnboarding() {
        userDefaults.set(true, forKey: Constants.hasCompletedOnboardingKey)
        isOnboardingComplete = true
    }
}
