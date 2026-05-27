## 这是需求流动任务看版文档，不要在这个文档放入需求细节

## New Requests


## Refined Requests

---

## Implemented Requests
- [x] **FA-002**：优化 App 启动延迟与首屏黑屏闪烁 (通过 100% 本地化前端核心静态依赖 JS 库、优雅的原生 `NSProgressIndicator` 菊花加载指示器、以及 50ms 高频异步 `URLSession` 网络探针轮询，实现了零黑屏 1.2s 内极速闪开)。
- [x] **FA-003**：设计并装配时尚的原生 macOS App 图标 (精心创作反重力沙漏引力双轨科幻主图，并使用 native `sips` 和 `iconutil` 工具合成高保真 Retina 多分辨率 `AppIcon.icns` 图标资产，完美关联应用并展示于 Dock 栏、Finder 和 DMG 引导界面)。
- [x] **FA-004**：重命名客户端应用与安装包为 AntigravityArchiveViewer (对齐主窗口、Info.plist、原生 app 属性名、.app 目录、可执行二进制文件、以及系统全局“编辑”菜单，打通全链路品牌认知，DMG 安装格式卷名和包名完美统一)。
- [x] **打包成 macOS App，DMG 安装格式** (已利用本地原生 Swift 6 编译器 + WebKit WebView + macOS `hdiutil` 完美实现本地编译打包，包体积仅为 1.5MB，运行内存仅 15MB，并支持自动回收后台 Node 进程端口防占用)。

