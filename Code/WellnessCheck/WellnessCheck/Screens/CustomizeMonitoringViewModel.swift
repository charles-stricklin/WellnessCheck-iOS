//
//  CustomizeMonitoringViewModel.swift
//  WellnessCheck
//
//  ViewModel for Screen 10 - Customize Monitoring
//  Manages monitoring preferences and persists to UserDefaults
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CustomizeMonitoringViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var fallDetectionEnabled: Bool = true
    @Published var inactivityAlertsEnabled: Bool = true
    @Published var nightOwlModeEnabled: Bool = false
    @Published var quietHoursEnabled: Bool = false
    @Published var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @Published var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let fallDetection = "monitoring_fallDetection"
        static let inactivityAlerts = "monitoring_inactivityAlerts"
        static let nightOwlMode = "monitoring_nightOwlMode"
        static let quietHoursEnabled = "monitoring_quietHoursEnabled"
        static let quietHoursStart = "monitoring_quietHoursStart"
        static let quietHoursEnd = "monitoring_quietHoursEnd"
    }
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Save current settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        
        defaults.set(fallDetectionEnabled, forKey: Keys.fallDetection)
        defaults.set(inactivityAlertsEnabled, forKey: Keys.inactivityAlerts)
        defaults.set(nightOwlModeEnabled, forKey: Keys.nightOwlMode)
        defaults.set(quietHoursEnabled, forKey: Keys.quietHoursEnabled)
        defaults.set(quietHoursStart.timeIntervalSince1970, forKey: Keys.quietHoursStart)
        defaults.set(quietHoursEnd.timeIntervalSince1970, forKey: Keys.quietHoursEnd)
        
        print("✅ Monitoring settings saved")
    }
    
    /// Use default settings (for "I'll customize this later")
    func useDefaults() {
        fallDetectionEnabled = true
        inactivityAlertsEnabled = true
        nightOwlModeEnabled = false
        quietHoursEnabled = false
        
        saveSettings()
        print("✅ Default monitoring settings applied")
    }
    
    // MARK: - Private Methods
    
    /// Load settings from UserDefaults (if previously saved)
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Only load if settings have been saved before
        if defaults.object(forKey: Keys.fallDetection) != nil {
            fallDetectionEnabled = defaults.bool(forKey: Keys.fallDetection)
            inactivityAlertsEnabled = defaults.bool(forKey: Keys.inactivityAlerts)
            nightOwlModeEnabled = defaults.bool(forKey: Keys.nightOwlMode)
            quietHoursEnabled = defaults.bool(forKey: Keys.quietHoursEnabled)
            
            if let startInterval = defaults.object(forKey: Keys.quietHoursStart) as? TimeInterval {
                quietHoursStart = Date(timeIntervalSince1970: startInterval)
            }
            
            if let endInterval = defaults.object(forKey: Keys.quietHoursEnd) as? TimeInterval {
                quietHoursEnd = Date(timeIntervalSince1970: endInterval)
            }
            
            print("📋 Monitoring settings loaded from UserDefaults")
        } else {
            print("📋 Using default monitoring settings (first run)")
        }
    }
}

// MARK: - Computed Properties for SmartMonitoringService Integration

extension CustomizeMonitoringViewModel {
    
    /// Returns quiet hours as a tuple of hour components for SmartMonitoringService
    var quietHoursRange: (start: Int, end: Int)? {
        guard quietHoursEnabled else { return nil }
        
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: quietHoursStart)
        let endHour = calendar.component(.hour, from: quietHoursEnd)
        
        return (start: startHour, end: endHour)
    }
    
    /// Summary of enabled features for display
    var enabledFeaturesSummary: String {
        var features: [String] = []
        
        if fallDetectionEnabled { features.append("Fall Detection") }
        if inactivityAlertsEnabled { features.append("Inactivity Alerts") }
        if nightOwlModeEnabled { features.append("Night Owl Mode") }
        if quietHoursEnabled { features.append("Quiet Hours") }
        
        if features.isEmpty {
            return "No monitoring features enabled"
        }
        
        return features.joined(separator: ", ")
    }
}
