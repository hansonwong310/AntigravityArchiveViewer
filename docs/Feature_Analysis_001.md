# 📑 需求分析说明书: FA-001 - macOS 原生桌面化与 DMG 编译打包

---

## 📌 1. 基础信息 (Basic Information)
* **需求编号 (ID)**: FA-001
* **需求名称 (Title)**: macOS 原生桌面应用程序与 DMG 安装包打包编译
* **优先级 (Priority)**: High
* **状态 (Status)**: Under Review (待确认)
* **提出时间 (Proposed)**: 2026-05-27
* **适用版本 (Target Version)**: v1.0.0

---

## 🎯 2. 背景与核心价值 (Background & Core Value)
* **现状痛点**：目前 ArchiveViewer 运行依赖于终端命令行或 IDE 的 Task 任务启动，用户需要开启终端运行 `./AntigravityAV.sh`。这种方式对非技术用户不够友好，且如果 IDE 退出，可能会产生端口孤儿进程。
* **业务价值**：
  * **零壁垒上手**：提供双击即可运行的 `.app` 原生程序，彻底脱离终端命令行。
  * **独立的常驻能力**：借助系统常驻与优雅关闭（Graceful Shutdown）机制，应用退出时自动回收 Node.js 进程，保障系统端口安全。
  * **原生 OS 融合**：在 macOS 窗口体系内运行，支持透明毛玻璃标题栏，并完美对齐 macOS 系统的全局复制、粘贴剪切板热键。

---

## 📋 3. 详细需求范围与规范 (Functional Requirements)

### 3.1 原生 Swift GUI 壳规范 (Native Swift Shell)
* **编译规范**：使用 macOS 预装的原生 `swiftc` 编译器将 Cocoa 原生入口 `main.swift` 编译为 arm64 架构的本地机器码二进制文件（不依赖任何第三方运行时，体积小于 500KB）。
* **进程生命周期守护 (Process Lifecycle Guard)**：
  * **启动时**：后台异步拉起 `agy-node server.js`。自动扫描 `agy-node` 默认安装路径，如不存在则平滑降级使用系统 node。
  * **退出时**：捕获系统的 `applicationWillTerminate` 退出生命周期，向 Node 子进程发送 `terminate()` 信号，实现**服务端口自动回收**，杜绝孤儿进程占用 5173 端口。
* **窗口级 UI 呈现**：
  * 窗口尺寸固定为 **1200 x 800**，支持缩放与拖拽。
  * 标题栏设为透明（`titlebarAppearsTransparent = true`），背景色预设为与 `app.css` 一致的极客暗黑底色（#0a0b10），消除 WebView 载入时的白屏闪烁。
  * 使用 WebKit 的 `WKWebView` 异步载入 `http://localhost:5173`。
* **快捷键映射补全**：
  * 动态构建 App 的主菜单（Main Menu），必须包含“编辑”子菜单（撤销/重做/剪切/复制/粘贴/全选），确保 `Cmd+C` / `Cmd+V` 在 WebView 输入框内完全可用。

### 3.2 自动化编译发布管道规范 (Build Pipeline)
* **目录结构生成**：一键生成 macOS 标准的 App Bundle 树状目录：
  ```text
  ArchiveViewer.app/
    Contents/
      Info.plist
      MacOS/
        ArchiveViewer (Swift 编译出的原生二进制)
      Resources/
        server.js
        public/ (index.html 与 app.css)
  ```
* **Info.plist 生成**：生成符合苹果官方规范的元属性文件，声明 `CFBundleExecutable`、`CFBundleIdentifier`（`com.hanson.antigravity-av-app`）及高分屏支持（`NSHighResolutionCapable`）。
* **DMG 安装镜像制作**：
  * 一键调用 macOS 系统自带的 `hdiutil` 磁盘镜像工具，将 `.app` 包压缩打包为挂载式镜像安装包 `ArchiveViewer.dmg`；
  * 打包完成后，自动清理根目录临时产生的 `.app` 文件夹，保持开发空间根目录极致干净。

---

## 🏗️ 4. 技术可行性与可行性审计 (Technical Audits)
* **环境兼容性**：
  * 本地已安装 Swift 6.3.1 编译器（Arm64 架构），完全满足 `swiftc` 本地极速编译要求；
  * 系统自带 `hdiutil`，完全满足 DMG 制作要求；
  * `server.js` 采用 0-Dependency 设计，可以直接在 App 内置的 `Contents/Resources/` 路径下被 `agy-node` 无缝执行。
* **能耗与体积**：
  * 编译后 App 安装包约 1.5MB（含全部 web 静态资源），比 Electron 方案（> 100MB）轻量约 98%；
  * 运行内存仅 15MB 左右，极其符合高能效开发要求。

---

## ✅ 5. 验收测试标准 (Acceptance Criteria)
1. **自动化编译通过**：执行 `./build.sh` 后，必须在 `release/` 目录下无错生成 `ArchiveViewer.dmg`；
2. **根目录整洁**：执行完 `./build.sh` 后，项目根目录下不得残留任何 `ArchiveViewer.app` 临时目录或 `.dmg` 临时文件；
3. **App 运行测试**：双击运行生成的 App，大盘面板必须在 1.2 秒延时内平滑显示；
4. **编辑功能测试**：在搜索框内使用 `Cmd+A` 全选和 `Cmd+C` 复制必须完全响应正常；
5. **端口释放测试**：彻底关闭 App 窗口后，终端运行 `lsof -i :5173` 必须无输出，验证端口已完美回收。
