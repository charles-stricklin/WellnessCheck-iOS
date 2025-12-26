# WellnessCheck Onboarding Flow - Setup Instructions

## Overview
The onboarding flow has been successfully built! This guide will help you complete the final configuration steps in Xcode.

## What Was Built

### 1. Folder Structure
- ✅ Models/ - User data model
- ✅ ViewModels/ - OnboardingViewModel for state management
- ✅ Screens/ - All onboarding views and main dashboard
- ✅ Shared/ - Reusable UI components (LargeButton)
- ✅ Utilities/ - Constants and helper functions
- ✅ Services/ - (Created, ready for implementation)

### 2. Onboarding Screens
1. **WelcomeView** - Introduction to WellnessCheck with key features
2. **PermissionsView** - Requests HealthKit and Notification permissions
3. **ProfileSetupView** - Collects user's name and phone number
4. **CareCircleIntroView** - Introduces Care Circle concept
5. **MainDashboardView** - Placeholder dashboard (shown after onboarding)

### 3. Components Created
- **OnboardingViewModel** - Manages onboarding flow state
- **OnboardingContainerView** - Orchestrates the onboarding screens
- **LargeButton** - Senior-friendly button component
- **User** model - Solo dweller data structure
- **Constants** - App-wide constants

## Required Xcode Configuration

### Step 1: Add HealthKit Capability
1. Open the WellnessCheck project in Xcode
2. Select the WellnessCheck target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "HealthKit"
6. Check "Background Delivery" if needed for continuous monitoring

### Step 2: Add Privacy Descriptions
In Xcode, you need to add the following privacy descriptions to Info.plist:

**Option A: Via Xcode UI**
1. Select the WellnessCheck target
2. Go to the "Info" tab
3. Add the following Custom iOS Target Properties:

| Key | Value |
|-----|-------|
| Privacy - Health Share Usage Description | WellnessCheck monitors your activity and fall detection to keep you safe and alert your Care Circle in emergencies. |
| Privacy - Health Update Usage Description | WellnessCheck records wellness check-ins to track your safety status. |
| NSUserNotificationsUsageDescription | WellnessCheck needs to send you alerts and reminders to help keep you safe. |

**Option B: Via Info.plist (if accessible)**
Add these keys to Info.plist:
```xml
<key>NSHealthShareUsageDescription</key>
<string>WellnessCheck monitors your activity and fall detection to keep you safe and alert your Care Circle in emergencies.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>WellnessCheck records wellness check-ins to track your safety status.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>WellnessCheck needs to send you alerts and reminders to help keep you safe.</string>
```

### Step 3: Add Files to Xcode Project
All Swift files have been created in the correct folders, but they need to be added to the Xcode project:

1. In Xcode, right-click on the "WellnessCheck" folder in the Project Navigator
2. Select "Add Files to 'WellnessCheck'..."
3. Navigate to each folder and add all `.swift` files:
   - Models/User.swift
   - ViewModels/OnboardingViewModel.swift
   - Screens/WelcomeView.swift
   - Screens/PermissionsView.swift
   - Screens/ProfileSetupView.swift
   - Screens/CareCircleIntroView.swift
   - Screens/OnboardingContainerView.swift
   - Screens/MainDashboardView.swift
   - Shared/LargeButton.swift
   - Utilities/Constants.swift
4. Make sure "Copy items if needed" is unchecked (files are already in correct location)
5. Make sure the WellnessCheck target is selected

**OR** you can add the folders:
1. Right-click on "WellnessCheck" folder
2. Select "Add Files to 'WellnessCheck'..."
3. Select the Models, ViewModels, Screens, Shared, and Utilities folders
4. Check "Create groups"
5. Select the WellnessCheck target

### Step 4: Remove Old ContentView.swift (Optional)
The ContentView.swift file is no longer needed since we're using the new onboarding flow:
1. In Xcode, find ContentView.swift
2. Right-click and select "Delete"
3. Choose "Move to Trash"

## Testing the Onboarding Flow

### Build and Run
1. Select a simulator or device (iOS 16.0+)
2. Press Cmd+R to build and run
3. The onboarding flow should appear automatically for first-time users

### Reset Onboarding (For Testing)
To test the onboarding flow again:
1. In the app, go to Settings app → WellnessCheck → Reset
2. Or in code, add a debug button that calls:
   ```swift
   UserDefaults.standard.removeObject(forKey: Constants.hasCompletedOnboardingKey)
   ```

### Expected Flow
1. **Welcome Screen** - Shows app features and disclaimer
2. **Permissions Screen** - Request HealthKit and Notifications
3. **Profile Setup** - Enter name and phone number (auto-formats phone)
4. **Care Circle Intro** - Explains Care Circle concept
5. **Main Dashboard** - Shows placeholder dashboard (ready for future development)

## Onboarding Features

### Design Principles
✅ Senior-friendly UI (large buttons, clear text, high contrast)
✅ 60x60pt minimum touch targets
✅ Font sizes: 20pt+ for body, 22pt+ for buttons
✅ Simple navigation with back button support
✅ Progress indicator showing current step
✅ Smooth transitions between screens

### Permissions Handling
✅ HealthKit permission request for activity monitoring
✅ Notification permission request for alerts
✅ Clear explanations of why each permission is needed
✅ Visual feedback when permissions are granted
✅ Can only proceed when all permissions granted

### Data Collection
✅ User name collection
✅ Phone number with auto-formatting (US format)
✅ Validation before allowing to proceed
✅ Data saved to UserDefaults (will be migrated to Firebase later)

### Privacy & Safety
✅ Medical device disclaimer on welcome screen
✅ Privacy notes throughout the flow
✅ Clear explanation of data usage
✅ User control emphasized

## Next Steps

### Immediate
1. ✅ Configure Info.plist privacy descriptions
2. ✅ Add HealthKit capability
3. ✅ Add files to Xcode project
4. ✅ Build and test the onboarding flow

### Future Development
- [ ] Implement Firebase authentication
- [ ] Build Care Circle member management
- [ ] Implement HealthKit monitoring services
- [ ] Create main dashboard with real functionality
- [ ] Add settings screen
- [ ] Implement alert system
- [ ] Add Do Not Disturb scheduling
- [ ] Build emergency alert flow

## File Structure
```
WellnessCheck/
├── Models/
│   └── User.swift
├── ViewModels/
│   └── OnboardingViewModel.swift
├── Screens/
│   ├── WelcomeView.swift
│   ├── PermissionsView.swift
│   ├── ProfileSetupView.swift
│   ├── CareCircleIntroView.swift
│   ├── OnboardingContainerView.swift
│   └── MainDashboardView.swift
├── Shared/
│   └── LargeButton.swift
├── Utilities/
│   └── Constants.swift
├── Services/ (empty, ready for implementation)
├── Resources/ (empty, ready for assets)
└── WellnessCheckApp.swift (updated)
```

## Troubleshooting

### Build Errors
- **"Cannot find 'Constants' in scope"**: Make sure Constants.swift is added to the Xcode project
- **"No such module 'HealthKit'"**: Add HealthKit capability in Signing & Capabilities
- **Missing privacy descriptions**: Add the required Info.plist entries

### Permission Issues
- **HealthKit permission not showing**: Ensure HealthKit capability is enabled
- **Notification permission fails silently**: Check that Info.plist has notification usage description

### Testing
- **Onboarding doesn't appear**: Check that `hasCompletedOnboardingKey` is false in UserDefaults
- **Can't proceed from permissions screen**: Both HealthKit and Notifications must be granted

## Notes
- The onboarding flow follows Apple's Human Interface Guidelines
- All code includes comprehensive comments explaining WHY, not just WHAT
- Senior-friendly design principles are followed throughout
- MVVM architecture is used consistently
- All views have SwiftUI previews for easy development

## Questions?
Refer to claude.md for the full project context and coding standards.
