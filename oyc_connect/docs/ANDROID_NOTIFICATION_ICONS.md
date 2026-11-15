# Android notification icons

OneSignal loads the following bundled drawable resources for notifications from
the dashboard and backend, including delivery while the app is closed:

- `ic_stat_onesignal_default`: transparent vector of the OYC linked figures.
  Android uses its alpha mask for the small icon and status bar. Full-colour
  launcher artwork must not be used here because its background becomes a block.
- `ic_onesignal_large_icon_default`: the existing full-colour launcher artwork.
  Device notification layouts determine where, or whether, the large icon appears.

`res/raw/notification_icons_keep.xml` preserves both resources in release builds,
which enable resource shrinking. No network image download or backend change is
required. Avoid overriding `small_icon` or `large_icon` with missing resource names
in a OneSignal message.

Install the updated APK, dismiss existing notifications, then send a new test
notification only to the test device. Check foreground, background and closed-app
delivery on the physical phone. Existing posted notifications retain their old
icons. System tint, icon position and notification layout vary by Android version
and manufacturer; a full-colour small icon cannot be forced on all devices.

Reference: https://documentation.onesignal.com/docs/en/notification-icons
