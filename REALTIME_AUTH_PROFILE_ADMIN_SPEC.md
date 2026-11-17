# PlotTheirFuture — Real-Time Authentication, Profile, Admin & Persistent Session Specification

- **Document Version:** `2.1.0-PROD`
- **Specification Status:** Canonical Client Integration Reference
- **Base URLs:**
  - **Local Development:** `http://localhost:8085/api/v1`
  - **Production:** `https://api.plottheirfuture.in/api/v1`
- **Default Format:** `application/json`
- **Security Protocols:** JWT Bearer Authentication (`Authorization: Bearer <token>`) & Role-Based Access Control (RBAC: `ROLE_USER`, `ROLE_COUPLE`, `ROLE_ADMIN`)
- **Session Duration:** 7 Days (`604800` seconds) with Auto-Renewal

---

## Table of Contents
1. [End-to-End Authentication & Session Architecture](#1-end-to-end-authentication--session-architecture)
2. [Section 1: Dynamic OTP Login Flow (`/api/v1/auth`)](#section-1-dynamic-otp-login-flow-apiv1auth)
   - 1.1 Request Dynamic OTP (WhatsApp / SMS)
   - 1.2 Verify Dynamic OTP & Issue JWT Session
3. [Section 2: Casual Profile Onboarding (Name & Occupation) (`/api/v1/users`)](#section-2-casual-profile-onboarding-name--occupation-apiv1users)
   - 2.1 Complete Profile Setup / Skip Profile
4. [Section 3: Profile Screen Real-Time Data Fetching](#section-3-profile-screen-real-time-data-fetching)
   - 3.1 Get Authenticated User Profile (`/auth/me`)
   - 3.2 Get My Marriage Registrations (`/marriages/my-registrations`)
   - 3.3 Get My Gifting Ledger & Section 56(2)(x) Tax Receipts
5. [Section 4: Admin Management & Role-Based Access Control (RBAC)](#section-4-admin-management--role-based-access-control-rbac)
   - 4.1 Admin User Creation API (`POST /api/v1/users`)
   - 4.2 Admin Login via Password (`POST /api/v1/auth/login`)
   - 4.3 Admin Marriage Moderation & Flat Assignment
   - 4.4 Role Matrix & Permissions Table
6. [Section 5: Persistent Session Blueprint ("Stay Logged In Until Sign Out")](#section-5-persistent-session-blueprint-stay-logged-in-until-sign-out)
   - 5.1 Storage Protocol & Key Architecture
   - 5.2 Cold-Start Restoration Flow
   - 5.3 Explicit Sign-Out Contract

---

## 1. End-to-End Authentication & Session Architecture

```mermaid
sequenceDiagram
    autonumber
    actor User as User / Admin
    participant App as Flutter Mobile App
    participant Storage as Local Device Storage (SharedPreferences)
    participant Backend as PTF REST API Backend

    Note over User,Backend: 1. Dynamic OTP Login Flow
    User->>App: Enters mobile number (+91 98480 12345) & taps Verify
    App->>Backend: POST /api/v1/auth/request-otp {"phone": "+91 98480 12345"}
    Backend-->>App: 200 OK {"sessionHash": "...", "expiresIn": 300}
    User->>App: Enters 6-digit OTP code (e.g. 123456)
    App->>Backend: POST /api/v1/auth/verify-otp {"phone": "...", "otp": "..."}
    Backend-->>App: 200 OK {"token": "eyJhbGci...", "user": {"registered": false, "role": "ROLE_USER"}}

    Note over App,Storage: 2. Persistent Storage (Never Logout across App Restarts)
    App->>Storage: Save AuthSession JSON (Token + User Profile + Role)

    alt New User (registered == false)
        App->>User: Displays Quick Intro (Name & Occupation input)
        User->>App: Enters Name ("Rahul") & Occupation ("Architect")
        App->>Backend: PUT /api/v1/users/{id}/profile {"name": "...", "occupation": "...", "skip": false}
        Backend-->>App: 200 OK (Updated User Dossier)
        App->>Storage: Update Saved AuthSession with registered=true
        App->>User: Navigates to HomeScreen
    else Existing User / Admin (registered == true)
        App->>User: Directly navigates to HomeScreen with Welcome Toast!
    end

    Note over User,Backend: 3. App Cold Start (Subsequent App Opens)
    User->>App: Launches App
    App->>Storage: Reads plot_their_future_auth_session_v1
    Storage-->>App: Restores JWT Token & User Session
    App->>Backend: GET /api/v1/auth/me (Background sync)
    Backend-->>App: 200 OK (Fresh User Profile & Role)
    Note over App: User remains continuously LOGGED IN until explicit Sign Out!
```

---

## Section 1: Dynamic OTP Login Flow (`/api/v1/auth`)

### 1.1 Request Dynamic OTP (WhatsApp / SMS)
Dispatches a 6-digit cryptographic one-time password via WhatsApp Business API (fallback to SMS).

- **Method / Endpoint:** `POST /api/v1/auth/request-otp`
- **Security:** Public (`BypassAuth: true`)
- **Rate Limit:** 3 requests per 10 minutes per IP / phone number.

#### Request Headers
```http
Content-Type: application/json
Accept: application/json
```

#### Request Body
```json
{
  "phone": "+91 98480 12345",
  "slug": "sanvi-santosh"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `phone` | String | Yes | E.164 formatted mobile number with country code (e.g. `+91 98480 12345`). |
| `slug` | String | No | Target wedding microsite slug. Defaults to `sanvi-santosh`. |

#### Response: `200 OK`
```json
{
  "message": "OTP dispatched successfully via WhatsApp/SMS",
  "phone": "+91 98480 12345",
  "sessionHash": "KzkxOTg0ODAxMjM0NTo...token-hash",
  "expiresIn": 300
}
```

#### cURL Example
```bash
curl -X POST "https://api.plottheirfuture.in/api/v1/auth/request-otp" \
  -H "Content-Type: application/json" \
  -d '{"phone": "+91 98480 12345", "slug": "sanvi-santosh"}'
```

---

### 1.2 Verify Dynamic OTP & Issue JWT Session
Validates the dynamic OTP. If valid, provisions a persistent 7-day JWT Bearer session and returns the user object, roles, and registration status.

- **Method / Endpoint:** `POST /api/v1/auth/verify-otp`
- **Security:** Public (`BypassAuth: true`)

#### Request Body
```json
{
  "phone": "+91 98480 12345",
  "otp": "123456"
}
```

#### Response: `200 OK` (New Unregistered User)
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwicm9sZXMiOlsicm9sZV91c2VyIl0sImV4cCI6MTc5NTI0NzgwMH0.ptf_secure_signature",
  "tokenType": "Bearer",
  "expiresIn": 604800,
  "user": {
    "id": 1042,
    "name": "",
    "mobileNumber": "+91 98480 12345",
    "role": "ROLE_USER",
    "registered": false,
    "occupation": null,
    "image": null
  },
  "accessibleWeddings": [
    "sanvi-santosh"
  ],
  "message": "OTP verified successfully"
}
```

#### Response: `200 OK` (Existing Registered User or Admin)
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwicm9sZXMiOlsicm9sZV9hZG1pbiJdLCJleHAiOjE3OTUyNDc4MDB9.ptf_admin_signature",
  "tokenType": "Bearer",
  "expiresIn": 604800,
  "user": {
    "id": 1,
    "name": "Sanvi Reddy",
    "mobileNumber": "+91 98480 12345",
    "role": "ROLE_ADMIN",
    "registered": true,
    "occupation": "Senior Software Architect",
    "image": "https://cdn.plottheirfuture.in/avatars/admin_1.png"
  },
  "accessibleWeddings": [
    "sanvi-santosh"
  ],
  "message": "OTP verified successfully. Welcome back!"
}
```

> [!IMPORTANT]
> **Client Routing Logic on OTP Success:**
> - If `user.registered == true` AND `user.name` is non-empty: The client navigates **directly to `HomeScreen`** without showing the intro profile form.
> - If `user.registered == false` OR `user.name` is empty: The client advances to **Step 2 (Quick Intro)** to collect Name & Occupation.

---

## Section 2: Casual Profile Onboarding (Name & Occupation) (`/api/v1/users`)

### 2.1 Complete Profile Setup / Skip Profile
Allows new users to quickly personalize their profile or skip straight to the platform.

- **Method / Endpoint:** `PUT /api/v1/users/{id}/profile` (Fallback: `PUT /api/v1/users/{id}`)
- **Security:** Bearer Token (`Authorization: Bearer <token>`)

#### Request Headers
```http
Authorization: Bearer <jwt-token>
Content-Type: application/json
Accept: application/json
```

#### Request Body (User completes name & profession)
```json
{
  "name": "Rahul Varma",
  "occupation": "Software Engineer",
  "skip": false
}
```

#### Request Body (User clicks "Skip for now")
```json
{
  "name": "Honored Guest",
  "occupation": null,
  "skip": true
}
```

#### Response: `200 OK`
```json
{
  "id": 1042,
  "name": "Rahul Varma",
  "mobileNumber": "+91 98480 12345",
  "role": "ROLE_USER",
  "registered": true,
  "occupation": "Software Engineer",
  "locationId": null,
  "image": null
}
```

#### cURL Example
```bash
curl -X PUT "https://api.plottheirfuture.in/api/v1/users/1042/profile" \
  -H "Authorization: Bearer eyJhbGciOiJIUz..." \
  -H "Content-Type: application/json" \
  -d '{"name": "Rahul Varma", "occupation": "Software Engineer", "skip": false}'
```

---

## Section 3: Profile Screen Real-Time Data Fetching

### 3.1 Get Authenticated User Profile (`/auth/me`)
Retrieves the real-time user profile, verification status, and permissions for the currently logged-in token.

- **Method / Endpoint:** `GET /api/v1/auth/me`
- **Security:** Bearer Token (`Authorization: Bearer <token>`)

#### Response: `200 OK`
```json
{
  "id": 1,
  "name": "Sanvi Reddy",
  "mobileNumber": "+91 98480 12345",
  "role": "ROLE_ADMIN",
  "registered": true,
  "occupation": "Senior Software Architect",
  "locationId": 1,
  "image": "https://cdn.plottheirfuture.in/avatars/admin_1.png"
}
```

---

### 3.2 Get My Marriage Registrations (`/marriages/my-registrations`)
Fetches all marriage registrations submitted by the authenticated couple/user, including RERA flat details, approval status, and shareable wedding microsite links.

- **Method / Endpoint:** `GET /api/v1/marriages/my-registrations`
- **Security:** Bearer Token (`Authorization: Bearer <token>`)

#### Response: `200 OK`
```json
[
  {
    "id": "1",
    "referenceNumber": "#REG-2026-BLR-0001",
    "status": "APPROVED",
    "submittedAt": "2026-10-15T10:30:00Z",
    "userId": 1,
    "bride": {
      "name": "Sanvi Reddy",
      "mobileNumber": "+919848012345",
      "email": "sanvi.reddy@example.com",
      "occupation": "Software Engineer"
    },
    "groom": {
      "name": "Santosh Varma",
      "mobileNumber": "+919848099999",
      "email": "santosh.varma@example.com",
      "occupation": "Product Designer"
    },
    "targetBhk": "2 BHK",
    "preferredArea": "Whitefield, Bangalore",
    "slug": "sanvi-santosh",
    "shareableUrl": "https://plottheirfuture.in/weddings/sanvi-santosh",
    "qrCodeUrl": "https://cdn.plottheirfuture.in/qrcodes/sanvi-santosh.png",
    "videoStreamUrl": "https://cdn.plottheirfuture.in/stream/sanvi-santosh/master.m3u8",
    "assignedFlat": {
      "builderName": "Prestige Group",
      "projectName": "Prestige Lakeside Habitat",
      "tower": "Tower 4 (Lotus)",
      "unitNumber": "Flat 402 (4th Floor)",
      "configuration": "2 BHK",
      "targetSft": 1200,
      "rateSft": 4500.0,
      "totalTargetAmountInr": 5400000.0,
      "builderReraId": "PRM/KA/RERA/1251/310/PR/210312/004018",
      "reraProjectUrl": "https://rera.karnataka.gov.in",
      "escrowBank": {
        "bankName": "HDFC Bank Ltd",
        "branchName": "Whitefield Branch",
        "accountHolder": "PLOT THEIR FUTURE ESCROW - SANVI SANTOSH",
        "accountNumber": "ESC-HDFC-99201948102",
        "ifscCode": "HDFC0000456",
        "upiVpa": "plottheirfuture.sanvi.santosh@hdfcbank"
      }
    }
  }
]
```

---

### 3.3 Get My Gifting Ledger & Section 56(2)(x) Tax Receipts
Fetches all sq.ft gift contributions made by this user, along with downloadable Section 56(2)(x) tax-free deeds.

- **Method / Endpoint:** `GET /api/v1/contributions/my-contributions`
- **Security:** Bearer Token (`Authorization: Bearer <token>`)

#### Response: `200 OK`
```json
[
  {
    "id": 501,
    "weddingSlug": "sanvi-santosh",
    "unitsSft": 5,
    "amount": 22500.00,
    "paymentStatus": "SUCCESS",
    "txnId": "PTF-ESC-89210",
    "taxReceiptUrl": "https://plottheirfuture.in/receipts/PTF-SEC-501.pdf",
    "createdAt": "2026-11-13T14:30:00Z"
  }
]
```

---

## Section 4: Admin Management & Role-Based Access Control (RBAC)

### 4.1 Admin User Creation API (`POST /api/v1/users`)
Used by super-administrators or provisioning scripts to create administrative personnel who have moderation rights.

- **Method / Endpoint:** `POST /api/v1/users`
- **Security:** Bearer Token (`ROLE_ADMIN` authorization)

#### Request Body
```json
{
  "name": "Karthik Velivela",
  "mobileNumber": "+91 98480 12345",
  "role": "ROLE_ADMIN",
  "occupation": "Chief Operations Director",
  "password": "SecureAdminPassword2026!"
}
```

#### Response: `201 Created`
```json
{
  "id": 2,
  "name": "Karthik Velivela",
  "mobileNumber": "+91 98480 12345",
  "role": "ROLE_ADMIN",
  "registered": true,
  "occupation": "Chief Operations Director",
  "createdAt": "2026-11-13T18:00:00Z"
}
```

#### cURL Example
```bash
curl -X POST "https://api.plottheirfuture.in/api/v1/users" \
  -H "Authorization: Bearer <super-admin-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Karthik Velivela",
    "mobileNumber": "+91 98480 12345",
    "role": "ROLE_ADMIN",
    "occupation": "Chief Operations Director",
    "password": "SecureAdminPassword2026!"
  }'
```

---

### 4.2 Admin Login via Password (`POST /api/v1/auth/login`)
Provides direct password-based login for administrators without requiring WhatsApp OTP.

- **Method / Endpoint:** `POST /api/v1/auth/login`
- **Security:** Public

#### Request Body
```json
{
  "mobileNumber": "+91 98480 12345",
  "password": "SecureAdminPassword2026!"
}
```

#### Response: `200 OK`
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 604800,
  "user": {
    "id": 1,
    "name": "Sanvi Reddy",
    "mobileNumber": "+91 98480 12345",
    "role": "ROLE_ADMIN",
    "registered": true,
    "occupation": "Senior Software Architect"
  },
  "message": "Admin session issued successfully"
}
```

---

### 4.3 Admin Marriage Moderation & Flat Assignment

#### Endpoint: `POST /api/v1/admin/marriages/{id}/approve-and-assign-flat`
- **Security:** `ROLE_ADMIN` Bearer Token

#### Request Body
```json
{
  "slug": "sanvi-santosh",
  "builderName": "Prestige Group",
  "projectName": "Prestige Lakeside Habitat",
  "tower": "Tower 4 (Lotus)",
  "unitNumber": "Flat 402 (4th Floor)",
  "configuration": "2 BHK",
  "targetSft": 1200,
  "rateSft": 4500.0,
  "builderReraId": "PRM/KA/RERA/1251/310/PR/210312/004018",
  "reraProjectUrl": "https://rera.karnataka.gov.in",
  "escrowBank": {
    "bankName": "HDFC Bank Ltd",
    "branchName": "Whitefield Branch",
    "accountHolder": "PLOT THEIR FUTURE ESCROW - SANVI SANTOSH",
    "accountNumber": "ESC-HDFC-99201948102",
    "ifscCode": "HDFC0000456",
    "upiVpa": "plottheirfuture.sanvi.santosh@hdfcbank"
  },
  "videoStreamUrl": "https://cdn.plottheirfuture.in/stream/sanvi-santosh/master.m3u8"
}
```

---

### 4.4 Role Matrix & Permissions Table

| Capability / Resource | `ROLE_USER` (Guest) | `ROLE_COUPLE` | `ROLE_ADMIN` |
|---|:---:|:---:|:---:|
| Request & Verify Dynamic OTP | ✅ Yes | ✅ Yes | ✅ Yes |
| Password Direct Login | ❌ No | ❌ No | ✅ Yes |
| Gift Sq. Ft & UPI Escrow Checkout | ✅ Yes | ✅ Yes | ✅ Yes |
| Submit Marriage Registration Draft | ✅ Yes | ✅ Yes | ✅ Yes |
| View Unmasked Mobile Numbers | ❌ No | ❌ No | ✅ Yes |
| Review & Approve Marriage Submissions | ❌ No | ❌ No | ✅ Yes |
| Assign RERA Flat & Escrow Bank Accounts | ❌ No | ❌ No | ✅ Yes |
| Access Admin Moderation Console | ❌ No | ❌ No | ✅ Yes |
| Provision New Admin Users | ❌ No | ❌ No | ✅ Yes |

---

## Section 5: Persistent Session Blueprint ("Stay Logged In Until Sign Out")

### 5.1 Storage Protocol & Key Architecture
To guarantee that the user is **never logged out** across application closures, process kills, or system reboots, the client utilizes device-level persistent storage:

- **Storage Engine:** `SharedPreferences` (Native `NSUserDefaults` on iOS, `EncryptedSharedPreferences` on Android)
- **Master Storage Key:** `plot_their_future_auth_session_v1`
- **Data Payload:** Full serialized `AuthSession` JSON:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 604800,
    "user": {
      "id": 1,
      "name": "Sanvi Reddy",
      "mobileNumber": "+91 98480 12345",
      "role": "ROLE_ADMIN",
      "registered": true,
      "occupation": "Senior Software Architect"
    },
    "accessibleWeddings": ["sanvi-santosh"],
    "message": "OTP verified successfully"
  }
  ```

### 5.2 Cold-Start Restoration Flow
1. In `main.dart`, before `runApp()`, the app calls:
   ```dart
   WidgetsFlutterBinding.ensureInitialized();
   await ApiService.instance.init();
   ```
2. `ApiService.instance.init()` reads `plot_their_future_auth_session_v1` from storage.
3. If the stored token exists:
   - `_currentSession` is populated immediately.
   - `_authToken` is assigned.
   - `isAuthenticated` becomes `true`.
   - Every outgoing HTTP request automatically includes:
     `Authorization: Bearer <stored_jwt_token>`
4. The user seamlessly enters the app in an authenticated state with full profile details loaded.

### 5.3 Explicit Sign-Out Contract
A session is terminated **ONLY** when the user explicitly clicks the "Sign Out" or "Switch Account" action on `ProfileScreen`.
- Calling `ApiService.instance.clearSession()`:
  1. Sets in-memory `_currentSession = null` and `_authToken = null`.
  2. Executes `prefs.remove('plot_their_future_auth_session_v1')`.
  3. Displays confirmation toast and redirects to `HomeScreen` as a guest.
- At no other point (app termination, backgrounding, network error, or offline mode) is the session cleared.

