//
//  WellnessCheckWatchApp.swift
//  WellnessCheckWatch Watch App
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Minimal watch app for 24/7 fall detection.
//  Uses Apple's CMFallDetectionManager which runs in background.
//  Shows alert UI when fall detected, sends to iPhone for SMS.
//

import SwiftUI

@main
struct WellnessCheckWatchApp: App {
    /// Fall detection manager handles CMFallDetectionManager
    @StateObject private var fallManager = FallDetectionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fallManager)
        }
    }
}
