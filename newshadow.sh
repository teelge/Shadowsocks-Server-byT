#!/bin/bash

# --- COLOR CODES ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}    SHADOWSOCKS PRO INSTALLER - VERSION 3.0   ${NC}"
echo -e "${CYAN}==============================================${NC}"

# --- 1. MANDATORY PASSWORD INPUT ---
echo -e "${YELLOW}Step 1: Security Configuration${NC}"
password=""
while [ -z "$password" ]; do
    printf "${CYAN}Enter your custom password: ${NC}"
    read -r password < /dev/tty
    if [ -z "$password" ]; then
        echo -e "${RED}Error: Password cannot be empty.${NC}"
    fi
done

# --- 2. AGGRESSIVE PURGE ---
echo -e "\n${YELLOW}[2/7] Purging old 'shadowsocks' service...${NC}"
sudo systemctl stop shadowsocks ss-troy 2>/dev/null
sudo systemctl disable shadowsocks ss-troy 2>/dev/null
# Delete the old broken file entirely
sudo rm -f /etc/systemd/system/shadowsocks.service
sudo fuser -k 443/tcp 2>/dev/null 

# --- 3. INSTALL & SPEED BOOST ---
sudo apt-get update && sudo apt-get install -y shadowsocks-libev jq wget tar qrencode psmisc net-tools
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p > /dev/null
fi

# --- 4. PLUGIN INSTALL ---
wget -q -O plugin.tar.gz https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf plugin.tar.gz
sudo mv v2ray-plugin*amd64 /usr/bin/v2ray-plugin 2>/dev/null
sudo chmod +x /usr/bin/v2ray-plugin
rm -f plugin.tar.gz

# --- 5. CONFIGURATION ---
sudo mkdir -p /etc/shadowsocks-libev
cat <<EOF | sudo tee /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":443,
    "password":"$password",
    "timeout":60,
    "method":"chacha20-ietf-poly1305",
    "plugin":"/usr/bin/v2ray-plugin",
    "plugin_opts":"server;host=www.google.com"
}
EOF

# --- 6. NEW SERVICE (RENAMED TO SS-TROY) ---
# Renaming forces systemd to ignore all previous cached errors
echo -e "${YELLOW}[6/7] Creating new service: ss-troy...${NC}"
cat <<EOF | sudo tee /etc/systemd/system/ss-troy.service
[Unit]
Description=Shadowsocks Troy Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# --- 7. LAUNCH ---
sudo systemctl daemon-reload
sudo systemctl enable ss-troy
sudo systemctl restart ss-troy

# --- GENERATE LINK ---
IP=$(curl -s https://api.ipify.org)
USER_PASS=$(echo -n "chacha20-ietf-poly1305:$password" | base64 | tr -d '\n')
SS_LINK="ss://${USER_PASS}@${IP}:443/?plugin=v2ray-plugin%3Bhost%3Dwww.google.com"

clear
echo -e "${GREEN}--- FREEDOM ACTIVATED BY T ---${NC}"
echo -e "${CYAN}Shadowsocks Link (HTTP Mode):${NC}"
echo -e "$SS_LINK\n"
qrencode -t ansiutf8 "$SS_LINK"

# --- 8. STATUS CHECK ---
echo ""
echo -e "${CYAN}Would you like to verify the service status? (y/n)${NC}"
read -r verify_choice < /dev/tty

if [[ "$verify_choice" =~ ^([yY])$ ]]; then
    echo -e "\n${YELLOW}--- [PROCESS TREE] ---${NC}"
    ps -ef | grep -E "ss-server|v2ray-plugin" | grep -v grep
    echo -e "\n${YELLOW}--- [PORT 443 STATUS] ---${NC}"
    sudo netstat -tulpn | grep :443
    echo -e "\n${YELLOW}--- [LOGS] ---${NC}"
    sudo journalctl -u ss-troy --no-pager -n 5
else
    echo -e "\n${GREEN}Setup complete! Your server is running as 'ss-troy'.${NC}"
fi
