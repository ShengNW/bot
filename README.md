# bot

## 项目名称
OpenClaw WhatsApp Bot（Router / GPT-5.3-Codex）

### 项目简介
这是一个用于快速搭建与维护 WhatsApp 机器人（OpenClaw + Router）的仓库，目标是让**新人小白或新开 Codex** 可以按步骤直接拉起服务。

本项目解决三类核心问题：
- **部署问题**：Windows + WSL 环境下，如何稳定运行 OpenClaw
- **网络问题**：国内网络下 v2rayN + WSL 出网与代理联通
- **运营问题**：WhatsApp 登录、群聊触发、健康检查与排障

适用场景：
- 公司内部维护 Bot
- 新同事接手机器人运维
- 多会话协作时统一执行标准

**技术栈：**
- 机器人框架：OpenClaw CLI / Gateway
- 大模型网关：Router（OpenAI-compatible）
- 模型：`gpt-5.3-codex`
- 渠道：WhatsApp
- 环境：Windows + WSL Ubuntu
- 网络：v2rayN + `netsh portproxy`

### 功能特性
- ✅ Router 模型接入（`gpt-5.3-codex`）
- ✅ WhatsApp 扫码登录（linked）
- ✅ 群聊触发配置（`groupPolicy` / `mentionPatterns`）
- ✅ 标准化健康检查命令
- ✅ 常见故障定位路径（405/503/not linked）
- 🚧 自动化安装脚本（计划中）
- 📋 多环境配置模板（计划中）

### 快速开始

#### 环境要求

| 依赖 | 版本要求 | 说明 |
|------|---------|------|
| Windows | Win10/11 | 主机环境 |
| WSL | Ubuntu 22.04+ | 运行环境 |
| Node.js | >= 22.12.0 | OpenClaw 依赖 |
| npm | >= 10 | 包管理器 |
| OpenClaw | >= 2026.2.26 | 机器人框架 |
| v2rayN | 最新稳定版 | 网络代理（国内环境推荐） |

#### 安装步骤

1. **克隆项目**
```bash
git clone git@github.com:ShengNW/bot.git
cd bot
```

2. **Windows 侧安装/检查 WSL（管理员 PowerShell）**
```powershell
wsl --list --online
wsl --install -d Ubuntu-22.04
```

3. **进入 WSL**
```powershell
"C:\Program Files\WSL\wsl.exe"
```

4. **安装 Node.js（示例：二进制安装）**
```bash
cd /tmp
curl -LO https://npmmirror.com/mirrors/node/v22.22.0/node-v22.22.0-linux-x64.tar.xz
sudo tar -xJf node-v22.22.0-linux-x64.tar.xz -C /usr/local
sudo ln -sf /usr/local/node-v22.22.0-linux-x64/bin/node /usr/local/bin/node
sudo ln -sf /usr/local/node-v22.22.0-linux-x64/bin/npm /usr/local/bin/npm
sudo ln -sf /usr/local/node-v22.22.0-linux-x64/bin/npx /usr/local/bin/npx

node -v
npm -v
```

5. **安装 OpenClaw**
```bash
npm i -g openclaw
openclaw --version
```

6. **启用 WhatsApp 插件并添加渠道**
```bash
openclaw plugins enable whatsapp
openclaw channels add --channel whatsapp
```

7. **扫码登录 WhatsApp**
```bash
openclaw channels login --channel whatsapp --verbose
```

8. **配置群聊策略（先跑通）**
```bash
openclaw config set channels.whatsapp.groupPolicy open
openclaw config set channels.whatsapp.accounts.default.groupPolicy open
openclaw config set channels.whatsapp.dmPolicy pairing
openclaw config set channels.whatsapp.accounts.default.dmPolicy pairing
openclaw config set messages.groupChat.mentionPatterns '[".*"]'
openclaw config set messages.groupChat.historyLimit 30
```

#### 配置说明

核心配置文件：
```text
~/.openclaw/openclaw.json
```

Router 关键配置（在 WSL 执行）：
```bash
openclaw config set models.providers.router.baseUrl "https://test-router.yeying.pub/v1"
openclaw config set models.providers.router.auth "api-key"
openclaw config set models.providers.router.apiKey "<ROUTER_API_KEY>"
openclaw config set models.providers.router.api "openai-responses"
openclaw config set models.providers.router.models '[{"id":"gpt-5.3-codex","name":"GPT-5.3-Codex"}]'
openclaw config set agents.defaults.model.primary "router/gpt-5.3-codex"
```

> 重要：
> - `models.providers.router.api` 必须使用 `openai-responses`
> - `<ROUTER_API_KEY>` 是敏感信息，禁止提交到仓库

### 本地开发

#### 开发环境搭建

1. **工具建议**
- IDE：VSCode（推荐 Remote-WSL）
- 终端：Windows Terminal / PowerShell

2. **基础检查（WSL）**
```bash
whoami
hostname
node -v
openclaw --version
```

3. **网络与代理检查（Windows + WSL）**

Windows（管理员）：
```powershell
# 检查 v2rayN 端口（示例 10808）
netstat -ano | findstr :10808

# 建立桥接：WSL -> Windows 本地代理
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=10810 connectaddress=127.0.0.1 connectport=10808
netsh interface portproxy show v4tov4
```

WSL：
```bash
# 固定 DNS，避免 WSL 解析抖动
sudo tee /etc/wsl.conf >/dev/null <<'CFG'
[network]
generateResolvConf = false
CFG

sudo rm -f /etc/resolv.conf
sudo tee /etc/resolv.conf >/dev/null <<'DNS'
nameserver 1.1.1.1
nameserver 8.8.8.8
DNS

# 通过 Windows 代理桥测试出网
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
curl --socks5-hostname "$HOST_IP:10810" https://api.ipify.org
```

#### 运行项目

```bash
# 1) 查看渠道状态
openclaw channels status

# 2) 查看网关健康
openclaw gateway --token <GATEWAY_TOKEN> health

# 3) 本地 agent 测试（验证模型链路）
openclaw agent --local --to +15555550123 --message "ping" --thinking off --timeout 120 --json
```

#### 调试方法

1. **Router 连通测试**
```bash
curl -sS https://test-router.yeying.pub/v1/models \
  -H "Authorization: Bearer <ROUTER_API_KEY>"
```

2. **Router responses 测试**
```bash
curl -sS https://test-router.yeying.pub/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ROUTER_API_KEY>" \
  -d '{"model":"gpt-5.3-codex","input":"reply with pong only"}'
```

3. **渠道日志**
```bash
openclaw channels logs --channel whatsapp --lines 120
```

4. **常见故障对照**
```text
- 405 Method Not Allowed：优先排查 WhatsApp 客户端指纹兼容
- 503 所有供应商暂时不可用：检查 router.api 是否为 openai-responses
- Failed to extract accountId from token：通常是 API 模式不匹配
- not linked：重新 channels login 扫码
```

### 生产部署

#### 部署前准备

**检查清单：**
- [ ] 目标主机已确认（hostname）
- [ ] WSL/Node/OpenClaw 版本满足要求
- [ ] `ROUTER_API_KEY` 已准备（不入库）
- [ ] v2rayN + portproxy 已验证
- [ ] WhatsApp 已扫码 linked

#### 部署步骤

1. **拉取代码**
```bash
git clone git@github.com:ShengNW/bot.git
cd bot
```

2. **按“快速开始”完成配置**

3. **启动网关**
```bash
# 前台（调试）
openclaw gateway run --allow-unconfigured
```

4. **验证在线状态**
```bash
openclaw channels status
openclaw gateway --token <GATEWAY_TOKEN> health
```

5. **群内实测**
- 把已 linked 的 WhatsApp 号拉进目标群
- 群里发文本，观察机器人回包

#### 环境变量配置

推荐在 WSL 配置：
```bash
# ~/.bashrc
export ROUTER_API_KEY="<ROUTER_API_KEY>"
```

如果需要代理：
```bash
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
export ALL_PROXY="socks5h://$HOST_IP:10810"
export http_proxy="$ALL_PROXY"
export https_proxy="$ALL_PROXY"
```

#### 健康检查

```bash
openclaw channels status
openclaw gateway --token <GATEWAY_TOKEN> health
openclaw channels logs --channel whatsapp --lines 60
```

预期关键状态：
```text
WhatsApp default: enabled, configured, linked, running, connected
Gateway Health: OK
```

### API文档
- OpenClaw CLI 文档：https://docs.openclaw.ai/cli
- Router API（OpenAI-compatible）：`https://test-router.yeying.pub/v1`
- 接口里程碑（示例）：https://github.com/yeying-community/interface/milestones

### 测试
```bash
# 1) Router 模型可用性
curl -sS https://test-router.yeying.pub/v1/models -H "Authorization: Bearer <ROUTER_API_KEY>"

# 2) WhatsApp 渠道是否在线
openclaw channels status

# 3) Agent 本地回复测试
openclaw agent --local --to +15555550123 --message "你好" --thinking off --timeout 120 --json
```

### 贡献指南
1. 建分支：
```bash
git checkout -b feat/<topic>
```

2. 提交规范：
- 配置模板可提交，真实密钥不可提交
- README 中命令必须可复制执行
- 修复问题要写清“现象-原因-解决”

3. 提交与推送：
```bash
git add .
git commit -m "feat: <summary>"
git push origin feat/<topic>
```

4. PR 要求：
- 明确复现步骤
- 关键日志输出（脱敏）
- 影响范围说明
