//
//  ConfirmCareCircleMemberView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/6/26.
//
//  Confirmation screen shown after selecting a contact from the iOS Contacts picker.
//  Displays the selected contact's information and allows the user to choose
//  the relationship before adding them to the Care Circle.
//

import SwiftUI

struct ConfirmCareCircleMemberView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: CareCircleViewModel

    let firstName: String
    let lastName: String
    let phoneNumber: String
    let email: String?
    let imageData: Data?

    @State private var selectedRelationship: String = "Friend"
    @State private var showInvitationPreview = false
    @State private var invitationResult: InvitationResult?

    private let relationships = [
        "Daughter",
        "Son",
        "Spouse",
        "Partner",
        "Sister",
        "Brother",
        "Friend",
        "Neighbor",
        "Caregiver",
        "Other"
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.784, green: 0.902, blue: 0.961))

                        Text("Add to Care Circle?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(primaryTextColor)

                        Text("Please confirm their information and relationship")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 30)

                    // Contact information card
                    VStack(alignment: .leading, spacing: 16) {
                        // Name
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            Text("\(firstName) \(lastName)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                        }

                        Divider()

                        // Phone
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Phone Number")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            Text(phoneNumber.isEmpty ? "No phone number" : phoneNumber)
                                .font(.system(size: 20))
                                .foregroundColor(phoneNumber.isEmpty ? .red : primaryTextColor)
                        }

                        if let email = email, !email.isEmpty {
                            Divider()

                            // Email
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Text(email)
                                    .font(.system(size: 18))
                                    .foregroundColor(primaryTextColor)
                            }
                        }

                        Divider()

                        // Relationship picker
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Relationship")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("*")
                                    .foregroundColor(.red)
                            }

                            Picker("Relationship", selection: $selectedRelationship) {
                                ForEach(relationships, id: \.self) { relationship in
                                    Text(relationship).tag(relationship)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(colorScheme == .dark ? Color(white: 0.2) : Color(UIColor.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding(24)
                    .background(cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    Spacer()

                    // Action buttons
                    VStack(spacing: 12) {
                        // Add Member button
                        Button(action: addMember) {
                            Text("Add to Care Circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? Color(red: 0.102, green: 0.227, blue: 0.322) : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(phoneNumber.isEmpty ? Color.gray : Color(red: 0.784, green: 0.902, blue: 0.961))
                                .cornerRadius(16)
                        }
                        .disabled(phoneNumber.isEmpty)

                        // Cancel button
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Invitation Preview", isPresented: $showInvitationPreview) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let result = invitationResult {
                    let testMode = String(localized: "(Test Mode)")
                    let toLabel = String(localized: "To:")
                    let phoneLabel = String(localized: "Phone:")
                    let readyMessage = String(localized: "Invitation ready to send. Not actually sent in test mode.")
                    Text("\(testMode)\n\n\(toLabel) \(result.recipientName)\n\(phoneLabel) \(result.recipientPhone)\n\n\(readyMessage)")
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.067, green: 0.133, blue: 0.267) : Color(red: 0.784, green: 0.902, blue: 0.961)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.102, green: 0.227, blue: 0.322)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color.white
    }

    // MARK: - Methods

    private func addMember() {
        guard !phoneNumber.isEmpty else { return }

        let member = CareCircleMember(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email,
            relationship: selectedRelationship,
            isPrimary: viewModel.members.isEmpty, // First one is primary
            notificationPreference: .sms,
            imageData: imageData
        )

        // Add member to the Care Circle
        viewModel.addMember(member)

        // Send invitation via Twilio (test mode for now)
        TwilioService.shared.sendInvitation(to: member) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let invitationResult):
                    // Update invitation status to 'sent'
                    self.viewModel.updateInvitationStatus(member, status: .sent)

                    // Show preview alert
                    self.invitationResult = invitationResult
                    self.showInvitationPreview = true
                case .failure(let error):
                    print("❌ Failed to send invitation: \(error.localizedDescription)")
                    // Still dismiss - member was added successfully
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ConfirmCareCircleMemberView(
        viewModel: CareCircleViewModel(),
        firstName: "Sharon",
        lastName: "Smith",
        phoneNumber: "+1 (555) 123-4567",
        email: "sharon@example.com",
        imageData: nil
    )
}
