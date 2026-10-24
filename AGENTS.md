# Clipboard Drop Agent Notes

Clipboard Drop is a focused macOS menu bar app built on the free Base modules
from `Kiki_mackit` 0.11.0. Read `Docs/Architecture.md` before structural changes.

Keep the app organized by responsibility:

- `App/`: app lifecycle, Kiki wiring, controllers, and routing.
- `Features/`: menu bar, settings, and onboarding UI.
- `Platform/`: pasteboard and macOS sharing-service bridges.
- `Shared/`: app-local payloads, send preferences, links, and design tokens.
- `Core/`: optional; add it only for platform-free logic with a second consumer.

Product boundaries:

- Clipboard Drop 1.2 and later is free. Do not add purchase, trial, entitlement,
  or donation flows.
- Send text and HTTP/HTTPS links as temporary AirDrop-able files.
- Keep recent clipboard items in memory only, capped at the app config limit.
- Do not add persisted clipboard history, cloud sync, or receive-side automation.
- The app does not make network requests. Keep
  `com.apple.security.network.client` out of its entitlements.
- Keep AirDrop and pasteboard business logic in the app target, not in Kiki.
- Keep SwiftUI/Kiki UI out of `Platform/`, and keep AppKit service code out of
  feature views.
- Settings should stay on `KikiSettingsShell` and Kiki row components. Do not
  add test-only Settings windows or duplicate panes.
- All send entry points go through `ClipDropAppRouter.send(_:source:)` or
  `sendCurrentClipboard(source:)`.
- Treat `NSSharingService` delegate success as a confirmed send. Return success,
  failure, or cancellation asynchronously; opening the AirDrop panel is not
  success.
- Delete each temporary file after the sharing callback. Clear the app's
  temporary directory at startup and shutdown.
- Start onboarding on first launch when it is incomplete. It has two steps and
  no paywall.
- Keep the debug `--clipdrop-debug-open-settings` and
  `--clipdrop-debug-open-onboarding` launch arguments for UI smoke checks.

Recommended verification:

- `xcodebuild test -project ClipDrop.xcodeproj -scheme ClipDrop -destination 'platform=macOS,arch=arm64'`
- `./script/build_and_run.sh --verify`
