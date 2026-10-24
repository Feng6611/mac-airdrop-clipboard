# Architecture

Clipboard Drop is a free macOS menu bar app. The app owns its clipboard and
AirDrop behavior; `Kiki_mackit` supplies the shared macOS Settings, onboarding,
menu bar, and review-request components.

## Boundaries

### App

`App/` owns launch and coordination:

- SwiftUI `App` entry point and `NSApplicationDelegate`.
- `ClipDropAppDefinition` and `ClipDropAppComposition`, which create the app's
  configuration, controller, Kiki coordinators, router, and lifecycle.
- `ClipDropAppRouter`, the single app-owned entry point for sends, Settings,
  onboarding, copy, history, and quit actions.
- `ClipDropLifecycleCoordinator`, which starts clipboard monitoring, registers
  the menu bar popover, presents first-launch onboarding, and clears temporary
  send files when the app exits.
- `ClipDropReviewRequestCoordinator`, which counts confirmed sends and applies
  Kiki's system review policy at an appropriate moment.

App code may import AppKit, SwiftUI, and Kiki modules. Product behavior and
policy stay in the app.

### Features

`Features/` owns app-facing UI:

- `MenuBar/`: SwiftUI popover content, clipboard rows, and action closures.
- `Settings/`: Kiki settings shell, app preferences, and About links.
- `Onboarding/`: a two-step introduction hosted by
  `KikiOnboardingCoordinator`; the final action completes onboarding.

Feature code may import SwiftUI and Kiki. It must not create status items, own
app lifecycle, or talk directly to pasteboard/AirDrop services.

### Platform

`Platform/` owns direct macOS services:

- `Clipboard/`: pasteboard monitoring, recent clipboard items, and formatted
  text extraction. Recent items exist in memory only.
- `Sharing/`: temporary file creation and the `NSSharingService` AirDrop
  delegate bridge.

This layer may import AppKit. Its protocols and result types stay close to the
service so tests can inject a deterministic provider.

`Platform/Hotkey/` owns Carbon global-hotkey registration and shortcut
serialization. `Platform/Services/` owns Services pasteboard reading, a
task-local `ClipDropEntryPayload` for text, URLs, rich text, images, and file
URLs, and the single drop-pasteboard handler seam. Its temporary Router bridge
falls back to text for rich content and files until the content pipeline adds
these cases to `ClipDropPayload` and the sharing implementation. AppKit
Services are listed in `Config/AppInfo.plist`; after changing them, run
`pbs -update` or log out and
back in before expecting the Services menu to refresh. Kiki 0.11.0 does not
provide popover drop callbacks, so `ClipDropDropHandler.handle(_:)` is ready for
the Kiki 0.12 integration point.

App Intents and their Shortcuts actions are app-owned. The Shortcuts actions are
Send Text (required Text, optional Edit before sending; summary: “Send {Text}”),
Send Clipboard (no parameters; summary: “Send the current clipboard”), and Show
QR Code (required Text; summary: “Show a QR code for {Text}”). Suggested phrases
include the app name through `\(.applicationName)`.

### Shared

`Shared/` owns app-local values:

- App name, bundle identifier, About URLs, limits, and design tokens.
- `ClipDropPayload` (`.text`, `.url`) and `ClipDropSendSource` for every send
  route.
- Send-format preferences and app-prefixed UserDefaults keys.

## Send lifecycle

Every send starts in `ClipDropAppRouter.send(_:source:)` or
`sendCurrentClipboard(source:)`. The popover sends the current item with source
`.popover` and recent rows with source `.history`. The router selects `.text` or
`.url`, then delegates to the app controller and `ClipboardSenderService`.

The sharing service writes one temporary file using the selected text or URL
format, sets itself as `NSSharingService.delegate`, and waits for a delegate
result. `sharingService(_:didShareItems:)` means success;
`sharingService(_:didFailToShareItems:error:)` means failure or cancellation.
The result is returned asynchronously. The panel opening alone does not count
as a send. The file is removed after every result, and the temporary directory
is cleared when the sender initializes and when the app terminates.

Text supports `.txt` and `.md`; links support plain `.txt` and `.url` shortcut
files. The app target declares the App Sandbox but no network client
entitlement. Clipboard Drop does not make network requests; macOS owns the
AirDrop transport.

## Launch and review behavior

At launch, the lifecycle coordinator starts clipboard monitoring and registers
the popover. If onboarding is incomplete, it starts immediately without any
network or access refresh. The two pages explain the send steps and receiver
settings. Completing the last page marks onboarding complete.

Only an AirDrop success callback increments
`ClipDrop.Review.successfulSendCount`. The review coordinator uses
`KikiReviewRequestRules.recommended(minimumQualifyingEvents: 3)` and
`KikiReviewRequestPolicy`. It checks eligibility when the user opens the menu
bar popover, not directly after a send, then uses `KikiSystemReviewRequest`.
Kiki's request timestamps and version keys use the `ClipDrop.Review` prefix.

## Settings and About

Settings uses `KikiSettingsCoordinator`, `KikiStandardAboutPane`, and Kiki row
components from the pinned Base package. The About pane has no access-status
row. The app adds its repository, author profile, App Store rating, Command
Reopen, Privacy, and Support links through `additionalLinks`.

The Open at Login control uses Kiki 0.11.0's stable `LaunchAtLogin.Toggle`.
After Kiki 0.12.0 ships, replace it with the approval-aware
`KikiSettingsLaunchAtLoginRow` so a pending Login Items approval is explained.

Keep the Settings scene in the app target and do not add duplicate windows or
test-only panes. The About links use Kiki's link-row component; Kiki itself is
not modified for this app-specific list.

## Data boundaries

Clipboard history is process-memory state and disappears on quit. Clipboard
content is written to disk only as the temporary file needed for the current
AirDrop operation. That file is removed after the sharing callback and the
dedicated temporary directory is cleared at startup and shutdown. There is no
cloud sync, persistent clipboard history, receive-side automation, or app
network client entitlement.

## Optional Core

ClipDrop does not currently have a `Core/` directory. Most behavior is bound to
pasteboard, AirDrop, and AppKit, so a separate Core layer would be ceremonial.
Add one only if a platform-free rule has a second consumer.

## Popover component specification

| Role | Component | Size | Color |
| --- | --- | --- | --- |
| Window | `NSPopover` through `KikiMenuBarPopoverController` | App-owned content size | System popover material |
| Clipboard content | SwiftUI `List` | 48 pt minimum row | Primary/secondary system text |
| Copy | Plain row `Button` | Full row | System neutral |
| Send | Borderless icon `Button` | Small | System neutral |
| Header/footer utilities | `Menu` or borderless `Button` | Small | System neutral; brand color for app identity |

Text uses semantic SwiftUI styles (`headline`, `body`, `subheadline`, and
`caption`) rather than fixed point sizes. Clipboard content types differ by
symbol, not by additional accent colors or repeated type labels. The popover
uses one continuous list rather than separate current/history surfaces.
