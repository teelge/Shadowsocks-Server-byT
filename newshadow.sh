#!/bin/bash

# --- COLOR CODES ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}    SHADOWSOCKS PRO INSTALLER - VERSION 2.0   ${NC}"
echo -e "${CYAN}==============================================${NC}"

# 1. AGGRESSIVE CLEANUP
echo -e "${YELLOW}[1/7] Cleaning up old services...${NC}"
sudo systemctl stop shadowsocks shadowsocks-libev 2>/dev/null
sudo snap remove shadowsocks-libev 2>/dev/null
sudo systemctl disable shadowsocks-libev-server@config 2>/dev/null
sudo fuser -k 443/tcp 2>/dev/null

# 2. INSTALL NATIVE TOOLS
echo -e "${YELLOW}[2/7] Installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y shadowsocks-libev jq wget tar qrencode psmisc net-tools

# 3. ENABLE TCP BBR (SPEED BOOSTER)
echo -e "${YELLOW}[3/7] Optimizing network speed (BBR)...${NC}"
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p > /dev/null
fi

# 4. DOWNLOAD V2RAY-PLUGIN (OBFUSCATION)
echo -e "${YELLOW}[4/7] Installing v2ray-plugin...${NC}"
wget -O plugin.tar.gz https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf plugin.tar.gz
# Ensure we find the binary regardless of naming conventions
sudo mv v2ray-plugin*amd64 /usr/bin/v2ray-plugin 2>/dev/null
sudo chmod +x /usr/bin/v2ray-plugin
rm plugin.tar.gz

# 5. CONFIGURE SERVER
echo -e "${YELLOW}[5/7] Creating configuration...${NC}"
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

# 6. SYSTEMD SERVICE CREATION
echo -e "${YELLOW}[6/7] Setting up system service...${NC}"
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

# 7. LAUNCH
echo -e "${YELLOW}[7/7] Launching server...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks
sudo systemctl restart shadowsocks

# GENERATE OUTPUT
IP=$(curl -s https://api.ipify.org)
USER_PASS=$(echo -n "chacha20-ietf-poly1305:troy00" | base64 | tr -d '\n')
SS_LINK="ss://${USER_PASS}@${IP}:443/?plugin=v2ray-plugin%3Btls%3Bhost%3Dwww.google.com"

clear
echo -e "${GREEN}--- FREEDOM ACTIVATED BY T ---${NC}"
echo -e "${CYAN}IP: $IP | Port: 443${NC}"
echo ""
qrencode -t ansiutf8 "$SS_LINK"
echo ""
echo -e "${YELLOW}Shadowsocks Link:${NC}"
echo "$SS_LINK"
echo ""

# --- NEW MONITORING QUESTION ---
echo -e "${CYAN}Would you like to see everything running to verify? (y/n)${NC}"
read -r answer
if [[ "$answer" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "\n${YELLOW}--- ACTIVE PROCESSES (Parent & Plugin) ---${NC}"
    ps -ef | grep -E "ss-server|v2ray-plugin" | grep -v grep
    
    echo -e "\n${YELLOW}--- PORT 443 STATUS ---${NC}"
    sudo netstat -tulpn | grep :443
    
    echo -e "\n${YELLOW}--- REAL-TIME SERVICE LOGS ---${NC}"
    sudo journalctl -u shadowsocks --no-pager -n 5
else
    echo -e "${GREEN}System is running in the background. Enjoy your freedom!${NC}"
fi
