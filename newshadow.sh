#!/bin/bash

# 1. Cleanup old Snap installation to prevent port conflicts
if snap list | grep -q shadowsocks-libev; then
    echo "Removing old Snap version..."
    sudo systemctl stop shadowsocks-libev-server@config.service 2>/dev/null
    sudo snap remove shadowsocks-libev
fi

clear
echo "--- SHADOWSOCKS + V2RAY-PLUGIN (NATIVE) ---"

# 2. Port & Password Setup
read -p " Enter Shadowsocks port (default: 443): " port
port=${port:-443}
read -p "Enter password: " password
while [ -z "$password" ]; do
    read -p "A password is required: " password
done

# 3. Install Native Shadowsocks and Dependencies
sudo apt-get update
sudo apt-get install -y shadowsocks-libev jq wget tar python3

# 4. Install v2ray-plugin to a global path
echo "Installing v2ray-plugin..."
wget -q https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
sudo mv v2ray-plugin-linux-amd64 /usr/bin/v2ray-plugin
sudo chmod +x /usr/bin/v2ray-plugin
# Give plugin permission to bind to privileged ports like 443
sudo setcap cap_net_bind_service+ep /usr/bin/v2ray-plugin
rm v2ray-plugin-linux-amd64-v1.3.2.tar.gz

# 5. Create Config (Native Path)
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

# 6. Fix Systemd Service (Native)
# Disable default service and use a clean one
sudo systemctl stop shadowsocks-libev
sudo systemctl disable shadowsocks-libev

sudo echo -e "[Unit]\nDescription=Shadowsocks-Libev Server\nAfter=network.target\n\n[Service]\nType=simple\nUser=root\nExecStart=/usr/bin/ss-server -c /etc/shadowsocks-libev/config.json\nRestart=on-failure\n\n[Install]\nWantedBy=multi-user.target" | sudo tee /etc/systemd/system/shadowsocks.service > /dev/null

# 7. Start and Verify
sudo ufw allow $port/tcp
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks.service
sudo systemctl restart shadowsocks.service

# 8. Generate SS Link
IP=$(curl -s http://checkip.dyndns.org | grep -Eo '[0-9\.]+')
METHOD="chacha20-ietf-poly1305"
USER_INFO=$(echo -n "${METHOD}:${password}" | base64 | tr -d '\n' | tr '/+' '_-' | tr -d '=')
PLUGIN_OPTS=$(echo -n "v2ray-plugin;tls;host=www.google.com" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")
SS_LINK="ss://${USER_INFO}@${IP}:${port}/?plugin=${PLUGIN_OPTS}"

clear
echo -e "\033[1m\033[32m--- FREEDOM ACTIVATED BY T ---\033[0m"
echo -e "\033[1m\033[33mIP: $IP  |  Port: $port\033[0m"
echo " "
echo -e "\033[1m\033[36mCopy and Paste this link into your Client:\033[0m"
echo -e "\033[1;37m$SS_LINK\033[0m"
echo " "
sudo systemctl status shadowsocks
