#!/bin/bash

# Remove any old snap versions to prevent conflicts
if snap list | grep -q shadowsocks-libev; then
    echo "Cleaning up old Snap installation..."
    sudo systemctl stop shadowsocks-libev-server@config.service
    sudo snap remove shadowsocks-libev
    sudo rm -rf /var/snap/shadowsocks-libev
fi

clear
echo "--- SHADOWSOCKS + V2RAY-PLUGIN INSTALLER ---"

# Port Selection
read -p " Enter Shadowsocks port (default: 443): " port
port=${port:-443}

# Password Selection
read -p "Enter password: " password
while [ -z "$password" ]; do
    read -p "A password is required: " password
done

# Install Native Dependencies
sudo apt-get update
sudo apt-get install -y shadowsocks-libev jq wget tar python3

# Install v2ray-plugin
echo "Downloading v2ray-plugin..."
wget -q https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
sudo mv v2ray-plugin-linux-amd64 /usr/local/bin/v2ray-plugin
sudo chmod +x /usr/local/bin/v2ray-plugin
rm v2ray-plugin-linux-amd64-v1.3.2.tar.gz

# Create Config Directory
sudo mkdir -p /etc/shadowsocks-libev

# Generate Config (Native Path)
echo "{
    \"server\":\"0.0.0.0\",
    \"server_port\":$port,
    \"password\":\"$password\",
    \"timeout\":60,
    \"method\":\"chacha20-ietf-poly1305\",
    \"plugin\":\"v2ray-plugin\",
    \"plugin_opts\":\"server;tls;host=www.google.com\"
}" | sudo tee /etc/shadowsocks-libev/config.json > /dev/null

# Restart and Enable Service
sudo systemctl stop shadowsocks-libev
sudo systemctl enable shadowsocks-libev
sudo systemctl restart shadowsocks-libev

# Generate SS Link
IP=$(curl -s http://checkip.dyndns.org | grep -Eo '[0-9\.]+')
METHOD="chacha20-ietf-poly1305"
USER_INFO=$(echo -n "${METHOD}:${password}" | base64 | tr -d '\n' | tr '/+' '_-' | tr -d '=')
PLUGIN_OPTS=$(echo -n "v2ray-plugin;tls;host=www.google.com" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")
SS_LINK="ss://${USER_INFO}@${IP}:${port}/?plugin=${PLUGIN_OPTS}"

clear
echo -e "\033[1m\033[32m--- FREEDOM ACTIVATED BY T ---\033[0m"
echo -e "\033[1m\033[33mIP: $IP  |  Port: $port\033[0m"
echo " "
echo -e "\033[1m\033[36mSS Link for Client:\033[0m"
echo -e "\033[1;37m$SS_LINK\033[0m"
echo " "
sudo systemctl status shadowsocks-libev
