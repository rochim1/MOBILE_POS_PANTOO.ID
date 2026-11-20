# Create PIN visibility controls — 20 November 2026

User journey derived from the request: while creating a cashier PIN, independently
show/hide the account password, new PIN, and repeated PIN without losing input.

Implemented three local visibility flags and trailing eye buttons. Values remain
hidden by default and are reset when the dialog is dismissed. Labels remain
visible; tooltips support Indonesian and English. Suggestions/autocorrection are
disabled for these secret inputs. PIN digit filtering, length limits, validation,
and the authentication request are unchanged.

## Evidence

- RED checkpoint `d0d7a7c`: new widget test executed and failed because the
  account-password eye button was absent (`expected one IconButton, found none`).
- GREEN checkpoint `dc25a76`: the same widget test passed after implementation.
- Regression selection: **20 tests passed** for keyboard entry, responsive lock
  layout, dialog labels, independent visibility, preserved input, reset on reopen,
  password correction and genuine session-expiry handling.
- Coverage of newly added executable lines in `pin_lock_screen.dart`: **27/27
  (100%)**. This is changed-line coverage, not coverage of the entire application.
- Targeted Dart analysis of the screen and test: **No issues found**.

Commands run from the mobile project:

```powershell
flutter test test/pin_lock_responsive_test.dart --plain-name 'create PIN visibility toggles' --no-pub --concurrency=1 --reporter expanded
flutter test test/pin_lock_responsive_test.dart test/pos_pin_setup_error_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-google-access-20261120/pin-visibility-lcov.info' --reporter expanded
```

Logs and separate coverage output are under
`D:/my node app/zera/output/pos-google-access-20261120/pin-visibility-*`.
Existing coverage data was not overwritten. No database changes or APK build
were needed. Verification uses Flutter widget tests, not a live-device GUI run.
