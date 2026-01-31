#!/bin/bash

clear
echo -e "\033[1;36m--- SHADOWSOCKS PRO INSTALLER by T ---\033[0m"

# 1. TOTAL SNAP PURGE (Preventing the 255/EXCEPTION loop)
echo -e "\033[1;33mRemoving conflicting Snap services...\033[0m"
sudo systemctl stop shadowsocks-libev-server@config.service 2>/dev/null
sudo systemctl disable shadowsocks-libev-server@config.service 2>/dev/null
sudo rm -f /etc/systemd/system/shadowsocks-libev-server@config.service
sudo snap remove shadowsocks-libev 2>/dev/null
sudo systemctl daemon-reload

# 2. Install Native Dependencies & QR Tool
sudo apt-get update
sudo apt-get install -y shadowsocks-libev jq wget tar python3 qrencode

# 3. Enable TCP BBR (Speed Booster)
echo -e "\033[1;32mEnabling TCP BBR Speed Booster...\033[0m"
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p > /dev/null
fi

# 4. User Inputs
read -p " Enter Shadowsocks port (default 443): " port
port=${port:-443}
read -p " Enter Password: " password
while [ -z "$password" ]; do
    read -p " Password cannot be empty: " password
done

# 5. Install v2ray-plugin (Native)
echo "Setting up obfuscation (v2ray-plugin)..."
wget -q https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
sudo mv v2ray-plugin-linux-amd64 /usr/bin/v2ray-plugin
sudo chmod +x /usr/bin/v2ray-plugin
sudo setcap cap_net_bind_service+ep /usr/bin/v2ray-plugin
rm v2ray-plugin-linux-amd64-v1.3.2.tar.gz

# 6. Configuration
sudo mkdir -p /etc/shadowsocks-libev
echo "{
    \"server\":\"0.0.0.0\",
    \"server_port\":$port,
    \"password\":\"$password\",
    \"timeout\":60,
    \"method\":\"chacha20-ietf-poly1305\",
    \"plugin\":\"v2ray-plugin\",
    \"plugin_opts\":\"server;tls;host=www.google.com\"
}" | sudo tee /etc/shadowsocks-libev/config.json > /dev/null

# 7. Create Native Service
sudo echo -e "[Unit]\nDescription=Shadowsocks-T\nAfter=network.target\n\n[Service]\nType=simple\nUser=root\nExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target" | sudo tee /etc/systemd/system/shadowsocks.service > /dev/null

sudo ufw allow $port/tcp 2>/dev/null
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks.service
sudo systemctl restart shadowsocks.service

# 8. Generate SS Link & QR Code
IP=$(curl -s http://checkip.dyndns.org | grep -Eo '[0-9\.]+')
METHOD="chacha20-ietf-poly1305"
USER_INFO=$(echo -n "${METHOD}:${password}" | base64 | tr -d '\n' | tr '/+' '_-' | tr -d '=')
PLUGIN_OPTS=$(echo -n "v2ray-plugin;tls;host=www.google.com" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")
SS_LINK="ss://${USER_INFO}@${IP}:${port}/?plugin=${PLUGIN_OPTS}"

clear
echo -e "\033[1;32m--- FREEDOM ACTIVATED BY T ---\033[0m"
echo -e "\033[1;33mIP: $IP  |  Port: $port\033[0m"
echo " "
echo -e "\033[1;36mSCAN THIS QR CODE WITH YOUR PHONE:\033[0m"
qrencode -t ansiutf8 "$SS_LINK"
echo " "
echo -e "\033[1;36mOR COPY THIS LINK:\033[0m"
echo -e "\033[1;37m$SS_LINK\033[0m"
echo " "
sudo systemctl status shadowsocks --no-pager
