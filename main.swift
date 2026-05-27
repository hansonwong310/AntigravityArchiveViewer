import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var serverProcess: Process?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. 启动本地 Node.js API 服务
        startNodeServer()

        // 2. 创建主窗口 (1200 x 800)
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let windowWidth: CGFloat = 1200
        let windowHeight: CGFloat = 800
        let rect = NSRect(
            x: (screenRect.width - windowWidth) / 2,
            y: (screenRect.height - windowHeight) / 2,
            width: windowWidth,
            height: windowHeight
        )

        window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Antigravity ArchiveViewer"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.delegate = self
        window.makeKeyAndOrderFront(nil)

        // 3. 配置与挂载 WebView
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: window.contentView!.bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.width, .height]
        
        // 预设磨砂玻璃背景底色以消除白屏闪烁 (对齐 HSL #0a0b10)
        webView.setValue(false, forKey: "drawsBackground") 
        window.backgroundColor = NSColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0) 

        window.contentView?.addSubview(webView)

        // 4. 延迟加载页面 (确保 Node 后端已启动就绪)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if let url = URL(string: "http://localhost:5173") {
                let request = URLRequest(url: url)
                self.webView.load(request)
            }
        }

        // 5. 组装原生应用编辑菜单 (对齐 Cmd+C/Cmd+V 复制粘贴等热键)
        setupMenu()
    }

    func startNodeServer() {
        let process = Process()
        
        // 环境中 agy-node 与 node 的定位逻辑
        let agyNodePath = "/Users/hansonwang/Library/Application Support/Antigravity/bin/agy-node"
        let fallbackNodePath = "/opt/homebrew/bin/node"
        let systemNodePath = "/usr/local/bin/node"
        
        var nodeExec = "node"
        if FileManager.default.fileExists(atPath: agyNodePath) {
            nodeExec = agyNodePath
        } else if FileManager.default.fileExists(atPath: fallbackNodePath) {
            nodeExec = fallbackNodePath
        } else if FileManager.default.fileExists(atPath: systemNodePath) {
            nodeExec = systemNodePath
        }
        
        process.executableURL = URL(fileURLWithPath: nodeExec)
        
        // 智能定位资源目录下的 server.js
        let resourcePath = Bundle.main.resourcePath ?? FileManager.default.currentDirectoryPath
        var serverJsPath = "\(resourcePath)/server.js"
        if !FileManager.default.fileExists(atPath: serverJsPath) {
            // 调试环境下兜底使用当前绝对路径
            serverJsPath = "/Users/hansonwang/Documents/AntigravityAV/server.js"
        }
        
        process.arguments = [serverJsPath]
        process.currentDirectoryURL = URL(fileURLWithPath: resourcePath)
        
        // 重定向日志输出 (保持后台清爽)
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        do {
            try process.run()
            self.serverProcess = process
            print("Successfully started node server with \(nodeExec)")
        } catch {
            print("Failed to start Node server: \(error)")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // App 退出时，强力杀掉 Node.js 子进程，避免端口占用溢出
        serverProcess?.terminate()
        print("Terminated Node server")
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(nil)
        return true
    }

    func setupMenu() {
        let mainMenu = NSMenu()
        
        // 1. 主应用菜单
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        appMenu.addItem(withTitle: "关于 ArchiveViewer", action: nil, keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "隐藏 ArchiveViewer", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "退出 ArchiveViewer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        // 2. 编辑菜单 (保证 Web 输入框内复制、粘贴、撤销、全选功能正常)
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "编辑")
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "剪切", action: Selector(("cut:")), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: Selector(("copy:")), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: Selector(("paste:")), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: Selector(("selectAll:")), keyEquivalent: "a")

        NSApplication.shared.mainMenu = mainMenu
    }
}

// 引导启动 App
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
