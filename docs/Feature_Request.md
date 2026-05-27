## New Requests
- [ ] 打包成macOS App，dmg安装格式


## Refined Requests

### 📦 [Refined] Antigravity ArchiveViewer macOS 原生桌面化与 DMG 打包规范

#### 1. 产品定位与目标 (Product Goal)
将当前的 "命令行启动服务 + IDE 内嵌浏览器" 运行模式，升级为**免终端、双击即用、带有系统托盘菜单（Menu Bar Tray）的 macOS 原生桌面应用程序（.app / .dmg）**。实现零配置全图形化操作，进一步降低非技术人员的使用壁垒。

---

#### 2. 技术选型分析 (Architectural Options)

我们为实现该打包目标规划了以下三种业界主流技术路线：

| 维度指标 | 方案 A：Tauri 纯原生（推荐 🌟） | 方案 B：Tauri + Node.js 侧边栏 | 方案 C：Electron 传统打包 |
| :--- | :--- | :--- | :--- |
| **技术架构** | **Rust (后端系统层) + Webview (前端)** | **Rust 壳 + Node.js 二进制 Sidecar** | **Node.js (Main) + Chromium (Renderer)** |
| **后端重构** | **需重构**（使用 Rust 重写文件 I/O、正则 AND 全文搜索、日历聚合数据接口） | **无需重构**（打包 server.js 为二进制子进程） | **无需重构**（直接复用当前全部 JS 代码） |
| **包体积大小** | **极小（约 5MB ~ 8MB）** | 中等（约 30MB ~ 50MB） | 较大（约 80MB ~ 120MB） |
| **系统能耗开销**| **极低**（仅占用约 15MB 内存，0% 闲置 CPU）| 中等（Node 进程与 Rust 壳并存） | 较高（Chromium 渲染器与 Node 并存） |
| **对系统 Node 依赖** | **0 依赖**（完全独立于系统环境，极其健壮）| 依赖内嵌编译的 Node.js 运行时环境 | 依赖内嵌编译的 Node.js 运行时环境 |

> **🌟 深度推荐 方案 A (Tauri 纯原生重构)**：
> 虽然需要用 Rust 重写 `server.js` 约 300 行的文件解析和正则搜索逻辑，但由于 Rust 具备极致的文件读取性能与安全性，不仅搜索日志效率能翻倍提升，最终打包出的 App 仅有约 **8MB** 大小，开机常驻能耗几乎为零，非常符合 ArchiveViewer 极客精美的产品调性。

---

#### 3. 原生桌面级交互集成规范 (UI/UX Integration Spec)

1. **系统菜单栏托盘（Menu Bar Tray Icon）**：
   - 应用程序启动后默认静默收纳至 macOS 右上角菜单栏；
   - **左键单击**：平滑升起 Mini 大盘面板（或控制窗口显示/隐藏）；
   - **右键单击**：弹出原生上下文菜单，包含以下功能：
     * `🔮 打开 ArchiveViewer`
     * `⏱️ 自动刷新设置` (子菜单：手动 / 5s / 15s / 30s)
     * `⚙️ 偏好设置` (可自定义 Brain 归档数据目录)
     * `🔄 重载服务`
     * `❌ 彻底退出`
2. **开机自启一键托管（Auto-start on Login）**：
   - 在客户端 UI 内集成“开机自动拉起”的 Toggle 拨盘；
   - 启用后，由 App 自动在系统中注册登录启动项，**彻底替代并废除繁琐的 `com.hanson.antigravity-av.plist` 手动 Launch Agent 运维配置**。
3. **系统主题无缝同步（System Theme Sync）**：
   - 智能侦听 macOS 系统级的深色/浅色模式切换事件，自动将 Webview 内的主题色平滑渲染为对应的 Cyber Dark 或 Minimalist Light 皮肤。
4. **原生通知召回（Native Notifications）**：
   - 当本地归档有新的大规模更新、或后台检测到重点日志步骤写入时，触发 macOS 原生 Banner 通知横幅。

---

#### 4. DMG 安装包视觉美学规范 (DMG Visual Design)

* **一键拖拽拖装**：
  DMG 挂载后，呈现高保真的引导安装窗口。窗口背景采用精心调制的暗黑霓虹渐变（HSL 紫光呼吸渐变），左侧为 `ArchiveViewer.app` 图标，右侧为系统 `Applications` 快捷方式，中间以丝滑的霓虹箭头指示拖拽安装。
* **数字签名与公证（Notarization）**：
  为避免 macOS 弹出“无法打开已损坏的应用程序”安全警告，在打包流水线中需支持通过 `Developer ID` 对 `.app` 进行代码签名，并提交 Apple 进行公证认证，确保开箱双击即用。

---

## Implemented Requests

