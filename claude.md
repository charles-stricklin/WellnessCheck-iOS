**On every session start:**
1. Read TODO.md and SESSION_LOG.md
2. Tell Charles what was last worked on and what's next
3. Ask for his direction

**On every session end:**
1. Update TODO.md and SESSION_LOG.md
2. Update version numbers and dates as needed
3. Give Charles a synopsis of what was worked on and what's next

---

# WellnessCheck - Project Context

**Last Updated**: January 20, 2026
**Current Version**: v0.7.0
**Developer**: Charles W. Stricklin

---

## CURRENT STATUS: Ready for TestFlight

**Build Status:** ✓ Compiles (Swift 6 clean)

**TestFlight Blockers:** None — all cleared 2026-01-20

---

## Project Overview

WellnessCheck is a safety monitoring iOS app designed to help solo dwellers stay connected to the people who care about them. The app detects falls, monitors for periods of inactivity, and automatically alerts designated Care Circle members when potential emergencies or wellness concerns are detected.

**Core Mission:** Create a reliable, privacy-respecting safety net for people living independently while giving their loved ones peace of mind.

---

## v1.0 Features

### Implemented ✓
- Fall detection (CoreMotion, wired to SMS)
- Step count monitoring (HealthKit)
- Phone movement proof-of-life (CoreMotion)
- Flights of stairs climbed (HealthKit)
- Battery level tracking (dead battery detection)
- Home awareness (user-defined)
- Learned pattern deviation (14-day learning, wired to SMS)
- Negative space detection (inactivity monitoring, wired to SMS)
- Silence threshold (2-12 hours configurable)
- Do Not Disturb / Quiet Hours
- Care Circle management with SMS invitations
- Firebase Auth + Firestore sync
- Full dashboard (4 tabs)
- Spanish localization
- Account deletion UI (App Store requirement)
- Notification tap actions with "I'm OK" response
- Crashlytics crash reporting (requires SPM package)

### Not Implemented
- Background monitoring (services stop when app closes)
- Push notifications (FCM)

---

## Key Services

| Service | File | Status |
|---------|------|--------|
| Fall Detection | FallDetectionService.swift | ✓ Works, sends SMS |
| Inactivity | NegativeSpaceService.swift | ✓ Works, sends SMS |
| Pattern Learning | PatternLearningService.swift | ✓ Works, sends SMS |
| Battery | BatteryService.swift | ✓ Works |
| HealthKit | HealthKitService.swift | ✓ Works |
| SMS | CloudFunctionsService.swift | ✓ Works |
| Auth | AuthService.swift | ✓ Works (with deletion UI) |
| Watch Connectivity | WatchConnectivityService.swift | ✓ Works |
| Watch Fall Detection | FallDetectionManager.swift (watchOS) | ✓ Works |

---

## Future Versions

- Geofencing (dementia/Alzheimer's use case)
- Known location arrival
- HomeKit signals
- Bluetooth/CarPlay connections
- Blood glucose monitoring (Libre 3, Dexcom via HealthKit)
- Medication tracking
- Appointment management
- Physician contacts

---

## WellnessWatch

Care Circle companion app. Planned but not part of v1. Build Care Circle management in WellnessCheck with cloud sync and role-based access so WellnessWatch can consume the same API later.

**Domains:** wellnesscheck.dev, wellnesswatch.dev (both registered)

---

## Terminology

| Term | Meaning |
|------|---------|
| Solo Dweller | Person using WellnessCheck (any age, living independently) |
| Care Circle | The group of connected people |
| Care Circle Member | Anyone in the Care Circle |

**In-app:** Use "My" (My Wellness, My Care Circle) instead of "Solo Dweller"

---

## Development Environment

- **Project Root:** ~/Documents/Development/iOS/MyiOSProjects/WellnessCheck-iOS/
- **Xcode Project:** ~/Documents/Development/iOS/MyiOSProjects/WellnessCheck-iOS/Code/WellnessCheck/
- **GitHub:** github.com/charles-stricklin/WellnessCheck-iOS

### Backend
- **Firebase:** Auth, Firestore, Cloud Functions
- **Twilio:** SMS alerts and invitations (A2P 10DLC approved)

---

## Design Requirements

Optimized for seniors:
- Touch targets: 60x60pt minimum
- Font sizes: 20pt body, 22pt buttons, 28pt+ headers
- Color contrast: 7:1 minimum
- No swipe gestures — explicit buttons only
- One-tap actions where possible

---

## Connection Model

1. Solo dweller taps "Add Care Circle Member"
2. Enters name and phone number
3. SMS invitation sent via Twilio
4. Solo dweller always initiates (consent chain)

---

## Health Data Privacy

- Only request HealthKit permissions actually needed
- Store minimal data in Firebase
- Never store HealthKit data externally without explicit consent
- Include disclaimer: app is NOT a medical device, does NOT replace 911

---

## Project Tracking

- **Tasks:** TODO.md in project root
- **Session history:** SESSION_LOG.md in project root
