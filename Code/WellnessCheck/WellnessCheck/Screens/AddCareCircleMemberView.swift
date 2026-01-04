//
//  AddCareCircleMemberView.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//

import SwiftUI
import Contacts

struct AddCareCircleMemberView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CareCircleViewModel
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var relationship = "Daughter"
    @State private var isPrimary = false
    @State private var notificationPreference: CareCircleMember.NotificationPreference = .sms
    @State private var showValidationAlert = false
    @State private var showContactPicker = false
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case firstName, lastName, phone, email
    }
    
    let relationships = ["Daughter", "Son", "Spouse/Partner", "Sibling", "Parent", "Friend", "Neighbor", "Caregiver", "Other"]
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Add Care Circle Member")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    // Choose from Contacts button
                    Button(action: {
                        showContactPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 18))
                            Text("Choose from Contacts")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                
                // Form fields
                VStack(spacing: 20) {
                    // First Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("First Name")
                                .font(.system(size: 18, weight: .semibold))
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        TextField("John", text: $firstName)
                            .font(.system(size: 20))
                            .padding()
                            .frame(height: 60)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .firstName)
                            .textContentType(.givenName)
                            .autocapitalization(.words)
                    }
                    
                    // Last Name
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Last Name")
                                .font(.system(size: 18, weight: .semibold))
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        TextField("Doe", text: $lastName)
                            .font(.system(size: 20))
                            .padding()
                            .frame(height: 60)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .lastName)
                            .textContentType(.familyName)
                            .autocapitalization(.words)
                    }
                    
                    // Phone Number
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Phone Number")
                                .font(.system(size: 18, weight: .semibold))
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        TextField("(555) 123-4567", text: $phoneNumber)
                            .font(.system(size: 20))
                            .padding()
                            .frame(height: 60)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .onChange(of: phoneNumber) { oldValue, newValue in
                                phoneNumber = formatPhoneNumber(newValue)
                            }
                    }
                    
                    // Email (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email (optional)")
                            .font(.system(size: 18, weight: .semibold))
                        
                        TextField("john@example.com", text: $email)
                            .font(.system(size: 20))
                            .padding()
                            .frame(height: 60)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Relationship Picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Relationship")
                                .font(.system(size: 18, weight: .semibold))
                            Text("*")
                                .foregroundColor(.red)
                        }
                        
                        Picker("Relationship", selection: $relationship) {
                            ForEach(relationships, id: \.self) { rel in
                                Text(rel).tag(rel)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Notification Preference
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to Notify")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Picker("Notification Method", selection: $notificationPreference) {
                            ForEach(CareCircleMember.NotificationPreference.allCases, id: \.self) { pref in
                                Text(pref.rawValue).tag(pref)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 8)
                    }
                    
                    // Primary Contact Toggle
                    if viewModel.members.isEmpty || !viewModel.hasPrimaryContact {
                        Toggle(isOn: $isPrimary) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Primary Contact")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("First person to be notified")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                // Save button
                Button(action: {
                    if isFormValid {
                        saveMember()
                    } else {
                        showValidationAlert = true
                    }
                }) {
                    Text("Add to Care Circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                    .frame(height: 32)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .alert("Missing Information", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please fill in all required fields (marked with *).")
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPicker(isPresented: $showContactPicker) { contact in
                // Fill in member info from selected contact
                firstName = contact.firstName
                lastName = contact.lastName
                if let phone = contact.primaryPhoneNumber {
                    phoneNumber = formatPhoneNumber(phone)
                }
                if let contactEmail = contact.primaryEmailAddress {
                    email = contactEmail
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidPhoneNumber(phoneNumber)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count == 10
    }
    
    private func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }
        
        let limitedDigits = String(digits.prefix(10))
        var formatted = ""
        
        for (index, digit) in limitedDigits.enumerated() {
            if index == 0 {
                formatted += "("
            } else if index == 3 {
                formatted += ") "
            } else if index == 6 {
                formatted += "-"
            }
            formatted.append(digit)
        }
        
        return formatted
    }
    
    private func saveMember() {
        let member = CareCircleMember(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber,
            email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            relationship: relationship,
            isPrimary: isPrimary,
            notificationPreference: notificationPreference
        )
        
        viewModel.addMember(member)
        dismiss() // Close the add form, returns to list
    }
}

// MARK: - Preview

#Preview {
    AddCareCircleMemberView(viewModel: CareCircleViewModel())
}
