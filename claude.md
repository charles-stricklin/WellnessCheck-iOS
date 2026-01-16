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

**Last Updated**: January 10, 2026  
**Developer**: Charles W. Stricklin

---

## Project Overview

WellnessCheck is a safety monitoring iOS app designed to help solo dwellers stay connected to the people who care about them. The app detects falls, monitors for periods of inactivity, and automatically alerts designated Care Circle members when potential emergencies or wellness concerns are detected.

**Core Mission:** Create a reliable, privacy-respecting safety net for people living independently while giving their loved ones peace of mind.

---

## v1.0 Features

- Fall detection
- Step count accumulation
- Phone movement proof-of-life
- Flights of stairs climbed
- Battery level (context for negative space gaps)
- Home awareness (user-defined at onboarding)
- Learned pattern deviation
- Negative space detection
- Wellness concern detection (pattern clusters)
- Care Circle management
- Do Not Disturb scheduling

**Pending API Research:** Screen unlock data

---

## Future Versions

- Geofencing (dementia/Alzheimer's use case)
- Known location arrival
- Apple Watch integration
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
- **Xcode Project:** ~/Documents/Development/iOS/MyiOSProjects/WellnessCheck/Code/WellnessCheck-iOS/
- **GitHub:** github.com/charles-stricklin/WellnessCheck-iOS

### Backend
- **Firebase:** Auth, Firestore, Cloud Functions, Cloud Messaging
- **Twilio:** SMS alerts and invitations

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
