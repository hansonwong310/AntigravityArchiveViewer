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
echo -e "${PURPLE}         🚀  AntigravityArchiveViewer 官方编译发布引擎 🚀         ${NC}"
echo -e "${PURPLE}================================================================${NC}"
echo ""

# 1. 创建干净的发布目录
echo -e "📂 ${BLUE}正在初始化发布目录 [release/]...${NC}"
RELEASE_DIR="release"
mkdir -p "$RELEASE_DIR"

# 2. 调用已有的打包引擎进行本地编译
if [ -f "./package.sh" ]; then
    echo -e "⚙️  ${BLUE}正在启动 package.sh 打包编译...${NC}"
    chmod +x package.sh
    ./package.sh
    
    if [ $? -eq 0 ]; then
        echo -e "✅ ${GREEN}本地编译打包已顺利完成！${NC}"
    else
        echo -e "❌ ${RED}错误: 编译打包脚本执行失败。${NC}"
        exit 1
    fi
else
    echo -e "❌ ${RED}错误: 找不到底层 package.sh 脚本。${NC}"
    exit 1
fi

# 3. 将生成的 DMG 转移到发布目录下 (对齐重命名)
echo -e "📦 ${BLUE}正在将 DMG 镜像移动至发布目录 [release/]...${NC}"
if [ -f "AntigravityArchiveViewer.dmg" ]; then
    mv AntigravityArchiveViewer.dmg "$RELEASE_DIR/AntigravityArchiveViewer.dmg"
    echo -e "✅ ${GREEN}成功移至: ${CYAN}${RELEASE_DIR}/AntigravityArchiveViewer.dmg${NC}"
else
    echo -e "❌ ${RED}错误: 未找到生成的 AntigravityArchiveViewer.dmg 文件。${NC}"
    exit 1
fi

# 4. 清理临时生成的 .app 目录以维持根目录纯净 (对齐重命名)
echo -e "🧹 ${BLUE}正在清理临时生成的 AntigravityArchiveViewer.app 目录...${NC}"
rm -rf AntigravityArchiveViewer.app

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "🎉 ${GREEN}编译发布大功告成！最终发布镜像已完全就绪。${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e " 📍 最终发布路径: ${CYAN}${PROJECT_DIR}/${RELEASE_DIR}/AntigravityArchiveViewer.dmg${NC}"
echo -e "${GREEN}================================================================${NC}"
