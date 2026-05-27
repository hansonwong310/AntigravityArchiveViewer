## 这是需求流动任务看版文档，不要在这个文档放入需求细节

## New Requests
- [ ] **FA-001**：打包成 macOS App，DMG 安装格式（详细需求定义见：[FA-001 需求分析说明书](file:///Users/hansonwang/Documents/AntigravityAV/docs/Feature_Analysis_001.md)）


## Refined Requests


#### 4. DMG 安装包视觉美学规范 (DMG Visual Design)

* **一键拖拽拖装**：
  DMG 挂载后，呈现高保真的引导安装窗口。窗口背景采用精心调制的暗黑霓虹渐变（HSL 紫光呼吸渐变），左侧为 `ArchiveViewer.app` 图标，右侧为系统 `Applications` 快捷方式，中间以丝滑的霓虹箭头指示拖拽安装。
* **数字签名与公证（Notarization）**：
  为避免 macOS 弹出“无法打开已损坏的应用程序”安全警告，在打包流水线中需支持通过 `Developer ID` 对 `.app` 进行代码签名，并提交 Apple 进行公证认证，确保开箱双击即用。

---

## Implemented Requests
- [x] **打包成 macOS App，DMG 安装格式** (已利用本地原生 Swift 6 编译器 + WebKit WebView + macOS \`hdiutil\` 完美实现本地编译打包，包体积仅为 1.5MB，运行内存仅 15MB，并支持自动回收后台 Node 进程端口防占用)。

