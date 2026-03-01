# bot

## 项目名称
OpenClaw WhatsApp Bot（A 路线：官方包 + 补丁脚本化 + 版本锁定）

### 项目简介
本仓库用于在**国内 Windows + WSL** 环境快速落地 OpenClaw 机器人，模型调用走公司 Router（`gpt-5.3-codex`），并支持 WhatsApp 群消息回复。

本仓库选择 **A 路线**：
- 不 fork OpenClaw
- 不引入 OpenClaw 子模块
- 使用官方安装包（`npm i -g openclaw@锁定版本`）
- 将兼容补丁与排障流程脚本化（可重复执行）

你可以把它理解为：
- OpenClaw 官方负责核心能力
- 本仓库负责“企业可复现部署层”（版本、配置、补丁、运维）

### 功能特性
- ✅ 版本锁定：`versions.lock`
- ✅ 配置模板：`config/openclaw.json.template`、`config/env.example`
- ✅ 脚本化安装：`scripts/install_openclaw.sh`
- ✅ WhatsApp 405 兼容补丁：`scripts/apply_whatsapp_patch.sh`
- ✅ 一键健康检查：`scripts/doctor.sh`
- ✅ 最终验收脚本：`scripts/verify.sh`
- ✅ Windows 代理桥接文档：`ops/windows/v2rayn-portproxy.md`
- ✅ 机器人工作区模板：`workspace/*.md`

### 快速开始

#### 环境要求

| 依赖 | 版本要求 | 说明 |
|------|---------|------|
| Windows | Win10/11 | 主机环境 |
| WSL | Ubuntu 22.04+ | 运行环境 |
| Node.js | >= 22.12.0 | OpenClaw 依赖 |
| npm | >= 10 | 包管理器 |
| OpenClaw | 2026.2.26（锁定） | 机器人框架 |
| v2rayN | 最新稳定版 | 国内网络代理（推荐） |

#### 安装步骤

1. **克隆项目（在 WSL）**
```bash
git clone git@github.com:ShengNW/bot.git
cd bot
```

2. **准备环境变量文件**
```bash
cp config/env.example .env.local
# 编辑 .env.local，至少填写 ROUTER_API_KEY
```

3. **加载环境变量**
```bash
set -a
source .env.local
set +a
```

4. **安装 Node + OpenClaw（锁定版本）**
```bash
bash scripts/install_openclaw.sh
```

5. **配置 OpenClaw（Router + WhatsApp 策略）**
```bash
bash scripts/configure_openclaw.sh
```

6. **应用 WhatsApp 兼容补丁（405 修复）**
```bash
bash scripts/apply_whatsapp_patch.sh
```

7. **扫码登录 WhatsApp**
```bash
openclaw channels login --channel whatsapp --verbose
```

8. **执行健康检查和验收**
```bash
bash scripts/doctor.sh
bash scripts/verify.sh
```

#### 配置说明

1. **环境变量（推荐）**
- 文件：`.env.local`（由 `config/env.example` 复制）
- 关键项：
```text
ROUTER_API_KEY=你的密钥
ROUTER_BASE_URL=https://test-router.yeying.pub/v1
ROUTER_MODEL=gpt-5.3-codex
OPENCLAW_GATEWAY_TOKEN=可选
```

2. **OpenClaw 运行配置位置**
```text
~/.openclaw/openclaw.json
```

3. **模板说明**
- `config/openclaw.json.template` 是脱敏模板，不直接带真实密钥。
- `scripts/configure_openclaw.sh` 会把关键配置写入 `~/.openclaw/openclaw.json`。

### 本地开发

#### 开发环境搭建

1. **推荐工具**
- VSCode（Remote-WSL）
- Windows Terminal / PowerShell

2. **基础自检**
```bash
whoami
hostname
node -v
openclaw --version
```

3. **网络自检（国内环境）**
- 先按 `ops/windows/v2rayn-portproxy.md` 完成 Windows 侧桥接。
- 再在 WSL 验证：
```bash
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
curl --socks5-hostname "$HOST_IP:10810" https://api.ipify.org
```

#### 运行项目

1. **查看渠道状态**
```bash
openclaw channels status
```

2. **启动网关（调试模式）**
```bash
openclaw gateway run --allow-unconfigured
```

3. **另一终端检查健康**
```bash
openclaw gateway --token "$OPENCLAW_GATEWAY_TOKEN" health
```

4. **模型链路试跑**
```bash
openclaw agent --local --to +15555550123 --message "ping" --thinking off --timeout 120 --json
```

#### 调试方法

1. **Router 模型列表检查**
```bash
curl -sS "$ROUTER_BASE_URL/models" -H "Authorization: Bearer $ROUTER_API_KEY"
```

2. **渠道日志**
```bash
openclaw channels logs --channel whatsapp --lines 120
```

3. **常见故障速查**
```text
- 405 Method Not Allowed：先跑 scripts/apply_whatsapp_patch.sh
- 503 所有供应商暂时不可用：检查 router.api 是否为 openai-responses
- Failed to extract accountId from token：检查 API wire 模式
- not linked：重新执行 channels login 扫码
```

### 生产部署

#### 部署前准备

**检查清单：**
- [ ] `.env.local` 已配置且未泄露
- [ ] 版本与 `versions.lock` 一致
- [ ] v2rayN 与 portproxy 已按文档配置
- [ ] WhatsApp 账号可扫码登录
- [ ] Router key 有效

#### 部署步骤

1. 拉代码并进入目录：
```bash
git clone git@github.com:ShengNW/bot.git
cd bot
```

2. 加载变量并安装：
```bash
cp config/env.example .env.local
set -a && source .env.local && set +a
bash scripts/install_openclaw.sh
bash scripts/configure_openclaw.sh
bash scripts/apply_whatsapp_patch.sh
```

3. 扫码并验收：
```bash
openclaw channels login --channel whatsapp --verbose
bash scripts/verify.sh
```

4. 运行服务：
```bash
openclaw gateway run --allow-unconfigured
```

#### 环境变量配置

建议最少配置：
```text
ROUTER_API_KEY=
ROUTER_BASE_URL=https://test-router.yeying.pub/v1
ROUTER_MODEL=gpt-5.3-codex
OPENCLAW_GATEWAY_TOKEN=
```

代理（可选）：
```text
ALL_PROXY=socks5h://<wsl-gateway-ip>:10810
http_proxy=$ALL_PROXY
https_proxy=$ALL_PROXY
```

#### 健康检查

执行：
```bash
bash scripts/doctor.sh
bash scripts/verify.sh
```

目标状态：
```text
WhatsApp default: enabled, configured, linked, running, connected
Gateway Health: OK
```

### API文档
- OpenClaw CLI：https://docs.openclaw.ai/cli
- Router API（OpenAI-compatible）：`https://test-router.yeying.pub/v1`

### 测试

```bash
# 1) 模型可用
curl -sS "$ROUTER_BASE_URL/models" -H "Authorization: Bearer $ROUTER_API_KEY"

# 2) 渠道在线
openclaw channels status

# 3) Agent 回包
openclaw agent --local --to +15555550123 --message "你好" --thinking off --timeout 120 --json
```

### 贡献指南

1. **创建分支**
```bash
git checkout -b feat/<topic>
```

2. **提交规范**
- 禁止提交真实密钥
- 脚本改动需保留幂等特性
- 文档改动必须给出可复制命令

3. **提交与推送**
```bash
git add .
git commit -m "feat: <summary>"
git push origin feat/<topic>
```

4. **PR 要求**
- 复现步骤
- 关键输出（脱敏）
- 影响范围与回滚方案
