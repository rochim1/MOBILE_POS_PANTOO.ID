# Google login: invalid access_via — 20 November 2026

## Cause and fix

The shared Google login/registration payload sent `access_via: mobile_pos`.
The backend GraphQL `access_via` enum only accepts `mobile_app` and
`web_browser`, so input validation rejected the request before authentication.

Changed the mobile payload to `access_via: mobile_app`. Kept
`registration_source: mobile_pos` and `primary_product: pos` for attribution.
No authentication permissions, backend production code, or schema were relaxed.

## Verification

- RED mobile checkpoint: `bc92ee0`; the new payload assertion failed with
  expected `mobile_app`, actual `mobile_pos`.
- RED backend checkpoint: `e14e4bf3`; actual merged GraphQL schema input coercion
  rejected `mobile_pos` at `access_via`.
- GREEN: **35 mobile tests passed**, covering Google login/registration,
  redirect, progress, session restoration, workspace and subscription gates.
- GREEN: **2 backend contract tests passed**, coercing the actual mobile source
  literal through `LoginInput` and checking enum separation from attribution.
- Targeted Dart analysis: **No issues found**.

Mobile command:

```powershell
flutter test test/google_login_test.dart test/google_login_progress_test.dart test/google_redirect_regression_test.dart test/pos_google_navigation_test.dart test/auth_session_loading_test.dart test/auth_workspace_session_test.dart test/auth_subscription_preparation_test.dart --no-pub --concurrency=1 --reporter expanded
```

Backend command:

```powershell
node --test tests/pos-google-access-via.contract.test.js
```

The broader regression run also exposed pending timers in existing mock settings
fixtures. Their teardown now completes the held fixture after unmount; test
assertions were not removed. Intermediate runs hit native test-runner memory
exhaustion. After stopping only this task's idle Gradle daemon, the final full
selection passed.

Evidence logs are in `D:/my node app/zera/output/pos-google-access-20261120/`:
`mobile-final.log`, `schema-red.log`, `schema-green.log`, `analyze.log`.

## Delivery limits

- No real Google account chooser/device OAuth end-to-end test was performed.
- No database records were modified.
- The previously delivered production APK 1.0.20+21 was built before this fix.
  A replacement build is required for that APK to include the correction.
