#!/bin/bash

clear
read -p "Enter server port: " port
read -p "Enter password: " password

if [ -z "$port" ]; then
  port=443
fi

if [ -z "$password" ]; then
  password=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
fi

sudo apt install -y snapd
sudo snap install shadowsocks-libev
sudo mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
sudo touch /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json
echo "{
   \"server\":[\"::0\", \"0.0.0.0\"],
   \"mode\":\"tcp_and_udp\",
   \"server_port\":$port,
   \"password\":\"$password\",
   \"timeout\":60,
   \"method\":\"chacha20-ietf-poly1305\",
   \"nameserver\":\"1.1.1.1\"
}" | sudo tee -a /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json
sudo touch /etc/systemd/system/shadowsocks-libev-server@.service
sudo echo -e "[Unit]\nDescription=Shadowsocks-Libev Custom Server Service for %I\nDocumentation=man:ss-server(1)\nAfter=network-online.target\n\n[Service]\nType=simple\nExecStart=/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/%i.json\n\n[Install]\nWantedBy=multi-user.target" |sudo tee -a /etc/systemd/system/shadowsocks-libev-server@.service
sudo ufw allow $port
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo systemctl enable --now shadowsocks-libev-server@config

clear

echo "Port: $port"
echo "Password: $password"

