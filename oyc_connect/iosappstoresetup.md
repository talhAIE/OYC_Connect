# iOS App Store Setup & Deployment Guide

This guide provides a comprehensive step-by-step walkthrough for configuring, building, and submitting the **OYC Connect** app to the Apple App Store, based on standard practices and the App Store Connect interface.

---

## 📋 Prerequisites

Before you begin, ensure you have:
- ✅ **Apple Developer Program Enrollment** ($99/year active subscription).
  - Sign in at [developer.apple.com](https://developer.apple.com/).
- ✅ **Mac Computer** with the latest version of **Xcode** installed.
- ✅ **App Assets Ready**:
  - App Icon (1024x1024 px PNG, no transparency).
  - Screenshots for different iPhone sizes (e.g., 6.7" and 6.5" displays, up to 10 screenshots).
  - Support URL and optionally a Marketing URL.
- ✅ **App Metadata**: Description, Promotional Text, and Keywords.

---

## 🛠️ Step 1: Xcode Configuration

1. **Open the Project:** Open your Flutter project's iOS folder `ios/Runner.xcworkspace` in Xcode.
2. **Bundle Identifier:** In Xcode, select your project in the navigator, go to your target settings (`Runner`) -> **General**. Ensure the **Bundle Identifier** is correct (e.g., `com.oycconnect.app`).
3. **Version and Build:** Set the Version (e.g., `1.0.0`) and Build Number (e.g., `1`). These must match what you intend to submit.
4. **Signing & Capabilities:**
   - Go to the **Signing & Capabilities** tab.
   - Check **"Automatically manage signing"**.
   - Select your Development Team (your Apple Developer account).
5. **App Icons:** Ensure the `AppIcon` asset catalog in `Assets.xcassets` is fully populated.

---

## 🍏 Step 2: App Store Connect Setup

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/).
2. Navigate to **My Apps** and click the **+** button to create a **New App**.
3. Fill in the details:
   - **Platforms:** iOS
   - **Name:** OYC Connect
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select the App ID that matches your Xcode project.
   - **SKU:** A unique ID for your app (e.g., `OYC-CONNECT-001`).
   - **User Access:** Full Access.

---

## 📝 Step 3: Configure the Store Listing (1.0 Prepare for Submission)

Navigate to your app's version page in App Store Connect (e.g., **1.0 Prepare for Submission**) and provide the required metadata.

### 📱 Visual Assets
- **Screenshots:** Drag and drop up to 10 screenshots. Required dimensions depend on devices (for instance: 1242x2688px, 2688x1242px, 1284x2778px, or 2778x1284px). Make sure you highlight the Home, Community, and Classes tabs.

### ✍️ App Metadata
- **Promotional Text:** (Max 170 chars) Brief text that appears above your description. You can change this at any time without an app update.
- **Description:** (Max 4,000 chars) A clear and concise description of the app's features (Prayer times with countdowns, Jummah details, community events, push notifications).
- **Keywords:** (Max 100 chars) Comma-separated search terms that users might use to find the app (e.g., `musalla, prayer times, community, jummah, islam, melbourne, connect`).
- **Support URL:** Link to your help desk or support page (Required).
- **Marketing URL:** Link to your app's main website (Optional).

### ⚙️ General Information
- **Version:** Make sure this matches the version number set in Xcode (e.g., `1.0`).
- **Copyright:** Your copyright statement (e.g., `© 2026 1881 Musalla`).

---

## 🏗️ Step 4: Archiving and Uploading the Build

1. **Clean Project:** Open your terminal, navigate to your Flutter project root and run:
   ```bash
   flutter clean
   flutter pub get
   ```
2. **Build iOS Archive:**
   ```bash
   flutter build ipa --release
   ```
   *Alternatively via Xcode:* Select "Any iOS Device (arm64)" as the target at the top. Go to Product -> Archive from the top menu bar.
3. **Distribute App (If doing via Xcode):**
   - Once the archiving finishes, the Organizer window will pop up.
   - Click **Distribute App**.
   - Select **App Store Connect** -> **Upload**.
   - Follow the prompts to analyze and sign the app. Click **Upload**.
4. Allow 15-30 minutes for the build to process on App Store Connect once uploaded.

---

## 🔧 Step 5: Configure Build & App Review Information

Once your build finishes processing, go back to App Store Connect to link the build and provide review details:

### 📦 Build Section
- Scroll down to the **Build** section on the App Store version page.
- Choose your uploaded build.
- **Export Compliance:** You will be prompted regarding encryption. If your app uses standard HTTPS (like connecting to Supabase/Stripe), you typically indicate that you do not require special export compliance documentation, or that you qualify for standard exemptions.

### 🔍 App Review Information
This section communicates critical info to the Apple App Reviewer:
- **Sign-In Information:** Check the **"Sign-in required"** box.
  - Provide a **User name** and **Password** for a test account that the reviewer can log into. Ensure the account already has data populated so the reviewer isn't looking at empty screens.
- **Contact Information:** Fill out the First Name, Last Name, Phone Number, and Email of the person Apple should contact if there are issues during the review.
- **Notes:** (Optional but highly recommended) Provide any specific instructions on how to use the app or context. Mention that the app is for the 1881 Musalla congregation and list what features use background location (if any) or handle payments (e.g., Stripe donations).
- **Attachment:** If there are supplementary documents or a video walkthrough demonstrating features hard to replicate in review, attach them here.

### 🚀 App Store Version Release
Choose how you want the app to be released once approved:
- **Manually release this version:** You click release when you are ready.
- **Automatically release this version:** The app goes live on the App Store as soon as Apple approves it.
- **Automatically release after App Review, no earlier than [Date/Time]:** Scheduled release.

---

## 🔏 Step 6: Trust & Safety (App Privacy & Guidelines)

1. Navigate to **App Privacy** in the left sidebar under General settings.
2. Provide your **Privacy Policy URL**.
3. Complete the **Data privacy questionnaire**. Declare any data you collect (Email, Name, Phone Number, Payment Info via Stripe) and specify whether the data is linked to the user's identity or used for precise tracking.

---

## ✅ Step 7: Submit for Review

1. Review all the information to ensure completeness. Save all your pages.
2. At the top right of the page, click the blue **Add for Review** or **Submit for Review** button.
3. Your app's status will change from "Prepare for Submission" to **"Waiting for Review"**.

**Timeline:** Initial Apple app reviews usually take 24 to 48 hours. Watch your email. If rejected, Apple will explain why via the Resolution Center. You can then fix the issue and resubmit.

---

## 📱 TestFlight Testing (Optional but Recommended)

Before submitting for App Review, you can distribute your processed build to real devices using TestFlight.
1. Go to the **TestFlight** tab at the top.
2. Click **Internal Testing**, create a group and invite members using their Apple IDs.
3. Users receive an email with instructions on how to download the app directly via the TestFlight app.
4. If you want external testers, create an **External Testing** group. Note that external Beta testing requires a mini-beta-review from Apple before testers can access it.
