# 📑 需求分析说明书: FA-004 - 客户端程序及编译输出重命名为 AntigravityArchiveViewer

---

## 📌 1. 基础信息 (Basic Information)
* **需求编号 (ID)**: FA-004
* **需求名称 (Title)**: 客户端应用命名、编译二进制、.app 目录与 DMG 安装包全链路重命名为 AntigravityArchiveViewer
* **优先级 (Priority)**: High
* **状态 (Status)**: Under Review (待确认)
* **提出时间 (Proposed)**: 2026-05-27
* **适用版本 (Target Version)**: v1.1.0

---

## 🎯 2. 背景与核心价值 (Background & Value)
* **现状痛点**：当前编译生成的应用程序目录为 `ArchiveViewer.app`，安装镜像为 `ArchiveViewer.dmg`，原生菜单显示为 `ArchiveViewer`。用户反馈此名称辨识度较低，容易与普通的压缩包阅读器混淆，无法突显其作为 **Antigravity IDE** 生态大盘工具的专属定位。
* **业务价值**：
  - **强化品牌认知**：统一命名为 **`AntigravityArchiveViewer`**，让用户在 Dock 栏、应用列表及访达中一眼看懂其核心功能和归属。
  - **规范化产品交付**：消除所有残存的旧名称，保证安装包与运行时窗口属性的一致性。

---

## 📋 3. 详细重命名范围与规范 (Renaming Scope)

我们将对整个构建生命周期及源代码进行全链路无死角重命名：

### 3.1 原生 Swift 壳重命名 (main.swift)
- **菜单选项更新**：
  将 `setupMenu()` 中硬编码的菜单标题进行对齐：
  * `"关于 ArchiveViewer"` ➡️ `"关于 AntigravityArchiveViewer"`
  * `"隐藏 ArchiveViewer"` ➡️ `"隐藏 AntigravityArchiveViewer"`
  * `"退出 ArchiveViewer"` ➡️ `"退出 AntigravityArchiveViewer"`
- **窗口与进程**：
  * 窗口 Delegate 及内部打印保持与 `AntigravityArchiveViewer` 命名一致。

### 3.2 编译打包脚本重命名 (package.sh)
- **输出包名称**：
  将 `APP_DIR="ArchiveViewer.app"` ➡️ `APP_DIR="AntigravityArchiveViewer.app"`。
- **系统元数据 (Info.plist)**：
  对齐 Info.plist 内的包属性：
  ```xml
  <key>CFBundleExecutable</key>
  <string>AntigravityArchiveViewer</string>
  <key>CFBundleName</key>
  <string>AntigravityArchiveViewer</string>
  <key>CFBundleIdentifier</key>
  <string>com.hanson.antigravity-archive-viewer</string>
  ```
- **编译器二进制输出**：
  `swiftc` 的输出文件名对齐：
  `-o "AntigravityArchiveViewer.app/Contents/MacOS/AntigravityArchiveViewer"`。
- **DMG 镜像卷名与输出**：
  `hdiutil` 生成参数对齐：
  `hdiutil create -fs HFS+ -volname "AntigravityArchiveViewer" -srcfolder "AntigravityArchiveViewer.app" ... AntigravityArchiveViewer.dmg`。

### 3.3 官方发布编译脚本重命名 (build.sh)
- **DMG 移动路径**：
  对齐检测与移动逻辑：
  `mv AntigravityArchiveViewer.dmg release/AntigravityArchiveViewer.dmg`。
- **临时目录清理**：
  对齐临时文件夹清理逻辑：
  `rm -rf AntigravityArchiveViewer.app`。

---

## ✅ 4. 验收测试标准 (Acceptance Criteria)
1. **编译发布包路径校验**：执行 `./build.sh` 后，必须在 `release/` 目录下无错生成 `AntigravityArchiveViewer.dmg`，且根目录下不得残留旧的 `ArchiveViewer.dmg` 或 `ArchiveViewer.app`；
2. **App Bundle 元数据校验**：右键查看编译生成的 `AntigravityArchiveViewer.app` 属性，其通用名称、可执行文件名称必须均已变更为 `AntigravityArchiveViewer`；
3. **原生菜单校验**：双击运行生成的 App，左上角系统菜单栏的 App Menu 中，“关于”、“隐藏”、“退出”后面的名字必须完美对齐变更为 `AntigravityArchiveViewer`。
