# PlotTheirFuture — Wedding Registry & Real Estate Crowdfunding Platform

PlotTheirFuture transforms traditional boxed wedding gifts into a real estate asset: a down payment on the couple's first home. Guests can gift individual square feet via RERA-compliant escrow bank checkout, explore interactive floor plan blueprints, and view live ceremony broadcasts.

## API Documentation & Architecture Specifications

- **[Marriage Registration, Dynamic Ceremonies & Admin Flat Approval API Specification](file:///Users/satyakarthikvelivela/Documents/Works/plot_their_future/MARRIAGE_REGISTRATION_AND_ADMIN_API_SPEC.md)**
  - Mobile & Dynamic OTP Login & Verification (`/api/v1/auth`)
  - Media & Wedding Card Upload (`/api/v1/media`)
  - User / Couple Marriage Registration with dynamic enabled ceremonies (Haldi, Mehendi, Sangeet, Muhurtham, Reception) (`/api/v1/marriages/register`)
  - Admin Dashboard for contact inspection, flat unit assignment & approval (`/api/v1/admin/marriages`)
  - Public Wedding Microsite by Slug (`/api/v1/weddings/slug/{slug}`)

---

## Getting Started

This project is built with Flutter and Spring Boot REST APIs.


A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
