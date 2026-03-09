# Google Play Console Deployment Guide

Complete step-by-step guide to deploy your OYC Connect app to Google Play Store.

---

## 📋 Prerequisites

Before you begin, ensure you have:

- ✅ **Google Play Console Account** ($25 one-time registration fee)
  - Sign up at: https://play.google.com/console/signup
  - Complete developer account registration
  
- ✅ **AAB file built** (`app-release.aab`)
  - Location: `build\app\outputs\bundle\release\app-release.aab`
  - Built with release signing key

- ✅ **App Assets Ready:**
  - App icon (512x512 PNG, 32-bit)
  - Feature graphic (1024x500 PNG)
  - Screenshots (at least 2, max 8 per device type)
  - Short description (80 characters max)
  - Full description (4000 characters max)

---

## 🚀 Step-by-Step Deployment Process

### Step 1: Access Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google account
3. Click **"Create app"** (if this is your first app) or select existing app

---

### Step 2: Create New App (First Time Only)

1. **App name:** `OYC Connect` (or your preferred name)
2. **Default language:** English (or your primary language)
3. **App or game:** Select **App**
4. **Free or paid:** Select **Free** (or Paid if applicable)
5. Click **"Create app"**

---

### Step 3: Complete Store Listing

Navigate to **"Store presence" → "Main store listing"**

#### Required Information:

1. **App name:** `OYC Connect`
2. **Short description** (80 chars max):
   ```
   Connect with your community - prayer times, events, classes, and donations.
   ```

3. **Full description** (4000 chars max):
   ```
   OYC Connect is your all-in-one community app for the 1881 Musalla.

   Features:
   • Real-time prayer times with countdown
   • Jummah prayer schedules and khutbah details
   • Community events and announcements
   • Weekly and Quran class schedules
   • Secure donation/payment system
   • Push notifications for important updates

   Stay connected with your community, never miss a prayer, and stay informed about events and classes.
   ```

4. **App icon:** Upload 512x512 PNG (32-bit, no transparency)
5. **Feature graphic:** Upload 1024x500 PNG
6. **Screenshots:** Upload at least 2 screenshots (phone, tablet if applicable)
   - Recommended: Home screen, Prayer times, Community, Donation page

7. **Category:** Select **Lifestyle** or **Social**
8. **Contact details:**
   - Email: Your support email
   - Phone: (Optional)
   - Website: Your website URL

9. Click **"Save"** at the bottom

---

### Step 4: Set Up Content Rating

Navigate to **"Policy" → "App content"**

1. Click **"Start questionnaire"**
2. Answer questions about your app:
   - **Category:** Lifestyle/Social
   - **Does your app contain user-generated content?** Usually **No**
   - **Does your app allow users to make payments?** **Yes** (for donations)
   - **Does your app contain ads?** Usually **No**
   - Continue answering all questions
3. Submit for rating (usually takes a few hours)

---

### Step 5: Set Up Pricing and Distribution

Navigate to **"Monetization setup" → "Monetization"**

1. **Free app:** Select **Free** (or set price if paid)
2. **Countries/regions:** Select all countries or specific regions
3. Click **"Save"**

---

### Step 6: Upload Your AAB File

Navigate to **"Production" → "Releases"** (or **"Testing" → "Internal testing"** for beta)

#### Option A: Internal Testing (Recommended First)

1. Click **"Create new release"**
2. **Release name:** `1.0.0` (or your version)
3. **Release notes:** 
   ```
   Initial release of OYC Connect
   - Prayer times with real-time updates
   - Community events and announcements
   - Class schedules
   - Secure donation system
   ```
4. Click **"Upload"** under "App bundles and APKs"
5. Select your AAB file: `build\app\outputs\bundle\release\app-release.aab`
6. Wait for upload to complete (may take a few minutes)
7. Review the release
8. Click **"Save"** then **"Review release"**
9. Review all information and click **"Start rollout to Internal testing"**

#### Option B: Production Release

1. Ensure you've completed:
   - ✅ Store listing
   - ✅ Content rating
   - ✅ Pricing and distribution
   - ✅ Tested via Internal testing

2. Go to **"Production" → "Releases"**
3. Click **"Create new release"**
4. Follow same steps as Internal testing
5. Click **"Review release"**
6. Review and click **"Start rollout to Production"**

---

### Step 7: Complete Required Declarations

Navigate to **"Policy" → "App content"**

Complete all required sections:

1. **Data safety:**
   - Declare what data you collect (email, payment info, etc.)
   - Explain how data is used
   - Specify if data is shared with third parties

2. **Target audience and content:**
   - Select appropriate age group
   - Declare content (usually "None" for a community app)

3. **COVID-19 contact tracing and status apps:** Usually **No**

---

### Step 8: Review and Submit

1. Go to **"Dashboard"**
2. Check for any **"Issues"** or **"Warnings"** (red/yellow indicators)
3. Resolve all critical issues before publishing
4. Once all checks pass, your app status will show **"Ready to publish"**

---

## 📱 Post-Upload Checklist

After uploading your AAB:

- [ ] AAB file uploaded successfully
- [ ] Store listing completed
- [ ] Content rating approved
- [ ] Screenshots uploaded
- [ ] App icon and feature graphic uploaded
- [ ] Privacy policy URL added (if required)
- [ ] Data safety form completed
- [ ] All required declarations completed
- [ ] No critical issues in Dashboard

---

## ⏱️ Timeline Expectations

- **Content Rating:** 1-3 hours
- **Internal Testing Review:** 1-7 days (usually 1-2 days)
- **Production Review:** 1-7 days (usually 1-3 days)
- **First-time app:** May take longer (up to 7 days)

---

## 🔧 Troubleshooting

### Common Issues:

1. **"Upload failed"**
   - Check AAB file size (should be reasonable, < 150MB)
   - Ensure AAB is properly signed
   - Try uploading again

2. **"Missing required information"**
   - Check Dashboard for red warnings
   - Complete all required sections in Store listing

3. **"Content rating pending"**
   - Wait for rating to complete (usually 1-3 hours)
   - Check email for updates

4. **"Rejected"**
   - Check email for specific reason
   - Address issues mentioned
   - Resubmit after fixes

---

## 📝 Version Updates (Future Releases)

For future updates:

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Increment version number
   ```

2. Build new AAB:
   ```powershell
   cd "C:\Users\PC\Desktop\OYC_Connect\oyc_connect"
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

3. In Play Console:
   - Go to **"Production" → "Releases"**
   - Click **"Create new release"**
   - Upload new AAB
   - Add release notes describing changes
   - Submit for review

---

## 🔐 Security Reminders

- ✅ Never commit `key.properties` or `.jks` files to git
- ✅ Keep your keystore file (`oyc-release-key.jks`) backed up securely
- ✅ If you lose your keystore, you cannot update your app (must create new app)
- ✅ Rotate API keys if they were ever exposed

---

## 📞 Support Resources

- **Google Play Console Help:** https://support.google.com/googleplay/android-developer
- **Play Console:** https://play.google.com/console
- **Flutter Deployment Docs:** https://docs.flutter.dev/deployment/android

---

## ✅ Final Checklist Before Publishing

- [ ] AAB file built and tested locally
- [ ] Store listing information complete
- [ ] Screenshots and graphics uploaded
- [ ] Content rating approved
- [ ] Privacy policy URL added (if collecting user data)
- [ ] Data safety form completed
- [ ] App tested on real device
- [ ] All features working correctly
- [ ] No critical errors in Dashboard
- [ ] Ready to publish!

---

**Good luck with your Play Store deployment! 🚀**
