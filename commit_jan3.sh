#!/bin/bash

# WellnessCheck Git Commit Script
# Session: January 3, 2026
# Changes: Language selection, Care Circle CRUD, Contacts integration

cd "/Users/charles/Documents/Development/iOS/MyiOSProjects/WellnessCheck"

# Stage all changes
git add -A

# Commit with detailed message
git commit -m "[Feature] Major onboarding enhancements - Language selection & Care Circle management

LANGUAGE SELECTION:
- Added LanguageSelectionView as Screen 0 (English/Spanish)
- Updated OnboardingViewModel with languageSelection step
- Bilingual support foundation for San Antonio demographics

CARE CIRCLE SYSTEM:
- Created CareCircleMember model with full contact details
- Built CareCircleViewModel with CRUD operations
- Three new screens: List, Add, Edit
- Tap member cards to edit relationship/remove
- UserDefaults storage (Firebase migration pending)

CONTACTS INTEGRATION:
- ContactPicker component for iOS Contacts access
- ProfileSetupView: 'Use My Contact Card' button
- AddCareCircleMemberView: 'Choose from Contacts' button  
- CareCircleListView: 'Add from Contacts' primary action
- Auto-fills name, phone, email from device contacts

ONBOARDING IMPROVEMENTS:
- Profile setup: Added surname (required) and email (optional)
- Red asterisks mark required fields
- 'Continue' button → 'Add Me' (more personal)
- Validation alerts on incomplete forms
- Progress dots removed (less intimidating)
- Permission screens split into two direct-request flows
- Care Circle flow: Users stay in list after adding members
- Centered 'Good to meet you, NAME!' greeting

PERMISSIONS FIXED:
- HealthKit permission dialog now working
- Added NSContactsUsageDescription to Info.plist
- Improved HealthKit type requests (active energy, steps, distance)

LOGO CONSISTENCY:
- Both Language & Welcome screens check for AppLogo asset
- Fallback to placeholders if AppLogo missing

FILES CREATED (8):
- LanguageSelectionView.swift
- CareCircleMember.swift
- CareCircleViewModel.swift
- AddCareCircleMemberView.swift
- CareCircleListView.swift
- EditCareCircleMemberView.swift
- ContactPicker.swift
- Updated LargeButton.swift (includes LargeOutlineButton)

FILES MODIFIED (9):
- OnboardingViewModel.swift
- OnboardingContainerView.swift
- ProfileSetupView.swift
- WhyNotificationsView.swift
- WhyHealthDataView.swift
- CareCircleIntroView.swift
- WelcomeView.swift
- Constants.swift
- claude.md

FILES DELETED (2):
- PermissionsView.swift (redundant)
- Duplicate LargeOutlineButton.swift

ONBOARDING STATUS: 7 of 9 screens complete
PENDING: Customize Monitoring (Screen 8), Completion (Screen 9)
VERSION: v0.2.0 → Ready for v0.3.0 bump after onboarding complete"

# Push to remote
git push origin main

echo "✅ Changes committed and pushed to GitHub"
echo "Version: v0.2.0"
echo "Onboarding: 78% complete (7/9 screens)"
