# Task P copy inventory

User-facing English added or changed for the Clipboard Drop content pipeline. “No hard limit” means the source has no enforced character cap; suggested targets are for the current UI surface.

| 位置 file:line | 当前英文 | 用途/上下文 | 长度限制 |
|---|---|---|---|
| `ClipDrop/App/ClipDropAppRouter.swift:98` | QR Code | QR 窗口标题 | 无硬限制；建议 ≤24 字符 |
| `ClipDrop/App/ClipDropAppRouter.swift:161` | Edit and Send | 编辑窗口标题 | 无硬限制；建议 ≤30 字符 |
| `ClipDrop/Features/Compose/ClipDropComposeView.swift:18` | Message | 编辑器无障碍名称 | 无硬限制；建议 ≤30 字符 |
| `ClipDrop/Features/Compose/ClipDropComposeView.swift:26` | Cancel | 编辑窗口取消按钮 | 无硬限制；建议 ≤16 字符 |
| `ClipDrop/Features/Compose/ClipDropComposeView.swift:28` | Send | 编辑窗口发送按钮 | 无硬限制；建议 ≤16 字符 |
| `ClipDrop/Features/QRCode/ClipDropQRCodeView.swift:47` | QR code | 二维码图像无障碍名称 | 无硬限制；建议 ≤24 字符 |
| `ClipDrop/Features/QRCode/ClipDropQRCodeView.swift:53` | This content is too long for a QR code. | 超过 M 级二维码容量时的说明 | 无硬限制；建议 ≤60 字符，可换行 |
| `ClipDrop/Features/QRCode/ClipDropQRCodeView.swift:55` | Copy shorter text or a shorter link, then try again. | 二维码容量错误的操作建议 | 无硬限制；建议 ≤80 字符，可换行 |
| `ClipDrop/Features/QRCode/ClipDropQRCodeView.swift:72` | Copy | 复制二维码预览文本 | 无硬限制；建议 ≤16 字符 |
| `ClipDrop/Features/MenuBar/ClipDropMenuPopoverView.swift:55` | Select Items to Merge / Cancel Selection | 溢出菜单开启合并选择或退出选择 | 无硬限制；建议每项 ≤30 字符 |
| `ClipDrop/Features/MenuBar/ClipDropMenuPopoverView.swift:164` | Images and files can’t be merged. | 选择中含不可合并项目时的提示 | 无硬限制；建议 ≤60 字符，可换行 |
| `ClipDrop/Features/MenuBar/ClipDropMenuPopoverView.swift:174` | Sending… | Popover 发送状态 | 无硬限制；建议 ≤20 字符 |
| `ClipDrop/Features/MenuBar/ClipDropMenuPopoverView.swift:182,184` | Send 1 Item / Send {count} Items; Cancel | 合并发送动作和退出选择 | 动作按钮建议 ≤30 字符；Cancel ≤16 字符 |
| `ClipDrop/Features/MenuBar/ClipDropRecentItemRow.swift:46,77` | Select item / Remove from selection | 合并选择行的帮助与无障碍标签 | 无硬限制；建议每项 ≤30 字符 |
| `ClipDrop/Features/MenuBar/ClipDropRecentItemRow.swift:46,55` | Send via AirDrop | 行帮助文字与右键菜单发送动作 | 无硬限制；建议 ≤30 字符 |
| `ClipDrop/Features/MenuBar/ClipDropRecentItemRow.swift:60` | Edit and Send… | 右键菜单编辑后发送 | 无硬限制；建议 ≤30 字符 |
| `ClipDrop/Features/MenuBar/ClipDropRecentItemRow.swift:63` | Show QR Code | 右键菜单显示二维码 | 无硬限制；建议 ≤30 字符 |
| `ClipDrop/Features/MenuBar/ClipDropRecentItemRow.swift:70` | Copy | 右键菜单复制历史项 | 无硬限制；建议 ≤16 字符 |
| `ClipDrop/Features/MenuBar/ClipDropRecentItemRow.swift:79` | Send {content type} via AirDrop | 历史项无障碍标签；类型为 Text、Text (Formatted)、Link、Image 或 Files | 无硬限制；供 VoiceOver 使用 |
| `ClipDrop/Platform/Clipboard/ClipboardHistoryItem.swift:71,73` | Image / Files | 新的内容类型名称，也用于行无障碍标签 | 无硬限制；建议每项 ≤20 字符 |
| `ClipDrop/Shared/ClipDropSendPreferences.swift:45` | Direct | 链接发送格式选项；默认直接发送 URL | 无硬限制；建议 ≤16 字符 |
| `ClipDrop/Features/Settings/ClipDropSendSettingsSection.swift:15` | File Formats | 发送格式设置组标题（既有标题，随设置区整理列出） | 无硬限制；建议 ≤30 字符 |
| `ClipDrop/Features/Settings/ClipDropSendSettingsSection.swift:16` | Links are sent directly by default. Choose a file format as a fallback. | 说明链接默认直发及文件回退选项 | 无硬限制；建议 ≤100 字符，可换行 |
| `ClipDrop/Features/Settings/ClipDropSendSettingsSection.swift:19,29` | Copied text / Copied link | 文本和链接的发送格式选择器（既有行标题，随设置区整理列出） | 无硬限制；建议每项 ≤30 字符 |
| `ClipDrop/Features/Settings/ClipDropSendSettingsSection.swift:39` | Sending | 发送行为设置组标题 | 无硬限制；建议 ≤24 字符 |
| `ClipDrop/Features/Settings/ClipDropSendSettingsSection.swift:40` | Keep formatting | 富文本保留格式开关；默认开启 | 无硬限制；建议 ≤30 字符 |
| `ClipDrop/Features/Settings/ClipDropSendSettingsSection.swift:41` | Rich text is sent as RTF. RTFD attachments may be simplified. | 说明富文本 RTF 发送及 RTFD 附件降级 | 无硬限制；建议 ≤100 字符，可换行 |
| `ClipDrop/Features/Settings/ClipDropSendSettingsSection.swift:42` | Edit before sending | 文本与链接发送前编辑开关；默认关闭 | 无硬限制；建议 ≤30 字符 |
| `ClipDrop/Features/Settings/ClipDropSendSettingsSection.swift:43` | Open an editor before sending text or links. | 编辑开关说明 | 无硬限制；建议 ≤80 字符，可换行 |
| `ClipDrop/Platform/Clipboard/ClipboardHistoryStore.swift:10` | Clipboard Drop could not copy the selected item to the clipboard. | 复制历史项目失败错误（文案已从仅指文本改为支持各类内容） | 无硬限制；建议 ≤100 字符 |
| `ClipDrop/Platform/Sharing/ClipboardSenderService.swift:13` | The clipboard does not contain sendable content. | 剪贴板没有可发送内容时的错误 | 无硬限制；建议 ≤80 字符 |
| `ClipDrop/Platform/Sharing/ClipboardSenderService.swift:26` | Copy text, a link, an image, or files before sending. | 无可发送内容时的恢复建议 | 无硬限制；建议 ≤80 字符，可换行 |
| `ClipDrop/App/ClipDropController.swift:92` | AirDrop sent file names because the app couldn’t access the files. | Finder 文件 URL 无法读取时显示的回退结果；Popovers 在 `ClipDropMenuPopoverView.swift:156` 呈现 | 无硬限制；建议 ≤100 字符，可换行 |
