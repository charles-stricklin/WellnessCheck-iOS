//
//  BrandingManager.swift
//  WellnessCheck
//
//  Created by Charles W. Stricklin on 1/14/26.
//
//  Manages app branding for consumer and enterprise customers.
//  Enterprise customers can have custom logos, colors, and app names.
//  This manager loads branding at app launch and provides it to all views
//  via environment injection.
//
//  Usage:
//    1. Add @StateObject var brandingManager = BrandingManager() in App
//    2. Inject via .environmentObject(brandingManager)
//    3. Access in views via @EnvironmentObject var branding: BrandingManager
//    4. Use branding.primaryColor instead of hardcoded Color(red: 0.784, ...)
//

import SwiftUI
import Combine

// MARK: - Branding Manager

@MainActor
class BrandingManager: ObservableObject {

    // MARK: - Published Properties

    /// The app display name shown in headers and splash screen
    @Published var appName: String = "WellnessCheck"

    /// The tagline shown on welcome/splash screens
    @Published var tagline: String = "Living alone doesn't mean having to be alone."

    /// Primary brand color - light blue for consumer, custom for enterprise
    /// Used for icons, buttons, accents in light mode
    @Published var primaryColor: Color = BrandingManager.defaultPrimaryColor

    /// Secondary/navy color for dark backgrounds and dark mode
    @Published var navyColor: Color = BrandingManager.defaultNavyColor

    /// Dark mode background color
    @Published var darkBackground: Color = BrandingManager.defaultDarkBackground

    /// Whether this is an enterprise account
    @Published var isEnterprise: Bool = false

    /// Enterprise organization ID (nil for consumer)
    @Published var organizationId: String? = nil

    /// Enterprise organization name
    @Published var organizationName: String? = nil

    /// Custom logo URL for enterprise (nil uses default asset)
    @Published var customLogoUrl: URL? = nil

    /// Cached custom logo image (loaded async from URL)
    @Published var customLogoImage: Image? = nil

    /// User's room number for enterprise/facility use
    @Published var roomNumber: String? = nil

    // MARK: - Default Colors (WellnessCheck Brand)

    /// Default light blue: #C8E6F5 / RGB(200, 230, 245)
    static let defaultPrimaryColor = Color(red: 0.784, green: 0.902, blue: 0.961)

    /// Default navy: #1A3A52 / RGB(26, 58, 82)
    static let defaultNavyColor = Color(red: 0.102, green: 0.227, blue: 0.322)

    /// Default dark mode background: RGB(19, 27, 50)
    static let defaultDarkBackground = Color(red: 0.075, green: 0.106, blue: 0.196)

    // MARK: - Computed Properties

    /// Returns the appropriate logo image (custom or default)
    var logoImage: Image {
        if let custom = customLogoImage {
            return custom
        }
        // Default to asset catalog image
        return Image("WellnessCheckIcon")
    }

    /// Background color that adapts to color scheme
    /// - Parameter colorScheme: Current system color scheme
    /// - Returns: Primary color for light mode, dark background for dark mode
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : primaryColor
    }

    /// Primary text color that adapts to color scheme
    /// - Parameter colorScheme: Current system color scheme
    /// - Returns: White for dark mode, navy for light mode
    func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : navyColor
    }

    /// Secondary/muted text color that adapts to color scheme
    /// - Parameter colorScheme: Current system color scheme
    /// - Returns: Light gray for dark mode, system gray for light mode
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.6) : .gray
    }

    /// Card background color that adapts to color scheme
    /// - Parameter colorScheme: Current system color scheme
    /// - Returns: Dark gray for dark mode, white for light mode
    func cardBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }

    /// Button text color (for buttons with primaryColor background)
    /// - Parameter colorScheme: Current system color scheme
    /// - Returns: Navy for dark mode (on light blue), white for light mode
    func buttonTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? navyColor : .white
    }

    /// Form field background color
    /// - Parameter colorScheme: Current system color scheme
    /// - Returns: Dark gray for dark mode, light gray for light mode
    func fieldBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: 0.2) : Color.gray.opacity(0.1)
    }

    // MARK: - Initialization

    init() {
        // Default consumer branding - no action needed
    }

    // MARK: - Enterprise Loading

    /// Load enterprise branding from Firestore
    /// Call this at app launch if user has an orgId stored
    /// - Parameter orgId: The organization ID to load branding for
    func loadEnterpriseBranding(for orgId: String) async {
        // TODO: Implement Firestore fetch when enterprise is ready
        //
        // let db = Firestore.firestore()
        // let doc = try await db.collection("organizations").document(orgId).getDocument()
        // guard let data = doc.data() else { return }
        //
        // if let brandingData = data["branding"] as? [String: Any] {
        //     if let appName = brandingData["appName"] as? String {
        //         self.appName = appName
        //     }
        //     if let primaryColorHex = brandingData["primaryColor"] as? String {
        //         self.primaryColor = Color(hex: primaryColorHex)
        //     }
        //     if let logoUrlString = brandingData["logoUrl"] as? String,
        //        let logoUrl = URL(string: logoUrlString) {
        //         self.customLogoUrl = logoUrl
        //         await loadCustomLogo(from: logoUrl)
        //     }
        // }
        //
        // self.organizationId = orgId
        // self.organizationName = data["name"] as? String
        // self.isEnterprise = true

        print("📦 BrandingManager: Enterprise branding not yet implemented for org: \(orgId)")
    }

    /// Load custom logo image from URL
    /// - Parameter url: URL of the logo image
    private func loadCustomLogo(from url: URL) async {
        // TODO: Implement async image loading when enterprise is ready
        //
        // do {
        //     let (data, _) = try await URLSession.shared.data(from: url)
        //     if let uiImage = UIImage(data: data) {
        //         self.customLogoImage = Image(uiImage: uiImage)
        //     }
        // } catch {
        //     print("❌ Failed to load custom logo: \(error.localizedDescription)")
        // }

        print("📦 BrandingManager: Custom logo loading not yet implemented")
    }

    /// Reset to default consumer branding
    /// Call this when user logs out of enterprise account
    func resetToDefaultBranding() {
        appName = "WellnessCheck"
        tagline = "Living alone doesn't mean having to be alone."
        primaryColor = BrandingManager.defaultPrimaryColor
        navyColor = BrandingManager.defaultNavyColor
        darkBackground = BrandingManager.defaultDarkBackground
        isEnterprise = false
        organizationId = nil
        organizationName = nil
        customLogoUrl = nil
        customLogoImage = nil
        roomNumber = nil
    }

    // MARK: - Enterprise Helpers

    /// Check if user has enterprise branding to load
    /// Call this at app launch to determine if enterprise branding should be fetched
    /// - Returns: Organization ID if stored, nil otherwise
    func checkForStoredEnterpriseAccount() -> String? {
        // TODO: Check UserDefaults or Keychain for stored orgId
        // return UserDefaults.standard.string(forKey: "enterpriseOrgId")
        return nil
    }

    /// Store enterprise organization ID for future launches
    /// - Parameter orgId: Organization ID to store
    func storeEnterpriseAccount(orgId: String) {
        // TODO: Store in UserDefaults or Keychain
        // UserDefaults.standard.set(orgId, forKey: "enterpriseOrgId")
        print("📦 BrandingManager: Storing enterprise org ID: \(orgId)")
    }

    /// Clear stored enterprise account
    func clearStoredEnterpriseAccount() {
        // TODO: Remove from UserDefaults or Keychain
        // UserDefaults.standard.removeObject(forKey: "enterpriseOrgId")
        print("📦 BrandingManager: Cleared stored enterprise account")
    }
}

// MARK: - Preview Helpers

extension BrandingManager {
    /// Create a preview instance with enterprise branding for SwiftUI previews
    static var enterprisePreview: BrandingManager {
        let manager = BrandingManager()
        manager.isEnterprise = true
        manager.organizationId = "preview-org"
        manager.organizationName = "Sunrise Senior Living"
        manager.appName = "Sunrise WellnessCheck"
        manager.primaryColor = Color(red: 0.1, green: 0.37, blue: 0.48)  // Teal example
        manager.roomNumber = "204B"
        return manager
    }
}
