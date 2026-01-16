//
//  CloudFunctionsService.swift
//  WellnessCheck
//
//  Created: v0.4.0 (2026-01-15)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Service for calling Firebase Cloud Functions.
//  Handles all SMS-related operations via Twilio through secure server-side functions.
//
//  WHY THIS EXISTS:
//  Twilio credentials must stay server-side for security. This service calls
//  Cloud Functions that have access to those credentials, keeping the iOS app
//  credential-free while still being able to send SMS.
//
//  AVAILABLE FUNCTIONS:
//  - sendImOkMessage: User manually sends "I'm OK" to Care Circle
//  - sendAlert: System sends alert when user may need help
//  - sendInvitation: Send SMS invitation to new Care Circle member
//

import Foundation
import Combine
import FirebaseFunctions

/// Service for calling Firebase Cloud Functions
/// All SMS operations go through this service to keep credentials server-side
@MainActor
class CloudFunctionsService: ObservableObject {

    // MARK: - Published Properties

    /// Whether an operation is in progress
    @Published var isLoading: Bool = false

    /// The most recent error message (nil if no error)
    @Published var errorMessage: String?

    /// Result of the last operation
    @Published var lastResult: SMSResult?

    // MARK: - Private Properties

    /// Firebase Functions instance
    private let functions = Functions.functions()

    // MARK: - Public Methods

    /// Send "I'm OK" message to all Care Circle members
    /// - Parameters:
    ///   - userName: The user's display name
    ///   - members: Array of Care Circle members with name and phone
    /// - Returns: Result indicating success/failure and count of messages sent
    func sendImOkMessage(userName: String, members: [CareCircleMember]) async -> SMSResult {
        isLoading = true
        errorMessage = nil

        // Convert members to the format expected by Cloud Function
        let memberData = members.map { member in
            [
                "name": member.firstName,
                "phone": member.phoneNumber
            ]
        }

        let data: [String: Any] = [
            "userName": userName,
            "members": memberData
        ]

        do {
            let result = try await functions.httpsCallable("sendImOkMessage").call(data)

            guard let resultData = result.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  let sent = resultData["sent"] as? Int,
                  let total = resultData["total"] as? Int else {
                throw NSError(domain: "CloudFunctions", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }

            let smsResult = SMSResult(success: success, sent: sent, total: total)
            lastResult = smsResult
            isLoading = false
            return smsResult

        } catch {
            let message = parseError(error)
            errorMessage = message
            isLoading = false
            return SMSResult(success: false, sent: 0, total: members.count, error: message)
        }
    }

    /// Send alert to Care Circle members when user may need help
    /// - Parameters:
    ///   - userName: The user's display name
    ///   - alertType: Type of alert (inactivity, fall, missed_checkin)
    ///   - location: Optional location info with address and isHome flag
    ///   - members: Array of Care Circle members to alert
    /// - Returns: Result indicating success/failure
    func sendAlert(
        userName: String,
        alertType: AlertType,
        location: AlertLocation? = nil,
        members: [CareCircleMember]
    ) async -> SMSResult {
        isLoading = true
        errorMessage = nil

        let memberData = members.map { member in
            [
                "name": member.firstName,
                "phone": member.phoneNumber
            ]
        }

        var data: [String: Any] = [
            "userName": userName,
            "alertType": alertType.rawValue,
            "members": memberData
        ]

        if let location = location {
            data["location"] = [
                "address": location.address,
                "isHome": location.isHome
            ]
        }

        do {
            let result = try await functions.httpsCallable("sendAlert").call(data)

            guard let resultData = result.data as? [String: Any],
                  let success = resultData["success"] as? Bool,
                  let sent = resultData["sent"] as? Int,
                  let total = resultData["total"] as? Int else {
                throw NSError(domain: "CloudFunctions", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }

            let smsResult = SMSResult(success: success, sent: sent, total: total)
            lastResult = smsResult
            isLoading = false
            return smsResult

        } catch {
            let message = parseError(error)
            errorMessage = message
            isLoading = false
            return SMSResult(success: false, sent: 0, total: members.count, error: message)
        }
    }

    /// Send invitation SMS to a new Care Circle member
    /// - Parameters:
    ///   - userName: The user's display name (who is inviting)
    ///   - memberName: The name of the person being invited
    ///   - memberPhone: The phone number to send the invitation to
    /// - Returns: Result indicating success/failure
    func sendInvitation(userName: String, memberName: String, memberPhone: String) async -> SMSResult {
        isLoading = true
        errorMessage = nil

        let data: [String: Any] = [
            "userName": userName,
            "memberName": memberName,
            "memberPhone": memberPhone
        ]

        do {
            let result = try await functions.httpsCallable("sendInvitation").call(data)

            guard let resultData = result.data as? [String: Any],
                  let success = resultData["success"] as? Bool else {
                throw NSError(domain: "CloudFunctions", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
            }

            let smsResult = SMSResult(success: success, sent: success ? 1 : 0, total: 1)
            lastResult = smsResult
            isLoading = false
            return smsResult

        } catch {
            let message = parseError(error)
            errorMessage = message
            isLoading = false
            return SMSResult(success: false, sent: 0, total: 1, error: message)
        }
    }

    // MARK: - Private Methods

    /// Parse Firebase Functions error into user-friendly message
    private func parseError(_ error: Error) -> String {
        if let functionsError = error as NSError?,
           functionsError.domain == FunctionsErrorDomain {
            // Map Firebase Functions error codes to friendly messages
            switch FunctionsErrorCode(rawValue: functionsError.code) {
            case .unauthenticated:
                return "Please sign in to send messages."
            case .invalidArgument:
                return "Invalid data provided."
            case .unavailable:
                return "Service temporarily unavailable. Please try again."
            case .internal:
                return "An error occurred sending the message. Please try again."
            default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
    }
}

// MARK: - Supporting Types

/// Result of an SMS operation
struct SMSResult {
    let success: Bool
    let sent: Int
    let total: Int
    var error: String?
}

/// Types of alerts that can be sent
enum AlertType: String {
    case inactivity = "inactivity"
    case fall = "fall"
    case missedCheckin = "missed_checkin"
}

/// Location information for alerts
struct AlertLocation {
    let address: String
    let isHome: Bool
}
