# Host the Reset Password Page on GitHub Pages

Follow these steps to host `web/reset-password.html` on GitHub Pages so the password-reset email link opens a real page instead of a blank browser tab.

---

## Option A: Dedicated repo (simplest)

Use a small repo that only contains the reset-password page.

### 1. Create a new repo on GitHub

1. Go to [github.com](https://github.com) and sign in.
2. Click the **+** (top right) → **New repository**.
3. **Repository name:** e.g. `oyc-connect-reset` (any name is fine).
4. **Public**, no README, no .gitignore. Click **Create repository**.

### 2. Add the reset-password page

**From your computer (Git / terminal):**

1. Create a new folder (e.g. `oyc-connect-reset`) and go into it:
   ```bash
   mkdir oyc-connect-reset
   cd oyc-connect-reset
   ```

2. Copy the reset-password file into this folder:
   - Copy `oyc_connect/web/reset-password.html` from your OYC Connect project into this folder (so the folder has exactly one file: `reset-password.html`).

3. Initialize Git and push to GitHub:
   ```bash
   git init
   git add reset-password.html
   git commit -m "Add reset password page"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/oyc-connect-reset.git
   git push -u origin main
   ```
   Replace `YOUR_USERNAME` with your GitHub username.

### 3. Turn on GitHub Pages

1. In the repo on GitHub, go to **Settings**.
2. In the left sidebar, click **Pages** (under “Code and automation”).
3. Under **Build and deployment**:
   - **Source:** Deploy from a branch.
   - **Branch:** `main`, folder **/ (root)**.
4. Click **Save**. Wait 1–2 minutes.

### 4. Get your page URL

Your page will be at:

```
https://YOUR_USERNAME.github.io/oyc-connect-reset/reset-password.html
```

Example: if your username is `ouryouthcenter1881`, the URL is:

```
https://ouryouthcenter1881.github.io/oyc-connect-reset/reset-password.html
```

Open that URL in a browser to confirm the page loads.

### 5. Use this URL in your app and Supabase

1. **Supabase:** Authentication → URL Configuration → Redirect URLs → add the URL above → Save.
2. **App:** In `lib/core/constants/supabase_constants.dart` set:
   ```dart
   static const String? passwordResetRedirectUrl = 'https://YOUR_USERNAME.github.io/oyc-connect-reset/reset-password.html';
   ```
   Use your real GitHub username and repo name.

3. Rebuild the app and test “Forgot password” again; the email link should open this page, then open the app on a phone where the app is installed.

---

## Option B: Use your existing OYC Connect repo

If your OYC Connect code is already in a **public** GitHub repo, you can serve the page from that repo.

### 1. Push the web folder

Make sure your repo has the file at:

```
web/reset-password.html
```

If it’s already there, push as usual. If not, add and push:

```bash
cd path/to/OYC_Connect/oyc_connect
git add web/reset-password.html
git commit -m "Add reset password page for GitHub Pages"
git push
```

### 2. Enable GitHub Pages from the docs folder

1. On GitHub, open your **OYC Connect repo**.
2. Go to **Settings** → **Pages**.
3. Under **Build and deployment**:
   - **Source:** Deploy from a branch.
   - **Branch:** `main` (or the branch you use), folder **/docs**.
4. Click **Save**.

5. Put the page where GitHub will serve it:
   - GitHub Pages with “/docs” serves files from a **`docs`** folder at the **root** of the repo.
   - So you need the page at `docs/reset-password.html` (not `web/`).
   - Copy or move the file:
     ```bash
     cp web/reset-password.html docs/reset-password.html
     git add docs/reset-password.html
     git commit -m "Add reset password page to docs for GitHub Pages"
     git push
     ```

### 3. Get your page URL

It will be:

```
https://YOUR_USERNAME.github.io/OYC_Connect/docs/reset-password.html
```

(Use your actual GitHub username and repo name; repo name is case-sensitive.)

### 4. Use this URL in Supabase and the app

Same as Option A, step 5: add this URL to Supabase Redirect URLs and set `passwordResetRedirectUrl` in `supabase_constants.dart` to this URL.

---

## Summary

| Step | What to do |
|------|------------|
| 1 | Create repo (Option A) or use existing repo (Option B). |
| 2 | Have `reset-password.html` in the repo (root for A, `docs/` for B). |
| 3 | Settings → Pages → choose branch and folder → Save. |
| 4 | Copy the live URL (`https://...github.io/.../reset-password.html`). |
| 5 | Add that URL in Supabase Redirect URLs. |
| 6 | Set `passwordResetRedirectUrl` in `lib/core/constants/supabase_constants.dart` to that URL. |
| 7 | Rebuild app and test “Forgot password”. |

If the link still opens a blank page, double-check the URL in Supabase and in `supabase_constants.dart` (no trailing slash, correct repo name and username).
