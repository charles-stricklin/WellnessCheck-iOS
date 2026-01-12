//
//  EditCareCircleMemberView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//

import SwiftUI
import UIKit

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

    private let relationships = [
        "Daughter",
        "Son",
        "Spouse",
        "Partner",
        "Sister",
        "Brother",
        "Parent",
        "Friend",
        "Neighbor",
        "Caregiver",
        "Other"
    ]

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
                    // MARK: - Header with Photo/Initials and Name
                    VStack(spacing: 16) {
                        // Contact photo or initials
                        if let imageData = member.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 3)
                                )
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 100, height: 100)

                                Text("\(firstName.prefix(1))\(lastName.prefix(1))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        // Full name
                        Text("\(firstName) \(lastName)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        // Primary badge if applicable
                        if member.isPrimary {
                            Text("PRIMARY CONTACT")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 24)

                    // MARK: - Editable Fields
                    VStack(spacing: 20) {
                        // Phone Number (editable)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)

                            TextField("Phone Number", text: $phoneNumber)
                                .font(.system(size: 20))
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }

                        // Email (editable, optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email (Optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)

                            TextField("Email", text: $email)
                                .font(.system(size: 20))
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }

                        // Relationship picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Relationship")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)

                            Picker("Relationship", selection: $relationship) {
                                ForEach(relationships, id: \.self) { rel in
                                    Text(rel).tag(rel)
                                }
                            }
                            .pickerStyle(.menu)
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    // MARK: - Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { saveMember() }) {
                            Text("Save Changes")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(Color.blue)
                                .cornerRadius(16)
                        }

                        Button(action: { showDeleteConfirmation = true }) {
                            Text("Remove from Care Circle")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
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
        updated.phoneNumber = phoneNumber
        updated.email = email.isEmpty ? nil : email
        updated.relationship = relationship
        viewModel.updateMember(updated)
        dismiss()
    }
}
