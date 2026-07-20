# RevenueCat and Apple purchase setup

Clipboard Drop is wired for two App Store Connect non-consumable products and
one shared RevenueCat entitlement. The app-side contract is deliberately
stable so the dashboard can be configured without another code change.

## App-side contract

| Item | Value |
| --- | --- |
| App Store Connect app | `6768068044` |
| Bundle ID | `dev.kkuk.clipboarddrop` |
| RevenueCat entitlement | `pro` |
| RevenueCat offering | `default` |
| Lifetime product | `dev.kkuk.clipboarddrop.pro.lifetime` — $6.99 fallback |
| Supporter product | `dev.kkuk.clipboarddrop.pro.supporter` — $10.99 fallback |
| Trial | Explicit two-day local trial |

Both products must be attached to the `pro` entitlement. Both must be added as
available packages in the `default` offering. RevenueCat matches the package
by the App Store product ID, so the package identifier itself is not part of
the app contract.

## Live catalog status

The production catalogs were configured and read back on 2026-07-15:

- App Store Connect contains both products as **Non-Consumable** IAPs with
  en-US localization, US prices of $6.99 and $10.99, all current territories,
  and automatic availability in future territories.
- RevenueCat project `Clipboard Drop` uses the modern `app_store` app type for
  bundle ID `dev.kkuk.clipboarddrop`.
- Both active RevenueCat products grant entitlement `pro` and are attached to
  the current `default` offering through `$rc_lifetime` and
  `$rc_custom_supporter_lifetime` packages.
- RevenueCat confirms the App Store Connect API key is configured. A
  subscription key is intentionally unnecessary for this lifetime-only model.

The production public SDK key is stored locally in the ignored file:

```xcconfig
// Config/LocalSecrets.xcconfig
CLIPDROP_REVENUECAT_API_KEY = appl_your_public_sdk_key
```

Do not commit that file. Clipboard Drop does not use RevenueCat Test Store:
Debug is an Apple Development-signed Apple Sandbox build and Release is the
production configuration. Both use the same `appl_` key, and every App Store
configuration rejects `test_`. For CI builds that do not materialize
`LocalSecrets.xcconfig`, pass the public key as an xcodebuild setting, for example:

```sh
xcodebuild ... CLIPDROP_REVENUECAT_API_KEY="$CLIPDROP_REVENUECAT_API_KEY"
```

The Xcode guard runs after the app resources are produced and validates the
final built `Info.plist`, including the embedded key and production bundle ID.
The build fails if injection was lost between the build setting and the app.

## Remaining release work

Both Apple products currently report `MISSING_METADATA` because their App
Review screenshots have not been supplied. Add a representative purchase UI
screenshot to each IAP, re-run strict validation, and submit the first IAP with
the first app version. Also verify Paid Apps agreements, tax, and banking in
App Store Connect; these account-level states are not available through the
public API.

## Sandbox acceptance checklist

- Fresh install shows Pro inactive and does not start the trial automatically.
- The onboarding paywall makes **Start Free 2-Day Trial** the primary action;
  closing or skipping it leaves the user Not Pro and does not start the clock.
- Starting the trial explicitly enables both send entry points for two days.
- Expiring the trial gates current-clipboard send and history resend while
  leaving copy/history/settings available.
- Purchasing either product unlocks Pro and the About pane identifies the
  active lifetime plan.
- Restore purchases unlocks Pro on a second install or a fresh local account.
- Cancelling a purchase leaves the user in the prior access state.
- A missing offering still shows the two fallback prices and does not hide the
  configured plans; purchasing remains unavailable until the store offering
  is fixed.
