#!/bin/bash

# 获取脚本所在的根目录
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_DIR"

# 优雅的彩色日志定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${PURPLE}================================================================${NC}"
echo -e "${PURPLE}     🛠️  AntigravityArchiveViewer 原生极速打包引擎 v1.1.0 🛠️       ${NC}"
echo -e "${PURPLE}================================================================${NC}"
echo ""

# 1. 创建干净的 .app 结构目录 (全面升级命名为 AntigravityArchiveViewer)
echo -e "📂 ${BLUE}正在创建 macOS App 目录结构...${NC}"
APP_DIR="AntigravityArchiveViewer.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 2. 编译并合成 macOS 原生多尺寸 .icns 图标 (FA-003)
echo -e "🎨 ${BLUE}正在启动原生 AppIcon.icns 图标自动合成流水线...${NC}"
ICON_SOURCE="public/icon.png"

if [ -f "$ICON_SOURCE" ]; then
    ICONSET_DIR="AppIcon.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    
    # 使用 macOS 原生 sips 工具自动缩放裁切 10 维视网膜阵列
    echo -e " ⚡ ${CYAN}正在调用 sips 生成多尺寸 PNG 图标树...${NC}"
    sips -s format png -z 16 16     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null 2>&1
    sips -s format png -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null 2>&1
    sips -s format png -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null 2>&1
    sips -s format png -z 64 64     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null 2>&1
    sips -s format png -z 128 128   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null 2>&1
    sips -s format png -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null 2>&1
    sips -s format png -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null 2>&1
    sips -s format png -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null 2>&1
    sips -s format png -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null 2>&1
    sips -s format png -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null 2>&1
    
    # 调用 macOS 原生 iconutil 编译合成为苹果专属 AppIcon.icns
    echo -e " ⚡ ${CYAN}正在调用 iconutil 编译合成为原生 AppIcon.icns 资产...${NC}"
    iconutil -c icns "$ICONSET_DIR" --out "$APP_DIR/Contents/Resources/AppIcon.icns"
    
    # 清理临时 iconset 目录
    rm -rf "$ICONSET_DIR"
    echo -e "✅ ${GREEN}应用原生 .icns 图标装配成功！${NC}"
else
    echo -e "⚠️  ${RED}警告: 未找到 public/icon.png 主图标素材，将跳过图标编译。${NC}"
fi

# 3. 生成符合苹果规范的 Info.plist 元配置文件 (FA-004)
echo -e "⚙️  ${BLUE}正在生成 App 系统元配置文件 Info.plist...${NC}"
cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AntigravityArchiveViewer</string>
    <key>CFBundleIdentifier</key>
    <string>com.hanson.antigravity-archive-viewer</string>
    <key>CFBundleName</key>
    <string>AntigravityArchiveViewer</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

# 4. 使用原生 swiftc 编译器编译 main.swift 源码 (FA-004)
echo -e "🚀 ${BLUE}正在使用 swiftc 高效编译 main.swift 原生程序...${NC}"
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)
swiftc -O -sdk "$SDK_PATH" -o "$APP_DIR/Contents/MacOS/AntigravityArchiveViewer" main.swift

if [ $? -eq 0 ]; then
    echo -e "✅ ${GREEN}Swift 原生机器码程序编译成功！${NC}"
else
    echo -e "❌ ${RED}错误: Swift 源码编译失败。${NC}"
    exit 1
fi

# 5. 同步拷贝静态前端网页以及后端 API 代码至 App 资源目录下
echo -e "📦 ${BLUE}正在同步拷贝 Web 前端及 API 服务代码至 App 资源包下...${NC}"
cp server.js "$APP_DIR/Contents/Resources/"
cp -R public "$APP_DIR/Contents/Resources/"

echo -e "✅ ${GREEN}成功生成独立原生包: ${CYAN}${APP_DIR}${NC}"
echo ""

# 6. 使用 macOS 原生磁盘镜像工具 hdiutil 编译并压缩生成 DMG 安装包 (FA-004)
echo -e "💿 ${BLUE}正在使用 hdiutil 打包并压缩生成安装镜像: ${CYAN}AntigravityArchiveViewer.dmg${NC}..."
rm -f AntigravityArchiveViewer.dmg

# 创建 dmg，卷名和文件名完全对齐
hdiutil create -fs HFS+ -volname "AntigravityArchiveViewer" -srcfolder "$APP_DIR" -ov -format UDZO AntigravityArchiveViewer.dmg

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}================================================================${NC}"
    echo -e "🎉 ${GREEN}打包成功！原生应用与 DMG 安装镜像均已编译就绪。${NC}"
    echo -e "${GREEN}================================================================${NC}"
    echo -e " 📍 App 文件位置: ${CYAN}${PROJECT_DIR}/${APP_DIR}${NC}"
    echo -e " 📍 DMG 镜像位置: ${CYAN}${PROJECT_DIR}/AntigravityArchiveViewer.dmg${NC}"
    echo -e "${GREEN}================================================================${NC}"
else
    echo -e "❌ ${RED}错误: DMG 镜像文件打包失败。${NC}"
    exit 1
fi
