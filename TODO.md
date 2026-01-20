# WellnessCheck Tasks

**Last Updated:** January 20, 2026

---

## BLOCKERS FOR TESTFLIGHT (Must Complete First)

None — ready for TestFlight upload!

---

## In Progress
- [ ] Device testing
- [ ] TestFlight upload

---

## Up Next
- [ ] Background monitoring (BGTaskScheduler) — services only run in foreground currently
- [ ] Push notification system (FCM) — only local notifications exist
- [ ] Family Controls entitlement (pending Apple approval) — applied 2026-01-13

---

## Additional Proof-of-Life Signals (v1.1 candidates)
- [ ] Sleep analysis from HealthKit (waking up daily = strong signal)
- [ ] Charging events (phone plugged in = alive)
- [ ] Significant location changes (user is out and about)
- [ ] Walking steadiness (already have HealthKit access, not analyzing)
- [ ] Resting vs active energy patterns

---

## Backlog

### Core Safety
- [ ] Wellness concern detection (pattern clusters)

### Research
- [ ] Screen unlock data API feasibility

### Future (v2)
- [ ] Apple Watch integration
- [ ] CGM/glucose monitoring
- [ ] Geofencing for dementia use case

### Post-Android: Enterprise Licensing
- [ ] Firestore schema for organizations (see /Docs/EnterpriseSchema.md)
- [ ] License validation Cloud Function
- [ ] Enterprise activation flow in onboarding
- [ ] Admin web portal (wellnesscheck.dev)
- [ ] Apple Business Manager / VPP integration (iOS)
- [ ] Managed Google Play setup (Android)
- [ ] Enterprise-specific features:
  - [ ] Admin dashboard (resident status overview)
  - [ ] Bulk onboarding (CSV import)
  - [ ] Facility staff as default Care Circle
  - [ ] Custom alert routing
  - [ ] Audit logs for compliance
  - [ ] HIPAA BAA option

---

## Done
- [x] Terms of Service published (wellnesscheck.dev/terms) — 2026-01-20
- [x] FirebaseCrashlytics added to SPM — 2026-01-20
- [x] Account deletion UI in Settings (App Store requirement) — 2026-01-20
- [x] Inactivity alert → SMS wired (NegativeSpaceService → CloudFunctionsService) — 2026-01-20
- [x] Pattern deviation → SMS wired (PatternLearningService → CloudFunctionsService) — 2026-01-20
- [x] UNUserNotificationCenterDelegate (notification tap handling, "I'm OK" action) — 2026-01-20
- [x] Crashlytics initialization code added — 2026-01-20
- [x] Fall alert sound verified (graceful fallback to system sounds works) — 2026-01-20
- [x] App Store Connect metadata entered (description, keywords, privacy policy) — 2026-01-18
- [x] Swift 6 concurrency fixes (Timer + Task captures) — 2026-01-18
- [x] README updated to v0.6.0 — 2026-01-18
- [x] Learned pattern deviation detection (PatternLearningService) — 2026-01-17
- [x] Negative space detection (NegativeSpaceService, inactivity monitoring) — 2026-01-17
- [x] Do Not Disturb / Quiet Hours (integrated with monitoring) — 2026-01-17
- [x] Silence threshold slider (2-12 hours) in Settings — 2026-01-17
- [x] Battery level tracking (BatteryService, dead battery detection) — 2026-01-17
- [x] Fall detection via CoreMotion (impact + stillness algorithm, 60s countdown, Care Circle alert) — 2026-01-17
- [x] Activity tab - weekly/monthly history with daily breakdown — 2026-01-17
- [x] Care Circle tab - full member management (add/edit/reorder/delete) — 2026-01-17
- [x] Settings tab - Profile, Notifications, Monitoring, Home Location, Help, About — 2026-01-17
- [x] Care Circle syncs to Firestore (with UserDefaults fallback for onboarding) — 2026-01-17
- [x] A2P 10DLC business registration approved — 2026-01-17
- [x] Firebase Auth UI (sign in/sign up, Sign in with Apple) — 2026-01-15
- [x] Firestore data structure for users and Care Circle — 2026-01-15
- [x] Cloud Functions for SMS (sendImOkMessage, sendAlert, sendInvitation) — 2026-01-15
- [x] Twilio SMS integration (production) — "I'm OK" button working — 2026-01-15
- [x] A2P 10DLC brand registration submitted — 2026-01-15
- [x] Dark mode backgrounds standardized to dark blue (#112244) — 2026-01-14
- [x] HealthKit expanded (energy, walking speed/length, steadiness, sleep) — 2026-01-14
- [x] Profile Setup illustrations (JaneDoe/JuanGarcia) — 2026-01-14
- [x] CompletionView bug fixes (member count, home location status) — 2026-01-14
- [x] Duplicate directory cleanup — 2026-01-14
- [x] Dashboard connected to real HealthKit data (steps, floors) — 2026-01-13
- [x] Care Circle preview shows actual stored members — 2026-01-13
- [x] Phone pickup proxy via CoreMotion — 2026-01-13
- [x] Splash screen with version number — 2026-01-13
- [x] Fade-to-black on inactivity/background — 2026-01-13
- [x] Tagline italicized "be" emphasis — 2026-01-13
- [x] Removed redundant header gear icon — 2026-01-13
- [x] Removed step goal/progress bar (not a fitness app) — 2026-01-13
- [x] Swift 6 concurrency fixes — 2026-01-13
- [x] Applied for Family Controls entitlement — 2026-01-13
- [x] Spanish localization complete — 2026-01-11
- [x] Care Circle contact photos from iOS Contacts — 2026-01-11
- [x] Care Circle member reordering (up/down arrows, position numbers) — 2026-01-11
- [x] EditCareCircleMemberView redesign (photo, name, editable phone/email) — 2026-01-11
- [x] In-app language switching (locale environment) — 2026-01-11
- [x] LocalizedStringKey fixes for custom components — 2026-01-11
- [x] Localization string catalog populated (143 strings) — 2026-01-11
- [x] Full onboarding flow (11 screens) — 2026-01-10
- [x] Home location setup with GPS + confirm — 2026-01-10
- [x] Customize Monitoring screen — 2026-01-10
- [x] Completion screen with ThumbsUp — 2026-01-10
- [x] Main Dashboard with tab bar — 2026-01-10
- [x] iOS 26 compatibility (MKReverseGeocodingRequest) — 2026-01-10
- [x] Care Circle management UI — 2026-01-06
- [x] Care Circle invitation preview (test mode) — 2026-01-06
- [x] Finalized v1.0 feature scope — 2026-01-10
- [x] Created CLAUDE.md project context — 2026-01-10
- [x] Splash screen — 2026-01-08
- [x] App icon assets — 2026-01-07
