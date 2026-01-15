# WellnessCheck Enterprise Licensing - Firestore Schema

**Created:** January 14, 2026
**Status:** Planning (Post-Android)

---

## Overview

This document outlines the Firestore data structure for enterprise licensing. Enterprise customers (assisted living facilities, home health agencies, senior communities) can purchase bulk licenses and manage multiple users through an admin portal.

---

## Collections

### `organizations`

Enterprise customer accounts.

```javascript
organizations/{orgId}
{
  // Core info
  name: "Sunrise Senior Living - Austin",
  slug: "sunrise-austin",                    // URL-friendly identifier

  // Contact
  adminEmail: "admin@sunrisesenior.com",
  adminName: "Jane Smith",
  phone: "+1-512-555-0100",

  // Address
  address: {
    street: "1234 Care Circle Dr",
    city: "Austin",
    state: "TX",
    zip: "78701",
    country: "US"
  },

  // Licensing
  plan: "enterprise",                        // "enterprise" | "enterprise_plus"
  seatLimit: 50,                             // Max users allowed
  seatsUsed: 23,                             // Current active users
  pricePerSeat: 8.00,                        // Monthly rate per seat
  billingCycle: "annual",                    // "monthly" | "annual"

  // Dates
  contractStartDate: Timestamp,
  contractEndDate: Timestamp,
  createdAt: Timestamp,
  updatedAt: Timestamp,

  // Status
  status: "active",                          // "active" | "suspended" | "cancelled"

  // Feature flags (enterprise customization)
  features: {
    customBranding: true,
    apiAccess: false,
    ssoEnabled: false,
    hipaaCompliant: true,
    auditLogs: true,
    bulkOnboarding: true,
    customAlertRouting: true
  },

  // Custom branding (if enabled)
  branding: {
    logoUrl: "https://storage.../sunrise-logo.png",
    primaryColor: "#1A5F7A",
    appName: "Sunrise WellnessCheck"         // Optional custom name
  },

  // Default Care Circle members (facility staff)
  defaultCareCircle: [
    {
      name: "Front Desk",
      phone: "+1-512-555-0101",
      role: "facility_staff",
      priority: 1
    },
    {
      name: "On-Call Nurse",
      phone: "+1-512-555-0102",
      role: "medical_staff",
      priority: 2
    }
  ],

  // Alert routing configuration
  alertRouting: {
    fallDetection: ["facility_staff", "medical_staff", "family"],
    inactivity: ["facility_staff", "family"],
    manualAlert: ["family", "facility_staff"]
  }
}
```

### `organizationAdmins`

Admin users who can manage the organization (separate from residents/users).

```javascript
organizationAdmins/{adminId}
{
  orgId: "sunrise-austin",
  userId: "firebase-auth-uid",               // Links to Firebase Auth
  email: "jane@sunrisesenior.com",
  name: "Jane Smith",
  role: "owner",                             // "owner" | "admin" | "viewer"
  permissions: {
    manageUsers: true,
    viewDashboard: true,
    editSettings: true,
    manageBilling: true,
    viewAuditLogs: true
  },
  createdAt: Timestamp,
  lastLoginAt: Timestamp
}
```

### `users` (updated)

Add enterprise fields to existing user documents.

```javascript
users/{userId}
{
  // ... existing user fields ...

  // Enterprise fields (optional - null for consumer users)
  orgId: "sunrise-austin",                   // null for consumer users
  enterpriseRole: "resident",                // "resident" | "family_member"
  roomNumber: "204B",                        // Facility-specific identifier
  enrolledBy: "admin-user-id",               // Who added this user
  enrolledAt: Timestamp,

  // Enterprise users may have org-provided default Care Circle
  useOrgDefaultCareCircle: true,             // Prepend org's default contacts

  // Consumer licensing (for non-enterprise)
  purchaseType: "one_time",                  // "one_time" | "enterprise"
  purchaseDate: Timestamp,
  receiptId: "apple-or-google-receipt"
}
```

### `organizationInvites`

Pending invitations for enterprise user enrollment.

```javascript
organizationInvites/{inviteId}
{
  orgId: "sunrise-austin",
  code: "SUNRISE-2026-ABCD",                 // Activation code
  email: "resident@email.com",               // Optional - for email invites
  createdBy: "admin-user-id",
  createdAt: Timestamp,
  expiresAt: Timestamp,
  usedBy: null,                              // userId when redeemed
  usedAt: null,
  status: "pending"                          // "pending" | "used" | "expired"
}
```

### `auditLogs`

For enterprise compliance requirements.

```javascript
auditLogs/{logId}
{
  orgId: "sunrise-austin",
  timestamp: Timestamp,
  actorId: "user-or-admin-id",
  actorType: "admin",                        // "admin" | "user" | "system"
  action: "user_enrolled",
  targetType: "user",
  targetId: "user-id",
  details: {
    roomNumber: "204B",
    enrolledBy: "Jane Smith"
  },
  ipAddress: "192.168.1.100"                 // Optional
}
```

---

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Organizations: only org admins can read/write
    match /organizations/{orgId} {
      allow read: if isOrgAdmin(orgId);
      allow write: if isOrgOwner(orgId);
    }

    // Organization admins
    match /organizationAdmins/{adminId} {
      allow read: if request.auth.uid == resource.data.userId
                  || isOrgOwner(resource.data.orgId);
      allow write: if isOrgOwner(resource.data.orgId);
    }

    // Users: user can read own doc, org admins can read org users
    match /users/{userId} {
      allow read: if request.auth.uid == userId
                  || (resource.data.orgId != null
                      && isOrgAdmin(resource.data.orgId));
      allow write: if request.auth.uid == userId;
    }

    // Audit logs: org admins with audit permission only
    match /auditLogs/{logId} {
      allow read: if isOrgAdmin(resource.data.orgId)
                  && hasPermission(resource.data.orgId, 'viewAuditLogs');
      allow write: if false; // Only Cloud Functions can write
    }

    // Helper functions
    function isOrgAdmin(orgId) {
      return exists(/databases/$(database)/documents/organizationAdmins/$(request.auth.uid))
             && get(/databases/$(database)/documents/organizationAdmins/$(request.auth.uid)).data.orgId == orgId;
    }

    function isOrgOwner(orgId) {
      return isOrgAdmin(orgId)
             && get(/databases/$(database)/documents/organizationAdmins/$(request.auth.uid)).data.role == 'owner';
    }

    function hasPermission(orgId, permission) {
      let admin = get(/databases/$(database)/documents/organizationAdmins/$(request.auth.uid));
      return admin.data.permissions[permission] == true;
    }
  }
}
```

---

## Cloud Functions

### `validateEnterpriseLicense`

Called during user signup when an org code is provided.

```javascript
// Pseudocode
exports.validateEnterpriseLicense = functions.https.onCall(async (data, context) => {
  const { orgCode } = data;

  // Find invite by code
  const invite = await findInviteByCode(orgCode);
  if (!invite || invite.status !== 'pending') {
    throw new Error('Invalid or expired code');
  }

  // Check org seat availability
  const org = await getOrg(invite.orgId);
  if (org.seatsUsed >= org.seatLimit) {
    throw new Error('Organization has reached seat limit');
  }

  // Check org status
  if (org.status !== 'active') {
    throw new Error('Organization account is not active');
  }

  return {
    valid: true,
    orgId: invite.orgId,
    orgName: org.name,
    inviteId: invite.id
  };
});
```

### `enrollEnterpriseUser`

Called after user completes onboarding with valid org code.

```javascript
exports.enrollEnterpriseUser = functions.https.onCall(async (data, context) => {
  const { userId, inviteId } = data;

  // Mark invite as used
  await markInviteUsed(inviteId, userId);

  // Increment org seat count
  await incrementSeatsUsed(invite.orgId);

  // Update user document with org info
  await updateUser(userId, {
    orgId: invite.orgId,
    enterpriseRole: 'resident',
    enrolledAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Write audit log
  await writeAuditLog({
    orgId: invite.orgId,
    action: 'user_enrolled',
    targetId: userId
  });

  return { success: true };
});
```

---

## Admin Portal Endpoints

The web admin portal (wellnesscheck.dev) will need these API endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/org/{orgId}/dashboard` | GET | Resident status overview |
| `/api/org/{orgId}/users` | GET | List all org users |
| `/api/org/{orgId}/users` | POST | Bulk import users (CSV) |
| `/api/org/{orgId}/invites` | POST | Generate invite codes |
| `/api/org/{orgId}/alerts` | GET | Recent alerts for all users |
| `/api/org/{orgId}/audit-logs` | GET | Compliance audit trail |
| `/api/org/{orgId}/settings` | PUT | Update org settings |

---

## Onboarding Flow (Enterprise)

1. User downloads app (App Store / Play Store, or via MDM)
2. On first launch, user sees option: "I have an organization code"
3. User enters code (e.g., `SUNRISE-2026-ABCD`)
4. App calls `validateEnterpriseLicense` Cloud Function
5. If valid, onboarding continues with org branding applied
6. On completion, `enrollEnterpriseUser` is called
7. Org's default Care Circle is automatically added (if configured)
8. User appears in org admin dashboard

---

## Pricing Model (Reference)

| Plan | Seats | Price/Seat/Month | Billing | Features |
|------|-------|------------------|---------|----------|
| Enterprise | 10-50 | $8.00 | Annual | Dashboard, bulk onboard, audit logs |
| Enterprise Plus | 50+ | $6.00 | Annual | All above + SSO, API access, custom branding |
| HIPAA Add-on | Any | +$2.00/seat | Annual | BAA, enhanced audit, data residency |

---

## Migration Notes

When implementing:

1. Existing consumer users (`orgId: null`) are unaffected
2. `users` collection needs schema migration to add optional enterprise fields
3. Consider Firestore composite indexes for org-scoped queries
4. Audit log retention policy: 7 years for HIPAA compliance

---

## Related Documents

- TODO.md - Implementation checklist
- CLAUDE.md - Project context
- (Future) AdminPortal/README.md - Web portal documentation
