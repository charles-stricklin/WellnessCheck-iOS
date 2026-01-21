# WellnessCheck

**Living alone doesn't mean having to be alone.**

A safety monitoring iOS app for solo dwellers and their Care Circle.

---

## About

WellnessCheck monitors for falls, inactivity, and wellness concerns, automatically alerting designated Care Circle members when something's wrong.

**Current Version:** v0.7.0
**Platform:** iOS 16.0+ / watchOS 9.0+ / Swift 6.x / SwiftUI
**Architecture:** MVVM
**License:** AGPL-3.0
**Developer:** Charles Stricklin, Stricklin Development, LLC

---

## v1.0 Features

### Implemented ✓
- Fall detection (CoreMotion accelerometer)
- Apple Watch fall detection companion (CMFallDetectionManager, 24/7 monitoring)
- Step count monitoring (HealthKit)
- Phone movement proof-of-life (CoreMotion)
- Flights of stairs climbed (HealthKit)
- Battery level tracking (dead battery detection)
- Home awareness (user-defined)
- Learned pattern deviation (14-day learning period)
- Negative space detection (inactivity monitoring)
- Do Not Disturb / Quiet Hours scheduling
- Silence threshold slider (2-12 hours configurable)
- Care Circle management with SMS invitations (Twilio)
- Firebase Auth (email/password + Sign in with Apple)
- Firestore sync for user data and Care Circle
- Full onboarding flow (11 screens)
- Main dashboard with Activity, Care Circle, and Settings tabs
- Spanish localization

### In Progress
- TestFlight preparation
- Device testing

### Backlog
- Wellness concern detection (pattern clusters)
- Push notification system

**Future:** WellnessWatch (Care Circle companion app), geofencing, glucose monitoring, medication tracking

---

## Current Status

The app is feature-complete for v1.0 core functionality:

- **Onboarding:** 11 screens covering language selection, permissions, profile setup, home location, Care Circle management, and monitoring customization
- **Dashboard:** Full Home, Activity, Care Circle, and Settings tabs
- **Fall Detection:** CoreMotion-based with 60-second countdown alert
- **Inactivity Monitoring:** Configurable silence threshold with quiet hours support
- **Pattern Learning:** 14-day learning period to reduce false positives
- **SMS Alerts:** Twilio integration via Firebase Cloud Functions (A2P 10DLC approved)

---

## Developer Setup

### 1. Clone and Open
```bash
git clone https://github.com/charles-stricklin/WellnessCheck.git
cd WellnessCheck/Code/WellnessCheck
open WellnessCheck.xcodeproj
```

### 2. Add Capabilities
1. Select the WellnessCheck target
2. Go to **Signing & Capabilities**
3. Add these capabilities:
   - **HealthKit** (with "Background Delivery" checked)
   - **Contacts**

### 3. Configure Info.plist
Add these privacy descriptions (via Info tab or directly in Info.plist):

| Key | Value |
|-----|-------|
| NSHealthShareUsageDescription | WellnessCheck monitors your activity and fall detection to keep you safe and alert your Care Circle in emergencies. |
| NSHealthUpdateUsageDescription | WellnessCheck records wellness check-ins to track your safety status. |
| NSContactsUsageDescription | WellnessCheck uses your contacts to easily add Care Circle members. |
| NSLocationWhenInUseUsageDescription | WellnessCheck uses your location to set your home address and detect when you're away, which helps us better interpret inactivity patterns. |
| NSMotionUsageDescription | WellnessCheck uses motion sensors to detect falls and phone pickups as proof-of-life signals. |

### 4. Firebase Setup
- Add `GoogleService-Info.plist` to the project (not in repo for security)
- Enable Email/Password and Apple Sign-In in Firebase Console
- Deploy Cloud Functions from `functions/` directory

### 5. Build and Run
- Select iOS 16.0+ simulator or device
- Cmd+R

### Reset Onboarding (Testing)
In Settings tab, use "Reset Onboarding" button (DEBUG builds only), or:
```swift
UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
```

---

## Project Structure

```
WellnessCheck/
├── Code/WellnessCheck/          # Xcode project
│   └── WellnessCheck/
│       ├── Models/              # Data models
│       ├── ViewModels/          # MVVM view models
│       ├── Screens/             # SwiftUI views
│       ├── Services/            # Core services
│       │   ├── AuthService.swift
│       │   ├── BatteryService.swift
│       │   ├── CloudFunctionsService.swift
│       │   ├── FallDetectionService.swift
│       │   ├── FirestoreService.swift
│       │   ├── HealthKitService.swift
│       │   ├── LocationService.swift
│       │   ├── NegativeSpaceService.swift
│       │   ├── PatternLearningService.swift
│       │   └── PhoneActivityService.swift
│       ├── Shared/              # Reusable components
│       └── Utilities/           # Constants, extensions
├── functions/                   # Firebase Cloud Functions
├── CLAUDE.md                    # Project context for AI assistance
├── SESSION_LOG.md               # Development history
├── TODO.md                      # Task tracking
└── LICENSE                      # AGPL-3.0
```

---

## Design Principles

- **Touch targets:** 60x60pt minimum
- **Typography:** 20pt body, 22pt buttons, 28pt+ headers
- **Contrast:** 7:1 minimum
- **Navigation:** Explicit buttons only, no swipe gestures
- **Privacy:** Minimal data collection, clear disclaimers

---

## Tech Stack

- **Frontend:** SwiftUI, HealthKit, CoreMotion, Contacts, CoreLocation
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, Cloud Messaging)
- **SMS:** Twilio (A2P 10DLC registered)
- **Languages:** English, Spanish (v1.0)

---

## License

GNU Affero General Public License v3.0 — See [LICENSE](LICENSE)

---

**Note:** This is a safety-critical application. Quality and user safety are prioritized over speed.
