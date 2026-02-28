# Windows v2rayN + WSL 代理桥接说明

适用场景：
- v2rayN 在 Windows 监听 `127.0.0.1:10808`
- WSL 里的应用无法直接使用该代理

## 1) Windows 管理员 PowerShell

```powershell
# 查看 v2rayN 是否监听（示例端口 10808）
netstat -ano | findstr :10808

# 先删除旧规则（不存在可忽略报错）
netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=10810

# 新增桥接：WSL -> Windows 代理
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=10810 connectaddress=127.0.0.1 connectport=10808

# 验证规则
netsh interface portproxy show v4tov4
```

预期：
```text
0.0.0.0  10810  127.0.0.1  10808
```

## 2) WSL 侧验证

```bash
HOST_IP=$(ip route | awk '/default/ {print $3; exit}')
curl --socks5-hostname "$HOST_IP:10810" https://api.ipify.org
```

## 3) WSL DNS 固定（推荐）

```bash
sudo tee /etc/wsl.conf >/dev/null <<'CFG'
[network]
generateResolvConf = false
CFG

sudo rm -f /etc/resolv.conf
sudo tee /etc/resolv.conf >/dev/null <<'DNS'
nameserver 1.1.1.1
nameserver 8.8.8.8
DNS
```
