# 🏗️ Antigravity ArchiveViewer 开发者参考指南

本指南面向 ArchiveViewer 项目的系统维护者与后续代码贡献者，深入解析项目的底层系统架构、前后端技术栈设计、核心 API 接口规约以及核心组件的技术实现方案。

---

## 🧭 1. 系统架构设计 (Architecture Overview)

ArchiveViewer 采用极轻量级的 **单页面前端 (React CDN) + 极速常驻服务端 (Launch Agent API Server)** 架构，整个系统与本地文件系统深度整合。

### 1.1 组件依赖拓扑

以下是系统内部的数据与请求流向：

```mermaid
graph TD
    A[浏览器客户端 Frontend] -->|HTTP 请求 / API| B[Node.js API 服务 Backend]
    B -->|正则过滤 & I/O 流| C[本地文件系统 ~/.gemini/antigravity/brain]
    D[macOS 守护进程 launchd] -->|常驻保活监听| B
    
    subgraph Frontend (React 18 + CDN + CSS3)
        E[CalendarWidget 3星强度日历]
        F[Resizer 侧边栏拖拽组件]
        G[CollapsibleText 长文可视折叠]
        H[MarkdownRenderer 标记解析器]
        I[Anchor Smooth-Scroll 脉冲高亮定位]
    end
    
    subgraph Backend (Native Node.js Server)
        J[CORS & Static File Server]
        K[Conversations & Metadata API]
        L[Transcript Detail Stream API]
        M[Calendar Turn Aggregator API]
        N[Regex Token Search API]
    end
```

### 1.2 架构哲学：0-Dependency 与 CDN 方案
* **后端**：完全基于原生 Node.js 的 `http`, `fs`, `path`, `url` 模块构建，**零 npm 第三方依赖**。这使得项目具备超乎寻常的冷启动表现（运行时间少于 50ms），且杜绝了外部库漏洞和版本崩坏风险。
* **前端**：采用 HTML5 + CSS3 + React 18 + Babel Standalone 构建。省去了 Vite/Webpack 等复杂的打包构建环节，只要有浏览器和网络连接即可直接秒级渲染，支持双击静态 HTML 调试。

---

## 📡 2. 后端 API 接口设计规范 (Backend API Spec)

后端 API 服务常驻于 `http://localhost:5173`。所有 API 接口返回的 Content-Type 均为 `application/json; charset=utf-8`，并且支持跨域访问（CORS）。

### 2.1 获取对话列表列表
* **接口地址**：`GET /api/conversations`
* **接口描述**：读取 `BRAIN_DIR` 目录下的所有子文件夹，解析其 `transcript.jsonl`，并返回包含净化后标题和基本属性的对话列表，按更新时间 `updatedAt` 降序排列。
* **返回数据格式 (JSON)**：
  ```json
  [
    {
      "id": "9e128135-1e6f-4988-a010-9598e08520d4",
      "title": "生成几分文档 1. 给使用者的文档 2.给开发者的文档...",
      "turns": 6,
      "createdAt": "2026-05-27T10:11:20.000Z",
      "updatedAt": "2026-05-27T10:14:54.000Z",
      "date": "2026-05-27"
    }
  ]
  ```

### 2.2 获取单个对话的历史步骤详情
* **接口地址**：`GET /api/conversations/:id` (例如 `/api/conversations/9e128135-1e6f-4988-a010-9598e08520d4`)
* **接口描述**：解析该对话目录下唯一的日志 `transcript.jsonl`，提取所有运行步骤，按顺序返回给前端气泡流。
* **返回数据格式 (JSON)**：
  ```json
  [
    {
      "step_index": 0,
      "source": "USER_EXPLICIT",
      "type": "USER_INPUT",
      "status": "DONE",
      "content": "<USER_REQUEST>\n生成几分文档...\n</USER_REQUEST>"
    },
    {
      "step_index": 1,
      "source": "MODEL",
      "type": "PLANNER_RESPONSE",
      "content": "我已针对项目编写了详细的设计方案...",
      "tool_calls": [
        {
          "name": "write_to_file",
          "arguments": "{\"TargetFile\":\"...\"}",
          "output": "Created file successfully"
        }
      ]
    }
  ]
  ```

### 2.3 获取日历聚合统计数据
* **接口地址**：`GET /api/calendar-stats`
* **接口描述**：全局扫描所有对话的修改日期 `mtime`，按日期（`YYYY-MM-DD`）进行统计归档，计算每日对话的总场数与对话总轮数（Turn Count），供给前端 3 星日历渲染。
* **返回数据格式 (JSON)**：
  ```json
  {
    "2026-05-27": {
      "conversations": 2,
      "turns": 18
    },
    "2026-05-28": {
      "conversations": 1,
      "turns": 4
    }
  }
  ```

### 2.4 全局全文多关键词 AND 检索
* **接口地址**：`GET /api/search?q=query_string` (例如 `/api/search?q=run_command%20git`)
* **接口描述**：支持多关键词空格、逗号或分号分隔。后端会将查询分词为独立的 Token，并在全量 `transcript.jsonl` 的 `content` 字段和 `tool_calls` 的执行结果中，进行**多关键词 AND 强匹配**（即每一行日志必须包含全部关键词）。限制最多返回前 100 条匹配数据。
* **返回数据格式 (JSON)**：
  ```json
  [
    {
      "conversationId": "9e128135-1e6f-4988-a010-9598e08520d4",
      "conversationTitle": "生成几分文档 1. 给使用者的文档 2.给开发者的文档...",
      "date": "2026-05-27",
      "stepIndex": 1,
      "source": "MODEL",
      "type": "PLANNER_RESPONSE",
      "snippet": "工具调用: write_to_file, replace_file_content..."
    }
  ]
  ```

---

## 💻 3. 前端核心组件技术实现细节

### 3.1 智能对话标题净化
* **文件位置**：`server.js` (`getConversationMetadata` 函数)
* **实现逻辑**：
  在 AI 运行日志中，首行输入通常被 `<USER_REQUEST>` 标签包裹。后端使用：
  ```javascript
  const cleanContent = step.content
    .replace(/<USER_REQUEST>/g, '')
    .replace(/<\/USER_REQUEST>/g, '')
    .trim();
  ```
  剔除标签并过滤掉空白行，提取用户说的第一句真实文本（截取前 40 字符），规避了标题千篇一律的痛点，显著提升了大盘可读性。

### 3.2 智能长文本可视限高折叠 (CollapsibleText)
* **文件位置**：`public/index.html`
* **痛点防范**：绝对不能在数据层使用 `slice()` 对 Markdown 文本进行字数截断，因为这会切断未闭合的代码块（例如 ` ``` `）或 HTML 标签，造成全局排版灾难。
* **实现方案**：
  React 渲染器渲染完完整的 Markdown HTML 后，在生命周期中通过 `useRef` 动态侦听高度。当发现实际渲染高度（`scrollHeight`）超过 **`260px`** 时，将容器的最大物理高度限制在 `250px`，并在容器底部渲染一个**随主题色动态渐变转换的毛玻璃半透明遮罩**：
  ```css
  .collapsible-text-overlay {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 60px;
    background: linear-gradient(transparent, var(--bg-card));
    pointer-events: none;
  }
  ```
  点击“展开余下全文”按钮则平滑移除限高，保证排版的稳定性。

### 3.3 左右拉伸侧边栏 (Resizer)
* **文件位置**：`public/index.html` 与 `public/app.css`
* **实现方案**：
  在侧边栏 `.sidebar` 与主显示区 `.main-content` 之间，安插了一个宽为 4px 的高灵敏度高亮边框线 `.resizer`。
  当在 `.resizer` 上触发 `onMouseDown` 时，将全局锁 `isResizing.current` 设为 `true`。监听全局 `window` 的 `mousemove` 事件，实时更新 `sidebarWidth`：
  ```javascript
  const newWidth = e.clientX;
  if (newWidth > 230 && newWidth < 480) {
    setSidebarWidth(newWidth);
  }
  ```
  该逻辑将侧边栏宽度强力钳制在 `230px` 至 `480px` 之间，并在移动过程中强制锁死系统文字选中（`user-select: none`）和光标样式（`cursor: col-resize`），体验丝滑且边界明确。

### 3.4 搜索平滑定位与霓虹呼吸脉冲 (Anchor Jump & Pulse Highlight)
* **文件位置**：`public/index.html` 与 `public/app.css`
* **实现方案**：
  Timeline 气泡流中每一个步骤卡片都具备唯一 DOM 标识：`step-card-${stepId}`。
  当用户在全局搜索面板中点击某条匹配结果时，React 状态引擎会先将界面切回阅读 Timeline 视图，并将 `highlightedStepIndex` 设为目标值。
  当 Timeline DOM 载入后，生命周期挂载如下动画定位逻辑：
  ```javascript
  const element = document.getElementById(`step-card-${highlightedStepIndex}`);
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'center' });
    element.classList.add('pulse-highlight');
  }
  ```
  在 CSS 中，`.pulse-highlight` 会触发持续 2.5 秒的紫色霓虹光圈闪烁关键帧动画：
  ```css
  @keyframes pulseGlow {
    0% { box-shadow: 0 0 0 0px rgba(139, 92, 246, 0.7); }
    70% { box-shadow: 0 0 0 15px rgba(139, 92, 246, 0); }
    100% { box-shadow: 0 0 0 0px rgba(139, 92, 246, 0); }
  }
  ```
  这种微交互能够秒级将用户的视觉焦点引导到指定的定位代码块上。

---

## 🔧 4. 本地开发与贡献指南

1. **零外部依赖红线**：
   在维护后端 API 时，**绝对禁止引入任何第三方 npm 包（如 Express, Lodash 等）**。所有的路由处理、文件读取以及正则匹配必须只使用 Node.js 核心 API。
2. **前端打包红线**：
   在维护前端交互时，必须保持 HTML5 单文件（React via Babel CDN）架构。**严禁引入 Vite, Webpack 等构建流程，严禁引入 Tailwind 或者是类似外部复杂框架**，保证 ArchiveViewer 的轻巧无感与直接载入效率。
3. **HSL 美学色板自定义**：
   项目的所有 UI 配色全部集中于 `public/app.css` 的 `:root` 与 `.theme-light` 变量中，采用了高级的 HSL 调色体系（如 `--primary: 263 90% 64%`），可以直接修改 these HSL 变量来自定义大盘的霓虹及主题配色。

---

## ⚙️ 5. macOS Launch Agent 后台常驻守护服务运维手册

为了实现“开机即用、零感知免开”的系统级体验，ArchiveViewer 支持装载为 macOS 的后台常驻进程（Launch Agent）。

### 5.1 Plist 配置文件规格
* **文件命名与存储位置**：`~/Library/LaunchAgents/com.hanson.antigravity-av.plist`
* **Plist 配置模板示例**：
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
      <key>Label</key>
      <string>com.hanson.antigravity-av</string>
      <key>ProgramArguments</key>
      <array>
          <string>/bin/bash</string>
          <string>-c</string>
          <string>/Users/hansonwang/Documents/AntigravityAV/AntigravityAV.sh</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <true/>
      <key>StandardOutPath</key>
      <string>/Users/hansonwang/Documents/AntigravityAV/server_stdout.log</string>
      <key>StandardErrorPath</key>
      <string>/Users/hansonwang/Documents/AntigravityAV/server_stderr.log</string>
  </dict>
  </plist>
  ```

### 5.2 常用 launchctl 系统指令
当本地开发调试需要重启服务、或者出现端口被抢占冲突时，开发者可直接在终端中运行以下原生命令进行维护：

* **加载并启动服务 (Load & Start)**：
  ```bash
  launchctl load ~/Library/LaunchAgents/com.hanson.antigravity-av.plist
  ```
* **卸载并停止服务 (Unload & Stop)**：
  ```bash
  launchctl unload ~/Library/LaunchAgents/com.hanson.antigravity-av.plist
  ```
* **查看服务当前在系统中的状态 (Check Status)**：
  ```bash
  launchctl list | grep antigravity
  ```
  *(注：若第二列返回非 0 退出状态码，代表守护进程启动异常，可查看 `server_stderr.log` 定位报错。)*

### 5.3 自动化一键安装构想 (`install.sh`)
为减少新开发者的上手安装摩擦，可在根目录下部署自动化脚本：
1. 动态生成指向当前 workspace 路径的 `com.hanson.antigravity-av.plist`。
2. 将文件自动拷贝至用户的 `~/Library/LaunchAgents/` 目录下。
3. 执行 `launchctl load` 激活服务。
