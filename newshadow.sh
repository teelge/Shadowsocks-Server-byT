#!/bin/bash

# 1. Aggressive Cleanup (Kill old Snaps and Services)
sudo systemctl stop shadowsocks-libev-server@config.service 2>/dev/null
sudo systemctl disable shadowsocks-libev-server@config.service 2>/dev/null
sudo snap remove shadowsocks-libev 2>/dev/null
sudo systemctl stop shadowsocks 2>/dev/null

# 2. Install Dependencies
sudo apt-get update
sudo apt-get install -y shadowsocks-libev jq wget tar qrencode

# 3. Download and Install Plugin (The Fix)
wget -O plugin.tar.gz https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf plugin.tar.gz
sudo mv v2ray-plugin*amd64 /usr/bin/v2ray-plugin
sudo chmod +x /usr/bin/v2ray-plugin
rm plugin.tar.gz

# 4. Configuration (Using Absolute Path)
sudo mkdir -p /etc/shadowsocks-libev
cat <<EOF | sudo tee /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":443,
    "password":"troy00",
    "timeout":60,
    "method":"chacha20-ietf-poly1305",
    "plugin":"/usr/bin/v2ray-plugin",
    "plugin_opts":"server;tls;host=www.google.com"
}
EOF

# 5. Create/Restart Service
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks
sudo systemctl restart shadowsocks

# 6. Display Connection Info
IP=$(curl -s https://api.ipify.org)
SS_LINK="ss://$(echo -n "chacha20-ietf-poly1305:troy00" | base64 | tr -d '\n')@$IP:443/?plugin=v2ray-plugin%3Btls%3Bhost%3Dwww.google.com"

clear
echo "--- FREEDOM ACTIVATED BY T ---"
qrencode -t ansiutf8 "$SS_LINK"
echo "Link: $SS_LINK"
