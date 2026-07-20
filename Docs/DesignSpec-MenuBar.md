# Clipboard Drop — Menu Bar Popover 设计规范 v1

菜单栏 popover 的组件契约与设计 token 的唯一说明来源。实现见
`ClipDrop/Shared/ClipDropDesignToken.swift` 与 `ClipDrop/Features/MenuBar/`。

## 设计原则

1. **系统优先**：贴合 macOS HIG。默认走系统外观、系统灰阶、系统控件反馈，
   不自造视觉。
2. **品牌紫收敛**：品牌紫仅用于「App 标识」（头部小徽标）和「Pro 相关 CTA」。
   剪贴板列表内的一切（内容类型图标、发送/复制按钮、hover）**全部使用系统灰阶**。
3. **动作优先级明确**：App 名为 Clipboard *Drop*，英雄动作是「AirDrop 发送」。
   行的主操作 = 发送；复制为次操作。
4. **随内容收紧**：popover 尺寸紧凑（窄、矮），列表在内部滚动，不留大片空白。
   > 注：真正的 hug-content（随条目数自适应高度）需改共享包 `Kiki_mackit`
   > 的 `NSHostingController.sizingOptions` 并跨仓库发版，暂缓；当前只在 app 内收紧固定尺寸。

## 尺寸 token（`Size`）

| token | 值 | 说明 |
| --- | --- | --- |
| `popoverWidth` | 400 | 内容优先：保证 2–3 行预览的信息量（v1 曾收到 320，实测内容太少，回调） |
| `popoverHeight` | 336 | 约容纳 3–4 行后内部滚动，避免少量记录时留下大面积空白 |
| `rowMinHeight` | 48 | 行最小高度，保证命中区 |
| `brandMark` | 18 | 头部品牌徽标尺寸（唯一品牌紫图标） |
| `leadingIcon` | 18 | 行首内容类型图标 |
| `iconButtonHit` | 26 | 图标按钮命中区（≥ 24 HIG 最小值） |

## 间距 token（`Spacing`）

| token | 值 | 用途 |
| --- | --- | --- |
| `page` | 12 | 页面水平内边距 |
| `headerVertical` | 8 | 头部垂直内边距（单行头部，压薄） |
| `footerVertical` | 8 | 底部垂直内边距 |
| `rowVertical` | 6 | 行垂直内边距 |
| `rowHorizontal` | 10 | 行内水平间距 |

## 颜色 token（`Colors`）

- `brand`：品牌紫，**深浅色自适应**。浅色 `#7852F2`，深色提亮至 `#9E82FA`，
  保证深色底上对比度。仅用于头部徽标与 Pro CTA。
- `rowHover`：`Color.primary.opacity(0.06)`，系统灰阶，行 hover / 键盘选中反馈。
- 行内容图标、发送/复制按钮：`.secondary`（系统灰阶），禁用态 `.tertiary`。

## 排版角色（Typography）

与 Settings 窗口同级：popover 内控件用系统默认 `regular` controlSize，
不再整体调小一号（v1 用 `.small` + `subheadline`，实测观感偏小，回调）。

| 角色 | 字体 | 用途 |
| --- | --- | --- |
| 标题 | `headline` | 头部 App 名 |
| 行主文 | `body` | 剪贴板内容（最多 3 行） |
| 空态主文 | `subheadline`.medium | 空列表标题 |
| 空态引导 | `caption` `.secondary` | 空列表引导语 |

不显示时间戳：菜单栏 popover 是「拿了就走」的瞬时界面，时间元数据是噪音。

## 组件契约

### Header（单行，常驻）
- 左：品牌徽标（`paperplane.fill`，18pt，品牌紫）+ App 名。
- 右：溢出菜单按钮（`ellipsis.circle`），**常驻**（不再仅在有历史时出现）。
- 移除原「大徽标 + 副标题状态行」双层结构与零信息的 "Ready to send"。

### 溢出菜单（`ellipsis.circle`）
承载低频/破坏性全局动作：
- Clear Clipboard History（destructive，仅有历史时可用）
- Settings…（⌘,）——冗余入口，主入口在 footer
- Quit Clipboard Drop（⌘Q）——用**文字 + 真实退出语义**，
  不再用 `power`（关机语义）图标。

### 列表行（Row）
- 状态：rest / hover / keyboard-selected / sending。
- hover 与键盘选中显示 `rowHover` 系统灰阶背景。
- `List` 只负责系统滚动与行容器，不绑定原生 selection；选中态由行组件自己绘制，
  避免用户的 macOS 强调色变成整行高饱和背景。打开 popover 时默认无选中项，
  第一次按 ↑ / ↓ 后才进入键盘选中态。
- **主操作**（整行点击 / Return / 行尾常驻 `paperplane` 按钮）= 通过 AirDrop 发送。
  发送按钮**常驻可见**——英雄动作必须有可见可供性，不能只靠整行点击的隐性行为。
- **次操作** = 复制：行尾 `doc.on.doc` 按钮，**hover / 键盘选中时浮现**（rest 态隐藏，
  参考 Raycast 的 hover 显操作），另有右键菜单 + ⌘C。
- 布局：`[内容类型图标] [主文 ≤3 行] —spacer— [复制按钮(hover)] [发送按钮(常驻)]`。
- 不显示时间戳。
- sending 时禁用发送、按钮转 `.tertiary`。

### 空态（Empty）
- 居中：`doc.on.clipboard`（tertiary）+ 主文 + 引导语。

### Footer（常驻）
- 左：Pro CTA（品牌紫 `sparkles`），仅非 Pro 时出现。
- 右：**Settings 按钮（`gearshape` + 文字）常驻**——设置是高频入口，
  必须一击可达，不能只藏在溢出菜单里（v1 只放溢出菜单，实测难点，回调）。

## 文案（Copy）

口吻：短、动作导向、始终指向「AirDrop 发送」这个价值主张。

| 位置 | 文案 |
| --- | --- |
| 空态主文 | `Clipboard is empty` |
| 空态引导 | `Copy text or a link — it shows up here, ready to AirDrop.` |
| 行 tooltip / a11y | `Send via AirDrop` |
| 复制按钮 | `Copy` |
| 溢出菜单 | `Clear History…` / `Settings…` / `Quit Clipboard Drop` |
| Pro CTA | `Try Pro` / `Trial · Nd left` / `Unlock Pro` |

## 键盘映射（app 内可达范围，macOS 13）
- ↑ / ↓：在列表内移动 App 自管的中性选中态。
- Return：对选中行执行发送。
- ⌘C：复制选中行。
- ⌘,：打开设置。⌘Q：退出。
- 说明：Return / ⌘C 通过绑定选中项的隐藏 default-action 按钮实现；
  更完整的按键处理需 macOS 14 的 `.onKeyPress` 或 AppKit 本地事件监听，暂不引入。
