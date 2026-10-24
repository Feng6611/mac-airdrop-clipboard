# Privacy Policy

Clipboard Drop is designed to keep content local to your Mac.

## Data Collection

Clipboard Drop does not collect, track, sell, or share personal data. The app has no network permission and cannot connect to the internet. There are no analytics, no crash reporting services, and no accounts.

App preferences (send formats, shortcuts, onboarding state, and a count of successful sends used only to time the system's App Store rating prompt) are stored locally in the app's preferences.

## Clipboard Content

Clipboard Drop reads content from the macOS clipboard (text, links, formatted text, and images), text selected in the macOS Services menu, items dragged onto the menu bar icon, and text passed by Shortcuts actions—only to prepare what you choose to send with AirDrop or show as a QR code. QR codes are generated locally on your Mac.

Clipboard Drop does not upload clipboard content to a server, sync it through cloud storage, or run a receiving service.

## Clipboard History

Clipboard Drop does not save clipboard history to disk. Recent items (including image previews) may be kept in memory while the app is running so they can be shown in the menu bar popover. This in-memory data is cleared when the app quits.

## Temporary Files

Links are handed to AirDrop as links, and dragged files are passed as the original files without being copied. For other content, Clipboard Drop writes a temporary file so macOS can hand it to AirDrop: text is written to a temporary `.txt` or `.md` file, formatted text to `.rtf`, and images to `.png`.

Temporary files are deleted right away if the send fails or is canceled. After a confirmed send, they are deleted about 10 minutes later so the transfer can finish. The temporary directory is also cleared when the app starts and quits.

## AirDrop

AirDrop delivery is handled by macOS. Clipboard Drop asks the system sharing service to send the item, but it does not control the receiver device or Apple account behavior.

## Contact

For questions, open an issue at <https://github.com/Feng6611/mac-airdrop-clipboard/issues>.
