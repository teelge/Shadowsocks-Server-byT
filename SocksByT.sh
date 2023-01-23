#!/bin/bash

clear

while true; do
    echo "What do you want to do?"
    echo "1) Install"
    echo "2) Uninstall"
    read -p "Enter your option: " option
    case $option in
        1)
            echo "You have selected option 1: Install."
            break;;
        2)
            echo "You have selected option 2: Uninstall."
            sudo systemctl stop shadowsocks-libev-server@config
            sudo systemctl disable shadowsocks-libev-server@config
            sudo snap remove shadowsocks-libev
            sudo rm -rf /var/snap/shadowsocks-libev
            echo "Shadowsocks-libev Uninstalled"
            break;;
        *)
            echo "Invalid option. Please enter '1' for install or '2' for uninstall.";;
    esac
done

if [ "$option" = "1" ]; then
    clear
    while true; do
        read -p "Enter Shadowsocks port [1-65535](default: 443):" port
        if [ -z "$port" ]; then
          port=443
          break
        else
          case $port in
            [1-9]|[1-9][0-9]|[1-9][0-9][0-9]|[1-5][0-9][0-9][0-9]|6[0-4][0-9][0-9]|65[0-4][0-9]|655[0-3][0-5])
              echo "Valid port"
              break;;
            *)
              echo "Invalid port. Please enter a number between 1-65535.";;
          esac
        fi
    done

    clear

    read -p "Enter password:" password

    while [ -z "$password" ]
    do
      echo "A password is required. Please enter a password:"
      read -p "Enter password: " password
    done

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
external_ip=$(curl -s http://checkip.dyndns.org | grep -Eo '[0-9\.]+')

echo "Please Wait "
sleep 1
clear

echo -e "\033[1m\033[33mServer's External IP: $external_ip\033[0m"
echo -e "\033[1m\033[33mPort: $port\033[0m"
echo -e "\033[1m\033[33mPassword: $password\033[0m"
echo -e "\033[1m\033[33mMethod: chacha20-ietf-poly1305\033[0m"


read -p "Do you want to see the status of your server? (y/n)? " choice
if [ "$choice" = "y" ]; then
  sudo systemctl status shadowsocks-libev-server@config
else
  echo "FREEDOM ACTIVATED BY T. "
fi

echo -e "\033[0;31mMake Sure that the TCP port That You Chose in the script ( $port ) is open by opening it on your router or server provider's network settings. Otherwise, you will not be able to connect to the server.\033[0m"

