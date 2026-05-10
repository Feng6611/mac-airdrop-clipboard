<h1 align="center">Clipboard Drop</h1>

<p align="center">
  <strong>Send copied text via AirDrop.</strong>
</p>

<p align="center">
  Different Apple ID? Send copied text with AirDrop. Clipboard Drop turns clipboard text into a simple <code>.txt</code>, <code>.md</code>, or URL item you can send to nearby Apple devices.
</p>

<p align="center">
  <sub>No receiver app · No cloud sync · No saved clipboard history</sub>
</p>

## Features

- **Send copied text with AirDrop** to nearby Apple devices.
- **No receiver setup** — the other device only needs to be able to receive AirDrop.
- **Simple file formats** for quick handoff: `.txt`, `.md`, and URL files for copied links.
- **Menu bar first** — copy text, open Clipboard Drop, and send.
- **Private by default** — clipboard text stays local and is not uploaded or synced.
- **Open source** and easy to audit.

## Supported Content

- Plain text
- URLs

Use it for links, codes, commands, addresses, notes, snippets, and quick text handoff.

## Send Formats

| Content | Formats |
|---|---|
| Text | `.txt`, `.md` |
| URLs | URL file, `.txt` |

## How It Works

Clipboard Drop reads the current text clipboard with `NSPasteboard`, writes a temporary UTF-8 file, and asks the system AirDrop sharing service to send it. The receiver does not need Clipboard Drop installed, paired, or signed in with the same Apple ID.

The app uses a menu bar popover hosted through `KikiMenuBar`, shared settings UI from `KikiSettings`, and local macOS services inside the app target.

## FAQ

**Does the receiver need to install anything?**

No. If their device can receive AirDrop, it can receive your text file or URL item.

**Does Clipboard Drop sync clipboard content?**

No. Clipboard Drop does not use cloud sync, accounts, servers, or a receiving service.

**Does Clipboard Drop store clipboard history?**

No saved history is written to disk. Recent clipboard text is only kept in memory while the app is running and is cleared when the app quits.

**Why use AirDrop instead of Universal Clipboard?**

Universal Clipboard is great when both devices are signed into the same Apple ID and handoff is working. Clipboard Drop is for quick text handoff when the receiving device is nearby but not part of that setup.

## Build

```sh
./script/build_and_run.sh
./script/build_and_run.sh --verify
```

## Test

```sh
xcodebuild test -project ClipDrop.xcodeproj -scheme ClipDrop -destination 'platform=macOS,arch=arm64'
```

## Architecture

Clipboard Drop follows a small macOS app structure:

- `App/`: app lifecycle, Kiki wiring, controller state, and access store.
- `Features/`: menu bar popover, settings scene, and access/paywall placeholder UI.
- `Platform/`: pasteboard monitoring, formatted text extraction, and AirDrop file sharing.
- `Shared/`: app config, send preferences, links, and app-specific design tokens.

See [Docs/Architecture.md](Docs/Architecture.md) for the folder boundaries.

## Privacy

Clipboard Drop collects no data. Everything runs locally on your Mac. See [PRIVACY.md](PRIVACY.md).

## License

[MIT](LICENSE)
