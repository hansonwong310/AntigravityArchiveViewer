# 📑 需求分析说明书: FA-002 - App 启动慢与黑屏延迟优化

---

## 📌 1. 基础信息 (Basic Information)
* **需求编号 (ID)**: FA-002
* **需求名称 (Title)**: macOS App 启动延迟与首屏黑屏闪烁优化
* **优先级 (Priority)**: High
* **状态 (Status)**: Under Review (待确认)
* **提出时间 (Proposed)**: 2026-05-27
* **适用版本 (Target Version)**: v1.1.0

---

## 🎯 2. 背景与痛点分析 (Background & Pain Points)
* **现状痛点**：目前双击打开 `ArchiveViewer.app` 后，窗口会维持大约 5 秒左右的黑屏，导致极度糟糕的第一交互体验（黑屏时间过长，用户可能误以为程序崩溃或假死）。
* **黑屏根因诊断**：
  1. **外部 CDN 网络延迟（核心瓶颈）**：
     在 `public/index.html` 中，React 18、ReactDOM、Babel Standalone、Marked（Markdown解析）以及 Mermaid（流程图渲染）全部采用 unpkg/CDN 动态拉取。在 desktop 环境下，首次加载需要建立多路 HTTPS 连接并下载数兆的 JS 库，若网络稍有波动即会造成严重的首屏白屏/黑屏。
  2. **系统 web 字体加载延迟**：
     大盘使用了 Google Web Fonts（Inter, JetBrains Mono），加载这组外部字体样式也会引起首屏阻塞。
  3. **硬编码静态延时（1.2s）**：
     `main.swift` 中使用固定的 `DispatchQueue.main.asyncAfter(deadline: .now() + 1.2)` 进行端口等待。该等待为盲目等待，未能精准捕获 Node.js 后端启动就绪的瞬间。

---

## 📋 3. 详细解决方案规约 (Solutions & Specs)

### 3.1 核心策略 A：前端第三方 JS 库与字体 100% 本地化 (Localize Assets)
* **实现方案**：
  - 弃用所有的 unpkg/CDN 链接，将以下核心组件 JS 库完整下载并放置在本地资源包中（`/public/js/` 目录下）：
    * `react.production.min.js`
    * `react-dom.production.min.js`
    * `babel.min.js`
    * `marked.min.js`
    * `mermaid.min.js`
  - 弃用 Google Web Fonts 外链，改用 macOS 系统自带的、高度一致的优秀系统原生字体族：
    * 标题与主文本：`-apple-system`, `BlinkMacSystemFont`, `"Segoe UI"`, `Roboto`, `Helvetica`
    * 代码与控制台：`"JetBrains Mono"`, `"SF Mono"`, `Menlo`, `Monaco`, `Courier New`
* **目标成效**：实现 **100% 离线运行能力**。静态网页及 JS 引擎载入耗时直接从 >4.5 秒降至 **小于 50 毫秒**！

### 3.2 核心策略 B：智能 Node.js 端口探针替代硬等待 (Port Probe)
* **实现方案**：
  - 在 Swift 原生壳 `main.swift` 中，弃用 `1.2s` 硬编码延迟；
  - 引入轻量级端口活跃探测循环（使用 Swift 原生的 `URLSession` 对 `http://localhost:5173/api/calendar-stats` 进行间隔 100ms 的异步轮询探针）；
  - 一旦捕获到 Node 服务成功响应，**在毫秒级内瞬间触发 WebView 载入**。
* **目标成效**：使首屏加载时间精准对齐后端真实启动耗时（~150ms），实现零误差闪开。

### 3.3 核心策略 C：Native 优雅菊花加载动画与骨架屏 (Skeleton & Loading)
* **实现方案**：
  - 在 WebView 尚未完全渲染并回调 `webView(_:didFinish:)` 导航完毕前，在 Swift 窗口中心升起一个高颜值的 macOS 原生系统级菊花加载指示器（`NSProgressIndicator`）；
  - 监听 WebView 的导航完成回调，在首屏彻底加载就绪后，执行平滑淡出动画将加载指示器隐藏，提供极高保真的原生过度动效。

---

## ✅ 4. 验收测试标准 (Acceptance Criteria)
1. **网络离线测试**：拔掉 Mac 网线/关闭 Wi-Fi，双击 `ArchiveViewer.app` 必须能 100% 顺畅打开并正常使用（证明已完成离线本地化）；
2. **启动速度测试**：双击运行 App 到首屏彻底显示完毕，总耗时必须控制在 **1.5秒内**（无任何 5s 黑屏假死感）；
3. **加载动效测试**：在首屏渲染完成前，窗口中心必须展示精致的 loading 指示器，且在渲染完毕后平滑消失，无突兀闪烁。
