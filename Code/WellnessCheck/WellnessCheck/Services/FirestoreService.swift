//
//  FirestoreService.swift
//  WellnessCheck
//
//  Created: v0.4.0 (2026-01-15)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Service for syncing data with Firebase Firestore.
//  Handles user profiles and Care Circle member data.
//
//  WHY THIS EXISTS:
//  WellnessCheck needs cloud sync to:
//  1. Persist data across device changes (new phone, reinstall, etc.)
//  2. Enable WellnessWatch companion app to access Care Circle data
//  3. Allow Cloud Functions to access user data for sending alerts
//
//  FIRESTORE STRUCTURE:
//  users/{userId}
//    - firstName: String
//    - lastName: String
//    - createdAt: Timestamp
//    - updatedAt: Timestamp
//    - homeLocation: GeoPoint? (lat/long only, privacy-conscious)
//    - homeRadius: Double (meters, default 100)
//    - silenceThresholdHours: Double (user-configured inactivity threshold)
//
//  users/{userId}/careCircle/{memberId}
//    - firstName: String
//    - lastName: String
//    - phoneNumber: String
//    - email: String?
//    - relationship: String
//    - isPrimary: Bool
//    - notificationPreference: String
//    - invitationStatus: String
//    - invitedAt: Timestamp?
//    - acceptedAt: Timestamp?
//    - sortOrder: Int (for maintaining notification priority order)
//    - imageData is NOT synced (too large, stays local)
//
//  OFFLINE SUPPORT:
//  Firestore has built-in offline persistence. Changes made while offline
//  are queued and synced when connectivity returns. This is critical for
//  a safety app that needs to work regardless of network status.
//

import Foundation
import Combine
import FirebaseFirestore

/// Service for syncing data with Firebase Firestore
/// Manages user profiles and Care Circle data in the cloud
@MainActor
class FirestoreService: ObservableObject {

    // MARK: - Published Properties

    /// The current user's profile data from Firestore
    @Published var userProfile: UserProfile?

    /// Care Circle members synced from Firestore
    @Published var careCircleMembers: [CareCircleMember] = []

    /// Whether a sync operation is in progress
    @Published var isSyncing: Bool = false

    /// The most recent error message (nil if no error)
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// Firestore database instance
    private let db = Firestore.firestore()

    /// Listener for Care Circle changes (for real-time updates)
    private var careCircleListener: ListenerRegistration?

    /// Listener for user profile changes
    private var userProfileListener: ListenerRegistration?

    /// The current user ID (set when user signs in)
    private var currentUserId: String?

    // MARK: - Initialization

    init() {
        // Firestore offline persistence is enabled by default in iOS SDK
        // No additional configuration needed
    }

    deinit {
        // Clean up listeners when service is destroyed
        careCircleListener?.remove()
        userProfileListener?.remove()
    }

    // MARK: - Setup

    /// Set the current user ID and start listening for their data
    /// Call this after successful authentication
    /// - Parameter userId: The Firebase Auth user ID
    func setUser(_ userId: String) {
        // Clean up old listeners if switching users
        careCircleListener?.remove()
        userProfileListener?.remove()

        currentUserId = userId

        // Start listening for real-time updates
        listenToUserProfile()
        listenToCareCircle()
    }

    /// Clear the current user and stop listening
    /// Call this on sign out
    func clearUser() {
        careCircleListener?.remove()
        userProfileListener?.remove()

        currentUserId = nil
        userProfile = nil
        careCircleMembers = []
    }

    // MARK: - User Profile

    /// Create or update the user's profile in Firestore
    /// - Parameters:
    ///   - firstName: User's first name
    ///   - lastName: User's last name
    func saveUserProfile(firstName: String, lastName: String) async {
        guard let userId = currentUserId else {
            errorMessage = "No user signed in"
            return
        }

        isSyncing = true
        errorMessage = nil

        let userRef = db.collection("users").document(userId)

        do {
            // Use merge to avoid overwriting other fields
            try await userRef.setData([
                "firstName": firstName,
                "lastName": lastName,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)

            // If this is a new user, also set createdAt
            let doc = try await userRef.getDocument()
            if doc.get("createdAt") == nil {
                try await userRef.setData([
                    "createdAt": FieldValue.serverTimestamp()
                ], merge: true)
            }
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    /// Update the user's home location
    /// - Parameters:
    ///   - latitude: Home latitude
    ///   - longitude: Home longitude
    ///   - radius: Detection radius in meters (default 100)
    func saveHomeLocation(latitude: Double, longitude: Double, radius: Double = 100) async {
        guard let userId = currentUserId else {
            errorMessage = "No user signed in"
            return
        }

        isSyncing = true
        errorMessage = nil

        let userRef = db.collection("users").document(userId)

        do {
            try await userRef.setData([
                "homeLocation": GeoPoint(latitude: latitude, longitude: longitude),
                "homeRadius": radius,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        } catch {
            errorMessage = "Failed to save home location: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    /// Update the user's inactivity threshold
    /// - Parameter hours: Hours of silence before triggering an alert
    func saveSilenceThreshold(hours: Double) async {
        guard let userId = currentUserId else {
            errorMessage = "No user signed in"
            return
        }

        let userRef = db.collection("users").document(userId)

        do {
            try await userRef.setData([
                "silenceThresholdHours": hours,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        } catch {
            errorMessage = "Failed to save silence threshold: \(error.localizedDescription)"
        }
    }

    // MARK: - Care Circle

    /// Add a Care Circle member to Firestore
    /// - Parameters:
    ///   - member: The CareCircleMember to add
    ///   - sortOrder: The position in the notification order (1-based)
    func addCareCircleMember(_ member: CareCircleMember, sortOrder: Int) async {
        guard let userId = currentUserId else {
            errorMessage = "No user signed in"
            return
        }

        isSyncing = true
        errorMessage = nil

        let memberRef = db.collection("users").document(userId)
            .collection("careCircle").document(member.id.uuidString)

        do {
            try await memberRef.setData(memberToDocument(member, sortOrder: sortOrder))
        } catch {
            errorMessage = "Failed to add Care Circle member: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    /// Update a Care Circle member in Firestore
    /// - Parameters:
    ///   - member: The updated CareCircleMember
    ///   - sortOrder: The position in the notification order (1-based)
    func updateCareCircleMember(_ member: CareCircleMember, sortOrder: Int) async {
        guard let userId = currentUserId else {
            errorMessage = "No user signed in"
            return
        }

        isSyncing = true
        errorMessage = nil

        let memberRef = db.collection("users").document(userId)
            .collection("careCircle").document(member.id.uuidString)

        do {
            try await memberRef.setData(memberToDocument(member, sortOrder: sortOrder))
        } catch {
            errorMessage = "Failed to update Care Circle member: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    /// Delete a Care Circle member from Firestore
    /// - Parameter memberId: The UUID of the member to delete
    func deleteCareCircleMember(memberId: UUID) async {
        guard let userId = currentUserId else {
            errorMessage = "No user signed in"
            return
        }

        isSyncing = true
        errorMessage = nil

        let memberRef = db.collection("users").document(userId)
            .collection("careCircle").document(memberId.uuidString)

        do {
            try await memberRef.delete()
        } catch {
            errorMessage = "Failed to delete Care Circle member: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    /// Sync all Care Circle members to Firestore (full replace)
    /// Use this for initial migration from UserDefaults or after reordering
    /// - Parameter members: The complete list of Care Circle members in order
    func syncAllCareCircleMembers(_ members: [CareCircleMember]) async {
        guard let userId = currentUserId else {
            errorMessage = "No user signed in"
            return
        }

        isSyncing = true
        errorMessage = nil

        let careCircleRef = db.collection("users").document(userId).collection("careCircle")

        do {
            // Use a batch write for atomic operation
            let batch = db.batch()

            // First, get existing documents to delete any that are no longer in the list
            let existingDocs = try await careCircleRef.getDocuments()
            let newMemberIds = Set(members.map { $0.id.uuidString })

            for doc in existingDocs.documents {
                if !newMemberIds.contains(doc.documentID) {
                    batch.deleteDocument(doc.reference)
                }
            }

            // Add/update all current members with their sort order
            for (index, member) in members.enumerated() {
                let memberRef = careCircleRef.document(member.id.uuidString)
                let data = memberToDocument(member, sortOrder: index + 1)
                batch.setData(data, forDocument: memberRef)
            }

            try await batch.commit()
        } catch {
            errorMessage = "Failed to sync Care Circle: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    // MARK: - Private Methods

    /// Start listening for real-time updates to the user profile
    private func listenToUserProfile() {
        guard let userId = currentUserId else { return }

        let userRef = db.collection("users").document(userId)

        userProfileListener = userRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                Task { @MainActor in
                    self.errorMessage = "Profile sync error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = snapshot?.data() else { return }

            Task { @MainActor in
                self.userProfile = UserProfile(
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    homeLatitude: (data["homeLocation"] as? GeoPoint)?.latitude,
                    homeLongitude: (data["homeLocation"] as? GeoPoint)?.longitude,
                    homeRadius: data["homeRadius"] as? Double ?? 100,
                    silenceThresholdHours: data["silenceThresholdHours"] as? Double ?? 8
                )
            }
        }
    }

    /// Start listening for real-time updates to the Care Circle
    private func listenToCareCircle() {
        guard let userId = currentUserId else { return }

        let careCircleRef = db.collection("users").document(userId)
            .collection("careCircle")
            .order(by: "sortOrder")

        careCircleListener = careCircleRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                Task { @MainActor in
                    self.errorMessage = "Care Circle sync error: \(error.localizedDescription)"
                }
                return
            }

            guard let documents = snapshot?.documents else { return }

            Task { @MainActor in
                self.careCircleMembers = documents.compactMap { doc -> CareCircleMember? in
                    self.documentToMember(doc.documentID, data: doc.data())
                }
            }
        }
    }

    /// Convert a CareCircleMember to a Firestore document
    /// - Parameters:
    ///   - member: The member to convert
    ///   - sortOrder: The position in notification order
    /// - Returns: Dictionary suitable for Firestore
    private func memberToDocument(_ member: CareCircleMember, sortOrder: Int) -> [String: Any] {
        var data: [String: Any] = [
            "firstName": member.firstName,
            "lastName": member.lastName,
            "phoneNumber": member.phoneNumber,
            "relationship": member.relationship,
            "isPrimary": member.isPrimary,
            "notificationPreference": member.notificationPreference.rawValue,
            "invitationStatus": member.invitationStatus.rawValue,
            "sortOrder": sortOrder,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        // Optional fields
        if let email = member.email {
            data["email"] = email
        }
        if let invitedAt = member.invitedAt {
            data["invitedAt"] = Timestamp(date: invitedAt)
        }
        if let acceptedAt = member.acceptedAt {
            data["acceptedAt"] = Timestamp(date: acceptedAt)
        }

        // Note: imageData is intentionally NOT synced to Firestore
        // It's too large and stays local only

        return data
    }

    /// Convert a Firestore document to a CareCircleMember
    /// - Parameters:
    ///   - documentId: The document ID (should be the member's UUID)
    ///   - data: The document data
    /// - Returns: A CareCircleMember or nil if conversion fails
    private func documentToMember(_ documentId: String, data: [String: Any]) -> CareCircleMember? {
        guard let uuid = UUID(uuidString: documentId),
              let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let phoneNumber = data["phoneNumber"] as? String,
              let relationship = data["relationship"] as? String else {
            return nil
        }

        let notificationPrefString = data["notificationPreference"] as? String ?? "Text Message"
        let notificationPref = CareCircleMember.NotificationPreference(rawValue: notificationPrefString) ?? .sms

        let invitationStatusString = data["invitationStatus"] as? String ?? "Pending"
        let invitationStatus = CareCircleMember.InvitationStatus(rawValue: invitationStatusString) ?? .pending

        return CareCircleMember(
            id: uuid,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: data["email"] as? String,
            relationship: relationship,
            isPrimary: data["isPrimary"] as? Bool ?? false,
            notificationPreference: notificationPref,
            invitationStatus: invitationStatus,
            invitedAt: (data["invitedAt"] as? Timestamp)?.dateValue(),
            acceptedAt: (data["acceptedAt"] as? Timestamp)?.dateValue(),
            imageData: nil // imageData stays local, not synced from Firestore
        )
    }
}

// MARK: - User Profile Model

/// Represents the user's profile data from Firestore
/// This is a lightweight struct for reading profile data, not for persistence
struct UserProfile {
    let firstName: String
    let lastName: String
    let homeLatitude: Double?
    let homeLongitude: Double?
    let homeRadius: Double
    let silenceThresholdHours: Double

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var hasHomeLocation: Bool {
        homeLatitude != nil && homeLongitude != nil
    }
}
