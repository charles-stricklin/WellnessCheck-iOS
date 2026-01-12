//
//  CareCircleViewModel.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//

import Foundation
import Combine

@MainActor
class CareCircleViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var members: [CareCircleMember] = []
    @Published var isAddingMember = false
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let membersKey = "careCircleMembers"
    
    // MARK: - Initialization
    
    init() {
        loadMembers()
    }
    
    // MARK: - Public Methods
    
    func addMember(_ member: CareCircleMember) {
        members.append(member)
        saveMembers()
    }
    
    func updateMember(_ member: CareCircleMember) {
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index] = member
            saveMembers()
        }
    }
    
    func deleteMember(_ member: CareCircleMember) {
        members.removeAll { $0.id == member.id }
        saveMembers()
    }
    
    func setPrimaryContact(_ member: CareCircleMember) {
        // Remove primary from all others
        for index in members.indices {
            members[index].isPrimary = false
        }

        // Set this one as primary
        if let index = members.firstIndex(where: { $0.id == member.id }) {
            members[index].isPrimary = true
        }

        saveMembers()
    }

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

            saveMembers()
        }
    }

    /// Move a member up in the notification order (towards position 1)
    func moveMemberUp(_ member: CareCircleMember) {
        guard let index = members.firstIndex(where: { $0.id == member.id }),
              index > 0 else { return }

        members.swapAt(index, index - 1)
        updatePrimaryStatus()
        saveMembers()
    }

    /// Move a member down in the notification order (away from position 1)
    func moveMemberDown(_ member: CareCircleMember) {
        guard let index = members.firstIndex(where: { $0.id == member.id }),
              index < members.count - 1 else { return }

        members.swapAt(index, index + 1)
        updatePrimaryStatus()
        saveMembers()
    }

    /// Returns the 1-based position of a member in the notification order
    func position(of member: CareCircleMember) -> Int? {
        guard let index = members.firstIndex(where: { $0.id == member.id }) else {
            return nil
        }
        return index + 1
    }

    /// Updates isPrimary so that only the first member is marked as primary
    private func updatePrimaryStatus() {
        for index in members.indices {
            members[index].isPrimary = (index == 0)
        }
    }

    var hasPrimaryContact: Bool {
        members.contains { $0.isPrimary }
    }
    
    // MARK: - Private Methods
    
    private func loadMembers() {
        guard let data = userDefaults.data(forKey: membersKey),
              let decoded = try? JSONDecoder().decode([CareCircleMember].self, from: data) else {
            return
        }
        members = decoded
    }
    
    private func saveMembers() {
        guard let encoded = try? JSONEncoder().encode(members) else {
            return
        }
        userDefaults.set(encoded, forKey: membersKey)
    }
}
