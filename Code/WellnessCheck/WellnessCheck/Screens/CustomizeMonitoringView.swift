//
//  CustomizeMonitoringView.swift
//  WellnessCheck
//
//  Screen 10 of 11 - Customize Monitoring
//  Lets users configure monitoring preferences before completing onboarding
//

import SwiftUI

struct CustomizeMonitoringView: View {
    @StateObject private var viewModel = CustomizeMonitoringViewModel()
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Customize Monitoring")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Choose what WellnessCheck watches for. You can always change these later in Settings.")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.top, 8)
                    
                    // MARK: - Settings Card
                    VStack(spacing: 0) {
                        MonitoringToggleRow(
                            title: "Fall Detection",
                            description: "Alert your Care Circle if you take a hard fall and don't respond.",
                            isOn: $viewModel.fallDetectionEnabled
                        )
                        
                        Divider()
                            .padding(.leading, 0)
                        
                        MonitoringToggleRow(
                            title: "Inactivity Alerts",
                            description: "Notice if you haven't moved your phone in an unusually long time.",
                            isOn: $viewModel.inactivityAlertsEnabled
                        )
                        
                        Divider()
                            .padding(.leading, 0)
                        
                        MonitoringToggleRow(
                            title: "I'm a Night Owl",
                            description: "Don't flag late-night activity as unusual. You keep your own hours.",
                            isOn: $viewModel.nightOwlModeEnabled
                        )
                        
                        Divider()
                            .padding(.leading, 0)
                        
                        MonitoringToggleRow(
                            title: "Quiet Hours",
                            description: "Pause check-ins during set hours (your Care Circle can still be alerted in emergencies).",
                            isOn: $viewModel.quietHoursEnabled
                        )
                        
                        // Quiet Hours Time Pickers
                        if viewModel.quietHoursEnabled {
                            VStack(spacing: 16) {
                                Divider()
                                
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Start")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        
                                        DatePicker(
                                            "",
                                            selection: $viewModel.quietHoursStart,
                                            displayedComponents: .hourAndMinute
                                        )
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("End")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                        
                                        DatePicker(
                                            "",
                                            selection: $viewModel.quietHoursEnd,
                                            displayedComponents: .hourAndMinute
                                        )
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.bottom, 8)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    // MARK: - Info Note
                    HStack(alignment: .top, spacing: 12) {
                        Text("💡")
                            .font(.system(size: 24))
                        
                        Text("WellnessCheck learns your routines over the first two weeks. The more you use your phone normally, the better it understands what's typical for you.")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
            }
            
            // MARK: - Bottom Buttons
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.saveSettings()
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    viewModel.useDefaults()
                    onContinue()
                }) {
                    Text("I'll customize this later")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .padding(.top, 16)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.25), value: viewModel.quietHoursEnabled)
    }
}

// MARK: - Toggle Row Component

struct MonitoringToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .frame(width: 60)
        }
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint("Double tap to toggle")
    }
}

// MARK: - Preview

#Preview {
    CustomizeMonitoringView {
        print("Continue tapped")
    }
}
