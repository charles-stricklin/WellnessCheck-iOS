//
//  CareCircleViewModel.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//  Last Modified: v0.5.0 (2026-01-17)
//
//  UPDATE 2026-01-17: Integrated with FirestoreService for cloud sync.
//  When user is signed in, Care Circle data syncs to Firestore.
//  When user is not signed in (during onboarding), uses UserDefaults.
//  Existing UserDefaults data migrates to Firestore on first sign-in.
//
//  WHY THIS DUAL-STORAGE APPROACH:
//  1. Onboarding happens BEFORE authentication — user can add Care Circle
//     members during setup, stored locally in UserDefaults
//  2. After sign-in, data migrates to Firestore for cloud sync
//  3. Firestore has built-in offline support, so once migrated, we use
//     Firestore exclusively (it handles offline/online seamlessly)
//  4. imageData stays local only — too large for Firestore, and contact
//     photos can be re-fetched from iOS Contacts if needed
//

import Foundation
import Combine
import FirebaseAuth

/// ViewModel for managing Care Circle members with cloud sync support.
/// Uses UserDefaults before authentication, Firestore after sign-in.
@MainActor
class CareCircleViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The list of Care Circle members
    @Published var members: [CareCircleMember] = []

    /// Whether a member is currently being added (UI state)
    @Published var isAddingMember = false

    /// Whether a sync operation is in progress
    @Published var isSyncing = false

    /// Error message for display, if any
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// UserDefaults for local storage (used during onboarding before auth)
    private let userDefaults = UserDefaults.standard
    private let membersKey = "careCircleMembers"
    private let hasMigratedKey = "careCircleMigratedToFirestore"

    /// Firestore service for cloud sync (injected or created)
    private var firestoreService: FirestoreService?

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// Firebase Auth listener handle
    private var authStateListener: AuthStateDidChangeListenerHandle?

    /// Current Firebase user ID (nil if not signed in)
    private var currentUserId: String?

    // MARK: - Initialization

    /// Initialize the CareCircleViewModel
    /// - Parameter firestoreService: Optional FirestoreService for dependency injection (useful for testing)
    init(firestoreService: FirestoreService? = nil) {
        self.firestoreService = firestoreService ?? FirestoreService()

        // Load from UserDefaults initially (covers onboarding case)
        loadMembersFromUserDefaults()

        // Listen for auth state changes to handle sign-in/sign-out
        setupAuthStateListener()
    }

    deinit {
        // Clean up auth listener
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Public Methods

    /// Add a new member to the Care Circle
    /// - Parameter member: The CareCircleMember to add
    func addMember(_ member: CareCircleMember) {
        members.append(member)
        saveMembersToCurrentStorage()
    }

    /// Update an existing member's information
    /// - Parameter member: The updated CareCircleMember (matched by ID)
    func updateMember(_ member: CareCircleMember) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
            saveMembersToCurrentStorage()
        }
    }

    /// Delete a member from the Care Circle
    /// - Parameter member: The CareCircleMember to remove
    func deleteMember(_ member: CareCircleMember) {
        members.removeAll { $0.id == member.id }
        saveMembersToCurrentStorage()
    }

    /// Set a member as the primary contact (first to be notified)
    /// - Parameter member: The member to make primary
    func setPrimaryContact(_ member: CareCircleMember) {
        // Remove primary from all others
        for index in members.indices {
            members[index].isPrimary = false
        }

        // Set this one as primary
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index].isPrimary = true
        }

        saveMembersToCurrentStorage()
    }

    /// Update a member's invitation status
    /// - Parameters:
    ///   - member: The member to update
    ///   - status: The new invitation status
    func updateInvitationStatus(_ member: CareCircleMember, status: CareCircleMember.InvitationStatus) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index].invitationStatus = status

            // Set invitedAt timestamp when status becomes 'sent'
            if status == .sent && members[index].invitedAt == nil {
                members[index].invitedAt = Date()
            }

            // Set acceptedAt timestamp when status becomes 'accepted'
            if status == .accepted && members[index].acceptedAt == nil {
                members[index].acceptedAt = Date()
            }

            saveMembersToCurrentStorage()
        }
    }

    /// Move a member up in the notification order (towards position 1)
    /// - Parameter member: The member to move up
    func moveMemberUp(_ member: CareCircleMember) {
        guard let index = members.firstIndex(where: { $0.id == member.id }),
              index > 0 else { return }

        members.swapAt(index, index - 1)
        updatePrimaryStatus()
        saveMembersToCurrentStorage()
    }

    /// Move a member down in the notification order (away from position 1)
    /// - Parameter member: The member to move down
    func moveMemberDown(_ member: CareCircleMember) {
        guard let index = members.firstIndex(where: { $0.id == member.id }),
              index < members.count - 1 else { return }

        members.swapAt(index, index + 1)
        updatePrimaryStatus()
        saveMembersToCurrentStorage()
    }

    /// Returns the 1-based position of a member in the notification order
    /// - Parameter member: The member to find
    /// - Returns: The position (1-based) or nil if not found
    func position(of member: CareCircleMember) -> Int? {
        guard let index = members.firstIndex(where: { $0.id == member.id }) else {
            return nil
        }
        return index + 1
    }

    /// Force a sync to Firestore (useful after batch operations)
    /// Only works when user is signed in
    func syncToFirestore() async {
        guard let userId = currentUserId,
              let firestoreService = firestoreService else {
            return
        }

        isSyncing = true
        firestoreService.setUser(userId)
        await firestoreService.syncAllCareCircleMembers(members)
        isSyncing = false
    }

    // MARK: - Computed Properties

    /// Whether there's a primary contact set
    var hasPrimaryContact: Bool {
        members.contains { $0.isPrimary }
    }

    /// Whether the user is currently signed in (determines storage backend)
    var isSignedIn: Bool {
        currentUserId != nil
    }

    // MARK: - Private Methods

    /// Set up listener for Firebase Auth state changes
    /// Triggers migration when user signs in
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }

                let previousUserId = self.currentUserId
                self.currentUserId = user?.uid

                if let userId = user?.uid {
                    // User signed in
                    self.handleSignIn(userId: userId, isNewSession: previousUserId == nil)
                } else {
                    // User signed out
                    self.handleSignOut()
                }
            }
        }
    }

    /// Handle user sign-in: migrate data and set up Firestore listener
    /// - Parameters:
    ///   - userId: The Firebase user ID
    ///   - isNewSession: Whether this is a fresh sign-in (vs. app restart while signed in)
    private func handleSignIn(userId: String, isNewSession: Bool) {
        guard let firestoreService = firestoreService else { return }

        // Set up Firestore for this user
        firestoreService.setUser(userId)

        // Check if we need to migrate UserDefaults data to Firestore
        let hasMigrated = userDefaults.bool(forKey: hasMigratedKey)
        let hasLocalData = !members.isEmpty

        if !hasMigrated && hasLocalData {
            // First sign-in with existing local data — migrate to Firestore
            Task {
                await migrateToFirestore()
            }
        } else {
            // Already migrated or no local data — listen to Firestore for updates
            setupFirestoreListener()
        }
    }

    /// Handle user sign-out: stop listening to Firestore, keep local data
    private func handleSignOut() {
        firestoreService?.clearUser()
        cancellables.removeAll()

        // Load from UserDefaults (in case user wants to use app without signing in)
        loadMembersFromUserDefaults()
    }

    /// Migrate existing UserDefaults data to Firestore
    /// Called on first sign-in when there's existing local data
    private func migrateToFirestore() async {
        guard let firestoreService = firestoreService else { return }

        isSyncing = true
        errorMessage = nil

        // Upload all local members to Firestore
        await firestoreService.syncAllCareCircleMembers(members)

        // Check for errors
        if let error = firestoreService.errorMessage {
            errorMessage = "Migration failed: \(error)"
            isSyncing = false
            return
        }

        // Mark migration as complete
        userDefaults.set(true, forKey: hasMigratedKey)

        // Now listen to Firestore for future updates
        setupFirestoreListener()

        isSyncing = false
    }

    /// Set up Combine subscription to Firestore changes
    /// Called after migration or on subsequent sign-ins
    private func setupFirestoreListener() {
        guard let firestoreService = firestoreService else { return }

        // Cancel any existing subscriptions
        cancellables.removeAll()

        // Subscribe to Firestore Care Circle changes
        firestoreService.$careCircleMembers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] firestoreMembers in
                guard let self = self else { return }

                // Merge Firestore data with local imageData
                // (imageData doesn't sync to Firestore — too large)
                self.mergeFirestoreWithLocalImages(firestoreMembers)
            }
            .store(in: &cancellables)

        // Subscribe to sync status
        firestoreService.$isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSyncing)

        // Subscribe to errors
        firestoreService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }

    /// Merge Firestore members with locally-stored imageData
    /// imageData is kept in UserDefaults since it's too large for Firestore
    /// - Parameter firestoreMembers: Members from Firestore (without imageData)
    private func mergeFirestoreWithLocalImages(_ firestoreMembers: [CareCircleMember]) {
        // Build a lookup of existing imageData by member ID
        let imageDataLookup = Dictionary(uniqueKeysWithValues:
            members.compactMap { member -> (UUID, Data)? in
                guard let imageData = member.imageData else { return nil }
                return (member.id, imageData)
            }
        )

        // Also check UserDefaults for any imageData we might have stored
        var localImageData: [UUID: Data] = imageDataLookup
        if let savedData = userDefaults.data(forKey: membersKey),
           let savedMembers = try? JSONDecoder().decode([CareCircleMember].self, from: savedData) {
            for member in savedMembers {
                if let imageData = member.imageData {
                    localImageData[member.id] = imageData
                }
            }
        }

        // Update members with Firestore data, preserving local imageData
        var updatedMembers = firestoreMembers
        for index in updatedMembers.indices {
            if let imageData = localImageData[updatedMembers[index].id] {
                updatedMembers[index].imageData = imageData
            }
        }

        self.members = updatedMembers

        // Save to UserDefaults to preserve imageData
        saveMembersToUserDefaults()
    }

    /// Updates isPrimary so that only the first member is marked as primary
    private func updatePrimaryStatus() {
        for index in members.indices {
            members[index].isPrimary = (index == 0)
        }
    }

    /// Save members to the appropriate storage based on auth state
    private func saveMembersToCurrentStorage() {
        // Always save to UserDefaults (for imageData and offline fallback)
        saveMembersToUserDefaults()

        // If signed in, also sync to Firestore
        if let userId = currentUserId, let firestoreService = firestoreService {
            Task {
                firestoreService.setUser(userId)
                await firestoreService.syncAllCareCircleMembers(members)
            }
        }
    }

    /// Load members from UserDefaults (used during onboarding and as fallback)
    private func loadMembersFromUserDefaults() {
        guard let data = userDefaults.data(forKey: membersKey),
              let decoded = try? JSONDecoder().decode([CareCircleMember].self, from: data) else {
            return
        }
        members = decoded
    }

    /// Save members to UserDefaults (for imageData and offline use)
    private func saveMembersToUserDefaults() {
        guard let encoded = try? JSONEncoder().encode(members) else {
            return
        }
        userDefaults.set(encoded, forKey: membersKey)
    }
}
