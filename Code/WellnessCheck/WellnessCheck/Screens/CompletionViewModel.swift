//
//  CompletionViewModel.swift
//  WellnessCheck
//
//  ViewModel for Screen 11 - Completion
//  Gathers setup summary from UserDefaults for display
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CompletionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var careCircleCount: Int = 0
    @Published var careCircleNames: String = ""
    @Published var monitoringFeatures: String = ""
    @Published var homeLocationSet: Bool = false
    
    // MARK: - Initialization
    
    init() {
        loadSummary()
    }
    
    // MARK: - Private Methods
    
    private func loadSummary() {
        loadCareCircleSummary()
        loadMonitoringSummary()
        loadHomeLocationStatus()
    }
    
    private func loadCareCircleSummary() {
        let defaults = UserDefaults.standard

        // Load Care Circle members from UserDefaults
        // Data is stored as JSON-encoded array of CareCircleMember objects
        guard let data = defaults.data(forKey: "careCircleMembers"),
              let members = try? JSONDecoder().decode([CareCircleMember].self, from: data) else {
            careCircleCount = 0
            careCircleNames = "No members added"
            return
        }

        careCircleCount = members.count

        // Build names string using firstName from each member
        let names = members.map { $0.firstName }

        if names.isEmpty {
            careCircleNames = "No members added"
        } else if names.count == 1 {
            careCircleNames = names[0]
        } else if names.count == 2 {
            careCircleNames = "\(names[0]) & \(names[1])"
        } else {
            careCircleNames = "\(names[0]), \(names[1]) + \(names.count - 2) more"
        }
    }
    
    private func loadMonitoringSummary() {
        let defaults = UserDefaults.standard
        
        var features: [String] = []
        
        // Default to true if not set (first run defaults)
        let fallDetection = defaults.object(forKey: "monitoring_fallDetection") as? Bool ?? true
        let inactivityAlerts = defaults.object(forKey: "monitoring_inactivityAlerts") as? Bool ?? true
        let nightOwlMode = defaults.bool(forKey: "monitoring_nightOwlMode")
        let quietHours = defaults.bool(forKey: "monitoring_quietHoursEnabled")
        
        if fallDetection { features.append("Fall Detection") }
        if inactivityAlerts { features.append("Inactivity Alerts") }
        if nightOwlMode { features.append("Night Owl Mode") }
        if quietHours { features.append("Quiet Hours") }
        
        if features.isEmpty {
            monitoringFeatures = "No features enabled"
        } else if features.count <= 2 {
            monitoringFeatures = features.joined(separator: ", ")
        } else {
            monitoringFeatures = "\(features[0]), \(features[1]) + \(features.count - 2) more"
        }
    }
    
    private func loadHomeLocationStatus() {
        let defaults = UserDefaults.standard

        // Home location is stored as JSON-encoded HomeLocation object under "homeLocation" key
        // We just need to check if the data exists - if it does, location was set
        homeLocationSet = defaults.data(forKey: "homeLocation") != nil
    }
}
