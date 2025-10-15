# TestFlight Prep Checklist and App Store Connect Steps

This document captures the steps to prepare the app for TestFlight, including Xcode project prep and the App Store Connect workflow.

## In Xcode: App metadata and project prep

1) Set your app’s identity and versioning
- Bundle Identifier: Ensure it’s unique and final for this app (Targets > Your App > Signing & Capabilities).
- Version and Build: Set a marketing version like 1.0.0 and start with build 1. Increment the build number for every upload (Targets > General > Version/Build).

2) App Name and Display Name
- App Name (App Store name) is set later in App Store Connect, but the on-device display name is in Info > “Bundle display name” or via the app target’s Info.plist. Keep it short.

3) App Icons and Launch screens
- App Icon: Add your app icon asset in the Asset Catalog under “AppIcon.” Make sure all required sizes are present (including 1024×1024 marketing icon uploaded later in App Store Connect).
- Launch screen: Use a Launch Screen storyboard/SwiftUI launch screen or a minimal config that matches Apple’s guidelines.

4) App Privacy and permissions
- Info.plist usage descriptions: If you’re using location, camera, photo library, Bluetooth, etc., add corresponding keys (e.g., NSLocationWhenInUseUsageDescription). For MapKit/location usage, include:
  - NSLocationWhenInUseUsageDescription (and/or Always if applicable)
- App Privacy Manifest (if needed): If you integrate SDKs that track users or require privacy disclosures, include a privacy manifest per Apple’s latest guidance.

5) Deployment and device support
- iOS Deployment Target: Choose the minimum iOS version you intend to support (Targets > General > Deployment Info).
- Device orientations and iPad support: Confirm orientations and iPad support settings are correct.

6) Signing & Certificates
- Automatic signing: Recommended. Ensure a valid “Apple Development” certificate for debug and “Apple Distribution” for release.
- Team: Make sure the correct Apple Developer Team is selected.

7) Build settings for Release
- Build Configuration: Ensure the “Release” configuration is selected for Archive.
- Remove any test flags or development-only settings from Release.

8) In-app purchases (if applicable)
- If you plan to add IAP later, you can skip for TestFlight unless you’re testing IAP now. If so, configure products in App Store Connect and implement StoreKit testing.

9) App Transport Security (ATS)
- If you load remote content (images for POIs, etc.), ensure ATS settings allow the domains you use (prefer HTTPS).

10) Localizations (optional but recommended)
- Add localized display name, descriptions, and Info.plist usage strings if supporting multiple languages.

11) Clean up debug-only code and logs
- Remove verbose print statements if they might clutter logs. It’s okay to keep some for TestFlight, but be mindful.
- Ensure no placeholder data or developer credentials ship in Release.

12) Accessibility and content checks
- Dynamic Type, VoiceOver labels, color contrast — basic checks improve tester experience and future App Review outcomes.

---

## Create an Archive and upload from Xcode

1) Select “Any iOS Device (arm64)” or a real device as the run destination.
2) Product > Archive.
3) In the Organizer, choose “Distribute App” > App Store Connect > Upload.
4) Ensure symbols are included and upload succeeds.
5) Wait for build processing (10–20 minutes typically).

---

## In App Store Connect: Configure your app and TestFlight

1) Create the App record (if not already)
- App Store Connect > My Apps > “+” > New App.
- Fill in App Name, primary language, Bundle ID, SKU.

2) App Information and metadata
- App Name and Subtitle.
- Privacy Policy URL (required in many cases).
- Primary Category (and optional secondary).
- Age Rating questionnaire.
- Copyright.

3) App Privacy
- Complete the Data Collection questionnaire (what you collect and why).
- Confirm third-party SDK practices if used.

4) Pricing and availability
- Choose Free or a price tier.
- Select regions.

5) Upload and process your build
- After Xcode upload, open the app > TestFlight tab.
- Answer Export Compliance (encryption) questions if prompted.

6) Internal testing (immediate)
- Add Internal Testers (team members in App Store Connect).
- Build available immediately after processing.

7) External testing (requires Beta App Review)
- Create an External Testing group.
- Add testers by email or enable a public link.
- Provide Beta App Review Information (demo credentials if needed, contact info, notes).
- Add “What to Test” notes and submit for Beta App Review.

8) Test details and builds
- Add per-build “What to Test” notes.
- TestFlight builds expire after 90 days.

---

## Assets checklist

- 1024×1024 App Store icon (no transparency).
- Screenshots for targeted devices (iPhone, iPad if applicable).
- Privacy policy URL.
- Support URL (optional but helpful).
- Marketing URL (optional).

---

## Common pitfalls

- Missing Info.plist usage descriptions (location, camera, etc.).
- Bundle ID mismatch between Xcode and App Store Connect.
- Not incrementing build number for each upload.
- Missing export compliance answers.
- Wrong team or signing identity in Xcode.

---

## App-specific notes (MapKit + POIs)

- If you request user location, include NSLocationWhenInUseUsageDescription with clear language.
- If you fetch images over the network, ensure ATS allows the domains (prefer HTTPS).
- If collecting analytics/crash data, disclose in App Privacy.

---

## What to Test (template)

- Core flow: Open the map, view POIs, toggle categories.
- Performance: Pan/zoom map responsiveness.
- Permissions: Location prompt flow (first launch), behavior when denied.
- Content: Verify sample POIs appear and details are correct.
- Stability: No crashes when switching filters rapidly.

---

## Quick reminder in code

Add a TODO where convenient:

```swift
// TODO: Resume TestFlight prep — see TESTFLIGHT_NOTES.md
