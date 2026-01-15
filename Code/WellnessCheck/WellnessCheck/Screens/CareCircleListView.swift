//
//  CareCircleListView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//

import SwiftUI
import Contacts
import UIKit

struct CareCircleListView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = CareCircleViewModel()
    let onComplete: () -> Void
    
    @State private var showAddMember = false
    @State private var showContactPicker = false
    @State private var selectedMemberToEdit: CareCircleMember? = nil
    @State private var showConfirmContact = false
    @State private var selectedContactData: (firstName: String, lastName: String, phone: String, email: String?, imageData: Data?)? = nil
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.784, green: 0.902, blue: 0.961))

                        Text("Your Care Circle")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(primaryTextColor)

                        Text("\(viewModel.members.count) member\(viewModel.members.count == 1 ? "" : "s")")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    if viewModel.members.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Spacer()

                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))

                            Text("No Care Circle Members Yet")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(secondaryTextColor)

                            Text("Add trusted people who can help if you need assistance")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Spacer()
                        }
                    } else {
                        // Member list
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                                    CareCircleMemberRow(
                                        member: member,
                                        position: index + 1,
                                        isFirst: index == 0,
                                        isLast: index == viewModel.members.count - 1,
                                        colorScheme: colorScheme,
                                        onMoveUp: { viewModel.moveMemberUp(member) },
                                        onMoveDown: { viewModel.moveMemberDown(member) }
                                    )
                                    .onTapGesture {
                                        selectedMemberToEdit = member
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Add from Contacts button
                        Button(action: {
                            showContactPicker = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 22))
                                Text("Add from Contacts")
                                    .font(.system(size: 22, weight: .semibold))
                            }
                            .foregroundColor(colorScheme == .dark ? Color(red: 0.102, green: 0.227, blue: 0.322) : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color(red: 0.784, green: 0.902, blue: 0.961))
                            .cornerRadius(16)
                        }

                        // Manual Add Member button
                        Button(action: {
                            showAddMember = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 22))
                                Text("Add Manually")
                                    .font(.system(size: 22, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 0.784, green: 0.902, blue: 0.961))
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 0.784, green: 0.902, blue: 0.961), lineWidth: 2)
                            )
                            .cornerRadius(16)
                        }

                        // Continue/Finish button
                        Button(action: {
                            onComplete()
                        }) {
                            Text(viewModel.members.isEmpty ? "I'll Do This Later" : "Continue")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(viewModel.members.isEmpty ? .gray : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(viewModel.members.isEmpty ? Color.clear : Color(red: 0.102, green: 0.227, blue: 0.322))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(viewModel.members.isEmpty ? Color.gray : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddCareCircleMemberView(viewModel: viewModel)
            }
            .sheet(item: $selectedMemberToEdit) { member in
                EditCareCircleMemberView(viewModel: viewModel, member: member)
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPicker(isPresented: $showContactPicker) { contact in
                    // Store the selected contact data (including photo) and show confirmation view
                    selectedContactData = (
                        firstName: contact.firstName,
                        lastName: contact.lastName,
                        phone: contact.primaryPhoneNumber ?? "",
                        email: contact.primaryEmailAddress,
                        imageData: contact.contactImageData
                    )
                    showConfirmContact = true
                }
            }
            .sheet(isPresented: $showConfirmContact) {
                if let contactData = selectedContactData {
                    ConfirmCareCircleMemberView(
                        viewModel: viewModel,
                        firstName: contactData.firstName,
                        lastName: contactData.lastName,
                        phoneNumber: contactData.phone,
                        email: contactData.email,
                        imageData: contactData.imageData
                    )
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

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.102, green: 0.227, blue: 0.322)
    }
}

// MARK: - Member Row Component

struct CareCircleMemberRow: View {
    let member: CareCircleMember
    let position: Int
    let isFirst: Bool
    let isLast: Bool
    let colorScheme: ColorScheme
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    private let lightBlue = Color(red: 0.784, green: 0.902, blue: 0.961)

    var body: some View {
        HStack(spacing: 12) {
            // Order number
            Text("\(position)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(lightBlue)
                .frame(width: 36)

            // Up/Down arrows
            VStack(spacing: 4) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isFirst ? .gray.opacity(0.3) : lightBlue)
                }
                .disabled(isFirst)

                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isLast ? .gray.opacity(0.3) : lightBlue)
                }
                .disabled(isLast)
            }
            .frame(width: 30)

            // Avatar - show contact photo if available, otherwise initials
            if let imageData = member.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(member.isPrimary ? lightBlue : Color.gray.opacity(0.3), lineWidth: 2)
                    )
            } else {
                // Fallback to initials
                ZStack {
                    Circle()
                        .fill(member.isPrimary ? lightBlue : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)

                    Text("\(member.firstName.prefix(1))\(member.lastName.prefix(1))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(member.isPrimary ? Color(red: 0.102, green: 0.227, blue: 0.322) : .gray)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(member.fullName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.102, green: 0.227, blue: 0.322))

                    if member.isPrimary {
                        Text("PRIMARY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.102, green: 0.227, blue: 0.322))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(lightBlue)
                            .cornerRadius(4)
                    }
                }

                Text(member.relationship)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                HStack(spacing: 8) {
                    Text(member.phoneNumber)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    // Invitation status badge
                    invitationStatusBadge(for: member)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func invitationStatusBadge(for member: CareCircleMember) -> some View {
        switch member.invitationStatus {
        case .pending:
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 10))
                Text("Pending")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)

        case .sent:
            HStack(spacing: 4) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 10))
                Text("Invited")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)

        case .accepted:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                Text("Connected")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.1))
            .cornerRadius(4)

        case .declined:
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                Text("Declined")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.red)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red.opacity(0.1))
            .cornerRadius(4)
        }
    }
}

// MARK: - Preview

#Preview {
    CareCircleListView {
        print("Complete")
    }
}
