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
        sudo snap remove shadowsocks-libev
        sudo systemctl stop shadowsocks-libev-server@config.service
        sudo systemctl disable shadowsocks-libev-server@config.service
        sudo rm /etc/systemd/system/shadowsocks-libev-server@config.service
        sudo rm /usr/local/bin/v2ray-plugin
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
        # Extract data for re-displaying the link
        CONF="/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json"
        IP=$(curl -s http://checkip.dyndns.org | grep -Eo '[0-9\.]+')
        PORT=$(jq -r '.server_port' $CONF)
        PASS=$(jq -r '.password' $CONF)
        METHOD=$(jq -r '.method' $CONF)
        # Generate the Link again
        USER_INFO=$(echo -n "${METHOD}:${PASS}" | base64 | tr -d '\n' | tr '/+' '_-' | tr -d '=')
        PLUGIN_OPTS=$(echo -n "v2ray-plugin;tls;host=www.google.com" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")
        SS_LINK="ss://${USER_INFO}@${IP}:${PORT}/?plugin=${PLUGIN_OPTS}"
        
        echo " "
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
    echo " "
    echo "Choose a port number (443 is best for hiding traffic) "
    echo " "
    read -p " Enter Shadowsocks port [1-65535](default: 443):" port
    if [ -z "$port" ]; then
      port=443
      break
    else
      case $port in
        [1-9]|[1-9][0-9]|[1-9][0-9][0-9]|[1-5][0-9][0-9][0-9]|6[0-4][0-9][0-9]|65[0-4][0-9]|655[0-3][0-5])
          break;;
        *)
          echo "Invalid port.";;
      esac
    fi
done

clear

# Password Selection
read -p "Enter password:" password
while [ -z "$password" ]
do
  read -p "A password is required: " password
done

# Install Dependencies
sudo apt-get update
sudo apt-get install -y jq wget tar snapd python3

# Install v2ray-plugin
echo "Downloading v2ray-plugin..."
wget -q https://github.com/shadowsocks/v2ray-plugin/releases/download/v1.3.2/v2ray-plugin-linux-amd64-v1.3.2.tar.gz
tar -xf v2ray-plugin-linux-amd64-v1.3.2.tar.gz
sudo mv v2ray-plugin-linux-amd64 /usr/local/bin/v2ray-plugin
sudo chmod +x /usr/local/bin/v2ray-plugin
rm v2ray-plugin-linux-amd64-v1.3.2.tar.gz

# Install Shadowsocks
sudo snap install shadowsocks-libev
sudo mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev

# Generate Config
echo "{
    \"server\":[\"::0\", \"0.0.0.0\"],
    \"mode\":\"tcp_and_udp\",
    \"server_port\":$port,
    \"password\":\"$password\",
    \"timeout\":60,
    \"method\":\"chacha20-ietf-poly1305\",
    \"nameserver\":\"1.1.1.1\",
    \"plugin\":\"v2ray-plugin\",
    \"plugin_opts\":\"server;tls;host=www.google.com\"
}" | sudo tee /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json

# Create Systemd Service
sudo echo -e "[Unit]\nDescription=Shadowsocks-Libev with Obfuscation\nAfter=network-online.target\n\n[Service]\nType=simple\nExecStart=/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json\n\n[Install]\nWantedBy=multi-user.target" | sudo tee /etc/systemd/system/shadowsocks-libev-server@config.service

sudo ufw allow $port
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
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
echo -e "\033[1m\033[33mPassword: $password\033[0m"
echo " "
echo -e "\033[1m\033[36mCopy and Paste this link into your Shadowsocks Client:\033[0m"
echo -e "\033[1;37m$SS_LINK\033[0m"
echo " "
echo -e "\033[0;31mNote: Ensure Port $port is open in your cloud firewall (AWS/GCP/Oracle).\033[0m"

read -p "Show server status (y/n)? " choice
if [ "$choice" = "y" ]; then
  sudo systemctl status shadowsocks-libev-server@config
fi
