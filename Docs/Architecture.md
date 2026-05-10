# Architecture

ClipDrop is a small macOS menu bar app. Its structure follows the practical
Command Reopen-style layout: keep the app shell thin, put product surfaces in
features, isolate direct macOS services in platform folders, and avoid a `Core/`
layer until there is a real platform-free boundary.

## Boundaries

### App

`App/` owns launch and coordination:

- SwiftUI `App` entry point and `NSApplicationDelegate`.
- Kiki menu bar and settings wiring.
- App-level controller state and access store.
- User-action routing from UI surfaces into platform services.

App code may import AppKit, SwiftUI, and Kiki packages. Keep it focused on
coordination, not reusable UI or system-service details.

### Features

`Features/` owns app-facing UI:

- `MenuBar/`: SwiftUI popover content, recent item rows, action buttons, and
  menu-specific presentation extensions.
- `Settings/`: Kiki settings shell usage and settings tab definitions.
- `Access/`: access/paywall placeholder UI and display models.

Feature code may import SwiftUI and Kiki. It should not create status items,
own app lifecycle, or talk directly to pasteboard/AirDrop.

### Platform

`Platform/` owns direct macOS services:

- `Clipboard/`: pasteboard monitoring, recent clipboard items, and formatted
  text extraction.
- `Sharing/`: AirDrop file creation and `NSSharingService` bridge.

This layer may import AppKit. Keep protocols and result types close to the
service that uses them so tests can replace platform behavior.

### Shared

`Shared/` owns app-local constants:

- App name, links, bundle id, and limits.
- Send-format preferences and user defaults keys.
- ClipDrop-specific design tokens.

Shared values are local to this app. Reusable shell/design behavior belongs in
Kiki, not here.

## Optional Core

ClipDrop does not currently have a `Core/` directory. Most of its behavior is
bound to pasteboard, AirDrop, and AppKit, so a heavy Core layer would be mostly
ceremonial.

Add `Core/` only if a future rule can be tested and reused without SwiftUI,
AppKit, Kiki, or app lifecycle state, or if a second runtime appears.
