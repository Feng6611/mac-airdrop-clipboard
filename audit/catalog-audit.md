# Clipboard Drop commerce catalog audit

Date: 2026-07-15

## App Store Connect

- App `6768068044`, bundle ID `dev.kkuk.clipboarddrop`.
- IAP `6791174721`: `dev.kkuk.clipboarddrop.pro.lifetime`,
  `NON_CONSUMABLE`, en-US, US $6.99.
- IAP `6791174796`: `dev.kkuk.clipboarddrop.pro.supporter`,
  `NON_CONSUMABLE`, en-US, US $10.99.
- Both products are enabled for the current 175-territory catalog and future
  territories.
- Strict validation: 0 errors, 2 warnings. Both warnings are
  `MISSING_METADATA`; App Review screenshots are absent.
- Machine-readable strict validation is stored in
  [`iap-validation.json`](iap-validation.json).

## RevenueCat

- Project: `Clipboard Drop` (`proj3fa88b2a`).
- App: `appb984bd968b`, type `app_store`, exact bundle ID confirmed.
- ASC API key configured: yes. Production Apple public SDK key present: yes.
- Active products: both exact App Store product identifiers above.
- Entitlement `pro`: both products attached.
- Current offering `default`: `$rc_lifetime` maps the standard unlock and
  `$rc_custom_supporter_lifetime` maps the supporter unlock.

No charged transaction or App Review submission was automated. Remaining
manual proof is documented in [`../Docs/RevenueCat.md`](../Docs/RevenueCat.md).
