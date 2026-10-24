# Changelog

## 1.2.0 - 2026-10-24

- Make Clipboard Drop free on the Mac App Store and remove purchase, trial, and
  RevenueCat code and dependencies.
- Update the app to `Kiki_mackit` 0.12.0.
- Route every send through one app-owned asynchronous AirDrop interface with
  confirmed success, failure, and cancellation.
- Send images and screenshots (PNG), formatted text (RTF), links as links, and
  files dropped on the menu bar icon.
- Add a global shortcut, a status item context menu, drag and drop onto the menu
  bar icon, a Services menu item, and Shortcuts actions.
- Add Edit and Send, merging several recent items into one send, and a QR code
  window for text and links.
- Add approval-aware Open at Login.
- Show a two-step onboarding and add GitHub, App Store, privacy, and support links
  to About; request an App Store rating only after confirmed sends.
- Remove the network client entitlement; recent clipboard items remain in memory.

## 2026-07-14

- Pinned the production app to the public `Kiki_mackit` `0.8.0` tag instead
  of tracking the `main` branch.
