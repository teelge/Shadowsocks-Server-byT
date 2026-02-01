#!/bin/bash
clear
echo -e "\033[0;36m==============================================\033[0m"
echo -e "\033[0;36m    SHADOWSOCKS - PURE MODE (NO PLUGIN)      \033[0m"
echo -e "\033[0;36m==============================================\033[0m"

# 1. Clean everything
sudo systemctl stop ss-troy 2>/dev/null
sudo apt-get update && sudo apt-get install -y shadowsocks-libev qrencode

# 2. Set Password
printf "\033[0;33mSet Password: \033[0m"
read -r password < /dev/tty

# 3. Simple Config (Optimized for Speed)
cat <<EOF | sudo tee /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":8388,
    "password":"$password",
    "timeout":300,
    "method":"chacha20-ietf-poly1305",
    "fast_open":true,
    "mode":"tcp_and_udp"
}
EOF

# 4. Critical Kernel Routing Fix
sudo sysctl -w net.ipv4.ip_forward=1
sudo ufw allow 8388/tcp
sudo ufw allow 8388/udp

# 5. Restart
sudo systemctl daemon-reload
sudo systemctl restart shadowsocks-libev

# 6. Generate Link
IP=$(curl -s https://api.ipify.org)
CONF=$(echo -n "chacha20-ietf-poly1305:$password" | base64 | tr -d '\n\r')
LINK="ss://$CONF@$IP:8388#PureShadowsocks"

echo -e "\n\033[0;32m--- SETUP COMPLETE ---\033[0m"
echo -e "Link: $LINK\n"
qrencode -t ansiutf8 "$LINK"
