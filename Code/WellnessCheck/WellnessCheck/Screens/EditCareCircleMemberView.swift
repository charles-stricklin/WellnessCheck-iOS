//
//  EditCareCircleMemberView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//

import SwiftUI

struct EditCareCircleMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CareCircleViewModel
    let member: CareCircleMember
    
    @State private var firstName: String
    @State private var lastName: String  
    @State private var phoneNumber: String
    @State private var email: String
    @State private var relationship: String
    @State private var isPrimary: Bool
    @State private var notificationPreference: CareCircleMember.NotificationPreference
    @State private var showDeleteConfirmation = false
    
    let relationships = ["Daughter", "Son", "Spouse/Partner", "Sibling", "Parent", "Friend", "Neighbor", "Caregiver", "Other"]
    
    init(viewModel: CareCircleViewModel, member: CareCircleMember) {
        self.viewModel = viewModel
        self.member = member
        _firstName = State(initialValue: member.firstName)
        _lastName = State(initialValue: member.lastName)
        _phoneNumber = State(initialValue: member.phoneNumber)
        _email = State(initialValue: member.email ?? "")
        _relationship = State(initialValue: member.relationship)
        _isPrimary = State(initialValue: member.isPrimary)
        _notificationPreference = State(initialValue: member.notificationPreference)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.blue).frame(width: 80, height: 80)
                            Text("\(firstName.prefix(1))\(lastName.prefix(1))")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Edit Member").font(.system(size: 28, weight: .bold))
                    }
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                Text("Relationship").font(.system(size: 18, weight: .semibold))
                                Text("*").foregroundColor(.red)
                            }
                            Picker("Relationship", selection: $relationship) {
                                ForEach(relationships, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Button(action: { saveMember() }) {
                        Text("Save Changes")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        Text("Remove from Care Circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red, lineWidth: 2))
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Remove Member?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                viewModel.deleteMember(member)
                dismiss()
            }
        } message: {
            Text("Remove \(member.fullName) from your Care Circle?")
        }
    }
    
    private func saveMember() {
        var updated = member
        updated.relationship = relationship
        viewModel.updateMember(updated)
        dismiss()
    }
}
