//
//  CareCircleMember.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//

import Foundation

/// Represents a member of the user's Care Circle
struct CareCircleMember: Identifiable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var email: String?
    var relationship: String // "Daughter", "Son", "Neighbor", "Friend", etc.
    var isPrimary: Bool // First person to be notified
    var notificationPreference: NotificationPreference
    var invitationStatus: InvitationStatus
    var invitedAt: Date?
    var acceptedAt: Date?
    var imageData: Data? // Contact photo from iOS Contacts, if available

    enum NotificationPreference: String, Codable, CaseIterable {
        case sms = "Text Message"
        case call = "Phone Call"
        case both = "Text & Call"
    }

    enum InvitationStatus: String, Codable {
        case pending = "Pending"           // Added but invitation not sent yet
        case sent = "Invitation Sent"      // SMS sent, awaiting download
        case accepted = "Accepted"         // Downloaded WellnessWatch and connected
        case declined = "Declined"         // Declined the invitation
    }
    
    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        phoneNumber: String,
        email: String? = nil,
        relationship: String,
        isPrimary: Bool = false,
        notificationPreference: NotificationPreference = .sms,
        invitationStatus: InvitationStatus = .pending,
        invitedAt: Date? = nil,
        acceptedAt: Date? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.relationship = relationship
        self.isPrimary = isPrimary
        self.notificationPreference = notificationPreference
        self.invitationStatus = invitationStatus
        self.invitedAt = invitedAt
        self.acceptedAt = acceptedAt
        self.imageData = imageData
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
