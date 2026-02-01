#!/bin/bash

# --- COLOR CODES ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' 

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}    SHADOWSOCKS PRO - ANDROID COMPATIBLE     ${NC}"
echo -e "${CYAN}==============================================${NC}"

# --- 1. DETECTION & UNINSTALL ---
if [ -f /etc/systemd/system/ss-troy.service ] || [ -f /etc/systemd/system/shadowsocks.service ]; then
    echo -e "${YELLOW}[!] PREVIOUS INSTALLATION DETECTED${NC}"
    printf "${CYAN}Would you like to UNINSTALL and wipe clean? [Y/n]: ${NC}"
    read -r purge_choice < /dev/tty
    purge_choice=${purge_choice:-y}
    
    if [[ "$purge_choice" =~ ^([yY])$ ]]; then
        sudo systemctl stop ss-troy shadowsocks 2>/dev/null
        sudo systemctl disable ss-troy shadowsocks 2>/dev/null
        sudo rm -f /etc/systemd/system/ss-troy.service /etc/systemd/system/shadowsocks.service
        sudo rm -rf /etc/shadowsocks-libev
        sudo rm -f /usr/bin/v2ray-plugin
        sudo fuser -k 443/tcp 2>/dev/null
        sudo systemctl daemon-reload
        echo -e "${GREEN}[+] System cleaned.${NC}"
        
        printf "${CYAN}Continue with fresh install? [Y/n]: ${NC}"
        read -r next_step < /dev/tty
        next_step=${next_step:-y}
        if [[ ! "$next_step" =~ ^([yY])$ ]]; then exit 0; fi
    fi
fi

# --- 2. CONFIG ---
echo -e "\n${YELLOW}Step 1: Security Configuration${NC}"
password=""
while [ -z "$password" ]; do
    printf "${CYAN}Enter password (e.g., troy00): ${NC}"
    read -r password < /dev/tty
done

# --- 3. INSTALLATION ---
sudo apt-get update && sudo apt-get install -y shadowsocks-libev jq wget tar qrencode psmisc net-tools

# --- 4. PLUGIN ---
wget -q -O plugin.tar.gz https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf plugin.tar.gz
sudo mv v2ray-plugin*amd64 /usr/bin/v2ray-plugin
sudo chmod +x /usr/bin/v2ray-plugin
rm -f plugin.tar.gz

# --- 5. JSON CONFIG ---
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

# --- 6. SERVICE ---
cat <<EOF | sudo tee /etc/systemd/system/ss-troy.service
[Unit]
Description=Shadowsocks Troy Service
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json
Restart=always
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ss-troy
sudo systemctl restart ss-troy

# --- 7. ROBUST LINK GENERATION ---
IP=$(curl -s https://api.ipify.org)
# Ensure clean Base64 without line breaks or illegal chars
USER_PASS_RAW="chacha20-ietf-poly1305:$password"
USER_PASS_B64=$(echo -n "$USER_PASS_RAW" | base64 | tr -d '\n\r')

# Construct the link with proper URL encoding for the plugin options
SS_LINK="ss://${USER_PASS_B64}@${IP}:443/?plugin=v2ray-plugin%3Bhost%3Dwww.google.com"

clear
echo -e "${GREEN}--- FREEDOM ACTIVATED ---${NC}"
echo -e "${CYAN}Shadowsocks Link:${NC}"
echo -e "$SS_LINK\n"
qrencode -t ansiutf8 "$SS_LINK"

echo -e "${YELLOW}Note for v2rayNG users:${NC}"
echo -e "If import fails, add manually: Method=chacha20-ietf-poly1305, Port=443, Plugin=v2ray-plugin, Option=host=www.google.com"
