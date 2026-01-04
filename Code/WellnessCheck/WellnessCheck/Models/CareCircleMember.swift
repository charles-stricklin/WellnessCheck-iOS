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
    
    enum NotificationPreference: String, Codable, CaseIterable {
        case sms = "Text Message"
        case call = "Phone Call"
        case both = "Text & Call"
    }
    
    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        phoneNumber: String,
        email: String? = nil,
        relationship: String,
        isPrimary: Bool = false,
        notificationPreference: NotificationPreference = .sms
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.relationship = relationship
        self.isPrimary = isPrimary
        self.notificationPreference = notificationPreference
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
