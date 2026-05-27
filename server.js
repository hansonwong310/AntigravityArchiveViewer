const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 5173;
const BRAIN_DIR = '/Users/hansonwang/.gemini/antigravity/brain';
const PUBLIC_DIR = path.join(__dirname, 'public');

// 辅助函数：获取文件的修改日期 (YYYY-MM-DD)
function getFormattedDate(filePath) {
  try {
    const stats = fs.statSync(filePath);
    const date = new Date(stats.mtime);
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  } catch (e) {
    return null;
  }
}

// 辅助函数：解析单个对话的元数据
function getConversationMetadata(convoId) {
  const convoDir = path.join(BRAIN_DIR, convoId);
  const logPath = path.join(convoDir, '.system_generated/logs/transcript.jsonl');
  
  if (!fs.existsSync(logPath)) return null;

  try {
    const stats = fs.statSync(logPath);
    const dateStr = getFormattedDate(logPath);
    
    // 读取文件内容提取标题和计算轮次
    const content = fs.readFileSync(logPath, 'utf8');
    const lines = content.trim().split('\n');
    let title = `未命名对话 (${convoId.slice(0, 8)})`;
    let turns = 0;

    for (const line of lines) {
      if (!line) continue;
      try {
        const step = JSON.parse(line);
        if (step.type === 'USER_INPUT') {
          turns++;
          // 用第一个用户输入作为对话标题 (过滤掉 <USER_REQUEST> 等包裹标签)
          if (turns === 1 && step.content) {
            const cleanContent = step.content
              .replace(/<USER_REQUEST>/g, '')
              .replace(/<\/USER_REQUEST>/g, '')
              .trim();
            
            const contentLines = cleanContent.split('\n').map(l => l.trim()).filter(l => l.length > 0);
            if (contentLines.length > 0) {
              title = contentLines[0];
              if (title.length > 40) {
                title = title.slice(0, 40) + '...';
              }
            }
          }
        }
      } catch (err) {
        // 忽略单行解析错误
      }
    }

    return {
      id: convoId,
      title,
      turns,
      createdAt: stats.birthtime,
      updatedAt: stats.mtime,
      date: dateStr
    };
  } catch (e) {
    return null;
  }
}

// 静态文件服务
function serveStaticFile(res, filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml'
  };

  const contentType = mimeTypes[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('404 Not Found');
      } else {
        res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end(`Server Error: ${err.code}`);
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content);
    }
  });
}

// 主请求处理逻辑
const server = http.createServer((req, res) => {
  // 设置 CORS 头信息以防开发调试跨域
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;

  // ================= API 路由 =================

  // 1. 获取所有对话列表 (按更新时间倒序)
  if (pathname === '/api/conversations' && req.method === 'GET') {
    try {
      if (!fs.existsSync(BRAIN_DIR)) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify([]));
        return;
      }

      const dirs = fs.readdirSync(BRAIN_DIR).filter(file => {
        const fullPath = path.join(BRAIN_DIR, file);
        return fs.statSync(fullPath).isDirectory() && !file.startsWith('.');
      });

      const conversations = dirs
        .map(dir => getConversationMetadata(dir))
        .filter(meta => meta !== null)
        .sort((a, b) => b.updatedAt - a.updatedAt);

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(conversations));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: '无法读取对话目录', details: e.message }));
    }
    return;
  }

  // 2. 获取单个对话的历史步骤详情
  const convoMatch = pathname.match(/^\/api\/conversations\/([a-f0-9-]+)$/);
  if (convoMatch && req.method === 'GET') {
    const convoId = convoMatch[1];
    const logPath = path.join(BRAIN_DIR, convoId, '.system_generated/logs/transcript.jsonl');

    if (!fs.existsSync(logPath)) {
      res.writeHead(404, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ error: '找不到该对话的日志文件' }));
      return;
    }

    try {
      const content = fs.readFileSync(logPath, 'utf8');
      const lines = content.trim().split('\n');
      const steps = [];

      for (const line of lines) {
        if (!line) continue;
        try {
          steps.push(JSON.parse(line));
        } catch (err) {
          // 忽略单行解析错误
        }
      }

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(steps));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: '解析日志失败', details: e.message }));
    }
    return;
  }

  // 3. 获取日历聚合统计数据
  if (pathname === '/api/calendar-stats' && req.method === 'GET') {
    try {
      if (!fs.existsSync(BRAIN_DIR)) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({}));
        return;
      }

      const dirs = fs.readdirSync(BRAIN_DIR).filter(file => {
        const fullPath = path.join(BRAIN_DIR, file);
        return fs.statSync(fullPath).isDirectory() && !file.startsWith('.');
      });

      const stats = {};

      dirs.forEach(dir => {
        const meta = getConversationMetadata(dir);
        if (meta) {
          const dateStr = meta.date; // 格式 YYYY-MM-DD
          if (dateStr) {
            if (!stats[dateStr]) {
              stats[dateStr] = { conversations: 0, turns: 0 };
            }
            stats[dateStr].conversations += 1;
            stats[dateStr].turns += meta.turns;
          }
        }
      });

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(stats));
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: '日历统计失败', details: e.message }));
    }
    return;
  }

  // 4. 全局搜索接口
  if (pathname === '/api/search' && req.method === 'GET') {
    const query = parsedUrl.query.q ? parsedUrl.query.q.toLowerCase() : '';
    if (!query) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify([]));
      return;
    }

    // 拆分多关键词 (支持空格、半角/全角逗号、半角/全角分号进行分隔)
    const keywords = query.split(/[ ,;，；]+/).map(k => k.trim()).filter(k => k.length > 0);
    if (keywords.length === 0) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify([]));
      return;
    }

    try {
      if (!fs.existsSync(BRAIN_DIR)) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify([]));
        return;
      }

      const dirs = fs.readdirSync(BRAIN_DIR).filter(file => {
        const fullPath = path.join(BRAIN_DIR, file);
        return fs.statSync(fullPath).isDirectory() && !file.startsWith('.');
      });

      const results = [];

      dirs.forEach(dir => {
        const meta = getConversationMetadata(dir);
        if (!meta) return;

        const logPath = path.join(BRAIN_DIR, dir, '.system_generated/logs/transcript.jsonl');
        if (!fs.existsSync(logPath)) return;

        const content = fs.readFileSync(logPath, 'utf8');
        const lines = content.trim().split('\n');

        lines.forEach((line, index) => {
          if (!line) return;
          try {
            const step = JSON.parse(line);
            let matched = true;
            let snippet = '';

            // 多关键词 AND 匹配 (必须满足所有关键词)
            for (const kw of keywords) {
              let kwMatched = false;
              if (step.content && step.content.toLowerCase().includes(kw)) {
                kwMatched = true;
                if (!snippet) snippet = step.content; // 用首个匹配的文本块作为摘要
              } else if (step.tool_calls && JSON.stringify(step.tool_calls).toLowerCase().includes(kw)) {
                kwMatched = true;
                if (!snippet) snippet = `工具调用: ${step.tool_calls.map(tc => tc.name).join(', ')}`;
              }

              if (!kwMatched) {
                matched = false;
                break; // 只要有一个关键词不满足，就中断匹配
              }
            }

            if (matched && keywords.length > 0) {
              if (snippet.length > 150) {
                snippet = snippet.slice(0, 150) + '...';
              }
              results.push({
                conversationId: dir,
                conversationTitle: meta.title,
                date: meta.date,
                stepIndex: step.step_index || index,
                source: step.source,
                type: step.type,
                snippet: snippet.trim()
              });
            }
          } catch (e) {
            // 忽略单行解析错误
          }
        });
      });

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify(results.slice(0, 100))); // 限制返回前 100 个结果
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: '全局搜索失败', details: e.message }));
    }
    return;
  }

  // ================= 静态文件路由 =================
  let filePath = path.join(PUBLIC_DIR, pathname === '/' ? 'index.html' : pathname);
  
  // 防止路径穿越攻击
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('403 Forbidden');
    return;
  }

  serveStaticFile(res, filePath);
});

server.listen(PORT, () => {
  console.log(`📡 Antigravity ArchiveViewer 服务端已启动！`);
  console.log(`🔗 访问地址: http://localhost:${PORT}`);
  console.log(`🧠 归档数据目录: ${BRAIN_DIR}`);
});
