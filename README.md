# WellnessCheck

**Living alone doesn't mean having to be alone.**

A safety monitoring iOS app for solo dwellers and their Care Circle.

---

## About

WellnessCheck monitors for falls, inactivity, and wellness concerns, automatically alerting designated Care Circle members when something's wrong.

**Current Version:** v0.2.0
**Platform:** iOS 16.0+ / Swift 6.x / SwiftUI
**Architecture:** MVVM
**License:** AGPL-3.0
**Developer:** Charles Stricklin, Stricklin Development, LLC

---

## v1.0 Features

- Fall detection
- Step count monitoring
- Phone movement (proof-of-life)
- Flights of stairs climbed
- Battery level (negative space context)
- Home awareness (user-defined)
- Learned pattern deviation
- Negative space detection
- Wellness concern detection (pattern clusters)
- Care Circle management with SMS invitations
- Do Not Disturb scheduling

**Future:** WellnessWatch (Care Circle companion app), Apple Watch, geofencing, glucose monitoring, medication tracking

---

## Current Status

### Completed
- Onboarding flow (7 screens): Language selection, Welcome, How It Works, Privacy, Profile, Permissions (split), Care Circle management
- Care Circle CRUD with iOS Contacts integration
- SMS invitation system (test mode)
- Brand identity and senior-friendly UI (60pt touch targets, 7:1 contrast)

### In Progress
- Screen 8: Customize Monitoring (or skip to Settings)
- Screen 9: Completion
- Main app tab structure

### Next
- Firebase integration
- Background monitoring service
- Home tab with status indicator

---

## Developer Setup

### 1. Clone and Open
```bash
git clone https://github.com/charles-stricklin/WellnessCheck.git
cd WellnessCheck/Code/WellnessCheck
open WellnessCheck.xcodeproj
```

### 2. Add HealthKit Capability
1. Select the WellnessCheck target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → Add **HealthKit**
4. Check "Background Delivery" for continuous monitoring

### 3. Add Contacts Capability
1. Same process → Add **Contacts**

### 4. Configure Info.plist
Add these privacy descriptions (via Info tab or directly in Info.plist):

| Key | Value |
|-----|-------|
| NSHealthShareUsageDescription | WellnessCheck monitors your activity and fall detection to keep you safe and alert your Care Circle in emergencies. |
| NSHealthUpdateUsageDescription | WellnessCheck records wellness check-ins to track your safety status. |
| NSContactsUsageDescription | WellnessCheck uses your contacts to easily add Care Circle members. |

### 5. Build and Run
- Select iOS 16.0+ simulator or device
- Cmd+R

### Reset Onboarding (Testing)
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
│       ├── Services/            # HealthKit, Twilio, Firebase
│       ├── Shared/              # Reusable components
│       └── Utilities/           # Constants, extensions
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

- **Frontend:** SwiftUI, HealthKit, Contacts
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, Cloud Messaging)
- **SMS:** Twilio
- **Languages:** English, Spanish (v1.0)

---

## License

GNU Affero General Public License v3.0 — See [LICENSE](LICENSE)

---

**Note:** This is a safety-critical application. Quality and user safety are prioritized over speed.
