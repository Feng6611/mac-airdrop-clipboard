# Architecture

ClipDrop is a small macOS menu bar app. Its structure follows the practical
Kiki Starter layout: keep the app shell thin, put product surfaces in
features, isolate direct macOS services in platform folders, and keep paid
access behind the shared Kiki commerce boundary.

## Boundaries

### App

`App/` owns launch and coordination:

- SwiftUI `App` entry point and `NSApplicationDelegate`.
- `ClipDropAppDefinition`: app-owned config, stable storage names, and
  commerce configuration.
- `ClipDropAppComposition`: the single object graph for controller, access
  manager, settings coordinator, router, and lifecycle.
- `ClipDropAppRouter`: the only route for send, settings, paywall, copy, and
  quit actions.
- `ClipDropLifecycleCoordinator`: menu bar startup/shutdown and entitlement
  refresh, followed by the first-launch decision only when access readiness is
  authoritative.

App code may import AppKit, SwiftUI, and Kiki packages. Keep it focused on
coordination, not reusable UI or system-service details.

### Features

`Features/` owns app-facing UI:

- `MenuBar/`: SwiftUI popover content, clipboard rows, action buttons, and
  menu-specific presentation extensions. The app owns the primary clipboard
  and history hierarchy; it expresses that hierarchy through action prominence
  instead of redundant section labels. The system `NSPopover` and SwiftUI list
  controls supply the visual treatment; the app owns product layout and actions.
- `Settings/`: Kiki settings shell usage and settings tab definitions.
- `Onboarding/`: a two-step app-owned introduction hosted by
  `KikiOnboardingCoordinator`; the final action presents the shared onboarding
  paywall as a sheet.

Feature code may import SwiftUI and Kiki. It should not create status items,
own app lifecycle, or talk directly to pasteboard/AirDrop. The Paywall feature
renders the shared Kiki paywall and does not call RevenueCat directly.

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

`ClipDropPurchasePlan` and `ClipDropRevenueCatConfiguration` are also app-local
policy. Both lifetime products unlock the same `pro` entitlement:

| Plan | Product ID | Fallback price |
| --- | --- | --- |
| Lifetime | `dev.kkuk.clipboarddrop.pro.lifetime` | `$6.99` |
| Lifetime + Support | `dev.kkuk.clipboarddrop.pro.supporter` | `$10.99` |

The trial is an explicit two-day local access trial. It starts only after the
user clicks **Start Free 2-Day Trial**; it is not represented as an Apple
introductory offer because these are lifetime non-consumables.

On first launch, Clipboard Drop waits for an authoritative access refresh.
Existing Pro users are not interrupted. Other new users see the product
introduction before the onboarding paywall. Skipping or closing onboarding
marks the introduction complete without starting the trial. The onboarding
paywall makes the explicit trial action primary and keeps lifetime purchase and
restore as alternatives. Settings keeps the lifetime purchase primary while
the trial is still eligible, so a person who skipped onboarding can start it
later. Closing a paywall never starts the trial or writes the trial start key.

Current clipboard send and resend-history actions require active access
(trial or purchased Pro). Copying history, viewing history, Settings, and Quit
remain available without Pro. Purchase and restore use RevenueCat through
`KikiCommerceKit`, with StoreKit/App Store Connect as the Apple store layer.
The sandboxed target declares `com.apple.security.network.client` because
RevenueCat customer and offering refreshes require outbound HTTPS access.
The router shares the startup entitlement refresh with early send actions. An
unresolved or degraded refresh is never treated as proof that the user is
unpaid; cached active access remains usable, and only an authoritative `.ready`
inactive state routes to the paywall.

## Optional Core

ClipDrop does not currently have a `Core/` directory. Most of its behavior is
bound to pasteboard, AirDrop, and AppKit, so a heavy Core layer would be mostly
ceremonial.

Add `Core/` only if a future rule can be tested and reused without SwiftUI,
AppKit, Kiki, or app lifecycle state, or if a second runtime appears.

## Action Entry Points

User actions should have one app-owned entry point:

- menu popover and future UI smoke paths call `openSettings()` for Settings;
- send actions call `ClipDropController.sendClipboardViaAirDrop()` or the
  matching history-item action;
- row send/copy actions synchronize an app-owned row selection, so Return and
  Command-C always resolve the same visible item without inheriting the user's
  macOS accent color as native `List` selection chrome;
- settings rows only change app-local preferences and do not call platform
  services directly.

Settings uses `KikiSettingsCoordinator`, `KikiStandardAboutPane`, and
`KikiSettingsSegmentedPickerRow` from the pinned `Kiki_mackit` dependency.
Avoid duplicate Settings
windows. When a desired Kiki row exists only in local kit and not in the pinned
remote dependency, push/bump the dependency before adopting that API here.

Debug builds also expose a `Developer Testing` section in General Settings.
It uses `KikiSettingsDebugPreviewRow` to drive the existing access manager's
Live / Not Pro / Trial / Pro override and provides real-route Onboarding and
Paywall buttons. The entire section is compiled out of Release builds.
Debug builds also accept `--clipdrop-debug-open-settings` and
`--clipdrop-debug-open-onboarding` so a menu-bar-only process can expose its
real Settings or onboarding route to repeatable UI smoke checks.

The shared About status row keeps the `Status` label and leading information
icon neutral. Active, trial, lifetime, and expired icons are rendered beside
the trailing value; inactive stays text-only to avoid a duplicate information
icon. Inactive and expired access use system orange; trial and purchased Pro
use the stable Clipboard Drop Pro accent `#CB30E0`. Lifetime therefore renders
as a purple crown immediately before `Lifetime`, rather than coloring the row
label.

The external catalog setup and sandbox checklist live in
[`Docs/RevenueCat.md`](RevenueCat.md). The repository intentionally keeps the
RevenueCat public SDK key out of source control; local builds read
`Config/LocalSecrets.xcconfig`, while CI can inject
`CLIPDROP_REVENUECAT_API_KEY`.

## Popover Component Specification

The popover follows a system-first component contract:

| Role | Component | Size | Color |
| --- | --- | --- | --- |
| Window | `NSPopover` through `KikiMenuBarPopoverController` | App-owned content size | System popover material |
| Clipboard content | SwiftUI `List` | 48 pt minimum row | Primary/secondary system text |
| Copy | Plain row `Button` | Full row | System neutral |
| Send | Borderless icon `Button` | Small | System neutral |
| Header/footer utilities | `Menu` or borderless `Button` | Small | System neutral; Pro may use brand accent |

Text uses semantic SwiftUI styles (`headline`, `body`, `subheadline`, and
`caption`) rather than fixed point sizes. Clipboard content types differ by
symbol, not by additional accent colors or repeated type labels. The popover
uses one continuous list rather than separate current/history surfaces. Brand
color is reserved for product identity and paid-access entry points.
