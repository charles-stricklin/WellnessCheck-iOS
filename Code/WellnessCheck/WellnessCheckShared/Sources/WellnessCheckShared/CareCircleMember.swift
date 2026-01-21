//
//  CareCircleMember.swift
//  WellnessCheckShared
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Shared Care Circle member model used by both iOS and watchOS targets.
//  This is the core data structure for people who receive alerts.
//
//  WATCHOS NOTE:
//  The imageData field exists for iOS (contact photos) but should not be
//  synced to the watch — it's too large and not needed for alerting.
//  Use WatchCareCircleMember for WatchConnectivity transfers.
//

import Foundation

/// Represents a member of the user's Care Circle
/// These are the trusted contacts who receive alerts when something may be wrong
public struct CareCircleMember: Identifiable, Codable, Sendable {
    public let id: UUID
    public var firstName: String
    public var lastName: String
    public var phoneNumber: String
    public var email: String?
    public var relationship: String // "Daughter", "Son", "Neighbor", "Friend", etc.
    public var isPrimary: Bool // First person to be notified
    public var notificationPreference: NotificationPreference
    public var invitationStatus: InvitationStatus
    public var invitedAt: Date?
    public var acceptedAt: Date?
    public var imageData: Data? // Contact photo from iOS Contacts (iOS only, not synced to watch)

    public enum NotificationPreference: String, Codable, CaseIterable, Sendable {
        case sms = "Text Message"
        case call = "Phone Call"
        case both = "Text & Call"
    }

    public enum InvitationStatus: String, Codable, Sendable {
        case pending = "Pending"           // Added but invitation not sent yet
        case sent = "Invitation Sent"      // SMS sent, awaiting download
        case accepted = "Accepted"         // Downloaded WellnessWatch and connected
        case declined = "Declined"         // Declined the invitation
    }

    public init(
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

    public var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// MARK: - Watch Transfer Model

/// Lightweight version of CareCircleMember for WatchConnectivity transfer
/// Excludes imageData and other fields not needed on watch
public struct WatchCareCircleMember: Codable, Sendable {
    public let id: UUID
    public let firstName: String
    public let lastName: String
    public let phoneNumber: String
    public let relationship: String
    public let isPrimary: Bool

    public init(from member: CareCircleMember) {
        self.id = member.id
        self.firstName = member.firstName
        self.lastName = member.lastName
        self.phoneNumber = member.phoneNumber
        self.relationship = member.relationship
        self.isPrimary = member.isPrimary
    }

    public init(
        id: UUID,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        relationship: String,
        isPrimary: Bool
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.relationship = relationship
        self.isPrimary = isPrimary
    }

    public var fullName: String {
        "\(firstName) \(lastName)"
    }
}
