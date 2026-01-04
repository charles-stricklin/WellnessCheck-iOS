//
//  CareCircleListView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//

import SwiftUI
import Contacts

struct CareCircleListView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CareCircleViewModel()
    let onComplete: () -> Void
    
    @State private var showAddMember = false
    @State private var showContactPicker = false
    @State private var selectedMemberToEdit: CareCircleMember? = nil
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.784, green: 0.902, blue: 0.961)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Your Care Circle")
                            .font(.system(size: 28, weight: .bold))
                        
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
                                .foregroundColor(.gray)
                            
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
                                ForEach(viewModel.members) { member in
                                    CareCircleMemberRow(member: member)
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color.blue)
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
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue, lineWidth: 2)
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
                    // Create a new member from the selected contact
                    let member = CareCircleMember(
                        firstName: contact.firstName,
                        lastName: contact.lastName,
                        phoneNumber: contact.primaryPhoneNumber ?? "",
                        email: contact.primaryEmailAddress,
                        relationship: "Friend", // Default - user can edit later if needed
                        isPrimary: viewModel.members.isEmpty, // First one is primary
                        notificationPreference: .sms
                    )
                    viewModel.addMember(member)
                }
            }
        }
    }
}

// MARK: - Member Row Component

struct CareCircleMemberRow: View {
    let member: CareCircleMember
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar circle with initials
            ZStack {
                Circle()
                    .fill(member.isPrimary ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text("\(member.firstName.prefix(1))\(member.lastName.prefix(1))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(member.isPrimary ? .white : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(member.fullName)
                        .font(.system(size: 18, weight: .semibold))
                    
                    if member.isPrimary {
                        Text("PRIMARY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(member.relationship)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(member.phoneNumber)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    CareCircleListView {
        print("Complete")
    }
}
