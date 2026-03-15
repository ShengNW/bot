# Rust Control Plane（Full Stack）

本目录已经从“Phase 1 骨架”升级为**可运行全栈应用**：
- Web 页面（钱包登录门禁）
- Public/Admin/Internal 三类接口
- 多机器人实例编排（WhatsApp / DingTalk）
- 每实例独立 OpenClaw profile、独立端口、独立运行目录

## 1. 目录

```text
rust/control-plane/
  Cargo.toml
  .env.example
  .env
  src/main.rs
  web/index.html
scripts/
  bootstrap_rust_control_plane.sh
  run_control_plane_dev.sh
  bootstrap_full_stack.sh
  run_full_stack.sh
  stop_full_stack.sh
  status_full_stack.sh
  doctor_full_stack.sh
```

## 2. 一键启动（WSL）

```bash
cd /home/administrator/code/bot_hub
bash scripts/deploy_full_stack.sh
```

如果你希望分步骤执行：

```bash
cd /home/administrator/code/bot_hub
bash scripts/bootstrap_full_stack.sh
# 编辑 rust/control-plane/.env，填 ROUTER_API_KEY
bash scripts/run_full_stack.sh
bash scripts/status_full_stack.sh
```

默认访问：`http://127.0.0.1:3900/`

## 3. Web 功能

1. 钱包连接登录（必须）
2. 创建机器人实例（WhatsApp / DingTalk）
3. 启动/停止实例
4. WhatsApp 一键触发配对命令
5. 查看实例日志（gateway/pair）
6. 设置全局默认模型（Admin Token）
7. 拉取 Router 模型列表

## 4. 接口分层（Interface 规范）

### public
- `GET /api/v1/public/health`
- `GET /api/v1/public/version`
- `GET /api/v1/public/auth/me`
- `POST /api/v1/public/auth/wallet/connect`
- `POST /api/v1/public/auth/logout`
- `GET /api/v1/public/bot/types`
- `GET /api/v1/public/router/models`
- `GET /api/v1/public/bot/instances`
- `POST /api/v1/public/bot/instances`
- `GET /api/v1/public/bot/instances/{id}`
- `PATCH /api/v1/public/bot/instances/{id}/model`
- `POST /api/v1/public/bot/instances/{id}/start`
- `POST /api/v1/public/bot/instances/{id}/stop`
- `POST /api/v1/public/bot/instances/{id}/pair-whatsapp`
- `GET /api/v1/public/bot/instances/{id}/logs`

### admin
- `PATCH /api/v1/admin/router/default-model`
- `GET /api/v1/admin/runtime/summary`

### internal
- `POST /api/v1/internal/runtime/health/probe`

## 5. 独立性保证（不互相影响）

每个实例创建后会绑定：
- 独立 profile：`hub-<instance_id>`
- 独立根目录：`runtime/instances/<instance_id>/...`
- 独立 gateway 端口：默认 `18800-18999` 自动分配
- 独立进程 PID 与日志文件

> 因此可并行运行多个 WhatsApp / DingTalk 机器人，且不覆盖已有生产机器人配置。

## 6. 快速验收命令

```bash
# 1) 健康检查
curl -sS http://127.0.0.1:3900/api/v1/public/health

# 2) 页面可访问
curl -sSI http://127.0.0.1:3900/ | head -n 5

# 3) admin summary（示例 token）
curl -sS http://127.0.0.1:3900/api/v1/admin/runtime/summary \
  -H 'x-admin-token: change-me-admin-token'

# 4) internal probe（示例 token）
curl -sS -X POST http://127.0.0.1:3900/api/v1/internal/runtime/health/probe \
  -H 'x-internal-token: change-me-internal-token'
```

## 7. 常见问题

### Q1: 浏览器打开 127.0.0.1:3900 连接被拒绝
- 先执行：`bash scripts/status_full_stack.sh`
- 若未运行：`bash scripts/run_full_stack.sh`
- 看日志：`tail -n 120 runtime/control-plane/logs/control-plane.out.log`

### Q2: 能登录但拉模型失败
- 检查 `.env` 中 `ROUTER_API_KEY`
- 执行：`bash scripts/doctor_full_stack.sh`

### Q3: 实例启动失败
- 检查 `openclaw --version`
- 看实例日志：UI 中点击“日志”或读取
  - `runtime/instances/<id>/logs/gateway.log`

### Q4: 钉钉实例报错 `plugin not found: dingtalk`
- 先在 WSL 安装插件：
```bash
openclaw plugins install @soimy/dingtalk
```
- 再回到 UI 重新点击“启动”。
- 如果 npm 依赖安装失败，先修复 npm 网络/代理后重试。

## 8. 停止服务

```bash
cd /home/administrator/code/bot_hub
bash scripts/stop_full_stack.sh
```
