# WellnessCheck Platform

**Living alone shouldn't mean being alone in an emergency.**

A comprehensive safety and wellness monitoring platform for solo dwellers and their Care Circle members.

---

## 📱 About

WellnessCheck Platform consists of two iOS apps working together:

- **WellnessCheck** - For solo dwellers (seniors and at-risk individuals living alone)
- **WellnessWatch** - For Care Circle members (family, friends, caregivers)

**Current Version:** v0.1.0 (Early Development)  
**Status:** Foundation stage - onboarding flow built, untested  
**Platform:** iOS 16.0+  
**Developer:** Charles Stricklin, Stricklin Development, LLC  
**Domains:** wellnesscheck.dev | wellnesswatch.dev

---

## 🎯 Mission

Create a reliable, privacy-respecting safety net for people living independently while giving their loved ones peace of mind.

---

## ✨ Planned Features (v1.0)

### WellnessCheck (Solo Dweller App)
- ⏳ Automatic fall detection
- ⏳ Inactivity monitoring  
- ⏳ Emergency alert slider
- ⏳ Glucose monitoring (Libre 3 integration)
- ⏳ Medication tracking
- ⏳ Appointment management
- ⏳ Physician contacts
- ⏳ Care Circle management
- ⏳ Wellness concern detection
- ⏳ Do Not Disturb scheduling

### WellnessWatch (Care Circle App)
- ⏳ Multi-person dashboard
- ⏳ Real-time alerts
- ⏳ Trend data and history
- ⏳ Quick-glance status updates

---

## 📊 Current Status

### Completed (v0.1.0)
- ✅ Git repository initialized
- ✅ Project structure created
- ✅ Onboarding flow code written (5 screens)
- ✅ User model and settings
- ✅ MVVM architecture established
- ✅ Documentation (claude.md)

### In Progress
- 🔄 Xcode project configuration
- 🔄 Testing onboarding flow

### Next Steps
- ⏳ Add files to Xcode project
- ⏳ Configure HealthKit capability
- ⏳ Implement HealthKit service
- ⏳ Set up Firebase backend
- ⏳ Build notification system

---

## 🏗️ Tech Stack

- **Language:** Swift 6.x
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Backend:** Firebase (Auth, Firestore, Functions, Messaging)
- **SMS:** Twilio
- **Health Data:** HealthKit
- **Minimum iOS:** 16.0+

---

## 📁 Repository Structure

```
WellnessCheck/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── claude.md                    # Project context for AI assistance
├── Code/
│   └── WellnessCheck/           # Xcode project
│       └── WellnessCheck/       # App code
│           ├── Models/
│           ├── ViewModels/
│           ├── Screens/
│           ├── Services/
│           ├── Shared/
│           └── Utilities/
└── docs/
    └── [Project documentation]
```

---

## 🚀 Development Roadmap

**v0.1.0** - Foundation (Current)  
**v0.2.0** - Xcode integration, onboarding tested  
**v0.3.0** - HealthKit service, fall detection  
**v0.4.0** - Firebase backend, emergency alerts  
**v0.5.0** - Glucose monitoring  
**v0.6.0** - Medication tracking  
**v0.7.0** - Appointments & physician contacts  
**v0.8.0** - WellnessWatch app development  
**v0.9.0** - Full integration & testing  
**v1.0.0** - App Store launch (when ready)

---

## 📝 License

MIT License - See LICENSE file for details

---

## 👨‍💻 Developer

**Charles Stricklin**  
Stricklin Development, LLC  
San Antonio, Texas

Building technology to help seniors and at-risk individuals live independently with dignity and safety.

---

**Note:** This is a safety-critical application under active development. Quality and user safety are prioritized over speed. Target launch: When it's ready and right.
