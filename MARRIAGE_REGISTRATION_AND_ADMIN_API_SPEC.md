# PlotTheirFuture — Marriage Registration, Dynamic Ceremonies, Admin Flat Assignment & Approval REST API Specification

- **Document Version:** `2.0.0-PROD`
- **Specification Status:** Canonical & Comprehensive
- **Base URL:** `http://localhost:8080/api/v1` (Production: `https://api.plottheirfuture.in/api/v1`)
- **Default Format:** `application/json`
- **Security Protocols:** JWT Bearer Authentication (`Authorization: Bearer <token>`) & Role-Based Access Control (RBAC: `ROLE_USER`, `ROLE_COUPLE`, `ROLE_ADMIN`)

---

## Table of Contents
1. [End-to-End System Architecture & Lifecycle](#1-end-to-end-system-architecture--lifecycle)
2. [Security & Authentication Specifications](#2-security--authentication-specifications)
3. [Section 1: User Authentication & Dynamic OTP (`/api/v1/auth`)](#section-1-user-authentication--dynamic-otp-apiv1auth)
   - [1.1 Request Dynamic OTP](#11-request-dynamic-otp)
   - [1.2 Verify Dynamic OTP & Issue JWT Session](#12-verify-dynamic-otp--issue-jwt-session)
   - [1.3 Casual Profile Setup / Skip Profile](#13-casual-profile-setup--skip-profile)
   - [1.4 Get Authenticated User Profile](#14-get-authenticated-user-profile)
4. [Section 2: Media & Wedding Card Upload (`/api/v1/media`)](#section-2-media--wedding-card-upload-apiv1media)
   - [2.1 Upload Media (Wedding Card, Ceremony Photo, Couple Banner)](#21-upload-media-wedding-card-ceremony-photo-couple-banner)
   - [2.2 Generate Pre-Signed S3 Upload URL](#22-generate-pre-signed-s3-upload-url)
5. [Section 3: Marriage Registration with Dynamic Functions (`/api/v1/marriages`)](#section-3-marriage-registration-with-dynamic-functions-apiv1marriages)
   - [3.1 Submit Marriage Registration (Couple / User Workflow)](#31-submit-marriage-registration-couple--user-workflow)
   - [3.2 List My Marriage Registrations](#32-list-my-marriage-registrations)
   - [3.3 Get Single Marriage Registration by ID (Owner View)](#33-get-single-marriage-registration-by-id-owner-view)
   - [3.4 Update / Edit Marriage Registration Draft](#34-update--edit-marriage-registration-draft)
   - [3.5 Get Public Shareable Link & Invite Metadata](#35-get-public-shareable-link--invite-metadata)
6. [Section 4: Admin Dashboard & Approval Workflow (`/api/v1/admin/marriages`)](#section-4-admin-dashboard--approval-workflow-apiv1adminmarriages)
   - [4.1 Admin Dashboard Metric Counts](#41-admin-dashboard-metric-counts)
   - [4.2 List All Submitted Marriage Registrations (With Filters)](#42-list-all-submitted-marriage-registrations-with-filters)
   - [4.3 Inspect Submission Full Details & Contact Numbers](#43-inspect-submission-full-details--contact-numbers)
   - [4.4 Assign Real Estate Flat & Approve Marriage](#44-assign-real-estate-flat--approve-marriage)
   - [4.5 Reject Marriage Submission](#45-reject-marriage-submission)
   - [4.6 Reconfigure / Modify Assigned Flat Details](#46-reconfigure--modify-assigned-flat-details)
7. [Section 5: Public Wedding Microsite & Guest Access (`/api/v1/weddings`)](#section-5-public-wedding-microsite--guest-access-apiv1weddings)
   - [5.1 Get Public Wedding Details by Slug](#51-get-public-wedding-details-by-slug)
   - [5.2 Get Chronological Ceremony Itinerary](#52-get-chronological-ceremony-itinerary)
   - [5.3 Get Interactive Floor Plan Grid & Zone Matrix](#53-get-interactive-floor-plan-grid--zone-matrix)
   - [5.4 WhatsApp / Social Share Preview Metadata](#54-whatsapp--social-share-preview-metadata)
8. [Data Dictionaries, Models & Enums](#8-data-dictionaries-models--enums)
9. [Standard Error Responses & HTTP Status Codes](#9-standard-error-responses--http-status-codes)

---

## 1. End-to-End System Architecture & Lifecycle

The following sequence illustrates the exact journey from couple registration to admin approval, flat assignment, and public link sharing:

```mermaid
sequenceDiagram
    autonumber
    actor Couple as Couple / User
    participant Auth as Auth & OTP Service (/auth)
    participant MarriageAPI as Marriage Registration (/marriages)
    actor Admin as Platform Admin
    participant AdminAPI as Admin Dashboard (/admin/marriages)
    participant PublicAPI as Wedding Microsite (/weddings)
    actor Guest as Wedding Guests & Family

    Note over Couple, Auth: Step 1: Authentication via Mobile & OTP
    Couple->>Auth: POST /api/v1/auth/request-otp (Phone: +919848012345)
    Auth-->>Couple: 200 OK (OTP dispatched via WhatsApp/SMS)
    Couple->>Auth: POST /api/v1/auth/verify-otp (OTP: 482910)
    Auth-->>Couple: 200 OK (JWT Bearer Token issued, Role: ROLE_USER)

    Note over Couple, MarriageAPI: Step 2: Marriage Registration with Dynamic Ceremonies
    Couple->>MarriageAPI: POST /api/v1/media/upload (Upload Wedding Card PDF/Image)
    MarriageAPI-->>Couple: 201 Created (weddingCardUrl)
    Couple->>MarriageAPI: POST /api/v1/marriages/register<br/>(Bride, Groom, Contacts, Card, Enabled Ceremonies: Haldi, Mehendi, Sangeet, Muhurtham, Reception)
    MarriageAPI-->>Couple: 201 Created (Status: PENDING_ADMIN_APPROVAL, registrationId: 104)

    Note over Admin, AdminAPI: Step 3: Admin Review, Contact Inspection & Flat Assignment
    Admin->>AdminAPI: GET /api/v1/admin/marriages?status=PENDING_ADMIN_APPROVAL
    AdminAPI-->>Admin: 200 OK (List with couple names, contact numbers, submission date)
    Admin->>AdminAPI: GET /api/v1/admin/marriages/104 (Full drill-down: Wedding Card, Venues, Timings, Photos)
    AdminAPI-->>Admin: 200 OK (Detailed dossier)
    Admin->>AdminAPI: POST /api/v1/admin/marriages/104/approve-and-assign-flat<br/>(Builder: My Home, Unit: 1402, 2 BHK, 1200 SFT, Rate: ₹4,500/SFT, RERA, Escrow Acc)
    AdminAPI-->>Admin: 200 OK (Status: APPROVED, Slug: rahul-sneha, ShareableLink generated)

    Note over Couple, PublicAPI: Step 4: Couple Receives Shareable Link
    Couple->>MarriageAPI: GET /api/v1/marriages/my-registrations
    MarriageAPI-->>Couple: 200 OK (Status: APPROVED, shareableUrl: https://plottheirfuture.in/weddings/rahul-sneha)
    Couple->>Guest: Shares link via WhatsApp, SMS & Social Media

    Note over Guest, PublicAPI: Step 5: Guests Open Microsite
    Guest->>PublicAPI: GET /api/v1/weddings/slug/rahul-sneha
    PublicAPI-->>Guest: 200 OK (Full Wedding Dossier: Couple Story, Itinerary with Google Maps, Flat 1402 Floor Plan Grid, Gift SqFt Checkout)
```

---

## 2. Security & Authentication Specifications

### 2.1 Authorization Header
Protected endpoints require an `Authorization` header containing the JWT token received from dynamic OTP verification:
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2.2 Role-Based Access Control (RBAC) Matrix
| Endpoint Group | Allowed Roles | Description |
| :--- | :--- | :--- |
| `/api/v1/auth/**` | Public (`ANONYMOUS`) | Login, OTP request, OTP verify |
| `/api/v1/weddings/slug/**` | Public (`ANONYMOUS`) | Public wedding microsites, ceremonies, blueprint |
| `/api/v1/marriages/register` | `ROLE_USER`, `ROLE_COUPLE` | Logged-in couple submitting their marriage registration |
| `/api/v1/marriages/my-registrations` | `ROLE_USER`, `ROLE_COUPLE` | Couple tracking their submissions and grabbing share link |
| `/api/v1/admin/**` | `ROLE_ADMIN` | Platform administrator reviewing dossiers, contact info, assigning flats, and approving |

---

## Section 1: User Authentication & Dynamic OTP (`/api/v1/auth`)

### 1.1 Request Dynamic OTP
Dispatches a secure 6-digit one-time password to the specified mobile phone number via WhatsApp / SMS gateway.

- **Method:** `POST`
- **Endpoint:** `/api/v1/auth/request-otp`
- **Access Level:** Public
- **Headers:** `Content-Type: application/json`

#### Request Body
```json
{
  "phone": "+919848012345",
  "channel": "WHATSAPP",
  "slug": "plot-their-future"
}
```

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `phone` | `string` | **Yes** | E.164 formatted 10-15 digit mobile number (e.g. `+919848012345`). |
| `channel` | `string` | No | Preferred OTP delivery channel: `"WHATSAPP"` (default) or `"SMS"`. |
| `slug` | `string` | No | Contextual campaign identifier (defaults to platform portal). |

#### Response: `200 OK`
```json
{
  "status": "SUCCESS",
  "message": "OTP dispatched successfully via WhatsApp",
  "phone": "+919848012345",
  "sessionHash": "KzkxOTg0ODAxMjM0NTo2NTQzMjE6MTY5...",
  "expiresIn": 300,
  "retryAfterSeconds": 30
}
```

---

### 1.2 Verify Dynamic OTP & Issue JWT Session
Validates the entered 6-digit OTP code against the issued session hash and returns an active JWT session.

- **Method:** `POST`
- **Endpoint:** `/api/v1/auth/verify-otp`
- **Access Level:** Public
- **Headers:** `Content-Type: application/json`

#### Request Body
```json
{
  "phone": "+919848012345",
  "otp": "482910"
}
```

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `phone` | `string` | **Yes** | Registered mobile number. |
| `otp` | `string` | **Yes** | 6-digit numeric string received by the user. |

#### Response: `200 OK` (Existing Registered User)
```json
{
  "token": "dGVzdC1qd3QtdG9rZW4tc2FudmktcmVkZHkt...",
  "tokenType": "Bearer",
  "expiresIn": 604800,
  "user": {
    "id": 101,
    "name": "Rahul Varma",
    "mobileNumber": "+919848012345",
    "role": "ROLE_USER",
    "registered": true,
    "occupation": "Senior Software Architect",
    "image": "https://images.unsplash.com/photo-1534528741775-53994a69daeb"
  },
  "isExistingUser": true,
  "hasActiveMarriageRegistration": false,
  "message": "OTP verified successfully. Welcome back!"
}
```

#### Response: `200 OK` (New / First-Time User)
```json
{
  "token": "dGVzdC1qd3QtdG9rZW4tbmV3LXVzZXIt...",
  "tokenType": "Bearer",
  "expiresIn": 604800,
  "user": {
    "id": 102,
    "name": "",
    "mobileNumber": "+919123456789",
    "role": "ROLE_USER",
    "registered": false,
    "occupation": null,
    "image": null
  },
  "isExistingUser": false,
  "hasActiveMarriageRegistration": false,
  "message": "OTP verified successfully. Please complete casual profile setup or skip."
}
```

---

### 1.3 Casual Profile Setup / Skip Profile
Allows newly authenticated users to quickly supply their name and occupation, or skip immediately to marriage registration.

- **Method:** `PUT`
- **Endpoint:** `/api/v1/users/{id}/profile`
- **Access Level:** Authenticated (`ROLE_USER`, `ROLE_COUPLE`)
- **Headers:** 
  - `Authorization: Bearer <token>`
  - `Content-Type: application/json`

#### Request Body (When User Enters Profile)
```json
{
  "name": "Rahul & Sneha",
  "occupation": "Tech Consultant & Doctor",
  "skip": false
}
```

#### Request Body (When User Taps "Skip for now")
```json
{
  "skip": true
}
```

#### Response: `200 OK`
```json
{
  "id": 102,
  "name": "Rahul & Sneha",
  "mobileNumber": "+919123456789",
  "role": "ROLE_USER",
  "registered": true,
  "occupation": "Tech Consultant & Doctor",
  "message": "Profile updated successfully."
}
```

---

### 1.4 Get Authenticated User Profile
Fetches the current session user details, active permissions, and submitted marriage references.

- **Method:** `GET`
- **Endpoint:** `/api/v1/auth/me`
- **Access Level:** Authenticated (`ROLE_USER`, `ROLE_COUPLE`, `ROLE_ADMIN`)
- **Headers:** `Authorization: Bearer <token>`

#### Response: `200 OK`
```json
{
  "id": 101,
  "name": "Rahul Varma",
  "mobileNumber": "+919848012345",
  "role": "ROLE_USER",
  "registered": true,
  "occupation": "Senior Software Architect",
  "activeMarriageRegistrationIds": [104],
  "associatedWeddings": []
}
```

---

## Section 2: Media & Wedding Card Upload (`/api/v1/media`)

### 2.1 Upload Media (Wedding Card, Ceremony Photo, Couple Banner)
Multipart file upload endpoint supporting image assets (`JPG`, `PNG`, `WEBP`) and PDF wedding invitation cards (`PDF`).

- **Method:** `POST`
- **Endpoint:** `/api/v1/media/upload`
- **Access Level:** Authenticated (`ROLE_USER`, `ROLE_COUPLE`, `ROLE_ADMIN`)
- **Headers:** 
  - `Authorization: Bearer <token>`
  - `Content-Type: multipart/form-data`

#### Multipart Form Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `file` | `Binary File` | **Yes** | Max size 15 MB. Valid types: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`. |
| `category` | `string` | **Yes** | `"WEDDING_CARD"`, `"CEREMONY_PHOTO"`, `"COUPLE_COVER"`, `"FLAT_BROCHURE"`. |
| `caption` | `string` | No | Optional human-readable description or title. |

#### Response: `201 Created`
```json
{
  "status": "SUCCESS",
  "mediaId": "med_88921048",
  "fileUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf",
  "thumbnailUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/thumbnails/rahul_sneha_invitation_thumb.jpg",
  "fileType": "application/pdf",
  "fileSizeBytes": 4194304,
  "uploadedAt": "2026-11-13T11:05:00Z"
}
```

---

### 2.2 Generate Pre-Signed S3 Upload URL
Allows direct browser/mobile client upload to AWS S3 / Google Cloud Storage bucket for large video feeds and high-resolution wedding cards.

- **Method:** `POST`
- **Endpoint:** `/api/v1/media/presigned-url`
- **Access Level:** Authenticated
- **Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

#### Request Body
```json
{
  "fileName": "wedding_invitation_card.pdf",
  "contentType": "application/pdf",
  "category": "WEDDING_CARD"
}
```

#### Response: `200 OK`
```json
{
  "uploadUrl": "https://s3.ap-south-1.amazonaws.com/plottheirfuture-media/weddings/...",
  "publicUrl": "https://cdn.plottheirfuture.in/weddings/wedding_invitation_card.pdf",
  "expiresInSeconds": 900
}
```

---

## Section 3: Marriage Registration with Dynamic Functions (`/api/v1/marriages`)

> **Crucial Rule:** The user must be authenticated (`ROLE_USER` or `ROLE_COUPLE`). This endpoint captures all required details about the marriage: Bride & Groom details, contact numbers, digital wedding card upload, couple cover photo, and a **dynamic list of enabled ceremonies/functions** (Haldi, Mehendi, Sangeet, Muhurtham, Reception, and arbitrary custom functions) with individual venues, map locations, timings, and photos.
>
> **Dynamic Custom Ceremony Support:** Users can configure unlimited custom functions (`ceremonyType: "CUSTOM"`), each accepting an arbitrary user-defined ceremony name (e.g., `"Pellikoduku"`, `"Pellikuthuru"`, `"Engagement Ceremony"`, `"Satyanarayana Vratham"`, `"Cocktail & DJ Night"`).
>
> **Direct Media Selection & Upload (Zero Raw URL Inputs):** All visual assets (Wedding Card PDF/JPG, Couple Cover Banner, Ceremony Photos) are uploaded directly via `/api/v1/media/upload` (Camera, Gallery, Files) or chosen from high-res curated templates, with the client sending resolved CDN URLs. Raw URL typing is eliminated from the user experience.

### 3.1 Submit Marriage Registration (Couple / User Workflow)
- **Method:** `POST`
- **Endpoint:** `/api/v1/marriages/register`
- **Access Level:** Authenticated (`ROLE_USER`)
- **Headers:** 
  - `Authorization: Bearer <token>`
  - `Content-Type: application/json`

#### Comprehensive Request Body
```json
{
  "bride": {
    "name": "Dr. Sneha Reddy",
    "mobileNumber": "+919876543210",
    "email": "sneha.reddy@example.com",
    "occupation": "Pediatrician"
  },
  "groom": {
    "name": "Rahul Varma",
    "mobileNumber": "+919848012345",
    "email": "rahul.varma@example.com",
    "occupation": "Senior Software Architect"
  },
  "primaryContactNumber": "+919848012345",
  "secondaryContactNumber": "+919876543210",
  "weddingDate": "2026-12-18",
  "city": "Hyderabad",
  "coupleStory": "We met during our university days in 2018. Over shared coffees and long architectural conversations, our dreams converged. As we step into our married life, your gift of a square foot lays the very foundation of our first home.",
  "coverImageUrl": "https://images.unsplash.com/photo-1583939003579-730e3918a45a",
  "weddingCardUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf",
  "weddingCardThumbnailUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/thumbnails/rahul_sneha_invitation_thumb.jpg",
  "targetBhk": "2 BHK",
  "preferredArea": "Gachibowli / Financial District, Hyderabad",
  "functions": [
    {
      "ceremonyType": "HALDI",
      "name": "Haldi & Mangala Snanam",
      "isEnabled": true,
      "eventDate": "2026-12-16",
      "startTime": "09:30:00",
      "endTime": "13:00:00",
      "venueName": "The Palm Meadows Lawns",
      "venueAddress": "Plot 12, Financial District, Nanakramguda, Hyderabad, Telangana 500032",
      "venueMapUrl": "https://maps.google.com/?q=The+Palm+Meadows+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c",
      "dressCode": "Yellow Traditional / Kurta & Kanjeevaram",
      "notes": "Followed by traditional lunch feast."
    },
    {
      "ceremonyType": "MEHENDI",
      "name": "Mehendi Ceremony",
      "isEnabled": true,
      "eventDate": "2026-12-16",
      "startTime": "17:00:00",
      "endTime": "21:30:00",
      "venueName": "The Palm Meadows Banquet Hall",
      "venueAddress": "Plot 12, Financial District, Nanakramguda, Hyderabad, Telangana 500032",
      "venueMapUrl": "https://maps.google.com/?q=The+Palm+Meadows+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1563241527-3004b7be0ffd",
      "dressCode": "Floral & Pastel Hues",
      "notes": "Live mehendi artists and musical night."
    },
    {
      "ceremonyType": "SANGEET",
      "name": "Musical Sangeet & Cocktails",
      "isEnabled": true,
      "eventDate": "2026-12-17",
      "startTime": "19:00:00",
      "endTime": "23:30:00",
      "venueName": "Grand Ballroom, ITC Kohenur",
      "venueAddress": "HITEC City, Madhapur, Hyderabad, Telangana 500081",
      "venueMapUrl": "https://maps.google.com/?q=ITC+Kohenur+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1545232979-fbf67554904c",
      "dressCode": "Glamorous Indo-Western / Tuxedos & Lehengas",
      "notes": "Dance performances by family & friends."
    },
    {
      "ceremonyType": "MUHURTHAM",
      "name": "Wedding Muhurtham",
      "isEnabled": true,
      "eventDate": "2026-12-18",
      "startTime": "09:45:00",
      "endTime": "13:00:00",
      "venueName": "N-Convention Centre, Hall A",
      "venueAddress": "Lane Opp Cultural Centre, Madhapur, Hyderabad, Telangana 500081",
      "venueMapUrl": "https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1519741497674-611481863552",
      "dressCode": "Pure Silk Traditional Attire (Dhoti / Pattu Saree)",
      "notes": "Sumuhurtham at 10:24 AM sharp. Followed by traditional Andhra Vindu."
    },
    {
      "ceremonyType": "RECEPTION",
      "name": "Grand Wedding Reception",
      "isEnabled": true,
      "eventDate": "2026-12-18",
      "startTime": "19:30:00",
      "endTime": "23:00:00",
      "venueName": "N-Convention Centre, Main Arena",
      "venueAddress": "Lane Opp Cultural Centre, Madhapur, Hyderabad, Telangana 500081",
      "venueMapUrl": "https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1511795409834-ef04bbd61622",
      "dressCode": "Formal Evening Wear / Black Tie",
      "notes": "Dinner and live orchestra."
    },
    {
      "ceremonyType": "CUSTOM",
      "name": "Post-Wedding Brunch & Farewell",
      "isEnabled": false,
      "eventDate": "2026-12-19",
      "startTime": "11:00:00",
      "endTime": "14:00:00",
      "venueName": "Private Family Farmhouse",
      "venueAddress": "Chevella Road, Hyderabad",
      "venueMapUrl": null,
      "ceremonyImageUrl": null,
      "dressCode": "Casual Sunday Brunch",
      "notes": "Disabled by couple for now."
    }
  ]
}
```

#### Key Payload Field Specifications
| Group | Field | Type | Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Couple Info** | `bride.name` | `string` | **Yes** | Full name of the bride. |
| | `bride.mobileNumber` | `string` | **Yes** | Bride's phone number for OTP/notifications. |
| | `groom.name` | `string` | **Yes** | Full name of the groom. |
| | `groom.mobileNumber` | `string` | **Yes** | Groom's phone number for coordination. |
| | `primaryContactNumber` | `string` | **Yes** | Host contact phone number shown in dashboard. |
| | `weddingDate` | `string (YYYY-MM-DD)` | **Yes** | Primary wedding event date. |
| | `city` | `string` | **Yes** | City of wedding celebration. |
| **Media** | `weddingCardUrl` | `string (URI)` | **Yes** | Uploaded invitation card (PDF or high-res image). |
| | `coverImageUrl` | `string (URI)` | No | Couple hero photograph for the microsite banner. |
| **Ceremonies** | `functions` | `array` | **Yes** | List of ceremonies. Only functions with `isEnabled: true` are scheduled and displayed. |
| | `functions[].ceremonyType` | `string (Enum)` | **Yes** | Enum: `HALDI`, `MEHENDI`, `SANGEET`, `ENGAGEMENT`, `PELLIKUTHURU`, `PELLIKODUKU`, `MUHURTHAM`, `RECEPTION`, `CUSTOM`. |
| | `functions[].isEnabled` | `boolean` | **Yes** | Toggle flag (`true` enables the function and captures its location/time/photo). |
| | `functions[].venueName` | `string` | If enabled | Name of banquet/hall/resort. |
| | `functions[].venueAddress`| `string` | If enabled | Complete postal address of the venue. |
| | `functions[].venueMapUrl` | `string (URI)` | No | Google Maps navigation pin URL. |
| | `functions[].startTime` | `string (HH:mm:ss)`| If enabled | Function start time. |
| | `functions[].endTime` | `string (HH:mm:ss)`| If enabled | Function end time. |
| | `functions[].ceremonyImageUrl`| `string (URI)` | No | Dedicated cover photo for the ceremony card. |

#### Response: `201 Created`
```json
{
  "status": "SUCCESS",
  "registrationId": 104,
  "referenceNumber": "REG-2026-HYD-0104",
  "coupleTitle": "Rahul & Sneha",
  "statusEnum": "PENDING_ADMIN_APPROVAL",
  "submittedAt": "2026-11-13T11:08:24Z",
  "enabledCeremonyCount": 5,
  "assignedFlat": null,
  "slug": null,
  "shareableUrl": null,
  "message": "Marriage registration submitted successfully! Our curation team is reviewing your dossier and will attach your verified flat unit shortly."
}
```

---

### 3.2 List My Marriage Registrations
Allows the logged-in user to see all their submissions, current approval statuses, and grab the share link once approved.

- **Method:** `GET`
- **Endpoint:** `/api/v1/marriages/my-registrations`
- **Access Level:** Authenticated (`ROLE_USER`, `ROLE_COUPLE`)
- **Headers:** `Authorization: Bearer <token>`

#### Response: `200 OK`
```json
[
  {
    "registrationId": 104,
    "referenceNumber": "REG-2026-HYD-0104",
    "brideName": "Dr. Sneha Reddy",
    "groomName": "Rahul Varma",
    "weddingDate": "2026-12-18",
    "status": "PENDING_ADMIN_APPROVAL",
    "weddingCardUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf",
    "enabledCeremonies": ["HALDI", "MEHENDI", "SANGEET", "MUHURTHAM", "RECEPTION"],
    "submittedAt": "2026-11-13T11:08:24Z",
    "assignedFlat": null,
    "shareableUrl": null,
    "qrCodeUrl": null
  }
]
```

---

### 3.3 Get Single Marriage Registration by ID (Owner View)
- **Method:** `GET`
- **Endpoint:** `/api/v1/marriages/{registrationId}`
- **Access Level:** Authenticated (Owner of registration or `ROLE_ADMIN`)
- **Headers:** `Authorization: Bearer <token>`

#### Response: `200 OK`
```json
{
  "registrationId": 104,
  "referenceNumber": "REG-2026-HYD-0104",
  "status": "PENDING_ADMIN_APPROVAL",
  "bride": {
    "name": "Dr. Sneha Reddy",
    "mobileNumber": "+919876543210",
    "email": "sneha.reddy@example.com"
  },
  "groom": {
    "name": "Rahul Varma",
    "mobileNumber": "+919848012345",
    "email": "rahul.varma@example.com"
  },
  "primaryContactNumber": "+919848012345",
  "weddingDate": "2026-12-18",
  "city": "Hyderabad",
  "weddingCardUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf",
  "functions": [
    {
      "id": 1,
      "ceremonyType": "HALDI",
      "name": "Haldi & Mangala Snanam",
      "isEnabled": true,
      "eventDate": "2026-12-16",
      "startTime": "09:30:00",
      "endTime": "13:00:00",
      "venueName": "The Palm Meadows Lawns",
      "venueAddress": "Plot 12, Financial District, Hyderabad",
      "venueMapUrl": "https://maps.google.com/?q=The+Palm+Meadows+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c"
    }
  ],
  "assignedFlat": null,
  "shareableUrl": null
}
```

---

### 3.4 Update / Edit Marriage Registration Draft
Allows couple to modify timings, venues, ceremony images, or replace wedding card prior to admin final approval.

- **Method:** `PUT`
- **Endpoint:** `/api/v1/marriages/{registrationId}`
- **Access Level:** Authenticated (`ROLE_USER` - Owner)
- **Headers:** `Authorization: Bearer <token>`, `Content-Type: application/json`

#### Response: `200 OK`
```json
{
  "status": "SUCCESS",
  "registrationId": 104,
  "message": "Marriage registration updated successfully."
}
```

---

### 3.5 Get Public Shareable Link & Invite Metadata
Once approved by Admin, the couple uses this endpoint to retrieve their official public microsite URL, QR code for printing on physical wedding cards, and automated WhatsApp invite message template.

- **Method:** `GET`
- **Endpoint:** `/api/v1/marriages/{registrationId}/share-info`
- **Access Level:** Authenticated (`ROLE_USER` - Owner)
- **Headers:** `Authorization: Bearer <token>`

#### Response: `200 OK` (When Status is `APPROVED` or `ACTIVE`)
```json
{
  "status": "APPROVED",
  "campaignSlug": "rahul-sneha",
  "shareableUrl": "https://plottheirfuture.in/weddings/rahul-sneha",
  "qrCodeImageUrl": "https://cdn.plottheirfuture.in/qrcodes/rahul-sneha-qr.png",
  "assignedFlatSummary": {
    "builderName": "My Home Constructions",
    "projectName": "My Home Bhooja",
    "unitNumber": "Tower 3, Flat 1402",
    "bhk": "2 BHK",
    "targetSft": 1200,
    "rateSft": 4500.0
  },
  "whatsAppShareTemplate": "Dear Family & Friends, We are delighted to invite you to our wedding celebrations! In lieu of boxed traditional gifts, we invite you to be part of our first home journey by gifting a square foot to our wedding flat at My Home Bhooja. Explore our full itinerary, venues, and gift a square foot here: https://plottheirfuture.in/weddings/rahul-sneha With love, Sneha & Rahul ❤️",
  "smsShareTemplate": "Sneha & Rahul wedding celebrations & First Home registry link: https://plottheirfuture.in/weddings/rahul-sneha"
}
```

#### Response: `409 Conflict` (When Registration is still `PENDING_ADMIN_APPROVAL`)
```json
{
  "status": 409,
  "error": "Conflict",
  "message": "Registration is currently under review. Flat allocation is in progress. Shareable link will be available immediately upon Admin approval.",
  "registrationStatus": "PENDING_ADMIN_APPROVAL"
}
```

---

## Section 4: Admin Dashboard & Approval Workflow (`/api/v1/admin/marriages`)

> **Administrative Role Requirement:** All endpoints under `/api/v1/admin/**` strictly enforce `ROLE_ADMIN` authorization. The admin can inspect all contact numbers, view uploaded wedding cards, review every ceremony, **assign a verified real estate flat unit**, configure the escrow bank account and RERA ID, and **approve the marriage**.

### 4.1 Admin Dashboard Metric Counts
Provides live metrics for the admin management console.

- **Method:** `GET`
- **Endpoint:** `/api/v1/admin/dashboard/stats`
- **Access Level:** Authenticated (`ROLE_ADMIN`)
- **Headers:** `Authorization: Bearer <admin-token>`

#### Response: `200 OK`
```json
{
  "totalRegistrations": 48,
  "pendingApprovalCount": 6,
  "approvedActiveCount": 38,
  "rejectedCount": 4,
  "totalTargetSft": 52800,
  "totalGiftedSft": 14920,
  "totalEscrowContributionsInr": 67140000.0
}
```

---

### 4.2 List All Submitted Marriage Registrations (With Filters)
Lists marriage registrations with search, status filters, and pagination. Displays primary & secondary contact numbers so admin can contact the family for physical verification.

- **Method:** `GET`
- **Endpoint:** `/api/v1/admin/marriages?status=PENDING_ADMIN_APPROVAL&page=0&size=20`
- **Access Level:** Authenticated (`ROLE_ADMIN`)
- **Headers:** `Authorization: Bearer <admin-token>`

#### Query Parameters
| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `status` | `string` | No | All | Filter by: `PENDING_ADMIN_APPROVAL`, `APPROVED`, `ACTIVE`, `REJECTED`. |
| `city` | `string` | No | All | Filter by city: `Hyderabad`, `Bangalore`, etc. |
| `query` | `string` | No | None | Search by couple name, phone number, or reference number. |
| `page` | `integer`| No | `0` | Zero-based page index. |
| `size` | `integer`| No | `20` | Page batch limit. |

#### Response: `200 OK`
```json
{
  "content": [
    {
      "registrationId": 104,
      "referenceNumber": "REG-2026-HYD-0104",
      "coupleTitle": "Rahul & Sneha",
      "bride": {
        "name": "Dr. Sneha Reddy",
        "mobileNumber": "+919876543210"
      },
      "groom": {
        "name": "Rahul Varma",
        "mobileNumber": "+919848012345"
      },
      "primaryContactNumber": "+919848012345",
      "secondaryContactNumber": "+919876543210",
      "weddingDate": "2026-12-18",
      "city": "Hyderabad",
      "status": "PENDING_ADMIN_APPROVAL",
      "weddingCardUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf",
      "enabledCeremoniesCount": 5,
      "submittedAt": "2026-11-13T11:08:24Z",
      "preferredBhk": "2 BHK",
      "assignedFlat": null
    }
  ],
  "page": 0,
  "size": 20,
  "totalElements": 1,
  "totalPages": 1
}
```

---

### 4.3 Inspect Submission Full Details & Contact Numbers
Drills down into the complete registration dossier, allowing the admin to inspect all bride/groom contact details, download the wedding card PDF, verify all function venues, and inspect timings.

- **Method:** `GET`
- **Endpoint:** `/api/v1/admin/marriages/{registrationId}`
- **Access Level:** Authenticated (`ROLE_ADMIN`)
- **Headers:** `Authorization: Bearer <admin-token>`

#### Response: `200 OK`
```json
{
  "registrationId": 104,
  "referenceNumber": "REG-2026-HYD-0104",
  "status": "PENDING_ADMIN_APPROVAL",
  "submittedAt": "2026-11-13T11:08:24Z",
  "userId": 101,
  "bride": {
    "name": "Dr. Sneha Reddy",
    "mobileNumber": "+919876543210",
    "email": "sneha.reddy@example.com",
    "occupation": "Pediatrician"
  },
  "groom": {
    "name": "Rahul Varma",
    "mobileNumber": "+919848012345",
    "email": "rahul.varma@example.com",
    "occupation": "Senior Software Architect"
  },
  "contactDossier": {
    "primaryMobile": "+919848012345",
    "secondaryMobile": "+919876543210",
    "verifiedViaOtp": true,
    "relationship": "GROOM"
  },
  "weddingCard": {
    "fileUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf",
    "fileType": "application/pdf",
    "thumbnailUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/thumbnails/rahul_sneha_invitation_thumb.jpg"
  },
  "coupleStory": "We met during our university days in 2018...",
  "coverImageUrl": "https://images.unsplash.com/photo-1583939003579-730e3918a45a",
  "enabledCeremonyList": [
    {
      "ceremonyId": 1,
      "ceremonyType": "HALDI",
      "name": "Haldi & Mangala Snanam",
      "eventDate": "2026-12-16",
      "timeSlot": "09:30:00 - 13:00:00",
      "venueName": "The Palm Meadows Lawns",
      "venueAddress": "Plot 12, Financial District, Hyderabad",
      "venueMapUrl": "https://maps.google.com/?q=The+Palm+Meadows+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c",
      "dressCode": "Yellow Traditional / Kurta & Kanjeevaram"
    },
    {
      "ceremonyId": 2,
      "ceremonyType": "MEHENDI",
      "name": "Mehendi Ceremony",
      "eventDate": "2026-12-16",
      "timeSlot": "17:00:00 - 21:30:00",
      "venueName": "The Palm Meadows Banquet Hall",
      "venueAddress": "Plot 12, Financial District, Hyderabad",
      "venueMapUrl": "https://maps.google.com/?q=The+Palm+Meadows+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1563241527-3004b7be0ffd"
    },
    {
      "ceremonyId": 3,
      "ceremonyType": "SANGEET",
      "name": "Musical Sangeet & Cocktails",
      "eventDate": "2026-12-17",
      "timeSlot": "19:00:00 - 23:30:00",
      "venueName": "Grand Ballroom, ITC Kohenur",
      "venueAddress": "HITEC City, Madhapur, Hyderabad",
      "venueMapUrl": "https://maps.google.com/?q=ITC+Kohenur+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1545232979-fbf67554904c"
    },
    {
      "ceremonyId": 4,
      "ceremonyType": "MUHURTHAM",
      "name": "Wedding Muhurtham",
      "eventDate": "2026-12-18",
      "timeSlot": "09:45:00 - 13:00:00",
      "venueName": "N-Convention Centre, Hall A",
      "venueAddress": "Lane Opp Cultural Centre, Madhapur, Hyderabad",
      "venueMapUrl": "https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1519741497674-611481863552"
    },
    {
      "ceremonyId": 5,
      "ceremonyType": "RECEPTION",
      "name": "Grand Wedding Reception",
      "eventDate": "2026-12-18",
      "timeSlot": "19:30:00 - 23:00:00",
      "venueName": "N-Convention Centre, Main Arena",
      "venueAddress": "Lane Opp Cultural Centre, Madhapur, Hyderabad",
      "venueMapUrl": "https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad",
      "ceremonyImageUrl": "https://images.unsplash.com/photo-1511795409834-ef04bbd61622"
    }
  ],
  "assignedFlat": null
}
```

---

### 4.4 Assign Real Estate Flat & Approve Marriage
**The Core Action:** The Admin approves the marriage and attaches a verified real estate flat unit. The system generates the unique URL slug (`/weddings/{slug}`), generates the interactive floor plan zone matrix, and marks the campaign `APPROVED` and `ACTIVE`.

- **Method:** `POST`
- **Endpoint:** `/api/v1/admin/marriages/{registrationId}/approve-and-assign-flat`
- **Access Level:** Authenticated (`ROLE_ADMIN`)
- **Headers:** 
  - `Authorization: Bearer <admin-token>`
  - `Content-Type: application/json`

#### Request Body
```json
{
  "slug": "rahul-sneha",
  "builderName": "My Home Constructions",
  "projectName": "My Home Bhooja",
  "tower": "Tower 3 (Aspen)",
  "unitNumber": "Flat 1402 (14th Floor)",
  "configuration": "2 BHK",
  "targetSft": 1200,
  "rateSft": 4500.0,
  "builderReraId": "PRM/KA/RERA/1251/310/PR/210312/004018",
  "reraProjectUrl": "https://rera.telangana.gov.in/projects/PRM-1251-004018",
  "escrowBank": {
    "bankName": "HDFC Bank Ltd",
    "branchName": "Gachibowli Financial District Branch",
    "accountHolder": "PLOT THEIR FUTURE ESCROW - RAHUL & SNEHA WEDDING",
    "accountNumber": "ESC-HDFC-99201948102",
    "ifscCode": "HDFC0000456",
    "upiVpa": "plottheirfuture.rahul.sneha@hdfcbank"
  },
  "floorPlanTemplate": "PREMIUM_2BHK_1200SFT",
  "videoStreamUrl": "https://cdn.plottheirfuture.in/stream/rahul-sneha/master.m3u8",
  "adminNotes": "Physical verification completed with groom Rahul Varma on Nov 13. Builder agreement signed. Escrow account verified."
}
```

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `slug` | `string` | **Yes** | Lowercase URL slug (e.g. `rahul-sneha`). Becomes `https://plottheirfuture.in/weddings/{slug}`. |
| `builderName` | `string` | **Yes** | Reputed builder/developer name. |
| `projectName` | `string` | **Yes** | Name of gated community/project. |
| `unitNumber` | `string` | **Yes** | Flat number (e.g. `Flat 1402, 14th Floor`). |
| `configuration` | `string` | **Yes** | `"2 BHK"`, `"3 BHK"`, `"4 BHK"`. |
| `targetSft` | `integer`| **Yes** | Total saleable area in Square Feet (e.g. `1200`). |
| `rateSft` | `number` | **Yes** | Rate in INR per SqFt (e.g. `4500.0`). |
| `builderReraId` | `string` | **Yes** | Valid state RERA certification number. |
| `escrowBank` | `object` | **Yes** | RERA-compliant dedicated escrow bank account structure. |
| `floorPlanTemplate`| `string`| No | Standard blueprint template to auto-seed zones and tiles. |
| `videoStreamUrl` | `string` | No | Master `.m3u8` HLS live video feed for remote guests. |

#### Response: `200 OK`
```json
{
  "status": "SUCCESS",
  "registrationId": 104,
  "weddingId": 12,
  "slug": "rahul-sneha",
  "statusEnum": "ACTIVE",
  "shareableUrl": "https://plottheirfuture.in/weddings/rahul-sneha",
  "assignedFlat": {
    "builderName": "My Home Constructions",
    "projectName": "My Home Bhooja",
    "unitNumber": "Flat 1402 (14th Floor)",
    "configuration": "2 BHK",
    "targetSft": 1200,
    "rateSft": 4500.0,
    "totalTargetAmountInr": 5400000.0,
    "builderReraId": "PRM/KA/RERA/1251/310/PR/210312/004018",
    "escrowAccountNumber": "ESC-HDFC-99201948102"
  },
  "zonesGenerated": [
    {"name": "Living & Dining Room", "allocatedSft": 450, "zoneId": 1},
    {"name": "Master Bedroom", "allocatedSft": 350, "zoneId": 2},
    {"name": "Guest Bedroom", "allocatedSft": 200, "zoneId": 3},
    {"name": "Modular Kitchen", "allocatedSft": 120, "zoneId": 4},
    {"name": "Sunrise Balcony", "allocatedSft": 80, "zoneId": 5}
  ],
  "totalTilesGenerated": 1200,
  "approvedAt": "2026-11-13T11:15:30Z",
  "approvedByAdminId": 1,
  "message": "Marriage registration approved! Flat 1402 has been successfully linked and floor plan matrix initialized. The couple can now share their link with all wedding guests."
}
```

---

### 4.5 Reject Marriage Submission
Rejects invalid, duplicate, or unverified submissions with a clear reason transmitted to the user.

- **Method:** `POST`
- **Endpoint:** `/api/v1/admin/marriages/{registrationId}/reject`
- **Access Level:** Authenticated (`ROLE_ADMIN`)
- **Headers:** `Authorization: Bearer <admin-token>`, `Content-Type: application/json`

#### Request Body
```json
{
  "rejectionReason": "Unable to verify bride and groom contact numbers. Wedding card provided does not match wedding date."
}
```

#### Response: `200 OK`
```json
{
  "status": "REJECTED",
  "registrationId": 104,
  "rejectionReason": "Unable to verify bride and groom contact numbers...",
  "rejectedAt": "2026-11-13T11:16:00Z"
}
```

---

### 4.6 Reconfigure / Modify Assigned Flat Details
Allows the admin to adjust rates, update unit numbers, or change escrow bank details post-approval.

- **Method:** `PUT`
- **Endpoint:** `/api/v1/admin/marriages/{registrationId}/flat`
- **Access Level:** Authenticated (`ROLE_ADMIN`)
- **Headers:** `Authorization: Bearer <admin-token>`, `Content-Type: application/json`

#### Response: `200 OK`
```json
{
  "status": "SUCCESS",
  "registrationId": 104,
  "message": "Flat configuration updated successfully."
}
```

---

## Section 5: Public Wedding Microsite & Guest Access (`/api/v1/weddings`)

> **Public Access:** These endpoints require **no authentication**. When a guest clicks the share link (`https://plottheirfuture.in/weddings/rahul-sneha`), the client fetches these endpoints using the `slug`. It loads all marriage details, the complete function itinerary with Google Maps pins, the assigned flat blueprint, and the escrow gifting matrix.

### 5.1 Get Public Wedding Details by Slug
- **Method:** `GET`
- **Endpoint:** `/api/v1/weddings/slug/{slug}` (e.g. `/api/v1/weddings/slug/rahul-sneha`)
- **Access Level:** Public (`*`)
- **Headers:** `Accept: application/json`

#### Response: `200 OK`
```json
{
  "id": 12,
  "slug": "rahul-sneha",
  "status": "ACTIVE",
  "bride": {
    "name": "Dr. Sneha Reddy",
    "occupation": "Pediatrician"
  },
  "groom": {
    "name": "Rahul Varma",
    "occupation": "Senior Software Architect"
  },
  "coupleStory": "We met during our university days in 2018. Over shared coffees and long architectural conversations...",
  "weddingDate": "2026-12-18",
  "city": "Hyderabad",
  "coverImageUrl": "https://images.unsplash.com/photo-1583939003579-730e3918a45a",
  "weddingCardUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/rahul_sneha_invitation.pdf",
  "weddingCardThumbnailUrl": "https://cdn.plottheirfuture.in/uploads/wedding-cards/thumbnails/rahul_sneha_invitation_thumb.jpg",
  "videoStreamUrl": "https://cdn.plottheirfuture.in/stream/rahul-sneha/master.m3u8",
  "flat": {
    "builderName": "My Home Constructions",
    "projectName": "My Home Bhooja",
    "unitNumber": "Flat 1402 (14th Floor)",
    "configuration": "2 BHK",
    "targetSft": 1200,
    "rateSft": 4500.0,
    "totalTargetAmountInr": 5400000.0,
    "fundedSft": 340,
    "fundedPercentage": 28.33,
    "builderReraId": "PRM/KA/RERA/1251/310/PR/210312/004018",
    "reraProjectUrl": "https://rera.telangana.gov.in/projects/PRM-1251-004018",
    "escrowBank": {
      "bankName": "HDFC Bank Ltd",
      "accountNumber": "ESC-HDFC-99201948102",
      "ifscCode": "HDFC0000456",
      "upiVpa": "plottheirfuture.rahul.sneha@hdfcbank"
    }
  },
  "ceremonySummary": [
    {"name": "Haldi & Mangala Snanam", "date": "2026-12-16", "time": "09:30 AM"},
    {"name": "Mehendi Ceremony", "date": "2026-12-16", "time": "05:00 PM"},
    {"name": "Musical Sangeet", "date": "2026-12-17", "time": "07:00 PM"},
    {"name": "Wedding Muhurtham", "date": "2026-12-18", "time": "09:45 AM"},
    {"name": "Grand Reception", "date": "2026-12-18", "time": "07:30 PM"}
  ]
}
```

---

### 5.2 Get Chronological Ceremony Itinerary
Fetches all enabled functions sorted chronologically by date and start time with full venue addresses and Google Maps direction links.

- **Method:** `GET`
- **Endpoint:** `/api/v1/ceremonies/wedding/{weddingId}` (or `/api/v1/weddings/slug/{slug}/ceremonies`)
- **Access Level:** Public (`*`)

#### Response: `200 OK`
```json
[
  {
    "id": 1,
    "ceremonyType": "HALDI",
    "name": "Haldi & Mangala Snanam",
    "eventDate": "2026-12-16",
    "startTime": "09:30:00",
    "endTime": "13:00:00",
    "venueName": "The Palm Meadows Lawns",
    "venueAddress": "Plot 12, Financial District, Nanakramguda, Hyderabad, Telangana 500032",
    "venueMapUrl": "https://maps.google.com/?q=The+Palm+Meadows+Hyderabad",
    "ceremonyImageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c",
    "dressCode": "Yellow Traditional / Kurta & Kanjeevaram",
    "notes": "Followed by traditional lunch feast."
  },
  {
    "id": 2,
    "ceremonyType": "MEHENDI",
    "name": "Mehendi Ceremony",
    "eventDate": "2026-12-16",
    "startTime": "17:00:00",
    "endTime": "21:30:00",
    "venueName": "The Palm Meadows Banquet Hall",
    "venueAddress": "Plot 12, Financial District, Nanakramguda, Hyderabad, Telangana 500032",
    "venueMapUrl": "https://maps.google.com/?q=The+Palm+Meadows+Hyderabad",
    "ceremonyImageUrl": "https://images.unsplash.com/photo-1563241527-3004b7be0ffd",
    "dressCode": "Floral & Pastel Hues",
    "notes": "Live mehendi artists and musical night."
  },
  {
    "id": 3,
    "ceremonyType": "SANGEET",
    "name": "Musical Sangeet & Cocktails",
    "eventDate": "2026-12-17",
    "startTime": "19:00:00",
    "endTime": "23:30:00",
    "venueName": "Grand Ballroom, ITC Kohenur",
    "venueAddress": "HITEC City, Madhapur, Hyderabad, Telangana 500081",
    "venueMapUrl": "https://maps.google.com/?q=ITC+Kohenur+Hyderabad",
    "ceremonyImageUrl": "https://images.unsplash.com/photo-1545232979-fbf67554904c",
    "dressCode": "Glamorous Indo-Western / Tuxedos & Lehengas",
    "notes": "Dance performances by family & friends."
  },
  {
    "id": 4,
    "ceremonyType": "MUHURTHAM",
    "name": "Wedding Muhurtham",
    "eventDate": "2026-12-18",
    "startTime": "09:45:00",
    "endTime": "13:00:00",
    "venueName": "N-Convention Centre, Hall A",
    "venueAddress": "Lane Opp Cultural Centre, Madhapur, Hyderabad, Telangana 500081",
    "venueMapUrl": "https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad",
    "ceremonyImageUrl": "https://images.unsplash.com/photo-1519741497674-611481863552",
    "dressCode": "Pure Silk Traditional Attire (Dhoti / Pattu Saree)",
    "notes": "Sumuhurtham at 10:24 AM sharp. Followed by traditional Andhra Vindu."
  },
  {
    "id": 5,
    "ceremonyType": "RECEPTION",
    "name": "Grand Wedding Reception",
    "eventDate": "2026-12-18",
    "startTime": "19:30:00",
    "endTime": "23:00:00",
    "venueName": "N-Convention Centre, Main Arena",
    "venueAddress": "Lane Opp Cultural Centre, Madhapur, Hyderabad, Telangana 500081",
    "venueMapUrl": "https://maps.google.com/?q=N-Convention+Madhapur+Hyderabad",
    "ceremonyImageUrl": "https://images.unsplash.com/photo-1511795409834-ef04bbd61622",
    "dressCode": "Formal Evening Wear / Black Tie",
    "notes": "Dinner and live orchestra."
  }
]
```

---

### 5.3 Get Interactive Floor Plan Grid & Zone Matrix
Returns the blueprint zones (Living Room, Master Bedroom, etc.) and individual SqFt tiles with gift states (`AVAILABLE`, `LOCKED_IN_CART`, `GIFTED`).

- **Method:** `GET`
- **Endpoint:** `/api/v1/floor-plan-zones/wedding/{weddingId}`
- **Access Level:** Public (`*`)

#### Response: `200 OK`
```json
[
  {
    "id": 1,
    "weddingId": 12,
    "name": "Living & Dining Room",
    "colorHex": "#D4AF37",
    "allocatedSft": 450,
    "fundedSft": 180,
    "ratePerSft": 4500.0,
    "tiles": [
      {
        "id": 1001,
        "zoneId": 1,
        "tileNumber": 1,
        "status": "GIFTED",
        "contributorName": "Anand & Priya Reddy",
        "blessing": "May this living room always echo with joy and laughter!"
      },
      {
        "id": 1002,
        "zoneId": 1,
        "tileNumber": 2,
        "status": "AVAILABLE",
        "contributorName": null,
        "blessing": null
      }
    ]
  }
]
```

---

### 5.4 WhatsApp / Social Share Preview Metadata
Returns Open Graph and JSON-LD structured data for rich previews when couples or guests share the link on WhatsApp, iMessage, Twitter, and Facebook.

- **Method:** `GET`
- **Endpoint:** `/api/v1/weddings/slug/{slug}/share-preview`
- **Access Level:** Public (`*`)

#### Response: `200 OK`
```json
{
  "title": "Sneha & Rahul's Wedding Registry • Flat 1402, My Home Bhooja",
  "description": "Celebrate our wedding! In lieu of boxed gifts, help us lay the bricks for our first home. Explore our ceremony itinerary & gift a square foot into our verified escrow.",
  "ogImage": "https://cdn.plottheirfuture.in/previews/rahul-sneha-share-banner.jpg",
  "url": "https://plottheirfuture.in/weddings/rahul-sneha",
  "weddingDateFormatted": "December 18, 2026",
  "city": "Hyderabad",
  "targetSft": 1200,
  "fundedSft": 340,
  "builder": "My Home Constructions"
}
```

---

## 8. Data Dictionaries, Models & Enums

### 8.1 Marriage Registration Status Enum (`MarriageRegistrationStatus`)
```java
public enum MarriageRegistrationStatus {
    DRAFT,                    // User created, not yet submitted
    PENDING_ADMIN_APPROVAL,   // Submitted with wedding card & functions; waiting for admin review
    UNDER_REVIEW,             // Admin opened dossier, verification in progress
    APPROVED,                 // Admin attached flat & approved; ready to share
    ACTIVE,                   // Publicly live, accepting SqFt contributions
    COMPLETED,                // 100% target SqFt funded or wedding concluded
    REJECTED                  // Admin rejected submission with specified reason
}
```

### 8.2 Ceremony Type Enum (`CeremonyType`)
```java
public enum CeremonyType {
    HALDI,                    // Haldi / Mangala Snanam
    MEHENDI,                  // Mehendi henna function
    SANGEET,                  // Musical dance night
    ENGAGEMENT,               // Ring exchange / Nischithartham
    PELLIKUTHURU,             // Traditional bride blessing
    PELLIKODUKU,              // Traditional groom blessing
    MUHURTHAM,                // Core wedding muhurtham
    RECEPTION,                // Formal evening reception
    VRATHAM,                  // Pre-wedding religious ceremony (e.g. Satyanarayana Vratham)
    CUSTOM                    // User-defined ceremony title
}
```

### 8.3 Flat Configuration Enum (`FlatConfiguration`)
```java
public enum FlatConfiguration {
    STUDIO,
    ONE_BHK,
    TWO_BHK,
    TWO_POINT_FIVE_BHK,
    THREE_BHK,
    FOUR_BHK_LUXURY,
    VILLA
}
```

### 8.4 User Roles (`UserRole`)
```java
public enum UserRole {
    ROLE_GUEST,               // Anonymous guest or OTP verified guest
    ROLE_USER,                // Registered user
    ROLE_COUPLE,              // Bride or Groom owning a marriage campaign
    ROLE_ADMIN                // Platform super-administrator
}
```

---

## 9. Standard Error Responses & HTTP Status Codes

All errors conform to the RFC 7807 Problem Details specification:

```json
{
  "timestamp": "2026-11-13T11:20:00Z",
  "status": 400,
  "error": "Bad Request",
  "code": "INVALID_CEREMONY_DATA",
  "message": "When ceremony 'HALDI' is enabled, 'venueName', 'eventDate', and 'startTime' are strictly required.",
  "path": "/api/v1/marriages/register"
}
```

### HTTP Status Code Reference
| Code | Meaning | Typical Usage |
| :--- | :--- | :--- |
| `200 OK` | Success | Successful retrieval, login verification, or admin approval. |
| `201 Created` | Resource Created | Registration submitted or media uploaded. |
| `400 Bad Request` | Validation Failure | Invalid phone format, missing ceremony details, or past event date. |
| `401 Unauthorized` | Missing / Invalid Token | Missing Bearer token or expired session. |
| `403 Forbidden` | Access Denied | Non-admin user attempting to access `/api/v1/admin/**`. |
| `404 Not Found` | Not Found | Registration ID or wedding slug does not exist. |
| `409 Conflict` | State Conflict | Requesting shareable link prior to Admin flat approval. |
| `500 Server Error` | Internal Error | SMS gateway timeout or database persistence error. |

---

*Specification Document maintained by the PlotTheirFuture Engineering Team. For questions or upgrades, contact `platform-engineering@plottheirfuture.in`.*

