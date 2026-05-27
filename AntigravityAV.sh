#!/bin/bash

# 获取脚本所在的目录，确保路径正确
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_DIR"

# 优雅的彩色日志输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo -e "${PURPLE}================================================================${NC}"
echo -e "${PURPLE}         🔮 Welcome to Antigravity ArchiveViewer 🔮             ${NC}"
echo -e "${PURPLE}================================================================${NC}"
echo ""

# 检测并定位 agy-node 运行时
NODE_EXEC="agy-node"
if ! command -v agy-node &> /dev/null; then
    # 如果 PATH 中找不到，尝试定位默认的 Antigravity 安装路径
    DEFAULT_AGY_NODE="/Users/hansonwang/Library/Application Support/Antigravity/bin/agy-node"
    if [ -f "$DEFAULT_AGY_NODE" ]; then
        NODE_EXEC="$DEFAULT_AGY_NODE"
    else
        # 兜底检测系统自带的 node
        if command -v node &> /dev/null; then
            NODE_EXEC="node"
        else
            echo -e "❌ ${RED}错误: 未检测到 agy-node 或是系统的 Node.js 运行时。${NC}"
            echo "请确保在 Antigravity IDE 中启动此程序，或将其路径加入环境变量。"
            exit 1
        fi
    fi
fi

echo -e "⚙️  ${BLUE}检测到运行时: ${CYAN}${NODE_EXEC}${NC}"
echo -e "📂 ${BLUE}正在启动本地服务于: ${CYAN}http://localhost:5173${NC}"
echo ""
echo -e "${GREEN}----------------------------------------------------------------${NC}"
echo -e "${GREEN}💡 最终如何在 VS Code / Cursor 内嵌分栏使用此 GUI 界面？${NC}"
echo -e "${GREEN}----------------------------------------------------------------${NC}"
echo -e " 1. 在编辑器中按快捷键: ${CYAN}Cmd + Shift + P${NC}"
echo -e " 2. 输入并选择: ${CYAN}Simple Browser: Show${NC} (内置极简浏览器)"
echo -e " 3. 在地址栏中输入: ${CYAN}http://localhost:5173${NC} 并回车"
echo -e " 4. 界面打开后，直接将它的网页标签【拖动到编辑器最右侧】进行分栏显示！"
echo -e "    👉 这样就能完美实现「左边编写代码，右边实时翻阅和搜索历史对话」"
echo -e "${GREEN}----------------------------------------------------------------${NC}"
echo ""
echo -e "🚀 ${BLUE}正在启动 Node.js API 引擎，请稍候...${NC}"
echo ""

# 启动 Node.js 服务器
exec "$NODE_EXEC" server.js
