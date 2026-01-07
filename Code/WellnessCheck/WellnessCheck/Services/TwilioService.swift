//
//  TwilioService.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/6/26.
//
//  Handles SMS invitations to Care Circle members via Twilio.
//  Supports test mode for development (no actual SMS sent).
//

import Foundation

class TwilioService {
    // MARK: - Properties

    static let shared = TwilioService()

    // Test mode flag - set to false when ready for production
    private let isTestMode = true

    // User's name for personalizing messages
    private var userName: String {
        UserDefaults.standard.string(forKey: "userFirstName") ?? "Your friend"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Sends a Care Circle invitation to a new member
    /// - Parameters:
    ///   - member: The Care Circle member to invite
    ///   - completion: Callback with success/failure and optional error
    func sendInvitation(to member: CareCircleMember, completion: @escaping (Result<InvitationResult, Error>) -> Void) {
        let message = createInvitationMessage(for: member)

        if isTestMode {
            // Test mode - simulate success and log
            logTestModeInvitation(to: member, message: message)

            // Simulate network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let result = InvitationResult(
                    success: true,
                    messagePreview: message,
                    recipientName: member.fullName,
                    recipientPhone: member.phoneNumber,
                    testMode: true
                )
                completion(.success(result))
            }
        } else {
            // Production mode - actually send via Twilio
            sendViaTwilio(to: member.phoneNumber, message: message) { result in
                completion(result)
            }
        }
    }

    /// Sends an emergency alert to a Care Circle member
    /// - Parameters:
    ///   - member: The member to alert
    ///   - alertType: Type of alert (fall, inactivity, manual, etc.)
    ///   - completion: Callback with success/failure
    func sendAlert(to member: CareCircleMember, alertType: String, completion: @escaping (Result<InvitationResult, Error>) -> Void) {
        let message = createAlertMessage(for: member, alertType: alertType)

        if isTestMode {
            logTestModeAlert(to: member, message: message, alertType: alertType)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let result = InvitationResult(
                    success: true,
                    messagePreview: message,
                    recipientName: member.fullName,
                    recipientPhone: member.phoneNumber,
                    testMode: true
                )
                completion(.success(result))
            }
        } else {
            sendViaTwilio(to: member.phoneNumber, message: message) { result in
                completion(result)
            }
        }
    }

    // MARK: - Private Methods

    private func createInvitationMessage(for member: CareCircleMember) -> String {
        """
        Hi \(member.firstName)! \(userName) has added you to their WellnessCheck Care Circle.

        Download WellnessWatch to stay connected and receive alerts if they need help:

        https://wellnesswatch.dev/download

        You'll be notified if \(userName) has a fall, prolonged inactivity, or manually requests assistance.

        - WellnessCheck Team
        """
    }

    private func createAlertMessage(for member: CareCircleMember, alertType: String) -> String {
        let alertDescription: String

        switch alertType.lowercased() {
        case "fall":
            alertDescription = "a fall has been detected"
        case "inactivity":
            alertDescription = "prolonged inactivity has been detected"
        case "manual":
            alertDescription = "they have requested assistance"
        case "wellness":
            alertDescription = "a wellness concern has been detected"
        default:
            alertDescription = "they may need help"
        }

        return """
        🚨 WELLNESSCHECK ALERT

        \(userName) may need assistance - \(alertDescription).

        Please check on them as soon as possible.

        Time: \(formatTime(Date()))

        Open WellnessWatch for more details.
        """
    }

    private func sendViaTwilio(to phoneNumber: String, message: String, completion: @escaping (Result<InvitationResult, Error>) -> Void) {
        // TODO: Implement actual Twilio API integration when ready
        // This will use Twilio's REST API to send SMS

        // For now, return an error indicating production mode isn't configured yet
        let error = NSError(
            domain: "com.wellnesscheck.twilio",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Twilio production mode not yet configured"]
        )
        completion(.failure(error))
    }

    private func logTestModeInvitation(to member: CareCircleMember, message: String) {
        print("""

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        🔔 CARE CIRCLE INVITATION (TEST MODE)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        To: \(member.phoneNumber)
        Name: \(member.fullName)
        Relationship: \(member.relationship)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Message:
        \(message)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ✓ Logged only - NO SMS SENT (Test Mode Active)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        """)
    }

    private func logTestModeAlert(to member: CareCircleMember, message: String, alertType: String) {
        print("""

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        🚨 EMERGENCY ALERT (TEST MODE)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        To: \(member.phoneNumber)
        Name: \(member.fullName)
        Alert Type: \(alertType)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Message:
        \(message)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ✓ Logged only - NO SMS SENT (Test Mode Active)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        """)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct InvitationResult {
    let success: Bool
    let messagePreview: String
    let recipientName: String
    let recipientPhone: String
    let testMode: Bool

    var displayMessage: String {
        if testMode {
            return """
            📧 Invitation Preview (Test Mode)

            To: \(recipientName)
            Phone: \(recipientPhone)

            Message:
            \(messagePreview)

            ✓ Not actually sent - Test Mode Active
            """
        } else {
            return "✓ Invitation sent to \(recipientName)"
        }
    }
}
