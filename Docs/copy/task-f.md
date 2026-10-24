# Task F copy inventory

Strings below are new or changed in task F. There are no enforced character
limits for these rows in the current UI; keep About titles concise and allow
onboarding details to wrap.

| 位置 file:line | 当前英文 | 用途/上下文 | 长度限制 |
| --- | --- | --- | --- |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:132` | `Send with AirDrop` | Onboarding step 1 title | Short title |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:134` | `Help the receiver accept AirDrop` | Onboarding step 2 title | Short title |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:141` | `Copy text or a link, open Clipboard Drop from the menu bar, choose Send, then pick a device. The other person doesn’t need to install this app.` | Onboarding step 1 summary | Wraps |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:143` | `A few AirDrop settings can help the other person receive your file.` | Onboarding step 2 summary | Wraps |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:150` | `Continue` | Onboarding step 1 primary action | Short button label |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:152` | `Done` | Onboarding step 2 completion action | Short button label |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:158` | `Back` | Onboarding step 2 back action | Short button label |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:167` | `Copy text or a link` | Onboarding step 1 row title | Short row title |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:168` | `Copy the content you want to send.` | Onboarding step 1 row detail | Wraps |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:172` | `Open Clipboard Drop` | Onboarding step 1 row title | Short row title |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:173` | `Choose Send from the menu bar app.` | Onboarding step 1 row detail | Wraps |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:177` | `Pick a device` | Onboarding step 1 row title | Short row title |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:178` | `The other person doesn’t need to install this app.` | Onboarding step 1 row detail | Wraps |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:185` | `Everyone for 10 Minutes` | Onboarding step 2 row title | Short row title |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:186` | `If the other person isn’t in Contacts, they can set AirDrop to Everyone for 10 Minutes.` | Onboarding step 2 row detail | Wraps |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:190` | `AirDrop code` | Onboarding step 2 row title | Short row title |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:191` | `On macOS and iOS 26.2 or later, they may need to enter the code shown on their screen.` | Onboarding step 2 row detail | Wraps |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:195` | `No shared Apple ID` | Onboarding step 2 row title | Short row title |
| `ClipDrop/Features/Onboarding/ClipDropOnboardingFlow.swift:196` | `You don’t need to use the same Apple ID.` | Onboarding step 2 row detail | Wraps |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:63` | `Star on GitHub` | About repository link title | Short row title |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:64` | `Feng6611/mac-airdrop-clipboard` | About repository link value | Short row value |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:70` | `Follow on GitHub` | About author link title | Short row title |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:71` | `Feng6611` | About author link value | Short row value |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:77` | `Rate Clipboard Drop` | About App Store rating link title | Short row title |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:78` | `App Store` | About App Store rating link value | Short row value |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:84` | `Command Reopen` | About other app link title | Short row title |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:85` | `App Store` | About other app link value | Short row value |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:91` | `Privacy` | About privacy link title | Short row title |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:92` | `clipboarddrop.kkuk.dev` | About privacy link value | Short row value |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:98` | `Support` | About support link title | Short row title |
| `ClipDrop/Features/Settings/ClipDropSettingsView.swift:99` | `clipboarddrop.kkuk.dev` | About support link value | Short row value |
| `ClipDrop/App/ClipDropController.swift:77` | `Sent` | Popover status after AirDrop confirms a send | Short status |
| `ClipDrop/App/ClipDropController.swift:78` | `AirDrop confirmed the send.` | Popover detail after confirmed send | Short status detail |
| `ClipDrop/App/ClipDropController.swift:80` | `Send canceled` | Popover status after the user cancels AirDrop | Short status |
| `ClipDrop/App/ClipDropController.swift:81` | `No item was sent.` | Popover detail after cancellation | Short status detail |
| `ClipDrop/Platform/Sharing/ClipboardSenderService.swift:20` | `Couldn’t create the temporary file: {system error}` | Error shown if the temporary send file cannot be written | System error is dynamic |
| `ClipDrop/Platform/Sharing/ClipboardSenderService.swift:22` | `A send is already in progress.` | Error shown if another send is active | Short error |
| `ClipDrop/Platform/Sharing/ClipboardSenderService.swift:33` | `Try sending again.` | Recovery suggestion for a send or temporary-file failure | Short recovery action |
