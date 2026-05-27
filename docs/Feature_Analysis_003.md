# 📑 需求分析说明书: FA-003 - macOS App 原生时尚图标设计与装配

---

## 📌 1. 基础信息 (Basic Information)
* **需求编号 (ID)**: FA-003
* **需求名称 (Title)**: macOS App 原生时尚图标（AppIcon.icns）设计、生成与编译装配
* **优先级 (Priority)**: High
* **状态 (Status)**: Under Review (待确认)
* **提出时间 (Proposed)**: 2026-05-27
* **适用版本 (Target Version)**: v1.1.0

---

## 🎯 2. 背景与痛点分析 (Background & Pain Points)
* **现状痛点**：目前编译出的 `ArchiveViewer.app` 采用系统的空白应用默认图标（白纸加铅笔/网格），这极大地损害了应用的高级感，缺乏认知识别度。在 Dock 栏、访达（Finder）以及 DMG 挂载安装界面中显得不专业。
* **业务价值**：
  - **建立产品心智**：设计一款极具视觉冲击力、一眼看懂功能的现代极客风图标。
  - **增强系统美感**：让 ArchiveViewer 成为 Dock 栏上一眼吸睛的时尚点缀，提升使用愉悦感。
  - **完善 DMG 安装体验**：在 DMG 安装磁盘中，提供精美的 App 图标，配合拖拽引导。

---

## 📋 3. 详细设计与技术规格 (Specs & Implementation)

### 3.1 图标美学设计构想 (Icon Visual Conception)
为契合 **Antigravity ArchiveViewer**（反重力日志时光大盘）的极客定位，图标将融合以下科幻美学原语：
* **核心意象：数字化沙漏 (Digital Hourglass)** ➡️ 象征时间、历史对话日志归档的深度探索。
* **反重力轨道（Antigravity Orbit）** ➡️ 沙漏外围漂浮着一圈发出霓虹紫光与青光（Cyan/Violet）的双环重力引力轨道，寓意 ArchiveViewer 强大的检索平滑召回能力。
* **数字粒子（Digital Particles）** ➡️ 沙漏内部的流沙转换为发光的二进制代码比特流与代码数字节点，象征日志数据的沉淀与高保真还原。
* **macOS Squircle 圆角格式** ➡️ 外框严格遵循苹果 macOS Big Sur 后统一的 Squircle（超圆角矩形）微拟物边缘质感，带有精致的金属拉丝倒角与背光漫反射。

> **🎨 图标生成方案**：
> 我们将使用高精度的 `generate_image` 图像生成工具，基于上述高保真 prompt 渲染出 1024x1024 的主图标素材 `public/icon.png`。

### 3.2 苹果原生 `.icns` 磁盘转换与装配规范 (ICNS Assembly)
macOS 应用程序需要专用的多分辨率 `.icns` 格式文件以适配视网膜屏（Retina）及不同视图。我们将**完全使用 macOS 预装的原生工具链在编译期进行自动化转换**：

1. **多尺寸裁切缩放 (Native sips)**：
   在 `package.sh` 中创建临时目录 `AppIcon.iconset`，并调用 macOS 原生的图像处理工具 `sips`，将 `public/icon.png` 瞬时裁切生成 10 个标准尺寸的 PNG 阵列：
   * `icon_16x16.png` & `icon_16x16@2x.png` (32x32)
   * `icon_32x32.png` & `icon_32x32@2x.png` (64x64)
   * `icon_128x128.png` & `icon_128x128@2x.png` (256x256)
   * `icon_256x256.png` & `icon_256x256@2x.png` (512x512)
   * `icon_512x512.png` & `icon_512x512@2x.png` (1024x1024)
2. **磁盘图标生成 (Native iconutil)**：
   运行 macOS 原生图标合集工具：
   ```bash
   iconutil -c icns AppIcon.iconset --out AppIcon.icns
   ```
3. **App 属性关联 (Info.plist)**：
   将生成的 `AppIcon.icns` 拷贝至 `ArchiveViewer.app/Contents/Resources/` 目录下，并在 `Info.plist` 中追加资产关联，确保系统能够秒级渲染：
   ```xml
   <key>CFBundleIconFile</key>
   <string>AppIcon</string>
   ```

---

## ✅ 4. 验收测试标准 (Acceptance Criteria)
1. **ICNS 编译零失败**：运行 `./package.sh` 时，自动完成 `icon.png` 的裁切和 `.icns` 生成，无报错阻断；
2. **Dock 栏图标显示**：双击运行生成的 `ArchiveViewer.app` 后，macOS 系统底部的 Dock 栏必须显示新设计的时尚霓虹沙漏图标；
3. **Finder 访达预览**：在访达中将应用缩放至 16x16 或最大尺寸，图标必须保持高清晰度，无虚边和马赛克；
4. **DMG 安装显示**：挂载 `ArchiveViewer.dmg` 后，安装引导窗口中显示的 App 必须已是新设计的沙漏图标。
