# WellnessCheck - Project Context for Claude

**Last Updated**: December 24, 2025  
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
- **Xcode Project Location**: `~/Documents/Development/iOS/My iOS Projects/WellnessCheck/Code/WellnessCheck/`

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
