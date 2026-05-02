Based on the navigation menu on the left side of App Store Connect, here are the **only three other sections** you absolutely must fill out to get your app approved. You can safely ignore "In-App Purchases," "Game Center," "Promo Codes," etc.

---

## 1. General -> App Information
This section defines the core identity of your app globally.

*   **Name:** `OYC Connect` (Already set)
*   **Subtitle:** `1881 Musalla Community` *(Max 30 chars. Highly recommended as it appears under your app's name in search results).*
*   **Bundle ID & SKU:** (Already set from when you created the app).
*   **Category:** 
    *   **Primary:** `Lifestyle` or `Social Networking`
    *   **Secondary (Optional):** `Education`
*   **Content Rights:** Select "No, it does not contain, show, or access third-party content" (unless you are pulling in copyrighted articles, which you aren't).
*   **Age Rating:** Click Edit. Answer the questionnaire honestly (No violence, no profanity, etc.). It will likely give you a **4+** rating.

---

## 2. Monetization -> Pricing and Availability
This section tells Apple if they need to charge users to download the app.

*   **Pricing:** Set to `0.00 (Free)`.
*   *(Note: Apple allows physical donations/charity without using their In-App Purchase system. Because your Stripe integration collects money for the Musalla—not for unlocking digital app features—you do not need to configure Apple In-App Purchases).*
*   **Availability:** 
    *   By default, it is available in All Countries.
    *   If you only want people in Australia to be able to download it, you can edit this to select only Australia. Otherwise, leave it as All Countries.

---

## 3. App Store -> App Privacy (CRITICAL)
Apple is extremely strict about privacy. You must declare what data your app collects using Supabase and Stripe.

1.  **Privacy Policy URL:** You **must** provide a link to your privacy policy (e.g., `https://oyc1881.com.au/privacy`). If you don't have one, you will need to generate a basic one and host it on your website or a free host like Google Sites/Notion.
2.  **Data Types:** Click "Get Started" on the Data Collection questionnaire.
    *   *Question:* "Do you or your third-party partners collect data from this app?" -> **Yes**.
3.  **What you need to check off (based on your app):**
    *   **Contact Info:** Name, Email Address, Phone Number (collected during Auth/Registration).
    *   **Financial Info:** Payment Information (Stripe collects this for donations, even if you don't store the credit card raw).
    *   **Identifiers:** User ID (Supabase Auth ID).
4.  **For each of those selected, it will ask:**
    *   *How is it used?* Select "App Functionality" (and maybe "Analytics" if you use OneSignal for analytics).
    *   *Is it linked to the user's identity?* **Yes** (because they log into an account).
    *   *Is it used for tracking?* **No** (You are not selling their data to Facebook/Google for targeted ads).

---

### Summary Checklist Before Clicking "Submit for Review":
1.  [x] **1.0 Prepare for Submission** (Screenshots, Description, Keywords, Support URL, Built App uploaded).
2.  [x] **App Information** (Subtitle, Category, Age Rating).
3.  [x] **Pricing and Availability** (Set to Free).
4.  [x] **App Privacy** (Privacy Policy URL added, Data Questionnaire completed).
