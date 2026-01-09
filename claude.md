# WellnessCheck - Project Context for Claude

**Last Updated**: January 6, 2026  
**Developer**: Charles W. Stricklin
**Target Audience**: Solo dwellers (seniors and people medically at risk living alone) and their loved ones

---

## Project Overview

WellnessCheck is a comprehensive safety monitoring and health management iOS platform designed to help solo dwellers stay connected to the people who care about them. The platform detects falls, monitors for periods of inactivity, syncs glucose data, tracks medications, and automatically alerts designated Care Circle members when potential emergencies or wellness concerns are detected.

### Core Mission
Create a reliable, privacy-respecting safety net for people living independently while giving their loved ones peace of mind.

---

## Platform Architecture

WellnessCheck follows a two-app model inspired by Libre 3/LibreLinkUp:

### WellnessCheck (Solo Dweller's App)
The primary app installed on the solo dweller's phone. Optimized for seniors with large touch targets, high contrast, and minimal cognitive load.

**Features:**
- Fall detection and inactivity monitoring
- Wellness concern monitoring (depression patterns, excessive sleep)
- Glucose data syncing (Libre 3 integration via Apple Health, intention is to do the same for DEXCOM when it becomes possible.)
- Medication tracking and alerts
- Appointment management
- Physician's contacts and specialties
- Care Circle management (invite/remove members)
- Check-in functionality
- Do Not Disturb scheduling

**Domain:** wellnesscheck.dev (registered)

### WellnessWatch (Care Circle Member's App)
The companion app for caregivers and loved ones. Provides monitoring dashboards and real-time alerts.

**Features:**
- Dashboard showing all connected solo dwellers
- Real-time status and alert notifications
- Trend data and history
- Quick-glance status updates
- Support for monitoring multiple people

**Domain:** wellnesswatch.dev (registered)

---

## Terminology

Consistent terminology used throughout both apps and all documentation:

| Concept | Term | Usage |
|---------|------|-------|
| Person using WellnessCheck | **Solo Dweller** | Marketing, docs. In-app uses "My" (My Wellness, My Care Circle) |
| The group of connected people | **Care Circle** | Both apps |
| Anyone in the Care Circle | **Care Circle Member** | Both apps. Can shorten to "Member" in context |
| Senior's app | **WellnessCheck** | |
| Caregiver's app | **WellnessWatch** | |

**Note:** "Solo Dweller" captures people navigating life independently without a built-in support network - regardless of age. A 35-year-old with epilepsy who lives alone is as much a solo dweller as a 75-year-old widow.

---

## Connection Model

The invitation flow ensures explicit consent from the solo dweller:

1. **Solo dweller initiates**: In WellnessCheck, tap "Add Care Circle Member"
2. **Enter contact info**: First Name, Last Name, Phone Number (email optional)
3. **SMS invitation sent**: Caregiver receives text with link to download WellnessWatch
4. **Caregiver accepts**: Downloads app, creates account, connection established

**Key principles:**
- Solo dweller always initiates (clear consent chain)
- Phone number is primary (seniors know phone numbers better than emails)
- Works for remote setup (family doesn't need to be physically present)
- Reuses Twilio infrastructure already built for emergency alerts

---

## Current Tech Stack

### Development Environment
- **IDE**: Xcode (latest stable version)
- **Language**: Swift 6.x
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum iOS Version**: iOS 16.0+
- **Repository Location**: `~/Documents/Development/iOS/My iOS Projects/WellnessCheck/`
- **Xcode Project Location**: `~/Documents/Development/iOS/MyiOSProjects/WellnessCheck/Code/WellnessCheck/`

### Apple Frameworks in Use
- **HealthKit**: Fall detection, activity monitoring, glucose data
- **UserNotifications**: Local alerts and reminders
- **CoreLocation**: Emergency services context (if needed)
- **BackgroundTasks**: Periodic wellness checks when app is in background

### Backend Services
- **Firebase**:
  - Authentication (user identity management)
  - Firestore (real-time database for user profiles, Care Circle, settings)
  - Cloud Functions (server-side logic for alert processing)
  - Cloud Messaging (push notifications)
- **Twilio**: SMS delivery for emergency alerts and Care Circle invitations
- **GitHub**: Version control and project management

### Testing & Distribution
- **TestFlight**: Beta testing with family/friends
- **XCTest**: Unit and UI testing framework

---

## Repository & Project Structure

### Target Repository Organization
```
WellnessCheck/                           # Repository root
├── claude.md                            # This file - project context for Claude
├── README.md                            # Project overview
├── CHANGELOG.md                         # Version history
├── FEATURES.md                          # Features tracking
├── PROJECT_RULES.md                     # Development standards
├── LICENSE                              # MIT License
│
├── .github/                             # GitHub community files
│   ├── CODE_OF_CONDUCT.md
│   └── CONTRIBUTING.md
│
├── docs/                                # Project documentation
│   ├── MISSION.md                      # Mission statement & values
│   ├── INSTRUCTIONS.md                 # Setup & update guide
│   ├── FUTURE-ROADMAP.md               # v2.0+ planning
│   ├── FEATURES_IMPLEMENTED.md         # Feature documentation
│   ├── PERMISSIONS.md                  # iOS permissions needed
│   ├── PROJECT_SETUP.md                # Project setup guide
│   └── SETUP.md                        # Quick setup reference
│
├── icons/                               # App icons and artwork
│   ├── 1024x1024.png
│   ├── 1024x1024_nobkgrd.png
│   └── AppIcon.png
│
└── Code/                                # All Xcode project files
    └── WellnessCheck/                   # Xcode project directory
        └── WellnessCheck/               # Main app target
            ├── WellnessCheckApp.swift   # App entry point
            ├── AppCoordinator.swift     # Navigation coordinator
            │
            ├── Models/                  # Data structures & model objects
            │   ├── User.swift
            │   ├── EmergencyContact.swift
            │   ├── HealthMetrics.swift
            │   └── AlertEvent.swift
            │
            ├── ViewModels/              # Business logic & state management
            │   ├── DashboardViewModel.swift
            │   ├── SettingsViewModel.swift
            │   ├── ContactsViewModel.swift
            │   └── HealthMonitorViewModel.swift
            │
            ├── Screens/                 # Full-screen SwiftUI views
            │   ├── AppCoordinatorView.swift
            │   ├── SplashScreenView.swift
            │   ├── WelcomeView.swift
            │   ├── ContactsPermissionView.swift
            │   ├── MainStatusView.swift
            │   ├── EmergencySliderView.swift
            │   ├── SettingsView.swift
            │   └── OnboardingView.swift
            │
            ├── Services/                # Background monitoring & alerts
            │   ├── HealthKitService.swift
            │   ├── FirebaseService.swift
            │   ├── NotificationService.swift
            │   ├── TwilioService.swift
            │   └── BackgroundMonitor.swift
            │
            ├── Shared/                  # Reusable UI components
            │   ├── LargeButton.swift
            │   ├── StatusCard.swift
            │   └── AlertHistoryRow.swift
            │
            ├── Utilities/               # Helper functions & extensions
            │   ├── AppColors.swift
            │   ├── Bundle+AppVersion.swift
            │   ├── Color+Hex.swift
            │   ├── Constants.swift
            │   └── Extensions/
            │
            ├── Resources/               # Assets & configuration
            │   ├── GoogleService-Info.plist
            │   ├── Info.plist
            │   └── Localizable.xcstrings
            │
            └── Assets.xcassets/         # Images, colors, icons
                ├── AccentColor.colorset
                ├── AppIcon.appiconset
                └── WellnessCheckLogo.imageset
```

### Folder Purposes

**Repository Root Files:**
- Documentation (README, CHANGELOG, PROJECT_RULES) for developers
- GitHub community files (.github/)
- Documentation folder (docs/) for detailed guides
- Icons folder (icons/) for artwork assets

**Code/WellnessCheck/WellnessCheck/ (Xcode Project):**
- **Models/**: Data structures and model objects (User, Contact, etc.)
- **ViewModels/**: Business logic, state management, connects models to views
- **Screens/**: Full-screen SwiftUI views (main app screens)
- **Services/**: Background tasks, API integrations, system services
- **Shared/**: Reusable UI components used across multiple screens
- **Utilities/**: Helper functions, extensions, app-wide constants
- **Resources/**: Configuration files, localization, assets
- **Assets.xcassets/**: Images, colors, app icons

---

## Code Style Guidelines

### Swift Style Principles
1. **Clarity over cleverness** - Code should be immediately understandable
2. **Consistent naming** - Follow Apple's Swift API Design Guidelines
3. **Comprehensive comments** - Explain WHY, not just WHAT
4. **Error handling** - Never silently fail, always handle or propagate errors

### Naming Conventions
```swift
// Classes, Structs, Enums, Protocols: PascalCase
class HealthMonitorViewModel { }
struct EmergencyContact { }
enum AlertType { }
protocol ContactsDelegate { }

// Variables, functions, parameters: camelCase
var isMonitoringActive: Bool
func sendEmergencyAlert(to contact: EmergencyContact)

// Constants: camelCase (local), PascalCase for static
let maxInactivityMinutes = 120
static let DefaultCheckInterval = 60

// Boolean variables: use "is", "has", "should" prefix
var isUserOnboarded: Bool
var hasActiveSubscription: Bool
var shouldShowAlert: Bool
```

### Comment Style
```swift
// MARK: - Section Headers for organization

// TODO: Feature to implement
// FIXME: Bug that needs fixing
// NOTE: Important implementation detail

/// Documentation comment for public APIs
/// - Parameters:
///   - contact: The emergency contact to notify
///   - event: The alert event that triggered notification
/// - Returns: Success status of SMS delivery
/// - Throws: TwilioError if SMS fails to send
func sendAlert(to contact: EmergencyContact, for event: AlertEvent) throws -> Bool {
    // Implementation details...
}
```

### SwiftUI View Organization
```swift
struct DashboardView: View {
    // MARK: - Properties
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingSettings = false
    
    // MARK: - Body
    var body: some View {
        // Main view code
    }
    
    // MARK: - Subviews
    private var statusSection: some View {
        // Extracted view component
    }
    
    // MARK: - Methods
    private func handleEmergencyButton() {
        // Action handlers
    }
}
```

---

## Security & Privacy Best Practices

### Health Data Privacy (CRITICAL)
1. **HealthKit Permissions**:
   - Only request permissions for data you actually need
   - Clearly explain WHY you need each permission in Info.plist
   - Never store HealthKit data on external servers without explicit consent
   
2. **Data Minimization**:
   - Store only essential data in Firebase
   - Use HealthKit queries on-device when possible
   - Implement automatic data retention limits

3. **Info.plist Privacy Descriptions**:
```xml
<key>NSHealthShareUsageDescription</key>
<string>WellnessCheck monitors your activity and fall detection to keep you safe and alert your Care Circle in emergencies.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>WellnessCheck records wellness check-ins to track your safety status.</string>
```

### Firebase Security Rules
```javascript
// Firestore security rules example
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Care Circle members can read their connected solo dwellers' shared data
    match /users/{userId}/careCircle/{memberId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Secure API Key Storage
- **Never commit API keys to Git**
- Use `.xcconfig` files for configuration (add to `.gitignore`)
- Store sensitive keys in Xcode Build Settings or environment variables
- For Twilio/Firebase keys: Use Firebase Security Rules and Cloud Functions

---

## Apple App Store Guidelines Compliance

### Critical Requirements for WellnessCheck

#### 1. Health & Medical Apps (App Store Review Guideline 5.1.1)
- **Required Disclaimer**: Include clear statement that app is NOT a medical device
- **Emergency Services**: Do NOT claim to replace 911 or emergency services
- **Accuracy Claims**: Be conservative about fall detection accuracy
- **User Safety**: Provide clear instructions and limitations

**Recommended Disclaimer Text**:
```
"WellnessCheck is a wellness monitoring tool designed to provide peace of mind. 
It is NOT a medical device and should NOT replace professional medical care or 
emergency services. In case of emergency, always call 911 immediately."
```

#### 2. Privacy & Data Collection (Guideline 5.1.2)
- **Privacy Policy**: MUST have before launch (required URL in App Store Connect)
- **Data Usage Transparency**: Clearly explain what data is collected and why
- **User Consent**: Explicit opt-in for all data collection
- **Data Deletion**: Provide way for users to delete their account and data

---

## Design Principles for Solo Dwellers

### Visual Design
1. **Color Contrast**: Minimum 7:1 ratio (stricter than WCAG AA)
2. **Font Sizes**: 
   - Body text: 20pt minimum
   - Buttons: 22pt minimum
   - Headers: 28pt+
3. **Touch Targets**: 60x60pt minimum (larger than Apple's 44pt)
4. **Whitespace**: Generous padding between elements

### Interaction Design
1. **Minimize Steps**: One-tap actions where possible
2. **Clear Labels**: "Call 911" not "Emergency"
3. **Confirmation Dialogs**: For destructive actions only
4. **Haptic Feedback**: Confirm actions with physical feedback
5. **Avoid Gestures**: No swipe-to-delete, use explicit buttons

### Example: Senior-Friendly Button
```swift
struct LargeActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
```

---

## Feature Overview

### Safety Monitoring
- Automatic fall detection via HealthKit/Apple Watch
- Inactivity monitoring (customizable 1-4 hour threshold)
- Manual emergency alert slider
- 24/7 background monitoring
- Do Not Disturb schedule support

### Wellness Monitoring
- Depression pattern detection (prolonged inactivity over multiple days)
- Tracks excessive sleep/sedentary behavior
- Early intervention alerts to Care Circle
- Customizable sensitivity (hours per day, consecutive days)

### Health Integration (Planned)
- Glucose data syncing from Libre 3 via Apple Health
- Medication tracking and reminders
- Appointment management

### Alert System
- SMS notifications to Care Circle members
- Countdown timer before sending (30-120 seconds based on urgency)
- User can cancel false alarms
- Priority-based notification system (immediate vs. wellness check)
- Multiple contact support

### Privacy & Control
- Health data stays on device (never uploaded without consent)
- Solo dweller controls all monitoring settings
- Pause monitoring anytime
- Optional Do Not Disturb hours
- Care Circle members can only see what solo dweller permits

---

## Firestore Data Structure

```
users (collection)
├── {userId} (document) - Solo Dweller
    ├── name: String
    ├── phoneNumber: String
    ├── createdAt: Timestamp
    ├── monitoringEnabled: Boolean
    ├── lastCheckIn: Timestamp
    ├── settings: Map
    │   ├── inactivityThresholdHours: Number
    │   ├── dndStartTime: String
    │   ├── dndEndTime: String
    │   └── wellnessConcernEnabled: Boolean
    │
    └── careCircle (subcollection)
        ├── {memberId} (document)
            ├── name: String
            ├── phoneNumber: String
            ├── email: String (optional)
            ├── relationship: String
            ├── inviteStatus: String (pending, accepted)
            ├── invitedAt: Timestamp
            └── acceptedAt: Timestamp

careCircleMembers (collection) - For WellnessWatch users
├── {memberId} (document)
    ├── name: String
    ├── phoneNumber: String
    ├── email: String
    ├── createdAt: Timestamp
    │
    └── connections (subcollection)
        ├── {connectionId} (document)
            ├── soloDwellerId: String (reference to users collection)
            ├── soloDwellerName: String
            ├── connectedAt: Timestamp
            └── notificationsEnabled: Boolean

alerts (collection)
├── {alertId} (document)
    ├── soloDwellerId: String
    ├── type: String (fall, inactivity, wellnessConcern, manual)
    ├── timestamp: Timestamp
    ├── resolved: Boolean
    ├── resolvedAt: Timestamp
    ├── cancelledByUser: Boolean
    └── notifiedMembers: [String] (member IDs)
```

---

## When Working with Claude

### Optimal Prompt Format for Code Requests
```
I need help with [specific feature] for WellnessCheck.

Context:
- Current implementation: [describe what exists]
- What's not working: [specific issue]
- Goal: [what you want to achieve]

Constraints:
- Must follow MVVM architecture
- SwiftUI only
- iOS 16+ minimum
- Senior-friendly UI (large buttons, clear text)

Please provide:
1. Complete, production-ready code
2. Inline comments explaining WHY
3. Error handling included
4. Any HealthKit/Firebase considerations
```

### What to Share with Claude
- **Always helpful**: Current code snippets with errors
- **Project context**: Which file/component you're working on
- **Error messages**: Full Xcode error text
- **Desired outcome**: Show examples or describe behavior

### Developer Preferences
- Detailed comments (explain WHY, not just WHAT)
- Building for seniors (accessibility is crucial)
- Code maintainability over clever shortcuts
- Educational explanations are welcome

### Learning Resources & Best Practices
Charles will frequently share PDFs from Medium and other technical sources covering:
- Modern Swift/SwiftUI patterns and best practices
- iOS development techniques and optimizations
- Architecture patterns and design principles
- Industry standards and cutting-edge approaches

**Claude should:**
- Carefully evaluate each shared article
- Extract applicable patterns and techniques
- Integrate relevant best practices into WellnessCheck codebase
- Flag outdated or conflicting information
- Suggest when to apply learned concepts to current work
- Keep the codebase modern and following current iOS development standards

**Goal:** Apply cutting-edge, production-quality iOS development practices while maintaining code clarity and maintainability

---

## Version History

**v3.0** - December 24, 2025
- Documented two-app architecture (WellnessCheck + WellnessWatch)
- Added terminology section (Solo Dweller, Care Circle, Care Circle Member)
- Documented connection model (phone-based invitations)
- Updated Firestore structure for Care Circle support
- Added WellnessWatch domain (wellnesswatch.dev)
- Expanded feature overview

**v2.0** - December 7, 2025
- Updated project structure to reflect actual organization
- Corrected folder hierarchy (Code/WellnessCheck/WellnessCheck/)
- Added Screens/, Shared/ folders
- Updated Swift version to 6.x

**v1.0** - November 26, 2024
- Initial claude.md creation
- Comprehensive WellnessCheck project context

---

## Additional Notes

- This is a living document - update as project evolves
- Add new patterns/learnings as you discover them
- When stuck, reference this first before asking Claude
- Share this with any future contributors

**Remember**: You're building something that could genuinely help people. Take pride in code quality, prioritize user safety, and don't rush to launch.


---

## Session Log - January 3, 2026

### Major Accomplishments - Onboarding Flow Complete (90%)

**Language Selection Added (Screen 0)**
- First screen users see before onboarding begins
- English 🇺🇸 and Español 🇪🇸 options
- Big, clear buttons with flags and labels
- Bilingual prompt ("Choose Your Language" / "Elige tu idioma")
- Sets foundation for future localization
- San Antonio demographics: ~64% Hispanic/Latino makes Spanish essential

**Complete Care Circle Management System Built**
- **CareCircleMember Model**: firstName, lastName, phone, email, relationship, isPrimary, notificationPreference
- **CareCircleViewModel**: Full CRUD operations (Create, Read, Update, Delete)
  - Add/update/delete members
  - Set primary contact
  - Saves to UserDefaults (Firebase integration later)
- **Three New Screens Created:**
  1. **CareCircleListView**: Shows all members, empty state, two action buttons
  2. **AddCareCircleMemberView**: Full form with validation, all fields
  3. **EditCareCircleMemberView**: Edit relationship, remove member

**iOS Contacts Integration Throughout**
- **ContactPicker Component**: Reusable contact selection with CNContactPickerViewController
- **ProfileSetupView**: "Use My Contact Card" button auto-fills user info
- **AddCareCircleMemberView**: "Choose from Contacts" button auto-fills member info
- **CareCircleListView**: Two-button approach:
  - "Add from Contacts" (primary) - instant add with relationship prompt
  - "Add Manually" (secondary) - full form for manual entry
- Requires NSContactsUsageDescription in Info.plist

**Onboarding Flow Refinements**
- **Progress dots removed**: Less intimidating (was showing 9+ screens upfront)
- **Permission screens split**: 
  - Screen 5A: Why Notifications → Direct iOS permission request
  - Screen 5B: Why Health Data → Direct HealthKit permission request
  - Removed redundant PermissionsView summary screen
- **Profile setup enhanced** (Screen 4):
  - Added surname field (required)
  - Added email field (optional)
  - Red asterisks (*) mark required fields
  - Button changed: "Continue" → "Add Me" (more personal)
  - Validation alert when incomplete
- **HealthKit permission working**: Fixed by adding proper Info.plist entries and improved error handling
- **"Good to meet you, [NAME]!" centered** on greeting screen
- **Care Circle flow streamlined**: Users stay in CareCircleListView after adding members (no bounce back to intro)

**Logo/Icon Consistency**
- Both Language Selection and Welcome screens now check for "AppLogo" asset first
- Falls back to appropriate placeholder if AppLogo doesn't exist
- Consistent branding across first two screens

### Technical Files Created

**New Components:**
1. `/Screens/LanguageSelectionView.swift` - Language choice screen
2. `/Models/CareCircleMember.swift` - Member data model
3. `/ViewModels/CareCircleViewModel.swift` - Care Circle state management
4. `/Screens/AddCareCircleMemberView.swift` - Add member form
5. `/Screens/CareCircleListView.swift` - Member list with actions
6. `/Screens/EditCareCircleMemberView.swift` - Edit/delete member
7. `/Shared/ContactPicker.swift` - Reusable contact picker
8. `/Shared/LargeOutlineButton.swift` - Secondary button style (already existed in LargeButton.swift)

**Files Modified:**
- `OnboardingViewModel.swift` - Added languageSelection step, selectedLanguage property, userSurname, userEmail
- `OnboardingContainerView.swift` - Wired up language screen, removed progress indicator
- `ProfileSetupView.swift` - Added surname/email fields, contact picker, validation
- `WhyNotificationsView.swift` - Centered greeting text, added permission request
- `WhyHealthDataView.swift` - Added permission request with proper HealthKit types
- `CareCircleIntroView.swift` - Opens list view modal, better flow
- `WelcomeView.swift` - Checks for AppLogo asset
- `Constants.swift` - Added userSurnameKey, userEmailKey

**Files Deleted:**
- `PermissionsView.swift` - Redundant after splitting permissions into two direct-request screens
- Duplicate `LargeOutlineButton.swift` - Was already part of LargeButton.swift

### Current Onboarding Flow (9 Screens)

0. **Language Selection** ✅ - English or Spanish
1. **Welcome** ✅ - "Living alone doesn't mean having to be alone"
2. **How It Works** ✅ - Explain monitoring, Care Circle, alerts
3. **Privacy Matters** ✅ - Data stays on device, user control
4. **Profile Setup** ✅ - Name, surname, phone, email + contact picker
5. **Why Notifications** ✅ - Explains + requests iOS notification permission
6. **Why Health Data** ✅ - Explains + requests HealthKit permission  
7. **Care Circle Intro → List** ✅ - Manage members with contacts integration
8. **Customize Monitoring** 🚧 - Placeholder "Coming Soon"
9. **Complete** ❌ - Not yet built

### Design Decisions This Session

**On Language Support:**
- Start with English + Spanish (covers ~91% of Americans)
- Spanish critical for San Antonio market (64% Hispanic/Latino)
- Chinese 3rd most spoken (~3.5M speakers) but lower priority for v1.0
- Full localization effort comes after v1.0 launch

**On Contacts Integration:**
- "Choose from Contacts" is PRIMARY action (blue button)
- "Add Manually" is SECONDARY (outline button)
- Contact picker auto-fills everything, sets sensible defaults
- Default relationship: "Friend" (can edit after)
- First member auto-becomes primary contact

**On Care Circle Flow:**
- Users STAY in list after adding member (no bounce back)
- Can add multiple members in one session
- Tap member card to edit relationship/details
- "Continue" button when ready to proceed
- "I'll Do This Later" if no members added

**On Progress Indicators:**
- Removed progress dots - too intimidating to see "9 screens left"
- Focus on current screen, not total journey
- Seniors prefer taking it one step at a time
- May add "Hang in there, we're almost done" near end

### Known Issues & Pending Work

**Immediate Fixes Needed:**
- ✅ ~~HealthKit permission dialog not appearing~~ - FIXED
- ✅ ~~Can't edit Care Circle member relationship~~ - FIXED with EditCareCircleMemberView
- Info.plist entries needed:
  - NSContactsUsageDescription ✅
  - NSHealthShareUsageDescription ✅
  - NSHealthUpdateUsageDescription ✅

**Remaining Onboarding Screens:**
- Screen 8: Customize Monitoring (build or skip?)
- Screen 9: Completion screen

**Firebase Integration:**
- Currently using UserDefaults for all data
- Need to migrate to Firebase:
  - User profile (name, surname, phone, email, language)
  - Care Circle members
  - Preferences and settings

**Main App Screens (Post-Onboarding):**
- Home tab: Status + "I'm Fine" / "Pause Monitoring" / "Test Alert" buttons
- Medications tab
- Appointments tab
- Care Circle tab
- Settings tab

**Alert Context System (Future):**
- When user sends alert, provide context:
  - "I've Fallen"
  - "Chest Pain / Heart Problem"
  - "Can't Get Up"
  - "Feeling Dizzy/Weak"
  - "Low Blood Sugar"
  - "I'm Lost/Disoriented"
  - "Need Help (General)"
  - "Emergency - Call 911"
- Decide: Manual alert screen vs automatic + manual hybrid

### Development Philosophy Reinforced

**Quality Over Speed:**
- Willing to extend timeline to 2027 for proper implementation
- "We're in no hurry" applies to development too
- Pack all features into v1.0 rather than phased releases
- Both WellnessCheck + WellnessWatch launch together

**Senior-First Design:**
- Large text (20pt+ body, 22pt+ buttons)
- Big touch targets (60x60pt minimum)
- Clear, conversational language (not clinical jargon)
- "I Like That" vs "Acknowledge" - speak human
- Contact picker reduces typing burden

**Honest Messaging:**
- No marketing fluff - tell seniors what's happening
- "We're looking for changes in YOUR patterns" (not absolute values)
- Acknowledge concerns: "Are you okay?" not "Health monitoring active"
- Transparency builds trust

### Session Statistics

**Files Added:** 8 new Swift files
**Files Modified:** 9 existing files  
**Files Deleted:** 2 redundant files
**Lines of Code:** ~2,000+ new lines
**Permissions Added:** 3 Info.plist entries
**Features Completed:** Language selection, full Care Circle CRUD, contacts integration
**Screens Completed:** 7 of 9 onboarding screens functional

**Current Version:** v0.2.0 (ready for v0.3.0 bump after onboarding complete)
**Next Session Focus:** Complete onboarding (screens 8-9), then main app

---

**Document Updated:** January 3, 2026, 9:57 PM

---

## Session Log - January 6, 2026

### Major Accomplishments - Care Circle Invitation System & UX Improvements

**ConfirmCareCircleMemberView Created** - Missing Link in Care Circle Flow
- Shows selected contact's complete information before adding
- Relationship picker with 10 options (Daughter, Son, Spouse, Partner, Sister, Brother, Friend, Neighbor, Caregiver, Other)
- Default to "Friend" but easily changeable before confirming
- Displays name, phone number, email (if available)
- Validation prevents adding members without phone numbers
- "Add to Care Circle" button triggers invitation flow

**TwilioService.swift Created** - SMS Invitation System with Test Mode
- Complete SMS invitation infrastructure ready for Twilio integration
- **Test Mode Active** - No Twilio account required yet, no real SMS sent
- `isTestMode = true` flag - flip to `false` when WellnessWatch is ready
- Preview alerts show exact message that would be sent
- Console logging with detailed invitation information
- Invitation message template personalized with user's name
- Emergency alert template for future use (fall, inactivity, manual, wellness)
- Ready for production Twilio API integration with minimal changes

**CareCircleMember Model Enhanced** - Invitation Status Tracking
- Added `invitationStatus` enum: pending, sent, accepted, declined
- Added `invitedAt: Date?` - timestamp when invitation sent
- Added `acceptedAt: Date?` - timestamp when member accepts via WellnessWatch
- Full status lifecycle tracking from invitation to connection
- Backward compatible with existing UserDefaults storage

**CareCircleViewModel Extended** - Status Management
- New `updateInvitationStatus()` method
- Automatically sets timestamps when status changes
- `invitedAt` set when status becomes `.sent`
- `acceptedAt` set when status becomes `.accepted`
- Persists status updates to UserDefaults (Firebase later)

**CareCircleListView Enhanced** - Visual Status Indicators
- Color-coded invitation status badges:
  - 🟠 **Pending** (orange) - Added but not invited yet
  - 🔵 **Invited** (blue) - SMS sent, awaiting download
  - 🟢 **Connected** (green) - Downloaded WellnessWatch and connected
  - 🔴 **Declined** (red) - Declined the invitation
- Badges show icon + text (e.g., "📧 Invited")
- Positioned next to phone number in member rows
- Semi-transparent background matching badge color

**Logo Consistency Fix**
- LanguageSelectionView now uses same logo logic as WelcomeView
- Checks for "AppLogo" asset first
- Falls back to "WelcomeIcon" if AppLogo doesn't exist
- Consistent branding across Screen 0 and Screen 1

### Complete Invitation Flow (Test Mode)

**User Experience:**
1. Tap "Add from Contacts" in Care Circle list
2. Select contact (e.g., Sharon) from iOS Contacts
3. **ConfirmCareCircleMemberView appears**:
   - Shows Sharon's full name, phone, email
   - Relationship picker (change from "Friend" to "Sister")
   - "Add to Care Circle" button
4. Tap "Add to Care Circle"
5. Member added to Care Circle
6. **TwilioService sends invitation** (test mode):
   - Alert appears: "📧 Invitation Preview (Test Mode)"
   - Shows exact SMS message that would be sent
   - Displays recipient name and phone
   - Notes: "✓ Not actually sent - Test Mode Active"
7. Console logs full invitation details
8. Status updated to "Invitation Sent"
9. Dismiss alert → back to Care Circle list
10. Sharon appears with 🔵 "Invited" badge

**What Users See in Test Mode Alert:**
```
📧 Invitation Preview (Test Mode)

To: Sharon Smith
Phone: +1 (555) 123-4567

Message:
Hi Sharon! Charles has added you to their
WellnessCheck Care Circle.

Download WellnessWatch to stay connected and
receive alerts if they need help:

https://wellnesswatch.dev/download

You'll be notified if Charles has a fall,
prolonged inactivity, or manually requests
assistance.

- WellnessCheck Team

✓ Not actually sent - Test Mode Active
```

**What Developers See in Console:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔔 CARE CIRCLE INVITATION (TEST MODE)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
To: +1 (555) 123-4567
Name: Sharon Smith
Relationship: Sister
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Message:
[Full invitation text]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Logged only - NO SMS SENT (Test Mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Technical Files Created/Modified

**New Files:**
1. `/Screens/ConfirmCareCircleMemberView.swift` - Contact confirmation with relationship picker
2. `/Services/TwilioService.swift` - SMS invitation system with test mode

**Modified Files:**
1. `CareCircleMember.swift` - Added invitation status tracking fields
2. `CareCircleListView.swift` - Added status badges, updated contact picker flow
3. `CareCircleViewModel.swift` - Added status update methods
4. `LanguageSelectionView.swift` - Logo consistency fix

**Total Changes:**
- 6 files changed
- 578 insertions(+), 25 deletions(-)
- ~600 new lines of production-ready code

### Design Decisions This Session

**On Invitation Flow:**
- User MUST see and confirm contact info before adding
- Relationship choice MUST happen before adding (not after)
- Immediate feedback via preview alert (test mode)
- Status badges provide at-a-glance understanding
- Color coding: Orange (waiting) → Blue (invited) → Green (connected)

**On Test Mode vs Production:**
- Develop complete flow now, deploy later
- Test mode prevents accidental SMS spam during development
- Preview alerts let you verify message content
- Console logs help debug invitation issues
- Single flag flip (`isTestMode = false`) enables production
- No Twilio account needed until WellnessWatch is ready

**On SMS Message Content:**
- Personal greeting with Care Circle member's first name
- Clear explanation of what WellnessCheck is
- Direct link to download WellnessWatch
- Specific examples of alert types (fall, inactivity, manual)
- Professional sign-off ("WellnessCheck Team")
- Friendly but not overly casual tone

**On Status Lifecycle:**
- **Pending** = Added to Care Circle, invitation not sent yet (shouldn't happen in normal flow)
- **Sent** = SMS delivered (or would be in production), awaiting action
- **Accepted** = Downloaded WellnessWatch and completed connection (future)
- **Declined** = Explicitly declined invitation (future feature)

### Known Issues & Next Steps

**Immediate (Add to Xcode):**
- ✅ ConfirmCareCircleMemberView.swift - Created, needs to be added to Xcode project
- ✅ TwilioService.swift - Created, needs to be added to Xcode project

**Testing Needed:**
- Test complete flow: Add contact → Confirm → See invitation preview
- Verify status badges display correctly
- Check console logs for proper formatting
- Test with contact that has no phone number (should prevent adding)

**Before Going to Production:**
1. Set up Twilio account (not urgent - wait for WellnessWatch)
2. Implement actual Twilio API integration in `sendViaTwilio()` method
3. Add Twilio credentials securely (not in code)
4. Test with real phone numbers (willing beta testers only)
5. Change `isTestMode = false` in TwilioService.swift

**Onboarding Still Needs:**
- Screen 8: Customize Monitoring Settings (or skip and put in main app Settings)
- Screen 9: Completion/Celebration screen
- Full flow test from Language Selection → Onboarding complete

**Main App (Post-Onboarding):**
- Tab bar structure (5 tabs: Home, Medications, Appointments, Care Circle, Settings)
- Home tab with status indicator
- "I'm Fine" check-in button
- "Pause Monitoring" toggle
- "Test Alert" button (sends test SMS in production)
- Care Circle tab (reuse CareCircleListView)

**WellnessWatch App (Future):**
- Needs to exist before enabling production SMS
- Invitation link must work (download from App Store)
- Connection flow from WellnessWatch side
- Ability to accept/decline invitations
- Update WellnessCheck member status when accepted

### Session Statistics

**Duration:** ~2 hours
**Files Created:** 2 new files
**Files Modified:** 4 existing files
**Lines Added:** ~600 lines
**Features Completed:**
- Complete invitation system with test mode
- Contact confirmation flow
- Status tracking and visualization
- Logo consistency across onboarding

**Commits:**
- Commit `7917550` - "Care Circle invitation system with test mode & UI improvements"
- Successfully pushed to GitHub

**Current Version:** v0.2.0 (ready for v0.3.0 after onboarding complete)

### Key Insights From This Session

**On User Feedback:**
- Charles immediately spotted the missing confirmation step
- "I saw no confirmation of her information" = critical UX gap
- "I saw no way to designate that she is my sister" = missing relationship choice
- Building backwards from user pain points creates better flows
- Senior users need explicit confirmation before actions

**On Test Mode Benefits:**
- Develop and iterate without costs or consequences
- Preview exact messages before sending to real people
- Debug invitation logic without spamming contacts
- Show investors/stakeholders the complete experience
- Easy switch to production when ready (one flag)

**On Status Visualization:**
- Color-coding reduces cognitive load
- Icons reinforce meaning (📧 = invited, ✅ = connected)
- Status badges answer "what's happening?" at a glance
- Seniors don't need to memorize what "pending" means

**On Development Velocity:**
- Building complete features (not MVPs) takes longer upfront
- But avoids technical debt and rework later
- Test mode lets us validate UX without production dependencies
- Clean abstractions (TwilioService) make production switch trivial

---

**Document Updated:** January 6, 2026, 8:30 PM

---

## Session Log - December 31, 2024

### Major Development Milestones

**SmartMonitoringService.swift Created** - The Heart of WellnessCheck
- 500+ line intelligent monitoring system that analyzes multiple health signals
- Learns user baseline patterns over 14 days (stand hours, steps, sleep, activity)
- Context-aware decision making (time of day, day of week, Do Not Disturb)
- Graduated escalation: Check with user first → Wait 15 min → Alert Care Circle
- Multi-signal analysis prevents false alarms while catching real emergencies
- Detects fall events, prolonged inactivity, wellness concerns
- This file represents the core intelligence that separates WellnessCheck from basic emergency alert apps

**Onboarding Flow Redesign** - Philosophy Shift
- Decided to completely rework onboarding with patience and clarity as guiding principles
- "We're in no hurry" - take time to explain, build trust, let seniors absorb information
- Focus on Connection message: "Seniors are afraid something will happen and no one will know"
- One screen at a time approach, no rushing to minimize friction
- Targeting seniors directly (stopped being "coy" about it)

**Welcome Screen v2.0** - Connection-Focused First Impression
- New messaging: "Stay connected to the people who care about you. If something happens, they'll know right away."
- Secondary: "WellnessCheck gives you independence and gives them peace of mind."
- Care Circle illustration commissioned (AI-generated via ChatGPT/DALL-E)
  - Senior in center, surrounded by daughter (with phone), son (hand on heart), neighbor, friend
  - Light blue (#C8E6F5) and navy (#1A3A52) brand colors
  - Warm, human, approachable style - NOT clinical
  - SVG version arriving morning of January 1st
- "Show Me How This Works" button (inviting, not demanding)
- "I'm helping someone set this up" link for caregivers
- Improved spacing (60pt between sections)
- Light blue background to match icon
- Text wrapping fixed for tagline

**Git Workflow Automation**
- Created commit.sh script for one-command git commits
- Version v0.2.0 committed and pushed
- Demonstrated file system access capabilities

### Technical Additions

**Files Created:**
1. `/Services/SmartMonitoringService.swift` - Intelligent health monitoring engine
2. `/Assets.xcassets/AccentColor.colorset/` - Brand accent color (navy #1A3A52)
3. Updated `/Screens/WelcomeView.swift` - Complete redesign

**HealthKit Permissions Discussion:**
- Identified need for NSHealthShareUsageDescription and NSHealthUpdateUsageDescription in Info.plist
- Discussion about detecting Apple Watch, CGM devices (Libre 3, Dexcom) before requesting permissions
- Decided to ask users directly rather than trying to detect (builds trust, avoids complexity)

### Design Decisions

**Care Circle Illustration Requirements:**
- Bird's eye view showing senior surrounded by 3-4 caring people
- Senior: calm, confident, dignified (not frail)
- Daughter with phone (will receive alerts)
- Son with protective gesture
- Neighbor/friend (community support)
- Soft connecting lines (support, not surveillance)
- Diverse representation
- Modern flat illustration style (Apple Health/Headspace aesthetic)
- Warm and reassuring emotional tone

**Onboarding Screens Planned** (not yet designed):
1. Welcome Screen ✅ (complete)
2. How It Works (TBD)
3. Your Privacy Matters (TBD)
4. About Care Circle (TBD)
5. Health Permissions Request (exists, needs integration into flow)
6. Set Up Your Care Circle (TBD)
7. Customize Your Monitoring (TBD)
8. You're All Set! (TBD)

### Key Insights & Philosophy

**On Smart Monitoring:**
- Multiple signals are better than one
- Learn what's normal for THIS user, not generic averages
- Context matters: Sunday afternoon football is different than Tuesday morning inactivity
- Escalate gradually to avoid false alarms while catching real emergencies
- The difference between "another useless app that cried wolf" and "the app that saved my dad's life"

**On Onboarding:**
- Quality and trust-building over speed
- Seniors deserve patience and clear explanations
- "Almost no time limit" if it means building genuine understanding
- Each screen should GIVE value (information, control) not TAKE (time, attention)
- Connection focus resonates: fear of "something happens and no one will know"

**On Development Approach:**
- Pack as much into Day One (v1.0) as possible
- No MVP - full-featured releases only
- Willing to extend timeline to 2027 for quality
- Both apps (WellnessCheck + WellnessWatch) launch simultaneously
- Android expansion only after successful iOS launch

### What's Next (Session Handoff for January 1st)

**Immediate Priorities:**
1. Add Care Circle SVG illustration to Assets.xcassets when received
2. Test complete Welcome Screen with illustration
3. Design "How It Works" screen (Screen 2 in onboarding)
4. Continue onboarding flow design one screen at a time

**Pending Technical Work:**
- Connect SmartMonitoringService to actual HealthKit data
- Build notification system that SmartMonitoringService calls
- Integrate Firebase for baseline storage
- Connect PermissionsRequestView to onboarding flow

**Current Version:** v0.2.0
**Current Focus:** Welcome Screen finalization, then continue onboarding design

---

**Document Updated:** December 31, 2024, 1:30 AM

---

## Session Log - January 8, 2026

### Major Accomplishments - Website & AI FAQ Bot

**Complete Marketing Website Infrastructure Built**

Tonight we built the entire public-facing web presence for WellnessCheck on wellnesscheck.dev:

**Coming Soon Page (front-page.php)**
- Two-tab signup system: "I'm Interested" and "I Want to Help Build This"
- Interested form: Name, Email, Role (Solo dweller/Care Circle/Caregiver/Curious), How Heard
- Contributor form: Name, Email, GitHub (optional), Skills checkboxes, Message
- Skills options: SwiftUI, Firebase, Android/Kotlin, UI/UX Design, QA/Testing, Marketing, Spanish Translation, Technical Writing
- Link to FAQ page at bottom
- All forms submit to Google Sheets via Apps Script

**Google Sheets Integration**
- Spreadsheet ID: `1hmKR1cz61gS4-QJCzLKqiyqBDDdR8p0Qm5raukmiMTY`
- Three tabs: Interested, Contributors, FAQ
- **Interested columns**: Timestamp, Name, Email, Role, How Heard, Status
- **Contributors columns**: Timestamp, Name, Email, GitHub, Skills, Message, Status
- **FAQ columns**: Timestamp, First Name, Question, AI Response, Status

**Google Apps Script - Form Handler + AI FAQ Bot**
- Handles all form submissions (interested, contributor, faq, aiFaq)
- Email confirmations to users (via Gmail)
- Admin notifications to mailinglist@wellnesscheck.dev
- Unsubscribe functionality with status update
- **AI FAQ Bot powered by Claude API (Haiku model)**
- Questions Claude can't confidently answer flagged as "NEEDS_HUMAN_REVIEW"
- Flagged questions saved to Google Sheet for human review

**FAQ System Using WordPress Custom Post Type**
- Using theme's built-in FAQ custom post type (not custom page template)
- FAQs managed via WordPress Admin → FAQs → Add New
- Title = Question, Content = Answer
- archive-faq.php template displays FAQs in accordion
- 7 starter FAQs created via WP-CLI

**AI Chat Widget (Claude-Powered)**
- **Floating chat widget** on all pages (bottom right corner)
- **Embedded chat** on /faq/ page
- Real-time responses from Claude Haiku
- Typing indicator while waiting
- Fallback: if API fails, question saved for human review
- CORS issues fixed for Google Apps Script compatibility

**Theme Customizer Fix**
- Header Colors settings weren't affecting navigation
- Added `!important` to customizer CSS output
- Navigation colors now controllable via Appearance → Customize → Header Colors

### Technical Infrastructure

**SSH Access**
- New RSA key pair generated: `~/.ssh/iMac_rsa`
- Web host: charlesstricklin.com
- Username: charle24
- WordPress path: `~/domains/wellnesscheck.dev/public_html/cms/`
- Theme path: `.../wp-content/themes/stricklin-development/`

**Key URLs**
- Site: https://wellnesscheck.dev
- FAQ: https://wellnesscheck.dev/faq/
- Apps Script: `https://script.google.com/macros/s/AKfycbxVztfuDDNvUSc7ooCTQiYx4JETHb0uMbpFK9ub1ilOhUKPHqv89UDtcQNkVyS3YwA/exec`

**Email Configuration**
- FROM_NAME: WellnessCheck
- ADMIN_EMAIL: mailinglist@wellnesscheck.dev
- Confirmation emails sent via GmailApp (from default Gmail account)
- Calendar link for contributors: https://calendar.app.google/2JYVsCdNnXHurFTRA

**Anthropic API**
- Using Claude 3 Haiku for FAQ bot (fast, cheap)
- API key stored in Google Apps Script Properties (secure)
- Cost estimate: fractions of a penny per question

### Files Created/Modified

**WordPress Theme Files:**
- `front-page.php` - Coming Soon page with signup forms
- `archive-faq.php` - FAQ archive with AI chat
- `footer.php` - Added floating chat widget
- `inc/customizer.php` - Fixed header color CSS output

**Google Apps Script:**
- Complete rewrite with AI FAQ integration
- ~300 lines of production code
- Stored at: `/Users/charles/Downloads/faq-bot-script.js`

### AI FAQ Knowledge Base

The FAQ bot's knowledge is stored in the `FAQ_KNOWLEDGE` variable in Apps Script. Current knowledge includes:

- App description and mission
- Two-app model (WellnessCheck + WellnessWatch)
- Platform roadmap: iPhone first → iPad (WellnessWatch) → Android
- Target users (seniors, solo dwellers, caregivers)
- Key features (vague - no competitive details)
- Privacy stance (no location tracking, no data selling)
- Response guidelines (concise, warm, professional)

**To update knowledge:** Edit `FAQ_KNOWLEDGE` in Apps Script → Save → Deploy → Manage deployments → Edit → New version → Deploy

### Design Decisions

**On FAQ System:**
- Used theme's built-in FAQ custom post type instead of custom page template
- More maintainable - add/edit FAQs via WordPress admin
- Archive page automatically updates

**On AI Chat:**
- Claude Haiku chosen for speed and cost-efficiency
- No name required for chat (reduces friction)
- Logs default to "Website Visitor" for privacy
- Questions Claude can't answer get flagged for human review

**On Under-18 Users:**
- WellnessCheck is for adults (18+)
- Added to Terms of Service consideration
- FAQ bot is low-risk (just answering product questions)
- Full app should require age confirmation at signup

### Session Statistics

**Duration:** ~5 hours
**Files Created:** 4+ new files
**Files Modified:** 3+ existing files
**Features Completed:**
- Complete Coming Soon page with forms
- Google Sheets integration with 3 tabs
- Email confirmation system
- FAQ system with 7 starter questions
- AI-powered FAQ chat bot
- Floating chat widget site-wide
- Customizer color fix

### Synopsis - What We Built Tonight

We transformed wellnesscheck.dev from a placeholder into a fully functional marketing site with:

1. **Lead capture** - Two signup forms feeding into Google Sheets
2. **Email automation** - Confirmation emails and admin notifications
3. **FAQ system** - Managed via WordPress, displayed in accordion
4. **AI support** - Claude-powered chat answers visitor questions 24/7
5. **Smart escalation** - Questions the AI can't answer get saved for human review

The AI FAQ bot is particularly notable - it's a production-ready customer support system that cost $5 to set up and will cost pennies to operate. It knows about WellnessCheck, can answer common questions, and automatically escalates anything it's unsure about.

All of this runs on free/cheap infrastructure: WordPress theme, Google Sheets, Google Apps Script, and Anthropic API.

---

**Document Updated:** January 8, 2026, 11:45 PM
