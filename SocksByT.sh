#!/bin/bash

echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y
sudo apt install -y snapd
sudo snap install shadowsocks-libev
sudo mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
echo "System update complete!"

echo "Enter the password for shadowsocks:"
read password

while [ -z "$password" ]; do
    echo "Password cannot be left blank. Please enter a password:"
    read password
done

echo "Enter the port number for shadowsocks:"
read port

if [ -z "$port" ]; then
    port=443
    echo "Port number left blank, using default value 443"
fi

echo "{
   \"server\":[\"0.0.0.0\", \"::0\"],
   \"mode\":\"tcp_and_udp\",
   \"server_port\":$port,
   \"password\":\"$password\",
   \"timeout\":60,
   \"method\":\"chacha20-ietf-poly1305\",
   \"nameserver\":\"1.1.1.1\"

}" | sudo tee /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json

sudo touch /etc/systemd/system/shadowsocks-libev-server@.service
echo "[Unit]
Description=Shadowsocks-Libev Custom Server Service for %I
Documentation=man:ss-server(1)
After=network-online.target
    
[Service]
Type=simple
ExecStart=/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json
    
[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/shadowsocks-libev-server@.service
sudo systemctl enable --now shadowsocks-libev-server@config

sudo ufw allow $port/tcp
sudo ufw allow $port/udp
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

echo "Shadowsocks-Libev server has been configured and started."

# add the cron job
echo "@daily  sudo apt update && sudo apt upgrade -y" | crontab -

echo "Server password: $password"
echo "Server port: $port"
echo "Password method: chacha20-ietf-poly1305"
