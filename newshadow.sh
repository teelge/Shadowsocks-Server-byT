#!/bin/bash

# --- COLOR CODES ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' 

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}    SHADOWSOCKS PRO INSTALLER - VERSION 2.4   ${NC}"
echo -e "${CYAN}==============================================${NC}"

# 1. INTERACTIVE PASSWORD
echo -e "${YELLOW}Step 1: Security Configuration${NC}"
printf "${CYAN}Enter Shadowsocks password (default: troy00): ${NC}"
read -r password < /dev/tty
password=${password:-troy00}

# 2. CLEANUP & INSTALL
echo -e "\n${YELLOW}[2/7] Installing dependencies...${NC}"
sudo systemctl stop shadowsocks 2>/dev/null
sudo apt-get update && sudo apt-get install -y shadowsocks-libev jq wget tar qrencode psmisc net-tools

# 3. SPEED OPTIMIZATION (BBR)
echo -e "${YELLOW}[3/7] Enabling BBR Speed Booster...${NC}"
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p > /dev/null
fi

# 4. PLUGIN INSTALL
echo -e "${YELLOW}[4/7] Setting up v2ray-plugin...${NC}"
wget -O plugin.tar.gz https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf plugin.tar.gz
sudo mv v2ray-plugin*amd64 /usr/bin/v2ray-plugin 2>/dev/null
sudo chmod +x /usr/bin/v2ray-plugin
rm -f plugin.tar.gz

# 5. CONFIGURATION (HTTP Mode - No Certificate Needed)
echo -e "${YELLOW}[5/7] Creating configuration...${NC}"
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

# 6. SERVICE CREATION
cat <<EOF | sudo tee /etc/systemd/system/shadowsocks.service
[Unit]
Description=Shadowsocks-T Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 7. LAUNCH
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks
sudo systemctl restart shadowsocks

# GENERATE LINK
IP=$(curl -s https://api.ipify.org)
USER_PASS=$(echo -n "chacha20-ietf-poly1305:$password" | base64 | tr -d '\n')
SS_LINK="ss://${USER_PASS}@${IP}:443/?plugin=v2ray-plugin%3Bhost%3Dwww.google.com"

clear
echo -e "${GREEN}--- FREEDOM ACTIVATED BY T ---${NC}"
echo -e "${CYAN}Shadowsocks Link (HTTP Obfuscation Mode):${NC}"
echo -e "$SS_LINK\n"
qrencode -t ansiutf8 "$SS_LINK"

# INTERACTIVE STATUS CHECK
echo -e "\n${CYAN}Would you like to verify the service status? (y/n)${NC}"
read -r verify_choice < /dev/tty

if [[ "$verify_choice" =~ ^([yY])$ ]]; then
    echo -e "\n${YELLOW}--- [PROCESSES] ---${NC}"
    ps -ef | grep -E "ss-server|v2ray-plugin" | grep -v grep
    echo -e "\n${YELLOW}--- [PORT 443] ---${NC}"
    sudo netstat -tulpn | grep :443
    echo -e "\n${YELLOW}--- [LOGS] ---${NC}"
    sudo journalctl -u shadowsocks --no-pager -n 5
fi
