#!/bin/bash

# --- COLOR CODES ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}    SHADOWSOCKS PRO - WEBSOCKET EDITION      ${NC}"
echo -e "${CYAN}==============================================${NC}"

# --- 1. CLEANUP & INSTALL ---
echo -e "${YELLOW}[1/5] Cleaning environment and installing tools...${NC}"
sudo systemctl stop ss-troy 2>/dev/null
sudo apt-get update && sudo apt-get install -y shadowsocks-libev wget tar jq qrencode

# --- 2. PLUGIN SETUP ---
echo -e "${YELLOW}[2/5] Downloading v2ray-plugin...${NC}"
PLUGIN_URL="https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz"
wget -q -O plugin.tar.gz "$PLUGIN_URL"
tar -xf plugin.tar.gz
sudo mv v2ray-plugin*amd64 /usr/bin/v2ray-plugin
sudo chmod +x /usr/bin/v2ray-plugin
# Allow the plugin to bind to port 443 without root if needed
sudo setcap cap_net_bind_service+ep /usr/bin/v2ray-plugin
rm -f plugin.tar.gz

# --- 3. CONFIGURATION ---
echo -e "\n${YELLOW}[3/5] Security Configuration${NC}"
printf "${CYAN}Enter password: ${NC}"
read -r password < /dev/tty

# We use WebSocket mode (mode=websocket) for better v2rayNG compatibility
sudo mkdir -p /etc/shadowsocks-libev
cat <<EOF | sudo tee /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":443,
    "password":"$password",
    "timeout":300,
    "method":"chacha20-ietf-poly1305",
    "plugin":"/usr/bin/v2ray-plugin",
    "plugin_opts":"server;host=www.google.com;mode=websocket"
}
EOF

# --- 4. SYSTEMD SERVICE ---
cat <<EOF | sudo tee /etc/systemd/system/ss-troy.service
[Unit]
Description=Shadowsocks Troy WebSocket Service
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json
Restart=always
[Install]
WantedBy=multi-user.target
EOF

# Enable IP Forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

sudo systemctl daemon-reload
sudo systemctl enable ss-troy
sudo systemctl restart ss-troy

# --- 5. LINK GENERATION ---
IP=$(curl -s https://api.ipify.org)
# Proper encoding for WebSocket plugin options
# The link format: ss://BASE64(method:pass)@ip:port/?plugin=...
USER_PASS_B64=$(echo -n "chacha20-ietf-poly1305:$password" | base64 | tr -d '\n\r')
SS_LINK="ss://${USER_PASS_B64}@${IP}:443/?plugin=v2ray-plugin%3Bhost%3Dwww.google.com%3Bmode%3Dwebsocket"

clear
echo -e "${GREEN}--- SERVER RECONFIGURED TO WEBSOCKET ---${NC}"
echo -e "${CYAN}1. Copy this link:${NC}"
echo -e "$SS_LINK\n"
echo -e "${CYAN}2. Or scan this QR Code:${NC}"
qrencode -t ansiutf8 "$SS_LINK"

echo -e "\n${YELLOW}IMPORTANT v2rayNG SETTINGS:${NC}"
echo -e "If the link import still gives a Base64 error, add MANUALLY:"
echo -e " - Transport: ${GREEN}ws${NC}"
echo -e " - Host: ${GREEN}www.google.com${NC}"
echo -e " - Path: ${GREEN}/${NC}"
