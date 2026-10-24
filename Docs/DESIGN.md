# Clipboard Drop Design

Authority for how Clipboard Drop looks. Implementation follows this file; a
screenshot that disagrees with it is a defect or a deliberate rule change made
here first. The popover contract lives in `DesignSpec-MenuBar.md`; the shared
Settings rules come from `Kiki_menubar_starter/Docs/SettingsDesignGuide.md`.

## Principles

- System first: native `Form` grouping from `KikiSettingsPane`, system text
  styles, semantic colors, the user's accent color for selection. No cards,
  custom backgrounds or borders inside a section.
- Brand purple `#CB30E0` (`ClipDropDesignToken.Colors.brand`) is for identity
  only (About tint, app icon). Controls never use it.
- One concept, one word. Settings say "link", "text", "shortcut", "QR code";
  never "URL" as a choice label or "Direct".

## Settings › General

Order follows the scan path: app-level, core behavior, send format, then
before-send behavior.

| Section | Header | Rows (SF Symbol · label · control) | Footer |
| --- | --- | --- | --- |
| 1 | none | `power` · Open at Login · switch (`KikiSettingsLaunchAtLoginRow`) | none (approval note appears inside the row when needed) |
| 2 | Keyboard Shortcuts | `paperplane` · Send clipboard · shortcut field; `qrcode` · Show QR code · shortcut field | Shortcuts work in any app while Clipboard Drop is running. |
| 3 | Send Format | `doc.text` · Text · segmented `Plain Text` / `Markdown`; `link` · Links · segmented `Link` / `URL File` / `Text File`; `textformat` · Keep formatting · switch | Links open on the other device as links. Formatted text is sent as an RTF file. |
| 4 | Before Sending | `square.and.pencil` · Edit before sending · switch | An editor opens so you can change text or a link before the AirDrop sheet appears. |

Rules:

- Every row has its SF Symbol in the leading slot (`KikiSettingsRowLabel`), the
  same size and color as every other row.
- Explanations live only in section footers, never as a row inside the section.
- Segmented controls share one width (`ClipDropDesignToken.Settings.segmentedWidth`
  = 220 pt) so their trailing edges align.
- Labels are sentence case; section headers are title case nouns.

## Shortcut field

A compact, native-looking recorder. No separate Clear button, never a
disabled button standing in for "empty".

| Part | Spec |
| --- | --- |
| Size | `ClipDropDesignToken.Settings.shortcutFieldWidth` = 140 pt wide, regular control height (22 pt) |
| Shape | rounded rectangle, radius 6 pt, `controlBackgroundColor` fill, 0.5 pt `separatorColor` stroke (reads like a text field) |
| Empty | placeholder "Record Shortcut" in `.secondary`, centered, `.body` (13 pt) |
| Set | key glyphs (e.g. `⌃⌥⌘C`) centered in `.body` monospaced digits, `.primary`; a trailing `xmark.circle.fill` (`.tertiary`, 12 pt) inside the field clears it; accessibility label "Clear shortcut" |
| Recording | 1.5 pt `controlAccentColor` stroke, focus ring style; text "Type Shortcut" in `.secondary`. Escape cancels, Delete clears, any valid chord saves |
| Error | the conflict / registration message as a `.caption` line in `.red` under the row label, aligned with the label text |

Hover shows the pointing-hand cursor only over the clear glyph. The whole field
is one click target to start recording.

## About

`KikiStandardAboutPane` with the brand tint. Support links, in order: Star on
GitHub, Follow on GitHub, Rate Clipboard Drop, Command Reopen, Privacy,
Support. No donation or social links.
