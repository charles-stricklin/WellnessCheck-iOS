//
//  LargeButton.swift
//  WellnessCheck
//
//  Created: v0.1.0 (2025-12-26)
//  Last Modified: v0.1.0 (2025-12-26)
//
//  By Charles Stricklin, Stricklin Development, LLC
//

import SwiftUI

/// Large, senior-friendly button with icon and clear text
/// Follows accessibility guidelines with 60x60pt minimum touch target
struct LargeButton: View {
    // MARK: - Properties

    let title: String
    let systemImage: String?
    let backgroundColor: Color
    let action: () -> Void

    /// Initializes a large button with optional icon
    /// - Parameters:
    ///   - title: Button label text
    ///   - systemImage: Optional SF Symbol icon name
    ///   - backgroundColor: Button background color (defaults to blue)
    ///   - action: Action to perform when tapped
    init(
        title: String,
        systemImage: String? = nil,
        backgroundColor: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.backgroundColor = backgroundColor
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.title)
                        .fontWeight(.semibold)
                }
                Text(title)
                    .font(.system(size: Constants.buttonTextSize))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constants.buttonHeight)
            .foregroundColor(.white)
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
        }
        .buttonStyle(.plain) // Prevents default iOS button styling
    }
}

/// Secondary button style with outline instead of filled background
struct LargeOutlineButton: View {
    // MARK: - Properties

    let title: String
    let systemImage: String?
    let foregroundColor: Color
    let action: () -> Void

    /// Initializes an outlined button
    /// - Parameters:
    ///   - title: Button label text
    ///   - systemImage: Optional SF Symbol icon name
    ///   - foregroundColor: Text and border color (defaults to blue)
    ///   - action: Action to perform when tapped
    init(
        title: String,
        systemImage: String? = nil,
        foregroundColor: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.foregroundColor = foregroundColor
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.title)
                        .fontWeight(.semibold)
                }
                Text(title)
                    .font(.system(size: Constants.buttonTextSize))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constants.buttonHeight)
            .foregroundColor(foregroundColor)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.cornerRadius)
                    .stroke(foregroundColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Filled Button") {
    VStack(spacing: 20) {
        LargeButton(
            title: "Continue",
            systemImage: "arrow.right",
            backgroundColor: .blue
        ) {
            print("Tapped")
        }

        LargeButton(
            title: "Emergency",
            systemImage: "exclamationmark.triangle.fill",
            backgroundColor: .red
        ) {
            print("Emergency tapped")
        }
    }
    .padding()
}

#Preview("Outline Button") {
    VStack(spacing: 20) {
        LargeOutlineButton(
            title: "Skip for Now",
            foregroundColor: .gray
        ) {
            print("Skipped")
        }
    }
    .padding()
}
