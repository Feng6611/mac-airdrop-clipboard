# Clipboard Drop 迭代计划（2026-10-24）

> **状态更新（2026-10-24 当天）**：owner 决定把 §5 的 1.2 / 1.3 / 1.4 全部合并进 1.2.0，并选定定位 A。
> 已实现并提交审核：免费化、Kiki 0.12.0、全局快捷键、右键菜单、拖到图标、Services、App Intents、
> 编辑后发送、多条合并、二维码、图片/截图、富文本、链接直发、登录启动、评分请求。
> 未做（与本文一致）：指定设备直发、云中转、Share Extension。Android 实机验证仍待 owner 测试。
> 下文保留当时的调研与取舍，版本切分以本段为准。

方向已定：开源（MIT）、Mac App Store 永久免费、删除全部付费代码、升级 Kiki，
支持方式改为“用作者的其他 App、GitHub star、GitHub/X 关注、App Store 评分”。
本文回答四个问题：现在是什么状态、该做哪些新能力、怎么定位、关键词为什么没命中。
第二意见来自 Codex GPT-6.1-Sol（经 Paseo，只读），采纳与不采纳见 §6。

## 1. 现状（2026-10-24 实读）

| 项 | 事实 | 来源 |
|---|---|---|
| 线上版本 | 1.1.0（2026-07-22），免费，0 评分，仅 en-US | iTunes lookup、`asc versions list` |
| Subtitle | `Send copied text as txt` | `asc localizations list --type app-info` |
| Keywords | `share,paste,copy,transfer,iphone,ipad,nearby,link,url,universal,handoff,sync,file,notes` | `asc localizations list` |
| IAP | lifetime / supporter 两个都是 `MISSING_METADATA`，从未上线 | `asc iap list` |
| main 分支 | 试用 + 付费墙 + RevenueCat 已写好但没发布；钉 Kiki 0.10.0 + Commerce 0.3.0 | `Package.resolved`、git log |
| 部署目标 | 工程 `MACOSX_DEPLOYMENT_TARGET = 13.0`；README/官网写 macOS 14 | `project.pbxproj` |
| 能力 | 剪贴板文本/http(s) 链接 → 临时 .txt/.md/.url → `NSSharingService(.sendViaAirDrop)` | `Platform/Sharing/ClipboardSenderService.swift` |

结论：**没有付费用户需要迁移**，免费化就是删代码，不涉及恢复购买或老用户补偿。

需要顺手纠正的不一致：

- 官网 `sale/sites/kkuk-sites/sites/clipboarddrop/src/config/facts.ts` 仍写 `$5.99`；README 写 Pro 和两档价格。
- 线上描述写 “No clipboard history”，代码其实有内存历史（退出即清）。
- `llms.txt` 的仓库链接是 `mac_airdrop_clipboard`（下划线），实际仓库是 `mac-airdrop-clipboard`。
- 临时文件只在下次启动时清理，“不落盘”的说法不严谨；应在退出时和发送完成后清理。
- `.github/FUNDING.yml` 指向 Buy Me a Coffee，和“不收钱”的支持方式冲突（待你确认是否删除）。
- 本地有一份旧 checkout `~/Documents/ada/mac_airdrop_clipboard`，落后 10 个提交；
  registry 登记的路径 `build/mac-airdrop-clipboard/` 本次已重新 clone。

## 2. 市场与平台变化（调研）

**直接竞品 Menu Drop（Sindre Sorhus，免费，id6754022187）**：拖文件、图片、链接、文本到菜单栏图标就弹 AirDrop，
也能发剪贴板，快捷键可设，不联网。要求 macOS 26，富文本会转成纯文本。
它在 `menu bar airdrop`、`airdrop shortcut`、`drag and drop airdrop` 都排第一。
**“菜单栏 + 拖放 + 快捷键”已经不能当卖点**，只能当基础能力补齐。

**AirDrop 现在能发到 Android**：2025-11 起 Pixel 10，2026-02 扩展到 Pixel 9，
2026-03/05 Samsung Galaxy S24–S26、Z Fold/Flip 6–7 陆续支持，Oppo/OnePlus/Vivo 部分机型也在列。
Apple 设备这边要临时设成 “Everyone for 10 minutes”；Contacts Only 还不能跨平台。
对 Clipboard Drop 来说，这意味着**不装 App 就能把 Mac 上的文字发到 Android 手机**，是一个新场景，也是一组新关键词。
（[MacRumors](https://www.macrumors.com/2026/02/11/airdrop-quick-share-interoperability-more-phones/)、
[Android Authority](https://www.androidauthority.com/quick-share-airdrop-functionality-macos-ipad-3618107/)）
具体哪些机型能收 `.txt`/`.url`、打开后长什么样，**还没有实机验证**，宣传前必须测。

**AirDrop 码（iOS/macOS 26.2）**：发给不在通讯录里的人时，接收方显示一次性码，发送方输入；
之后 30 天互为临时联系人。正好对应 Clipboard Drop 的“不同 Apple ID”场景：首次多一步，之后更顺。
这是系统行为，App 不用改，但 Onboarding/FAQ 要讲清楚。
（[MacRumors](https://www.macrumors.com/2025/11/17/ios-26-2-airdrop-codes/)、[Six Colors](https://sixcolors.com/post/2025/12/airdrop-codes-allow-temporary-persistent-contact/)）

**系统限制（不变）**：没有公开 API 能列出附近设备或指定接收人，所以每次都必须在系统面板里选设备；
“一键发给上次那台”做不了，不排期。

## 3. 定位

当前 “Different Apple ID? Send copied text with AirDrop” 太窄：只说出一个场景，Subtitle 还把结果写成 “as txt”，把实现细节当成了卖点。

候选：

| 方案 | 一句话 | wedge | 评价 |
|---|---|---|---|
| A 文本优先 + 发到任何手机（推荐） | 复制的文字和链接，AirDrop 到任何附近的手机：iPhone、不同 Apple ID，现在也包括 Android | 文本/链接专用（格式、编辑、合并）+ 接收方零安装 + 覆盖 Android；对方连 AirDrop 都没有时用 QR 兜底 | 能被搜索承接（airdrop text / send text to android / text to qr）；与 Menu Drop（文件优先、macOS 26 才能用）错开 |
| B 整理后再发（Codex 推荐） | 把复制的内容整理好，一次 AirDrop 出去 | 编辑、保留富文本、多条合并 | 差异真实，但几乎没人这样搜，适合当转化卖点，不适合当搜索定位 |
| C 菜单栏快捷 AirDrop | Mac 菜单栏里的快速 AirDrop 入口 | 少几步、兼容 macOS 13/14 | 与 Menu Drop 正面重叠，不推荐 |

**推荐 A，并把 B 的能力当作 A 的转化理由**：搜索上靠“文字/链接 → 手机（含 Android）”，
落地页和截图上用“发送前能改、能合并、保留格式”说服。
和其他方案的区别：Universal Clipboard 要求同一 Apple ID；LocalSend/Quick Share 应用要两端都装；Menu Drop 以文件为主、只支持 macOS 26。

**名字不改**。`Clipboard Drop` 是唯一排第一的词，域名、官网、截图都已绑定；改名的代价大于收益。
只在 Subtitle 和描述里扩场景。

## 4. 关键词：为什么没命中、怎么改

2026-10-24 美区公开排名（`sale/aso/scripts/rank.py`，前 50，证据 `.local/aso/2026-10-24-clipdrop-us*.json`）：
44 个词里只有 `clipboard drop` #1、`quick airdrop` #36 进前 50。7 月底的 `send text airdrop` #28 已经掉出前 50。

原因（按影响大小推断，未证明）：

1. **Subtitle 浪费**：`Send copied text as txt` 里没有 AirDrop，最强的意图词不在 Title/Subtitle。
2. **Keywords 意图错配**：`universal,handoff,sync` 指向的是剪贴板同步类产品，搜这些词的人要的是自动同步，进不了前排，进了也不转化；
   `iphone,ipad,file,notes` 很宽，竞争者都是大 App。
3. **0 评分 + 功能窄**：同一 SERP 里的剪贴板管理器都有成百上千条评分。
4. **只有 en-US**：解释不了美区的问题，但其他语区完全没有覆盖。
5. **另一个叫 “ClipDrop” 的 App** 出现在 `drag and drop airdrop` 的 SERP 里，品牌词有混淆风险。

方向（定稿走 `/aso-metadata` 完整管线，这里不写成品文案）：

- Title：保留 `Clipboard Drop`，评估加任务后缀（如 “… – AirDrop Text”），30 字符内。
- Subtitle：写结果，包含 AirDrop + 文字/链接 + 手机（iPhone/Android 二选一，看字符）。
- Keywords：删除 `universal,handoff,sync,file,notes,ipad`；只加已上线能力对应的词，例如 android、qr、screenshot（各自随能力上线再加）。
- 1.2 发版同时补 zh-Hans、ja、de-DE（按 aso-metadata 流程做本地调研，不机翻）。

建议追踪的词（入 `sale/aso/keywords/clipboard-drop/`，14–28 天复盘一次）：

| 组 | 词 | 理由 |
|---|---|---|
| 品牌 | `clipboard drop` | 守门 |
| 核心任务 | `airdrop text`、`send text airdrop`、`airdrop clipboard`、`copy to airdrop`、`airdrop link` | 意图与产品完全一致；SERP 前排大多不是专做这件事的 App，有机会 |
| 手机场景 | `send link to iphone`、`send text to iphone`、`airdrop to android`、`send text to android` | Android 是新场景；SERP 被 MacDroid/LocalSend 这类文件工具占着，文本专用是空档 |
| 能力上线后 | `airdrop screenshot`、`text to qr`、`airdrop shortcut` | 图片、QR、快捷键各自上线后再加进字段 |
| 宽词对照 | `airdrop`、`share clipboard` | 只观察，不为它们改定位 |

## 5. 新能力与版本切分

可行性：除注明外都能在 App Sandbox / MAS 里用公开 API 做，不需要辅助功能权限。成本 S/M/L 是相对值。

| 能力 | 价值 | 实现要点 | 成本 | 版本 |
|---|---|---|---|---|
| 全局快捷键发送当前剪贴板 | 不点菜单栏，一键弹 AirDrop | Carbon `RegisterEventHotKey`，沙盒内可用，无需辅助功能 | S | 1.2 |
| 发送成功回调 | 知道真的发出去了，才能做评分请求和清理临时文件 | `NSSharingServiceDelegate` `didShareItems` / `didFailToShareItems` | S | 1.2 |
| 链接直接发 URL 对象 | 对方直接打开网页，而不是收到一个 `.url` 文件 | `perform(withItems: [URL])`，iPhone/Android 两端都要实测 | S | 1.2 |
| 菜单栏右键菜单 | 快捷入口（发送、设置、退出） | Kiki 0.11 `contextMenuItems` | S | 1.2 |
| 发送前编辑 | 删掉隐私内容、补一句说明 | 弹出式小编辑器，可跳过 | S | 1.3 |
| 图片 / 截图 | 截图复制后直接发 PNG（`airdrop screenshot`） | 读 `NSPasteboard` 图片类型，写 PNG；不自建截图 | M | 1.3 |
| 富文本保留 | 发 RTF，格式不丢（Menu Drop 会转成纯文本） | 已存 `attributedText`，补一种发送格式；接收端效果要测 | M | 1.3 |
| 多条合并 | 地址 + 说明 + 链接一次发出 | 历史里多选 → 合并为一个文件 | M | 1.3 |
| QR 兜底 | 对方没有 AirDrop（旧 Android、Windows 旁边的手机）时扫码拿走 | `CIQRCodeGenerator`，纯本地；只做短文本/URL，不做文件中转 | S | 1.3 |
| Services 菜单 “Send with Clipboard Drop” | 选中文字就能发，不用先复制 | `NSServices` + 服务 provider，沙盒可用 | M | 1.4 |
| App Intents / Shortcuts | 进 Spotlight 和快捷指令 | App Intents，仍需前台选设备 | M | 1.4 |
| 拖到菜单栏图标 | 补齐基础能力（与 Menu Drop 持平） | Kiki 目前没有拖放接口：先在 Kiki 加，或 App 内自己接 status item 的 drag | M | 1.4 |
| Share Extension | 系统分享菜单本来就有 AirDrop，收益不明 | 独立 target | L | 不排期 |
| 指定上次的设备直发 | 无公开 API | — | — | 不做 |
| 云中转 / 局域网下载大文件 | 违背“不联网、零服务器” | — | — | 不做 |

### 1.2 — 免费化 + Kiki 0.11 + 两个小能力

范围：

- 删除 KikiCommerceKit、RevenueCat、试用、付费墙、`ClipDropPurchasePlan`、`ClipDropRevenueCatConfiguration`、
  `Config/RevenueCat.xcconfig`、`script/verify_revenuecat_api_key.sh`、`Docs/RevenueCat.md`、`audit/`；
  Router 不再有 `performProAction`，发送直接执行；对应约 13 个测试改写或删除。
- 删除 `com.apple.security.network.client` 授权，App 完全不联网，隐私说法从“不收集”升级为“不能联网”。
- Kiki 0.10.0 → 0.11.0（钉 exact tag）；Unreleased 的 Launch at Login 批准状态等发版后再跟。
- Onboarding 去掉付费页，改成 2 步：怎么用 + AirDrop 设置提示（Everyone for 10 minutes / AirDrop 码）。
- About 页的支持区：Rate on App Store、Star on GitHub、Follow on GitHub / X、作者的其他 App（Command Reopen 等）。
- 评分请求：`KikiReviewRequestPolicy.recommended`，以 `didShareItems` 成功次数（例如 3 次）为门槛，用系统 `AppStore.requestReview`，不用自定义弹窗。
- 全局快捷键、链接发 URL 对象、右键菜单、发送后清理临时文件。
- registry：`profile`/`dependency_policy` 改成 free，去掉 `commerce_version_policy`。
- ASC：两个 IAP 删除或停售（本人操作）；元数据按 §4 改写并补 3 个语区。
- 官网 facts、README、llms.txt、描述同步免费和新事实。

不做：新内容类型、拖放、Extension。

### 1.3 — 主要新能力（文本优先 + 任何手机）

编辑后发送、图片/截图、富文本、多条合并、QR 兜底。
发版前做一次 iPhone（不同 Apple ID，含 AirDrop 码）和至少一台 Android（Pixel 9/10 或 Galaxy S24+）的实机矩阵，
只把测过的机型写进官网和描述。Keywords 加入 android / screenshot / qr。

不做：文件管理、扩展、云服务。

### 1.4 — 入口铺开

Services 菜单、App Intents、拖到菜单栏图标（先评估加进 Kiki，供其他菜单栏 App 共用）。

### 增长侧（与版本并行）

- GitHub README 重写：首屏写清场景（不同 Apple ID / Android / QR），加 GIF、Star 引导；
  提交到 awesome-macOS、open-source-mac-os-apps 这类开源清单（走 `/backlinks`）。
- 官网加一篇 “How to send text from Mac to Android without an app (2026)” 类的文章（走 `seo-content`），承接 Android 新场景。
- 0 评分是首要信任缺口：1.2 的评分请求上线后，看 4 周的评分数。

## 6. 和 Codex 的分歧与取舍

采纳：

- 免费化要连 Router、启动流程、依赖一起删，不能只隐藏付费墙。
- “AirDrop 已打开”不等于发送成功，评分请求要挂在发送成功回调上。
- 临时文件清理时机、官网 `$5.99`、README Pro 残留。
- 最近设备直发、云中转不排期；Share Extension 先不做。
- 不改名。

不采纳 / 调整：

- Codex 推荐定位 B（整理后再发）。我改为 A：B 的差异是真的，但没有可承接的搜索需求；
  Android 互通是 2026 年真实发生的新场景，搜索面也明确。B 的能力保留，作为转化卖点。
- Codex 的追踪词没有 Android 组，已补上。
- Codex 把 QR 放在 1.4；QR 实现成本 S，又直接服务“任何手机”的定位，提前到 1.3。

## 7. 需要你决定 / 本人操作

1. 定位是否按 A 走。
2. X 账号确认（工作区里只找到 `x.com/chen31641727` 一处引用）。
3. `.github/FUNDING.yml`（Buy Me a Coffee）是否删除。
4. 部署目标：建议保持 macOS 13（Kiki 0.11.0 的 `Package.swift` 最低也是 macOS 13），把 README/官网的 “14” 改成 13；
   比 Menu Drop（要求 macOS 26）覆盖更多老机器，可以写进卖点。
5. 本人操作：ASC 删除或停售两个 IAP、RevenueCat 项目归档、Android 实机测试设备。
