# Clipboard Drop Agent Notes

This is a focused macOS menu bar app built on remote `Kiki_mackit`.

Read `Docs/Architecture.md` before structural changes. ClipDrop follows the
Command Reopen-style app-target layout:

- `App/`: app lifecycle, Kiki wiring, controllers, and app state.
- `Features/`: menu bar, settings, and access UI surfaces.
- `Platform/`: direct pasteboard, AirDrop, and other macOS service bridges.
- `Shared/`: app-local config, send preferences, links, and design tokens.
- `Core/`: optional only; do not add it unless a rule is truly platform-free or
  has a second consumer.

Keep V1 narrow:

- Send text clipboard content as one AirDrop-able UTF-8 `.txt` file.
- Keep recent clipboard items in memory only, capped at the app config limit.
- Do not add persisted clipboard history, cloud sync, receive-side automation, or Nearby Direct in V1.
- Keep AirDrop and pasteboard business logic in the app target, not in `Kiki_mackit`.
- Keep SwiftUI/Kiki UI out of `Platform/`, and keep AppKit service code out of
  feature views.

Recommended verification:

- `xcodebuild test -project ClipDrop.xcodeproj -scheme ClipDrop -destination 'platform=macOS,arch=arm64'`
- `./script/build_and_run.sh --verify`
