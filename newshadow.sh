#!/bin/bash
# --- COLOR CODES ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

clear
echo -e "${CYAN}==============================================${NC}"
echo -e "${CYAN}    SHADOWSOCKS PRO - REPAIR EDITION         ${NC}"
echo -e "${CYAN}==============================================${NC}"

# 1. CLEANUP & RESET FIREWALL
sudo systemctl stop ss-troy 2>/dev/null
sudo ufw allow 443/tcp
sudo ufw allow 443/udp

# 2. CONFIGURATION (STRICT WEBSOCKET)
printf "${CYAN}Enter your password (e.g., troy00): ${NC}"
read -r password < /dev/tty

cat <<EOF | sudo tee /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":443,
    "password":"$password",
    "timeout":300,
    "method":"chacha20-ietf-poly1305",
    "plugin":"v2ray-plugin",
    "plugin_opts":"server;host=www.google.com;mode=websocket",
    "fast_open":true,
    "reuse_port":true,
    "mode":"tcp_and_udp"
}
EOF

# 3. KERNEL OPTIMIZATION (THE INTERNET FIX)
# This ensures the server actually routes the traffic to the web
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.core.rmem_max=67108864
sudo sysctl -w net.core.wmem_max=67108864
sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864"
sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864"
sudo sysctl -w net.ipv4.tcp_mtu_probing=1

# 4. RESTART SERVICE
sudo systemctl daemon-reload
sudo systemctl restart ss-troy

# 5. GENERATE CLEAN LINK
IP=$(curl -s https://api.ipify.org)
USER_PASS_B64=$(echo -n "chacha20-ietf-poly1305:$password" | base64 | tr -d '\n\r')
SS_LINK="ss://${USER_PASS_B64}@${IP}:443/?plugin=v2ray-plugin%3Bhost%3Dwww.google.com%3Bmode%3Dwebsocket"

clear
echo -e "${GREEN}--- REPAIR COMPLETE ---${NC}"
echo -e "${YELLOW}NEW LINK (Copy this exactly):${NC}"
echo -e "$SS_LINK\n"
qrencode -t ansiutf8 "$SS_LINK"
