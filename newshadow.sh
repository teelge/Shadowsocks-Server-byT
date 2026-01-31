#!/bin/bash

# --- COLOR CODES ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}    SHADOWSOCKS PRO INSTALLER - VERSION 2.3   ${NC}"
echo -e "${CYAN}==============================================${NC}"

# --- 1. PASSWORD INPUT (STRICT) ---
echo -e "${YELLOW}Step 1: Set your Shadowsocks Password${NC}"
# Using /dev/tty ensures it reads from your keyboard directly
printf "${CYAN}Enter password (default: troy00): ${NC}"
read -r password < /dev/tty
password=${password:-troy00}
echo -e "${GREEN}Password locked in as: $password${NC}\n"

# 2. CLEANUP OLD SERVICES
echo -e "${YELLOW}[2/7] Clearing Port 443 & Old Services...${NC}"
sudo systemctl stop shadowsocks shadowsocks-libev 2>/dev/null
sudo snap remove shadowsocks-libev 2>/dev/null
sudo fuser -k 443/tcp 2>/dev/null

# 3. INSTALL NATIVE TOOLS
echo -e "${YELLOW}[3/7] Installing dependencies...${NC}"
sudo apt-get update && sudo apt-get install -y shadowsocks-libev jq wget tar qrencode psmisc net-tools

# 4. ENABLE TCP BBR (SPEED BOOSTER)
echo -e "${YELLOW}[4/7] Enabling BBR Congestion Control...${NC}"
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p > /dev/null
fi

# 5. DOWNLOAD & CONFIGURE V2RAY-PLUGIN
echo -e "${YELLOW}[5/7] Setting up v2ray-plugin...${NC}"
wget -O plugin.tar.gz https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf plugin.tar.gz
sudo mv v2ray-plugin*amd64 /usr/bin/v2ray-plugin 2>/dev/null
sudo chmod +x /usr/bin/v2ray-plugin
rm plugin.tar.gz

# 6. CONFIGURE SERVER
sudo mkdir -p /etc/shadowsocks-libev
cat <<EOF | sudo tee /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":443,
    "password":"$password",
    "timeout":60,
    "method":"chacha20-ietf-poly1305",
    "plugin":"/usr/bin/v2ray-plugin",
    "plugin_opts":"server;tls;host=www.google.com"
}
EOF

# 7. SERVICE CREATION & START
cat <<EOF | sudo tee /etc/systemd/system/shadowsocks.service
[Unit]
Description=Shadowsocks-T Service
After=network.target

[Service]
Type=simple
User=root
ExecStartPre=/usr/bin/fuser -k 443/tcp
ExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable shadowsocks
sudo systemctl restart shadowsocks

# FINAL OUTPUT
IP=$(curl -s https://api.ipify.org)
USER_PASS=$(echo -n "chacha20-ietf-poly1305:$password" | base64 | tr -d '\n')
SS_LINK="ss://${USER_PASS}@${IP}:443/?plugin=v2ray-plugin%3Btls%3Bhost%3Dwww.google.com"

clear
echo -e "${GREEN}--- FREEDOM ACTIVATED BY T ---${NC}"
echo -e "${YELLOW}Shadowsocks Link:${NC}"
echo -e "${CYAN}$SS_LINK${NC}\n"
qrencode -t ansiutf8 "$SS_LINK"

# --- 8. THE STATUS CHECK PROMPT (FORCED) ---
echo ""
echo -e "${CYAN}Do you want to check the status of Shadowsocks & v2ray-plugin? (y/n)${NC}"
# Forced read from terminal
read -r -p "Enter Choice: " verify_choice < /dev/tty

if [[ "$verify_choice" =~ ^([yY])$ ]]; then
    echo -e "\n${YELLOW}--- [PROCESSES] ---${NC}"
    ps -ef | grep -E "ss-server|v2ray-plugin" | grep -v grep
    echo -e "\n${YELLOW}--- [NETWORK PORT 443] ---${NC}"
    sudo netstat -tulpn | grep :443
    echo -e "\n${YELLOW}--- [LOGS] ---${NC}"
    sudo journalctl -u shadowsocks --no-pager -n 5
else
    echo -e "\n${GREEN}Setup complete! Your server is running in the background.${NC}"
fi
