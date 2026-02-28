#!/usr/bin/env bash
set -euo pipefail

: "${ROUTER_API_KEY:?ROUTER_API_KEY is required}"
ROUTER_BASE_URL="${ROUTER_BASE_URL:-https://test-router.yeying.pub/v1}"
ROUTER_MODEL="${ROUTER_MODEL:-gpt-5.3-codex}"
OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}"

openclaw config set models.providers.router.baseUrl "${ROUTER_BASE_URL}"
openclaw config set models.providers.router.auth "api-key"
openclaw config set models.providers.router.apiKey "${ROUTER_API_KEY}"
openclaw config set models.providers.router.api "openai-responses"
openclaw config set models.providers.router.models "[{\"id\":\"${ROUTER_MODEL}\",\"name\":\"${ROUTER_MODEL}\"}]"
openclaw config set agents.defaults.model.primary "router/${ROUTER_MODEL}"

openclaw plugins enable whatsapp
openclaw channels add --channel whatsapp

openclaw config set channels.whatsapp.groupPolicy open
openclaw config set channels.whatsapp.accounts.default.groupPolicy open
openclaw config set channels.whatsapp.dmPolicy pairing
openclaw config set channels.whatsapp.accounts.default.dmPolicy pairing
openclaw config set messages.groupChat.mentionPatterns '[".*"]'
openclaw config set messages.groupChat.historyLimit 30

if [[ -n "${OPENCLAW_GATEWAY_TOKEN}" ]]; then
  openclaw config set gateway.auth.mode token
  openclaw config set gateway.auth.token "${OPENCLAW_GATEWAY_TOKEN}"
fi

echo "[ok] OpenClaw configured"
