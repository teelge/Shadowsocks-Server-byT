#!/bin/bash

clear

# Check if package is already installed
if snap list | grep -q shadowsocks-libev; then
    echo "Shadowsocks Server Is Already Installed !! "
    echo " "
    echo "What Do You Want To Do? "
    echo " "
    echo "UNINSTALL = 1 "
    echo " "
    echo "CHECK STATUS = 2 "
    echo " "
    echo "VIEW SETTINGS & LINK = 3 "
    echo " "
    read -p "1, 2, OR 3 ? : " choice
    if [ "$choice" = "1" ]; then
        clear
        echo " "
        echo "        Uninstalling .. "
        echo " "
        sudo systemctl stop shadowsocks-libev-server@config.service
        sudo systemctl disable shadowsocks-libev-server@config.service
        sudo snap remove shadowsocks-libev
        sudo rm /etc/systemd/system/shadowsocks-libev-server@config.service
        sudo rm -rf /var/snap/shadowsocks-libev/common/bin/
        clear        
        echo " "
        echo "    Shadowsocks has been uninstalled. "
        echo " "
        exit 0
    elif [ "$choice" = "2" ]; then
        sudo systemctl status shadowsocks-libev-server@config
        exit 0
    elif [ "$choice" = "3" ]; then
        clear
        CONF="/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json"
        if [ ! -f "$CONF" ]; then echo "Config file not found."; exit 1; fi
        IP=$(curl -s http://checkip.dyndns.org | grep -Eo '[0-9\.]+')
        PORT=$(jq -r '.server_port' $CONF)
        PASS=$(jq -r '.password' $CONF)
        METHOD=$(jq -r '.method' $CONF)
        USER_INFO=$(echo -n "${METHOD}:${PASS}" | base64 | tr -d '\n' | tr '/+' '_-' | tr -d '=')
        PLUGIN_OPTS=$(echo -n "v2ray-plugin;tls;host=www.google.com" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")
        SS_LINK="ss://${USER_INFO}@${IP}:${PORT}/?plugin=${PLUGIN_OPTS}"
        echo "    Server External IP: $IP"
        echo "    Server Port: $PORT"
        echo "    Password: $PASS"
        echo "    Method: $METHOD"
        echo " "
        echo -e "\033[1m\033[32mYour SS Link:\033[0m"
        echo -e "\033[1m$SS_LINK\033[0m"
        echo " "
        exit 0
    fi
fi

clear

# Port Selection
while true; do
    echo "Choose a port (443 is recommended for obfuscation)"
    read -p " Enter Shadowsocks port (default: 443): " port
    port=${port:-443}
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        break
    else
        echo "Invalid port."
    fi
done

# Password Selection
read -p "Enter password: " password
while [ -z "$password" ]; do
    read -p "A password is required: " password
done

# Install Dependencies
sudo apt-get update
sudo apt-get install -y jq wget tar snapd python3

# Install Shadowsocks via Snap
sudo snap install shadowsocks-libev
sudo mkdir -p /var/snap/shadowsocks-libev/common/bin
sudo mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev

# Install v2ray-plugin inside the Snap directory
echo "Installing v2ray-plugin for Snap..."
wget -q https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
sudo mv v2ray-plugin-linux-amd64 /var/snap/shadowsocks-libev/common/bin/v2ray-plugin
sudo chmod +x /var/snap/shadowsocks-libev/common/bin/v2ray-plugin
rm v2ray-plugin-linux-amd64-v1.3.2.tar.gz

# Generate Config with the CORRECT plugin path for Snap
echo "{
    \"server\":[\"::0\", \"0.0.0.0\"],
    \"mode\":\"tcp_and_udp\",
    \"server_port\":$port,
    \"password\":\"$password\",
    \"timeout\":60,
    \"method\":\"chacha20-ietf-poly1305\",
    \"nameserver\":\"1.1.1.1\",
    \"plugin\":\"/var/snap/shadowsocks-libev/common/bin/v2ray-plugin\",
    \"plugin_opts\":\"server;tls;host=www.google.com\"
}" | sudo tee /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json > /dev/null

# Create Systemd Service
sudo echo -e "[Unit]\nDescription=Shadowsocks-Libev with v2ray-plugin\nAfter=network-online.target\n\n[Service]\nType=simple\nExecStart=/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json\nRestart=on-failure\nRestartSec=5\n\n[Install]\nWantedBy=multi-user.target" | sudo tee /etc/systemd/system/shadowsocks-libev-server@config.service > /dev/null

# Firewall and System Tweaks
sudo ufw allow $port
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null

# Start Service
sudo systemctl daemon-reload
sudo systemctl enable --now shadowsocks-libev-server@config

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
echo -e "\033[1m\033[36mCopy and Paste this link into your Client:\033[0m"
echo -e "\033[1;37m$SS_LINK\033[0m"
echo " "
sleep 2
read -p "Show server status (y/n)? " choice
if [ "$choice" = "y" ]; then
  sudo systemctl status shadowsocks-libev-server@config
fi
