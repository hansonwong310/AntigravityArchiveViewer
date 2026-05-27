#!/bin/bash

# 获取脚本所在的根目录
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_DIR"

# 优雅的彩色日志定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo -e "${PURPLE}================================================================${NC}"
echo -e "${PURPLE}         🛠️  Antigravity ArchiveViewer 原生打包引擎 🛠️             ${NC}"
echo -e "${PURPLE}================================================================${NC}"
echo ""

# 1. 创建干净的 .app 结构目录
echo -e "📂 ${BLUE}正在创建 macOS App 目录结构...${NC}"
APP_DIR="ArchiveViewer.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 2. 生成 Info.plist 元配置文件
echo -e "⚙️  ${BLUE}正在生成 App 系统配置文件 Info.plist...${NC}"
cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ArchiveViewer</string>
    <key>CFBundleIdentifier</key>
    <string>com.hanson.antigravity-av-app</string>
    <key>CFBundleName</key>
    <string>ArchiveViewer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 3. 使用原生 swiftc 编译器编译 main.swift 源码
echo -e "🚀 ${BLUE}正在使用 swiftc 高效编译 main.swift 源程序...${NC}"
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)
swiftc -O -sdk "$SDK_PATH" -o "$APP_DIR/Contents/MacOS/ArchiveViewer" main.swift

if [ $? -eq 0 ]; then
    echo -e "✅ ${GREEN}Swift 源代码编译成功！${NC}"
else
    echo -e "❌ ${RED}错误: Swift 源码编译失败。${NC}"
    exit 1
fi

# 4. 同步拷贝静态前端网页以及后端 API 代码至 App 资源目录下
echo -e "📦 ${BLUE}正在同步拷贝 Web 前端及 API 服务代码至 App 资源包下...${NC}"
cp server.js "$APP_DIR/Contents/Resources/"
cp -R public "$APP_DIR/Contents/Resources/"

echo -e "✅ ${GREEN}成功生成独立运行包: ${CYAN}${APP_DIR}${NC}"
echo ""

# 5. 使用 macOS 原生磁盘镜像工具 hdiutil 编译并压缩生成 .dmg 安装包
echo -e "💿 ${BLUE}正在使用 hdiutil 打包并压缩生成安装镜像: ${CYAN}ArchiveViewer.dmg${NC}..."
rm -f ArchiveViewer.dmg

# 创建 dmg
hdiutil create -fs HFS+ -volname "ArchiveViewer" -srcfolder "$APP_DIR" -ov -format UDZO ArchiveViewer.dmg

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "🎉 ${GREEN}打包成功！原生应用与 DMG 安装镜像均已编译就绪。${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo -e " 📍 App 文件位置: ${CYAN}${PROJECT_DIR}/${APP_DIR}${NC}"
    echo -e " 📍 DMG 镜像位置: ${CYAN}${PROJECT_DIR}/ArchiveViewer.dmg${NC}"
    echo -e "${GREEN}================================================================${NC}"
else
    echo -e "❌ ${RED}错误: DMG 镜像文件打包失败。${NC}"
    exit 1
fi
