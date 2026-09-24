# Petto mobile acceptance runbook

Use this checklist before a Progress demo or release candidate. Automated tests
cover the application contract; these checks cover OS services that cannot be
proven by widget tests or a web build.

## Prerequisites

- One Android phone (Android 12 or newer preferred).
- Optional iPhone for iOS notification and deep-link verification.
- A real email inbox belonging to the tester.
- Staging backend `/ready` returns HTTP 200 and the current repository migration.
- Build the app with the staging `API_BASE_URL`, `SUPABASE_URL`, and public key.
- Do not place database, service-role, Gemini, or admin secrets in the app build.

Record the device model, OS version, app commit, date, result, and screenshot for
each case. Store evidence outside the source tree or under the approved test
record location.

## A. Password recovery

1. On Login, choose **Forgot password?** and submit the test account email.
2. Confirm the UI always shows the neutral response; it must not reveal whether
   an arbitrary address is registered.
3. Open the Supabase recovery email on the same device.
4. Confirm the link opens Petto's password recovery screen, not the normal Home.
5. Enter and confirm a new valid password.
6. Confirm the recovery session is cleared and Login/Home appears normally.
7. Log out, then log in with the new password.

Pass: the email arrives, the deep link reaches recovery, the password changes,
and no reset token is exposed in UI or logs.

## B. Local notifications

1. Allow notifications when requested.
2. Create a timed Calendar event at least 32 minutes in the future.
3. Confirm a reminder is scheduled for 30 minutes before the event.
4. Edit its time; confirm the old reminder is replaced rather than duplicated.
5. Delete the event; confirm its reminder is cancelled.
6. Restart the phone and confirm scheduled reminders remain.
7. Repeat once with notification permission denied. Saving the event must still
   succeed and the app must explain that OS delivery is unavailable.
8. Verify Daily Mission reminders at 09:00 and 19:00 with a temporary test-time
   build if waiting for the real times is impractical.

Pass: no duplicate reminders, Calendar data is never lost because permission
was denied, and reminders use the device timezone.

## C. BLE/GPS tracking

Until collar hardware is selected, run steps 1-5 with **Use simulator instead**.

1. Open Wellness > Live Pet Tracking and allow Nearby Devices/Bluetooth.
2. Start the simulator or scan and connect a collar.
3. Confirm the map marker, route, speed, battery, last-seen, and motion status
   update without manual refresh.
4. Put the app in the background and return. Confirm reconnect or a clear
   disconnected state; stale data must not be labelled live.
5. Disconnect the source and wait for the Offline threshold/alert.
6. With hardware, repeat while walking, stationary, moving rapidly, out of BLE
   range, and after power cycling the collar.
7. Confirm a qualifying 15-minute walk completes the Walk Mission once only.

Pass: updates reach both the current device and another signed-in session via
Realtime, and denied permission/error states remain recoverable.

## D. Public Pet Health Card / QR / NFC

1. Open Health Records and set up **QR / NFC Health Card**.
2. Select only non-sensitive fields needed for the test.
3. Scan the QR from a second phone that is not signed in.
4. Confirm only the selected fields appear and browser history/cache is not
   relied on for access.
5. Replace the link. Confirm the previous QR returns 404.
6. Disable the card. Confirm the latest QR returns 404.
7. After QR passes, write the exact same HTTPS URL to an NFC URL record and
   repeat steps 3-6. NFC contains a URL only; it must not contain health data.

Pass: allow-listing, rotation, and revocation all work from an unauthenticated
second device.

## Failure handling

- Capture the screen and timestamp.
- Record the app commit and `/ready` response.
- Do not work around a failed privacy or authorization check for a demo.
- For a denied OS permission, verify Settings instructions and simulator
  fallback instead of repeatedly prompting.
- For a failed Railway deploy, keep the previous container active, inspect
  pre-deploy logs, and do not downgrade the database without a reviewed plan.

