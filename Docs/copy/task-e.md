# Task E copy inventory

| Location (`file:line`) | Current English | Purpose / context | Length limit |
| --- | --- | --- | --- |
| `ClipDrop/Platform/Hotkey/ClipDropShortcut.swift:12` | Send Clipboard | Shortcut setting label and action name. | None specified |
| `ClipDrop/Platform/Hotkey/ClipDropShortcut.swift:14` | Show QR Code for Clipboard | Shortcut setting label and action name. | None specified |
| `ClipDrop/Platform/Hotkey/ClipDropShortcut.swift:48-75` | ⌃, ⌥, ⇧, ⌘; A–Z; 0–9; Space; Return; Tab; Delete; Forward Delete; Escape; arrow keys; Key {code} | Recorded shortcut display. | Compact button label |
| `ClipDrop/Platform/Hotkey/ClipDropShortcut.swift:86` | This shortcut is already in use. | System shortcut registration conflict. | None specified |
| `ClipDrop/Platform/Hotkey/ClipDropShortcut.swift:88` | macOS could not register this shortcut (OSStatus {status}). | Carbon registration failure with status code. | None specified |
| `ClipDrop/Platform/Hotkey/ClipDropHotkeyCoordinator.swift:71` | This shortcut conflicts with {action}. | Conflict with the other ClipDrop shortcut. | None specified |
| `ClipDrop/Platform/Hotkey/ClipDropHotkeyCoordinator.swift:83` | macOS could not register this shortcut. | Unexpected registration failure. | None specified |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:11` | Keyboard Shortcuts | Settings section heading. | None specified |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:15` | Click a shortcut to record it. Press Escape to cancel. | Shortcut recording help. | None specified |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:18` | Startup | Settings section heading. | None specified |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:20` | Open at Login | Login item toggle label. | None specified |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:49` | Clear | Clear the selected shortcut. | Short button label |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:76,79,89,127` | Record Shortcut | Shortcut capture button and accessibility label. | Short button label |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:89` | Press Shortcut | Shortcut capture state. | Short button label |
| `ClipDrop/App/ClipDropLifecycleCoordinator.swift:132` | Send Clipboard | Status bar context menu action. | None specified |
| `ClipDrop/App/ClipDropLifecycleCoordinator.swift:133` | Show QR Code for Clipboard | Status bar context menu action. | None specified |
| `ClipDrop/App/ClipDropLifecycleCoordinator.swift:135` | Settings… | Status bar context menu action. | None specified |
| `ClipDrop/App/ClipDropLifecycleCoordinator.swift:136` | Quit | Status bar context menu action. | None specified |
| `ClipDrop/Platform/Services/ClipDropServicesProvider.swift:74` | Clipboard Drop could not read text, a link, an image, or a file. | Services error returned for an unsupported pasteboard. | None specified |
| `Config/AppInfo.plist:41` | Send with Clipboard Drop | macOS Services menu item. | None specified |
| `Config/AppInfo.plist:46` | Clipboard Drop | Services port name (system registration value). | Internal value |
| `ClipDrop/App/Intents/ClipDropIntents.swift:13` | Send Text | App Intent display name. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:14` | Send text with Clipboard Drop. | App Intent description. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:17` | Text / The text to send. | Send Text parameter title and description. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:20` | Edit before sending | Optional Send Text parameter, default off. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:24` | Send {Text} | Send Text parameter summary. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:41` | Send Clipboard | App Intent display name. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:42` | Send the current clipboard with Clipboard Drop. | App Intent description. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:46` | Send the current clipboard | Send Clipboard parameter summary. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:61` | Show QR Code | App Intent display name. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:62` | Show a QR code for text with Clipboard Drop. | App Intent description. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:65` | Text / The text to encode as a QR code. | Show QR Code parameter title and description. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:69` | Show a QR code for {Text} | Show QR Code parameter summary. | None specified |
| `ClipDrop/App/Intents/ClipDropIntents.swift:87-88` | Send clipboard with {App Name} / Send Clipboard | Send Clipboard App Shortcut phrase and short title. | Short title |
| `ClipDrop/App/Intents/ClipDropIntents.swift:93-94` | Send text with {App Name} / Send Text | Send Text App Shortcut phrase and short title. | Short title |
| `ClipDrop/App/Intents/ClipDropIntents.swift:99-100` | Show a QR code with {App Name} / Show QR Code | Show QR Code App Shortcut phrase and short title. | Short title |

## Kiki 0.12 follow-up

| Location (`file:line`) | Current English | Purpose / context | Length limit |
| --- | --- | --- | --- |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:21` | Allow Clipboard Drop in System Settings › Login Items to finish enabling it. | Explains that macOS requires approval for the login item. | None specified |
| `ClipDrop/Features/Settings/ClipDropShortcutSettingsSection.swift:22` | Open Login Items | Opens System Settings to the Login Items approval state. | Short button label |
