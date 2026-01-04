//
//  ContactPicker.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/3/26.
//

import SwiftUI
import Contacts
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onContactSelected: (CNContact) -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPicker
        
        init(parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onContactSelected(contact)
            parent.isPresented = false
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }
    }
}

// Helper extension to extract contact info
extension CNContact {
    var firstName: String {
        givenName
    }
    
    var lastName: String {
        familyName
    }
    
    var primaryPhoneNumber: String? {
        phoneNumbers.first?.value.stringValue
    }
    
    var primaryEmailAddress: String? {
        emailAddresses.first?.value as String?
    }
}
